#!/usr/bin/env bash
set -euo pipefail

# Detect promotion command in last commit message
message="${1:-$(git log --format=%B -n 1)}"

# Accepts the following formats:
#  [ci promote v1.2.3]
#  [ci release v1.2.3]
#  [ci tag 1.2.30]
#  [ci tag v1.22.3]
#  [ci tag v1.2.3-testing]

if grep -qE "\\[ci (promote|tag|release) v?[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+.*\\]" <<< "$message"
then
  # Detect version string
  regex="(v?[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+.*)]"

  if [[ $message =~ $regex ]]
  then
    tag="${BASH_REMATCH[1]}"
    echo "${tag}"
    echo "Version found in commit message: ${tag}" >&2
    exit 0
  else
    echo "$message doesn't match" >&2 # this could get noisy if there
  fi
fi

# Fallback to incrementing latest tag
current_version=$(git-current-tag.sh)
echo "Found existing tag: $current_version" >&2

tag=$(increment-version.sh "$current_version")
echo "$tag"
echo "Promoting branch ${CIRCLE_BRANCH} to ${tag}" >&2
