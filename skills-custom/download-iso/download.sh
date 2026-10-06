#!/usr/bin/env bash
set -euo pipefail

usage="usage: download.sh <iso-url> | <16.0|16.1|16.2> --flavor Online|Full"
arg="${1:?$usage}"
shift
dest_dir="/root/Downloads/isos"

flavor=""
arch="x86_64"   # development only: always x86_64
while [ $# -gt 0 ]; do
  case "$1" in
    --flavor) flavor="${2:?--flavor requires a value}"; shift 2 ;;
    *) echo "$usage" >&2; exit 1 ;;
  esac
done

case "$arg" in
  16.[0-9]*)
    case "$arg" in *[!0-9.]*|*.*.*) echo "invalid version: $arg" >&2; exit 1 ;; esac
    case "$flavor" in Online|Full) ;; *) echo "missing or invalid --flavor (Online|Full): '$flavor'" >&2; exit 1 ;; esac
    base="https://download.suse.de/ibs/SUSE:/SLFO:/Products:/SLES:/$arg:/TEST/product/iso"
    # pick the highest build number (sort -V handles Build75.8 vs Build75.10)
    name="$(curl -fsSk "$base/?json" \
      | grep -o "\"name\":\"SLES-$arg-$flavor-$arch-Build[0-9.]*\.install\.iso\"" \
      | sed -E 's/^"name":"//; s/"$//' | sort -V | tail -n1)"
    [ -n "$name" ] || { echo "no $flavor $arch ISO found for $arg at $base" >&2; exit 1; }
    url="$base/$name"
    echo "latest for $arg: $name" >&2
    ;;
  https://*.iso|http://*.iso) url="$arg" ;;
  *) echo "invalid iso url (must be http(s) and end in .iso) or version: $arg" >&2; exit 1 ;;
esac

mkdir -p "$dest_dir"
name="$(basename "$url")"

if [ -e "$dest_dir/$name" ]; then
  echo "already downloaded: $dest_dir/$name"
  exit 0
fi

curl -fSLk "$url" -o "$dest_dir/$name.part"
mv "$dest_dir/$name.part" "$dest_dir/$name"
echo "$dest_dir/$name"
