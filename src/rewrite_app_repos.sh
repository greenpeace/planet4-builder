#!/usr/bin/env bash
set -ex

composer_files=(
  "${HOME}/source/composer.json"
  "${HOME}/source/composer-local.json"
  "${HOME}/merge/composer.json"
  "${HOME}/merge/composer-local.json"
)

plugin_branch_env_vars=(
  "MASTER_THEME_BRANCH"
  "PLUGIN_BLOCKS_BRANCH"
  "PLUGIN_GUTENBERG_BLOCKS_BRANCH"
  "PLUGIN_ENGAGINGNETWORKS_BRANCH"
  "PLUGIN_GUTENBERG_ENGAGINGNETWORKS_BRANCH"
)

built_assets_dir="${HOME}/source/built-dev-assets"
mkdir -p "${built_assets_dir}"

echo "rewrite_app_repos"

build_assets() {
  branch="$1"
  reponame="$2"

  git clone --recurse-submodules --single-branch --branch "${branch}" https://github.com/greenpeace/"${reponame}"

  npm ci --prefix "${reponame}" "${reponame}"
  npm run-script --prefix "${reponame}" build

  if [[ "${reponame}" == *theme ]]; then \
      subdir="themes"; \
  else \
      subdir="plugins"; \
  fi; \

  buildDir="${built_assets_dir}/public/wp-content/${subdir}/${reponame}/assets/build/"
  mkdir -p "${buildDir}"
  cp -a "${reponame}/assets/build/." "${buildDir}"
  rm -rf "${reponame}"
}

for plugin_branch_env_var in "${plugin_branch_env_vars[@]}"
do
  reponame=planet4-$( echo "${plugin_branch_env_var%_*}" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
  composer_dev_prefix="dev-"
  # temp solution to remove it and add it again where it is needed. It would be better if this script got branchname
  # without dev- before it, so stripping it as the first thing allows us to change that
  branch=${!plugin_branch_env_var#"$composer_dev_prefix"}

  if [ -n "${!plugin_branch_env_var}" ]; then
    echo "Replacing ${reponame} with branch ${branch} from environment variable"
    for f in "${composer_files[@]}"
    do
      if [ -e "$f" ]
      then
        echo " - $f"
        sed -i "s|\"greenpeace\\/${reponame}\" : \".*\",|\"greenpeace\\/${reponame}\" : \"dev-${branch}\",|g" "${f}"
      fi
    done

    echo "And now, delete any cached version of this package"
    rm -rf "${HOME}/source/cache/files/greenpeace/planet4-master-theme"

  else
    echo "Nothing to replace for the ${reponame}"
  fi

  # now go throuhg the composer file and see if there are any dev branches for planet4 plugins or theme
  for f in "${composer_files[@]}"
  do
    if [ -e "$f" ]; then
      json_path=".require.\"greenpeace/${reponame}\""
      plugin_version=$(jq -r "${json_path} // empty" < "${f}")
      branch=${plugin_version#"$composer_dev_prefix"}

      if [ -n "$branch" ]; then
        # Assets are not included in the repositories, so we need to build them here.
        # All built files are put together in built-dev-assets, which has the same directory structure as /app/source.
        # In the last step in the Dockerfile the contents of this directory are rsync'ed over the source.
        # This is not ideal, however there was no better alternative as packagist only works with files in a github repo.
        echo "Building assets for ${reponame} at branch ${branch}"

        time build_assets "$branch" "$reponame" &
      else
        if [ -z "${plugin_version}" ]; then
          echo "Plugin ${reponame} is not in ${f}"
        else
          echo "Version ${plugin_version} for ${reponame} in ${f} is not a branch"
        fi
      fi
    fi
  done
done

wait

echo "DEBUG: We will echo where master theme is defined as what: "
grep -r -H '"greenpeace/planet4-master-theme" :' ./*
