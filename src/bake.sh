#!/usr/bin/env bash
set -eu

function usage() {
  echo "Usage: $(basename "$0")

Performs initial composer install in container and exports the
generated files for use elsewhere.

"
}

# Create composer cache directory if not exist
mkdir -p source/cache

# ----------------------------------------------------------------------------

docker-compose -p build down -v --remove-orphans

# ----------------------------------------------------------------------------

docker pull "${PARENT_IMAGE}:${PARENT_VERSION}"

# Build the container and start
echo "Building containers..."
docker-compose -p build build
echo

echo "Starting containers..."
docker-compose -p build up -d
echo

# 2 seconds * 150 == 5+ minutes
interval=2
loop=150

# Number of consecutive successes to qualify as 'up'
threshold=3
success=0

docker-compose -p build logs -f php-fpm &

# Not going to be ready immediately
sleep 20

proxy_container=$(docker-compose -p build ps -q app)

until [[ $success -ge $threshold ]]
do
  # Curl to container and expect status code 200
  if docker run --network "container:$proxy_container" --rm appropriate/curl -s -k "http://localhost:80" | grep -s "greenpeace" > /dev/null
  then
    success=$((success+1))
    echo "Success: $success/$threshold"
  else
    success=0
  fi

  loop=$((loop-1))
  if [[ $loop -lt 1 ]]
  then
    >&2 echo "[ERROR] Timeout waiting for docker-compose to start"
    >&2 docker-compose -p build logs
    exit 1
  fi

  [[ $success -ge $threshold ]] || sleep $interval
done

# Debug running container names
docker ps

php_container=$(docker-compose -p build ps -q php-fpm)

echo "Copying build artifacts..."
docker cp "$php_container:/app/source/cache" source
docker cp "$php_container:/app/source/public" source

echo "Contents of public folder:"
ls -al source/public
echo

echo "Contents of cache folder:"
ls -al source/cache
echo

echo "Bringing down containers..."
docker-compose -p build down -v &
echo

shopt -s nullglob
files=(source/public/*)
numfiles=${#files[@]}

echo "$numfiles files in source/public"

if [[ $numfiles -lt 3 ]]
then
  >&2 echo "ERROR not enough files for a success"
  ls source/public
  exit 1
fi

# FIXME volume: nocopy not working in the docker-compose.yml file
rm -f source/public/index.html

# Tagged releases are production, remove the robots.txt
# FIXME Find a better way to handle robots.txt
if [[ -n "${CIRCLE_TAG:-}" ]]
then
  rm -f source/public/robots.txt
fi

echo "Done"
