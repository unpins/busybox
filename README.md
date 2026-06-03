# busybox

Standalone build of [busybox](https://busybox.net/), the famous Swiss-army-knife UNIX userland packaged as a single multicall binary with ~395 programs — `ls`, `cat`, `cp`, `mv`, `sed`, `awk`, `grep`, `tar`, `gzip`, `vi`, `top`, `ps`, `kill`, `mount`, `ifconfig`, `ip`, `dhcpc`, `httpd`, `init`, `mdev`, `udhcpc`, …

[![CI](https://github.com/unpins/busybox/actions/workflows/busybox.yml/badge.svg)](https://github.com/unpins/busybox/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

Linux-only: busybox upstream targets the Linux kernel (Linux-specific syscalls, `/proc`, `/sys`, namespaces, `mount`, `switch_root`, etc.).

## Usage

busybox is one binary with ~395 programs. Run it bare to list them:

```bash
unpin busybox
```

Run one of its programs:

```bash
unpin busybox ls -la /etc
unpin busybox sed -i 's/foo/bar/g' file.txt
```

To install onto your PATH (each program becomes its own command — `ls`, `cat`, `sed`, …):

```bash
unpin install busybox
```

`busybox --list` prints every built-in program (~395 in this configuration; busybox's own docs call them *applets*). Most are materialized as `unpin install` aliases; exceptions: `[`/`[[` (shell built-ins) and `sh`/`su` (excluded by the unpins validator to avoid shadowing system tools — still callable as `busybox sh`/`busybox su`).

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

## Build notes

- **Tests:** busybox's testsuite isn't run — most cases drive applets needing root, `/proc`, `/sys`, network and a writable FHS, none available in the build sandbox. The `busybox --list` smoke is the floor.
