#!/usr/bin/env bash
set -euo pipefail

url="${1:?usage: download.sh <iso-url>}"
dest_dir="/root/Downloads/isos"

case "$url" in
  https://*.iso|http://*.iso) ;;
  *) echo "invalid iso url (must be http(s) and end in .iso): $url" >&2; exit 1 ;;
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
