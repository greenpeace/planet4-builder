#!/usr/bin/env bash
set -ex

# Workaround old docker images with incorrect $HOME
# check https://github.com/docker/docker/issues/2968 for details
if [ "${HOME}" = "/" ]; then
  HOME=$(getent passwd "$(id -un)" | cut -d: -f6)
  export HOME
fi

mkdir -p ~/.ssh

echo 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
' >>~/.ssh/known_hosts

(
  umask 077
  touch ~/.ssh/id_rsa
)
chmod 0600 ~/.ssh/id_rsa
(
  cat <<EOF >~/.ssh/id_rsa
$CHECKOUT_KEY
EOF
)

# use git+ssh instead of https
git config --global url."ssh://git@github.com".insteadOf "https://github.com" || true

if [ -e /home/circleci/source/.git ]; then
  echo "WARNING: source directory is already a Git repository: /home/circleci/source"
  cd /home/circleci/source
  git remote set-url origin "$GIT_SOURCE" || true
else
  mkdir -p /home/circleci/source
  cd /home/circleci/source
  git init
  git remote add origin "$GIT_SOURCE"
  git fetch --all --tags
  if [ "$APP_ENVIRONMENT" == "production" ]; then
    latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")
    if [ -n "$BASE_RELEASE" ]; then
      echo "Base release specified: ${BASE_RELEASE}"
      latest_tag="${BASE_RELEASE}"
    fi
    git checkout "$latest_tag"
    echo "${latest_tag}" >/tmp/workspace/release_number
  else
    git reset "origin/${GIT_REF}"
    echo "${GIT_REF}" >/tmp/workspace/release_number
  fi
  git checkout -- .
fi

ls -al

################################################################################

if [ -e /home/circleci/merge/.git ]; then
  echo "WARNING: merge directory is already a Git repository: /home/circleci/merge"
  cd /home/circleci/merge
  git remote set-url origin "$CIRCLE_REPOSITORY_URL" || true
else
  mkdir -p /home/circleci/merge
  cd /home/circleci/merge
  git clone "$MERGE_SOURCE" .
fi

git checkout "$MERGE_REF"

ls -al
