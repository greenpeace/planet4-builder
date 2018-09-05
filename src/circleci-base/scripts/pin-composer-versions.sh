#!/usr/bin/env bash
set -euo pipefail

composer=${1:-${COMPOSER:-composer-local.json}}

tmpdir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")

BLACKLIST=( \
  greenpeace/planet4-master-theme \
  greenpeace/planet4-plugin-blocks \
  greenpeace/planet4-plugin-engagingnetworks \
  greenpeace/planet4-plugin-medialibrary \
)

inArray () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function finish {
  rm -fr $tmpdir
}
trap finish EXIT

function remove {
  echo "dev-develop => **remove**"
  COMPOSER=$composer composer remove --no-update $1
  echo
}

function pin {
  echo "dev-develop => $new_version"
  # curl_string "https://api.github.com/repos/${repo}/releases/latest"
  COMPOSER=$composer composer require --no-update $repo $new_version
  echo
}
jq -r ".require|to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" $composer | tee "$tmpdir/requires"
echo
while IFS="" read -r require || [ -n "$require" ]
do
  while IFS="=" read -r repo version
  do
    if [[ $version = "dev-develop" ]]
    then
      echo $repo
      if inArray $repo "${BLACKLIST[@]}"
      then
        remove $repo
      else
        new_version=$(git-latest-remote-tag.awk https://github.com/$repo | cut -d'v' -f2)
        if [[ -z "$new_version" ]]
        then
          remove $repo
        else
          pin $repo $new_version
        fi

      fi
    fi
  done <<< "$require"
done < "$tmpdir/requires"

COMPOSER=$composer composer validate
