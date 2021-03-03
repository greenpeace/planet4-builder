#!/usr/bin/env bash
set -eu

export SOURCE_PATH=/app/source

for i in build app openresty; do
  build_dir=$i
  envsubst <"${build_dir}/Dockerfile.in" >"${build_dir}/Dockerfile"
done
