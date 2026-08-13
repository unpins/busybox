{
  description = "busybox as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # busybox is already a single-binary multicall by design — `bin/busybox`
  # plus 396 argv[0]-dispatch symlinks (`ls`, `sh`, `vi`, `mount`, …), one per
  # configured applet. Mirrors the kmod/coreutils pattern: ship only the
  # multicall, embed the applet names as an UNPIN_META block so unpin's
  # installer can recreate the symlinks at install time. No `multicall` option
  # on purpose — busybox names none of its applets to nix-lib, so the embed
  # wrap harvests the symlinks the build itself installed (nix-lib documents
  # this package as the case that path exists for).
  #
  # Linux-only: busybox upstream targets the Linux kernel (Linux-specific
  # syscalls, /proc, /sys, namespaces, mount, switch_root). nixpkgs
  # `meta.platforms` lists every Linux arch and nothing else.
  #
  # No `engine = "unpin-llvm"`: kbuild pipes every `-MD` depfile through
  # `fixdep`, which opens each header the compiler recorded. The engine clang
  # serves libc from a virtual root inside the compiler image
  # (`/__unpin_ziglib__/…`, nix-lib toolchain/unpin_clang_vfs.cpp) that has no
  # on-disk existence, so fixdep dies on the very first object, applets.o
  # ("No such file or directory" on `.../generic-musl/limits.h`) — measured on
  # x86_64 and i686. Same class as libvpx, which escapes with
  # `--disable-dependency-tracking`; kbuild has no such switch.
  #
  # nixpkgs also drops a `sbin → bin` symlink, a `linuxrc → bin/busybox`
  # symlink and a `default.script` initramfs helper at the package root. None
  # of the three reach `result/` — nix-lib's embed wrap rebuilds the output
  # from `bin/<primary>` plus `share/man` — but they are live input to the
  # alias harvest, which reads this build's own tree. Hence the two fixups
  # below.
  #
  # Why merge sbin→bin in postInstall: busybox installs its applets across two
  # dirs (`bin/` and `sbin/` from `busybox.links` — 265 + 130 in the current
  # nixpkgs build), and the alias list shipped in the binary is harvested from
  # the symlinks in `bin/` alone. The standard `_moveSbinToBin`
  # fixupOutputHook would merge them, but leaving 130 applets (depmod, mount,
  # fdisk, lsmod, …) to a hook's ordering is how they go missing silently;
  # doing it here makes the merge a property of the build. `_moveSbinToBin`
  # then no-ops because sbin is already a symlink.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      dnsFallback = true; # resolves hostnames; opt into the Android DNS fallback
      name = "busybox";
      smoke = [ "--help" ];
      smokePattern = "BusyBox v[0-9]+\\.[0-9]+";
      linuxOnly = true;
      build = pkgs:
        let
          prepared = (pkgs.pkgsStatic.busybox.override {
            # nixpkgs compiles `$out/default.script` in as udhcpc's built-in
            # script path — right for a NixOS system, wrong for a binary we
            # ship on its own. It puts an absolute store path in the shipped
            # artifact (visible in `udhcpc --help` and in the generated man
            # page) and makes the output RETAIN a runtime reference to the
            # build tree, which the embed wrap does not ship: the closure
            # carries 2.9 MB for a 1.3 MB binary, all of it dead. Restore
            # busybox's own default; `udhcpc -s PROG` still takes any script.
            extraConfig = ''
              CONFIG_UDHCPC_DEFAULT_SCRIPT "/usr/share/udhcpc/default.script"
            '';
          }).overrideAttrs (old: {
            # Teach busybox unpins' uniform `--unpin-program=NAME` multicall
            # selector (a synonym of the native `busybox <applet>` form), so
            # every catalog multicall is driven the same way. See
            # docs/multicall.md. Alias symlinks keep dispatching on argv[0].
            patches = (old.patches or [ ]) ++ [ ./busybox-unpin-program.patch ];

            # No tests: busybox's testsuite drives applets that need root,
            # /proc, /sys, network and a writable FHS — none available in the
            # Nix build sandbox, so most cases error out. The floor is CI's
            # applet sweep: `--help` through both dispatch paths for all 396
            # names, on each native host.
            doCheck = false;
            # busybox's man page is POD: `make doc` runs applets/usage_pod
            # (built from the configured usage messages) through pod2man to emit
            # docs/busybox.1 — one page documenting every applet. nixpkgs builds
            # without perl, and the Makefile's `-pod2man` swallows the resulting
            # failure (leading `-`), so no man ships. Add perl + generate it so
            # mkStandaloneFlake's withMan embeds it (.unpin_man / `unpin man`).
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.buildPackages.perl ];
            postBuild = (old.postBuild or "") + ''
              make docs/busybox.1
              test -s docs/busybox.1   # pod2man's errors are ignored upstream; fail loud if empty
            '';
            postInstall = (old.postInstall or "") + ''
              install -Dm644 docs/busybox.1 "$out/share/man/man1/busybox.1"
              # Merge sbin/ into bin/ so the shipping embed harvests every
              # applet, not just the bin/-installed subset. Idempotent — noop
              # when sbin is already a symlink (re-runs, cached builds).
              if [ -d "$out/sbin" ] && [ ! -L "$out/sbin" ]; then
                echo "unpins(busybox): merging $out/sbin/* into $out/bin"
                for f in "$out/sbin"/*; do
                  mv "$f" "$out/bin/" 2>/dev/null || true
                done
                rmdir "$out/sbin" 2>/dev/null || true
                ln -s bin "$out/sbin"
              fi
              # `linuxrc` is the initramfs PID-1 entry name the kernel runs when
              # the root device is an initrd. Upstream busybox install drops it at
              # the package root (`$out/linuxrc → bin/busybox`); we hoist it into
              # bin/ so the harvest picks it up alongside the other applets.
              if [ -L "$out/linuxrc" ] && [ ! -e "$out/bin/linuxrc" ]; then
                ln -s busybox "$out/bin/linuxrc"
              fi
            '';
          });
        in
        prepared;
    };
}
