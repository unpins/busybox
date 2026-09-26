# Changelog

## [Unreleased]

## [1.37.0-2] - 2026-09-26

### Changed

- Built by the same compiler as the rest of the catalog (clang, in place of
  gcc). The binary is larger: 2.06 MB against 1.30 MB on x86_64.

### Fixed

- `udhcpc` no longer has a path from the machine that built it compiled in as
  its default script. The path showed up in `udhcpc --help` and in the manual
  page and pointed at a directory that is not shipped. It is back to busybox's
  own default, `/usr/share/udhcpc/default.script`; `udhcpc -s PROG` still takes
  any script you name.

### Changed

- `unpin install busybox` now puts all 396 programs on your PATH. It previously
  linked only `busybox` itself, so every program had to be called as
  `busybox <name>`.
