# busybox

[busybox](https://busybox.net/) — the famous Swiss-army-knife UNIX userland, built natively for Linux as a single self-contained binary with 396 programs (`ls`, `cat`, `cp`, `mv`, `sed`, `awk`, `grep`, `tar`, `gzip`, `vi`, `top`, `ps`, `kill`, `mount`, `ip`, `httpd`, `init`, `udhcpc`, …).

[![CI](https://github.com/unpins/busybox/actions/workflows/busybox.yml/badge.svg)](https://github.com/unpins/busybox/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install busybox`.

Linux-only: busybox upstream targets the Linux kernel (Linux-specific syscalls, `/proc`, `/sys`, namespaces, `mount`, `switch_root`, etc.).

## Usage

busybox is one binary with 396 programs. Run it bare to list them:

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

`busybox --list` prints every built-in program (396 in this configuration), and `unpin install` puts all of them on your PATH. One asks first: `su` would shadow the system `su`, so unpin prompts before linking it. Decline and it stays callable as `unpin busybox su`.

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

- **Platforms:** Linux only — x86_64, aarch64, armv7l, i686, ppc64le, riscv64.
- **Tests:** busybox's testsuite isn't run — most cases drive applets needing root, `/proc`, `/sys`, network and a writable FHS, none available in the build sandbox. What CI checks instead is every one of the 396 programs, called both as `busybox <name>` and under its own name, on each native host.
- **Man page:** upstream generates `busybox.1` from the configured usage text and needs perl to do it; the stock nixpkgs build has no perl and silently ships no page. This build adds perl and generates it, so `unpin man busybox` works.
