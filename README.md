# busybox

Standalone build of [busybox](https://busybox.net/), the famous Swiss-army-knife UNIX userland packaged as a single multicall binary. argv[0] dispatch to ~395 applets — `ls`, `cat`, `cp`, `mv`, `sed`, `awk`, `grep`, `tar`, `gzip`, `vi`, `top`, `ps`, `kill`, `mount`, `ifconfig`, `ip`, `dhcpc`, `httpd`, `init`, `mdev`, `udhcpc`, …

[![CI](https://github.com/unpins/busybox/actions/workflows/busybox.yml/badge.svg)](https://github.com/unpins/busybox/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

Linux-only: busybox upstream targets the Linux kernel (Linux-specific syscalls, `/proc`, `/sys`, namespaces, `mount`, `switch_root`, etc.).

## Usage

The package ships one executable, `busybox`. `unpin install` materializes per-applet shims (`ls`, `cat`, `sed`, …) next to the multicall using argv[0] dispatch. To run a command directly without installing, invoke as `busybox <applet>`:

```bash
busybox ls -la /etc
busybox tar czf data.tar.gz /var/data
busybox sed -i 's/foo/bar/g' file.txt
busybox httpd -p 8080 -h /srv/www
```

Or create symlinks named after the commands you want to use as bare names:

```bash
ln -s "$(command -v busybox)" ~/bin/ls
ls -la /etc
```

`busybox --list` prints every built-in applet name (~395 in this configuration). `busybox --help` lists usage for the full set. Most names are also embedded as `unpin install` aliases — exceptions: `[`/`[[` (shell built-ins), `sh`/`su` (excluded by the unpins validator to avoid shadowing system tools — still callable via `busybox sh`/`busybox su`).

## Installation

Install with [unpin](https://github.com/unpins/unpin):

```bash
unpin busybox
```

Or run without installing:

```bash
unpin run busybox
```

## Build locally

```bash
nix build github:unpins/busybox
./result/bin/busybox --list | head
```

Or run directly:

```bash
nix run github:unpins/busybox -- ls -la
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/busybox/releases) page has standalone binaries for manual download.
