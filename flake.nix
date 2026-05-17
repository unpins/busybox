{
  description = "Standalone build of busybox";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "busybox";
      # busybox upstream targets the Linux kernel (Linux-specific syscalls,
      # /proc, /sys, namespaces, mount, switch_root). nixpkgs
      # `meta.platforms` lists Linux arches only.
      linuxOnly = true;
    };
}
