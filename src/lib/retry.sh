#!/usr/bin/env bash
set -euo pipefail

# Retries a command a configurable number of times with backoff.
#
# The retry count is given by ATTEMPTS (default 5), the initial backoff
# timeout is given by TIMEOUT in seconds (default 1.)
#
# Successive backoffs double the timeout.
function retry {
  local n=1
  local max_attempts=${ATTEMPTS:-5}
  local timeout=${TIMEOUT:-1}
  local attempt=1

  while true; do
    "$@" && break || {
      if [[ $n -lt $max_attempts ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $timeout;
        timeout=$(( timeout * 2 ))
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

export retry
