{
  description = "Standalone build of busybox";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # busybox is already a single-binary multicall by design — `bin/busybox`
  # plus 394 argv[0]-dispatch symlinks (`ls`, `sh`, `vi`, `mount`, …)
  # covering every configured applet. Mirrors the kmod/coreutils pattern:
  # ship only the multicall, embed the applet names as an UNPIN_META block
  # so unpin's installer can recreate the symlinks at install time.
  #
  # Linux-only: busybox upstream targets the Linux kernel (Linux-specific
  # syscalls, /proc, /sys, namespaces, mount, switch_root). nixpkgs
  # `meta.platforms` lists every Linux arch and nothing else.
  #
  # nixpkgs also drops a `sbin → bin` symlink, a `linuxrc → bin/busybox`
  # symlink, and a `default.script` initramfs helper at the package root.
  # Those are convenience artifacts for embedded/initramfs usage, harmless
  # in `result/` and not shipped by action-build (which tars only the bin).
  #
  # Why the preInstall hop: busybox installs ~395 applets across two dirs
  # (`bin/` and `sbin/` from `busybox.links` — 265 + 130 in the current
  # nixpkgs build). The standard `_moveSbinToBin` fixupOutputHook merges
  # them into `bin/`, BUT it runs in fixupPhase — AFTER `lib.withAliases`'
  # postInstall scan. Without intervention `withAliases` would see only the
  # 265 bin/-installed names; the 130 sbin/-side applets (depmod, mount,
  # fdisk, lsmod, …) would never make it into UNPIN_META, and `unpin
  # install busybox` would materialise only ~265 aliases. Merging sbin→bin
  # in our postInstall — BEFORE withAliases appends its own scan-then-delete
  # pass — gets all 395 picked up. `_moveSbinToBin` then no-ops because
  # sbin is already a symlink.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "busybox";
      linuxOnly = true;
      build = pkgs:
        let
          prepared = pkgs.pkgsStatic.busybox.overrideAttrs (old: {
            # busybox kbuild aggregates per-directory `.o` files into a
            # `built-in.o` via `$(LD) -nostdlib -r`. With our fat-LTO
            # chain that engages lto-plugin which fails to close the
            # relocatable output ("final close failed: invalid operation").
            # We patch scripts/Makefile.build to use thin archives
            # instead of `ld -r` (same approach the Linux kernel takes
            # with CONFIG_THIN_ARCHIVES under LTO): the per-dir aggregate
            # becomes an `ar` thin archive, LTO doesn't engage until the
            # final link, and gcc's lto-plugin scans archive members at
            # that point — preserving full chain-LTO across the tree.
            #
            # AR/NM/RANLIB are pointed at the `gcc-*` wrappers so the
            # archive symbol indexes pick up bitcode symbols (regular
            # `ar` can't read LTO bitcode; the wrappers load lto-plugin).
            patches = (old.patches or [ ]) ++ [ ./lto-thin-archives.patch ];
            makeFlags = (old.makeFlags or [ ]) ++ [
              "AR=gcc-ar"
              "NM=gcc-nm"
              "RANLIB=gcc-ranlib"
            ];
            postInstall = (old.postInstall or "") + ''
              # Merge sbin/ into bin/ so lib.withAliases (appended below) harvests
              # every applet, not just the bin/-installed subset. Idempotent —
              # noop when sbin is already a symlink (re-runs, cached builds).
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
              # bin/ so lib.withAliases picks it up alongside the other applets.
              if [ -L "$out/linuxrc" ] && [ ! -e "$out/bin/linuxrc" ]; then
                ln -s busybox "$out/bin/linuxrc"
              fi
            '';
          });
        in
        unpins-lib.lib.withAliases pkgs
          {
            primary = "busybox";
            aliasesFromSymlinksIn = "bin";
          }
          prepared;
    };
}
