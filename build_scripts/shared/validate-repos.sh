#!/usr/bin/bash

set -eou pipefail

ALLOWED_REPOS=(
  fedora
  updates{-archive,}
)

BETA_REPOS=(updates-testing)

source /usr/lib/os-release

# TODO: we need a way to temporarily allow this on stable releases by checking
# installed packages via dnf
# Betas/pre-releases use updates-testing
if [[ "$RELEASE_TYPE" == "development" ]]; then
  ALLOWED_REPOS=( "${ALLOWED_REPOS[@]}" "${BETA_REPOS[@]}" )
fi

ALLOWED_REPO_LIST="$(printf '%s\n' "${ALLOWED_REPOS[@]}")"

ENABLED_REPOS="$(dnf repolist --enabled | awk 'NR>1 {print $1}')"

BAD_REPOS="$(grep -v --fixed-strings --line-regexp -f <(echo "$ALLOWED_REPO_LIST") <<< "$ENABLED_REPOS" || true)"

if [[ -n "$BAD_REPOS" ]]; then
  echo "unexpected enabled repo(s) detected:"
  echo "$BAD_REPOS"; exit 1
fi
