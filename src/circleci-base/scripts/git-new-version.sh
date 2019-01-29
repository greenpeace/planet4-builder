#!/usr/bin/env bash
set -euo pipefail

# Detect promotion string in first argument or most recent commit message
message="${1:-$(git log --format=%B -n 1)}"

# Accepts the following formats and variations thereof:
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
if [[ -z "$current_version" ]]
then
  echo "Previous version not detected" >&2
else
  echo "Found existing tag: $current_version" >&2
fi

tag=$(increment-version.sh "$current_version")
if [[ -z "$tag" ]]
then
  echo "Error generating new version string: '$tag'" >&2
  exit 1
fi

echo "$tag"
echo "Promoting branch ${CIRCLE_BRANCH} to ${tag}" >&2
