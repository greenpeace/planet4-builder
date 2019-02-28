#!/usr/bin/env bash
set -euo pipefail

DEBUG=${DEBUG:-0}

debug () {
  [ "$DEBUG" -eq 0 ] && return
  printf "%s\\n" "$*"
}

if [ $# -gt 0 ]
then
  # Detect promotion string in first argument or most recent commit message
  message="$*"
  debug "Parsing argument for command: '$message'"

else
  message="$(git log --format=%B -n 1)"
  debug "Using last git commit message: '$message'"
fi


[ -n "${message}" ] && {
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
      echo "$tag"
      debug "Version string found: ${tag}"
      exit 0
    else
      debug "Version string not found, skipping ..." # this could get noisy if there
    fi
  else
    debug "Unmatched regex in $message, skipping ..."
  fi
}

# Fallback to incrementing latest tag
current_version=$(git-current-tag.sh)
if [[ -z "$current_version" ]]
then
  debug "Previous version not detected"
else
  debug "Found existing tag: $current_version"
fi

tag=$(increment-version.sh "$current_version")
if [[ -z "$tag" ]]
then
  debug "Error generating new version string: '$tag'"
  exit 1
fi

echo "$tag"
debug "Promoting to ${tag}"
