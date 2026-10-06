#!/usr/bin/env bash
# Orchestrates download-iso + modify-iso and records the result for later skills.
set -euo pipefail

usage="usage: prepare.sh <16.0|16.1|16.2> --flavor Online|Full [--password <pw>] [--grub-timeout <sec>] [--register-url <url>]"
skills="/root/.pi/agent/skills-custom"
iso_dir="/root/Downloads/isos"
state="$iso_dir/last-prepared.json"
keep_builds=2

version="${1:?$usage}"; shift
flavor=""; password="nots3cr3t"; grub_timeout=3; register_url=""
while [ $# -gt 0 ]; do
  case "$1" in
    --flavor) flavor="${2:?--flavor requires a value}"; shift 2 ;;
    --password) password="${2:?--password requires a value}"; shift 2 ;;
    --grub-timeout) grub_timeout="${2:?--grub-timeout requires a value}"; shift 2 ;;
    --register-url) register_url="${2:?--register-url requires a value}"; shift 2 ;;
    *) echo "$usage" >&2; exit 1 ;;
  esac
done
case "$version" in 16.[0-9]*) ;; *) echo "$usage" >&2; exit 1 ;; esac
case "$flavor" in Online|Full) ;; *) echo "missing or invalid --flavor (Online|Full)" >&2; exit 1 ;; esac

# ---- step 1: download (path = last stdout line, minus optional prefix) ----
echo "== step 1/2: download ==" >&2
src="$(bash "$skills/download-iso/download.sh" "$version" --flavor "$flavor" | tail -n1)"
src="${src#already downloaded: }"
[ -f "$src" ] || { echo "download step failed: $src not found" >&2; exit 1; }
build="$(basename "$src" | sed -E 's/.*-Build([0-9.]+)\.install\.iso$/\1/')"

# ---- register URL: the proxy only exists for the latest product version ----
latest="$version"
for m in 0 1 2 3 4 5 6 7 8 9; do
  v="16.$m"
  if curl -fsSk -m 20 "https://download.suse.de/ibs/SUSE:/SLFO:/Products:/SLES:/$v:/TEST/product/iso/?json" 2>/dev/null \
      | grep -q "\"name\":\"SLES-$v-[A-Za-z]*-x86_64-Build[0-9.]*\.install\.iso\""; then
    latest="$v"
  fi
done
if [ -z "$register_url" ] && [ "$version" = "$latest" ]; then
  register_url="http://all-$build.proxy.scc.suse.de"
fi
echo "latest version: $latest; register url: ${register_url:-<none>}" >&2

# ---- step 2: modify (reuse previous result if same source + params) ----
echo "== step 2/2: modify ==" >&2
out="${src%.iso}-modified.iso"
params="password=$password;grub_timeout=$grub_timeout;register_url=$register_url"
if [ -f "$out" ] && [ -f "$out.json" ] && grep -qF "\"params\": \"$params\"" "$out.json"; then
  echo "reusing existing $out" >&2
else
  args=("$src" --password "$password" --grub-timeout "$grub_timeout")
  [ -n "$register_url" ] && args+=("inst.register_url=$register_url")
  out="$(bash "$skills/modify-iso/modify.sh" "${args[@]}" | tail -n1)"
  [ -f "$out" ] || { echo "modify step failed" >&2; exit 1; }
fi

# ---- state file (per-ISO sidecar + last-prepared.json) ----
json="{
  \"iso\": \"$out\",
  \"source_iso\": \"$src\",
  \"version\": \"$version\",
  \"flavor\": \"$flavor\",
  \"arch\": \"x86_64\",
  \"build\": \"$build\",
  \"password\": \"$password\",
  \"grub_timeout\": $grub_timeout,
  \"register_url\": \"$register_url\",
  \"params\": \"$params\"
}"
printf '%s\n' "$json" > "$out.json"
printf '%s\n' "$json" > "$state"

# ---- retention: keep the newest $keep_builds builds of this version ----
builds="$(ls -1 "$iso_dir"/SLES-$version-*-x86_64-Build*.install.iso 2>/dev/null \
  | sed -E 's/.*-Build([0-9.]+)\.install\.iso$/\1/' | sort -uV)"
old="$(printf '%s\n' "$builds" | head -n -"$keep_builds")"
for b in $old; do
  for f in "$iso_dir"/SLES-$version-*-x86_64-Build$b.install*; do
    [ -e "$f" ] && { echo "removing old build: $f" >&2; rm -f "$f"; }
  done
done

echo "$out"
