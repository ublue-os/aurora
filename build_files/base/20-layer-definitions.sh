#!/usr/bin/bash

# to reduce the indiviual layer size we put big files that are not shipped with RPMs in their own layers
# See: https://coreos.github.io/rpm-ostree/build-chunked-oci/

set -eoux pipefail

COUNT=30
OUTPUT="/tmp/nonrpm.json"
# 600KiB
MIN_SIZE=614400
IGNORE=(
    "^/usr/lib/sysimage/rpm-ostree-base-db/rpmdb.sqlite"
    "^/usr/share/rpm/rpmdb.sqlite"
    "^/usr/lib/modules" # spam
    "^/usr/bin/tailscaled" # packaging is bumd, hardlinks
    "^/usr/bin/zpool"
    "^/usr/lib/fontconfig/cache"
    "^/usr/lib64/.*\.so" # mostly useless files
    "^/usr/lib32/.*\.so" # can't be assed to make this one thing
    "^/usr/lib/.*\.so" # and do it properly
    "^/usr/lib/bootupd/" # not worth
)

IGNORE_REGEX=$(printf "|%s" "${IGNORE[@]}")
IGNORE_REGEX="${IGNORE_REGEX:1}"

# which files are not tracked by the rpmdb
RPM_FILES=$(mktemp)
rpm -qa --qf '[%{FILENAMES}\n]' | grep -E "^/usr|^/opt" | sort > "$RPM_FILES"

NON_RPM_FILES=$(comm -23 \
    <(find /usr -type f 2>/dev/null | grep -Ev "$IGNORE_REGEX" | sort) \
    "$RPM_FILES"
)

echo "$NON_RPM_FILES" | xargs -d '\n' du -b 2>/dev/null | jq -Rn --argjson min "$MIN_SIZE" '
  [
    inputs | split("\t") | {
      "path": .[1],
      "size": (.[0] | tonumber),
      "component": (.[1] | ltrimstr("/") | gsub("/"; "-"))
    } | select(.size >= $min)
  ]
' > "$OUTPUT"

echo "found $(jq 'length' "$OUTPUT") non-rpm tracked files"

# generated example command
# setfattr -n user.component -v usr-share-doc-aurora-aurora.pdf /usr/share/doc/aurora/aurora.pdf
jq -c '.[]' "$OUTPUT" | while read -r item; do
    path=$(echo "$item" | jq -r '.path')
    comp=$(echo "$item" | jq -r '.component')
    setfattr -n user.component -v "$comp" "$path"
done

echo "listing $COUNT biggest ones"
jq -r --arg n "$COUNT" ' sort_by(.size) | reverse | .[0:($n | tonumber)] | .[] | "\(.size)\t\(.path)" ' "$OUTPUT" | numfmt --to=iec --field=1

echo "::endgroup::"
