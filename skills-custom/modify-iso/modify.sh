#!/usr/bin/env bash
set -euo pipefail

iso="${1:?usage: modify.sh <iso-path> [--password <pw>] [boot-param ...]}"
shift

password="nots3cr3t"
extra_params=()

while [ $# -gt 0 ]; do
  case "$1" in
    --password)
      password="${2:?--password requires a value}"
      shift 2
      ;;
    *)
      extra_params+=("$1")
      shift
      ;;
  esac
done

case "$iso" in
  *.iso) ;;
  *) echo "not an iso file: $iso" >&2; exit 1 ;;
esac

if [ ! -f "$iso" ]; then
  echo "iso not found: $iso" >&2
  exit 1
fi

command -v mkmedia >/dev/null 2>&1 || { echo "mkmedia not found (zypper in mkmedia)" >&2; exit 1; }
command -v xorriso >/dev/null 2>&1 || { echo "xorriso not found (zypper in xorriso)" >&2; exit 1; }

dir="$(dirname "$iso")"
base="$(basename "$iso" .iso)"
out="$dir/$base-modified.iso"
rm -f "$out"

boot_params="live.password=$password"
for p in "${extra_params[@]}"; do
  boot_params="$boot_params $p"
done

# mkmedia only needs root to loop-mount an iso *file*; feeding it an
# already-unpacked directory avoids that mount entirely (unprivileged).
tmpdir="$(mktemp -d)"
# extracted ISO files are read-only; make them writable or rm fails
trap 'chmod -R u+w "$tmpdir"; rm -rf "$tmpdir"' EXIT
xorriso -indev "$iso" -osirrox on -extract / "$tmpdir" >/dev/null

mkmedia --create "$out" --boot "$boot_params" "$tmpdir"

echo "$out"
