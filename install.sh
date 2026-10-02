#!/usr/bin/env bash
set -euo pipefail

# Imports the four rule types through Pi-hole's CLI, without database edits.
base_url='https://raw.githubusercontent.com/cadenshub/pihole-streaming-filters/main'
include_optional=false
case "${1:-}" in
  '') ;;
  --include-optional) include_optional=true ;;
  *) printf 'Usage: bash install.sh [--include-optional]\n' >&2; exit 1 ;;
esac
if ! command -v pihole >/dev/null 2>&1; then
  printf 'Run this on the Pi-hole v6 host (or inside its container). The pihole command was not found.\n' >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  printf 'curl is required to download the rule files.\n' >&2
  exit 1
fi
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT

# Fetch every file before adding entries so a download error causes no changes.
for name in allowlist-exact allowlist-regex denylist-exact denylist-regex; do
  curl --fail --silent --show-error --location "$base_url/$name.txt" -o "$scratch_dir/$name.txt"
  if [ ! -s "$scratch_dir/$name.txt" ]; then
    printf 'Downloaded file is empty: %s\n' "$name" >&2
    exit 1
  fi
done

# Validate the file format and compile regexes with the actual Pi-hole engine
# before importing. A non-match (exit 2) is a successful syntax check.
for name in allowlist-exact allowlist-regex denylist-exact denylist-regex; do
  while IFS= read -r entry || [ -n "$entry" ]; do
    if [[ -z "$entry" || "$entry" == *[[:space:]]* || "$entry" == \#* ]]; then
      printf 'Invalid entry in %s: %s\n' "$name" "$entry" >&2
      exit 1
    fi
    if [[ "$name" == *-regex ]]; then
      if ! command -v pihole-FTL >/dev/null 2>&1; then
        printf 'pihole-FTL is required for regex validation.\n' >&2
        exit 1
      fi
      result=0
      pihole-FTL regex-test validation.example "$entry" > "$scratch_dir/regex-test.log" 2>&1 || result=$?
      case "$result" in
        0|2) ;;
        *) cat "$scratch_dir/regex-test.log" >&2; exit 1 ;;
      esac
    elif [[ ! "$entry" =~ ^[a-z0-9][a-z0-9.-]*\.[a-z0-9.-]+$ ]]; then
      printf 'Invalid domain in %s: %s\n' "$name" "$entry" >&2
      exit 1
    fi
  done < "$scratch_dir/$name.txt"
done

printf 'Importing streaming rules into the Default group. Playback compatibility is not guaranteed.\n'
printf 'Peacock and Paramount+ may need troubleshooting; DNS rules cannot reliably remove streaming ads.\n'
if [ "$include_optional" = false ]; then
  printf 'Skipping the Roku Channel-wide deny rule, two untested Roku troubleshooting allows, and the untested Disney rule.\n'
fi
for name in allowlist-exact allowlist-regex denylist-exact denylist-regex; do
  case "$name" in
    allowlist-exact) action=allow ;;
    allowlist-regex) action=--allow-regex ;;
    denylist-exact) action=deny ;;
    denylist-regex) action=--regex ;;
  esac
  while IFS= read -r entry || [ -n "$entry" ]; do
    if [ "$include_optional" = false ]; then
      case "$name:$entry" in
        'allowlist-exact:tis.cti.roku.com'|'allowlist-exact:ls.cti.roku.com'|'denylist-regex:^[^.]+\.(sr|sc)\.roku\.com$'|'denylist-regex:^([^.]+\.)*disneyadvertising\.com$') continue ;;
      esac
    fi
    pihole "$action" "$entry"
  done < "$scratch_dir/$name.txt"
done
printf '\nImport commands completed. Check output for rejected entries and test your apps.\n'
printf 'Disable any problematic entries under Group Management > Domains.\n'
printf 'To limit these rules to streaming devices, change their group assignments there.\n'
