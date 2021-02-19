#!/usr/bin/env bash
set -e

composer_files=(
  "${HOME}/source/composer.json"
  "${HOME}/source/composer-local.json"
  "${HOME}/merge/composer.json"
  "${HOME}/merge/composer-local.json"
)

plugin_branch_env_vars=(
  "MASTER_THEME_BRANCH"
  "PLUGIN_GUTENBERG_BLOCKS_BRANCH"
)

built_assets_dir="${HOME}/source/built-dev-assets"
mkdir -p "${built_assets_dir}"

echo "rewrite_app_repos"

build_assets() {
  branch="$1"
  reponame="$2"

  # If the repository name is the repository of the current job, the code will already be checked out, even if it's a
  # fork PR.
  checkoutDir="/home/circleci/checkout/${reponame}"
  if [ "$CIRCLE_PROJECT_REPONAME" == "$reponame" ] && [ -d "${checkoutDir}" ]; then
    mkdir -p "$reponame"
    cp -r "${checkoutDir}/." "$reponame"
    git -C "$reponame" submodule init
    git -C "$reponame" submodule update --remote
  else
    git clone --recurse-submodules --single-branch --branch "${branch}" https://github.com/greenpeace/"${reponame}"
  fi

  PUPPETEER_SKIP_DOWNLOAD=true PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true npm ci --prefix "${reponame}" "${reponame}"
  for i in {1..5}; do
    echo "build attempt $i"
    NODE_OPTIONS=--max_old_space_size=2048 npm run-script --prefix "${reponame}" build && break
  done

  if [[ "${reponame}" == *theme ]]; then
    subdir="themes"
  else
    subdir="plugins"
  fi

  buildDir="${built_assets_dir}/public/wp-content/${subdir}/${reponame}/assets/build/"
  mkdir -p "${buildDir}"
  cp -a "${reponame}/assets/build/." "${buildDir}"
  rm -rf "${reponame}"
}

for plugin_branch_env_var in "${plugin_branch_env_vars[@]}"; do
  reponame=planet4-$(echo "${plugin_branch_env_var%_*}" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
  composer_dev_prefix="dev-"
  # temp solution to remove it and add it again where it is needed. It would be better if this script got branchname
  # without dev- before it, so stripping it as the first thing allows us to change that
  branch=${!plugin_branch_env_var#"$composer_dev_prefix"}

  if [ -n "${!plugin_branch_env_var}" ]; then
    echo "Replacing ${reponame} with branch ${branch} from environment variable"
    for f in "${composer_files[@]}"; do
      if [ ! -e "$f" ]; then
        continue
      fi
      echo " - $f"
      tmp=$(mktemp)
      jq ".require.\"greenpeace/${reponame}\" = \"dev-${branch}\"" "$f" >"$tmp"
      mv "$tmp" "$f"

      checkoutDir="/home/circleci/checkout/${reponame}"
      # If builder is running for the theme or plugin, then we can use the checked out code of the current commit.
      if [ "$CIRCLE_PROJECT_REPONAME" == "$reponame" ] && [ -d "${checkoutDir}" ]; then
        tmp=$(mktemp)
        jq ".repositories |= [{\"type\": \"path\", \"url\": \"${checkoutDir}\"}] + ." "$f" >"$tmp"
        mv "$tmp" "$f"
      fi
    done

    echo "And now, delete any cached version of this package"
    rm -rf "${HOME}/source/cache/files/greenpeace/planet4-master-theme"

  else
    echo "Nothing to replace for the ${reponame}"
  fi

  repo_branch=""

  # now go throuhg the composer file and see if there are any dev branches for planet4 plugins or theme
  for f in "${composer_files[@]}"; do
    echo "Checking $f..."

    if [ ! -e "$f" ]; then
      echo "...It does not exist."
      continue
    fi

    json_path=".require.\"greenpeace/${reponame}\""
    plugin_version=$(jq -r "${json_path} // empty" <"${f}")
    branch=${plugin_version#"$composer_dev_prefix"}

    if [ -z "${plugin_version}" ]; then
      echo "Plugin ${reponame} is not in ${f}"
      continue
    fi

    # We don't need to build the assets for tags anymore, as we made those work with github releases.
    # Branches still need to be built at this point for now.
    # We know if it's a branch when the prefix was present, so $branch should differ from $plugin_version only in that case.
    if [ "${branch}" == "${plugin_version}" ]; then
      echo "Version ${plugin_version} for ${reponame} in ${f} is not a branch, no need to build."
      # Empty $repo_branch in case a previous composer file had set it.
      repo_branch=""
      continue
    fi

    # Assets are not included in the repositories, so we need to build them here.
    # All built files are put together in built-dev-assets, which has the same directory structure as /app/source.
    # In the last step in the Dockerfile the contents of this directory are rsync'ed over the source.
    # This is not ideal, however there was no better alternative as packagist only works with files in a github repo.
    echo "Repo ${reponame} exists for branch ${branch}"
    repo_branch="${branch}"
  done

  # Build the last encountered branch's assets
  if [ -n "$repo_branch" ]; then
    echo "Building assets for ${reponame} at branch ${repo_branch}"
    time PS4="__$reponame: " build_assets "$repo_branch" "$reponame"
  fi
done

echo "DEBUG: We will echo where master theme is defined as what: "
grep -r -H '"greenpeace/planet4-master-theme" :' ./*
