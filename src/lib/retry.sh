#!/usr/bin/env bash
set -euo pipefail

# Retries a command a configurable number of times with backoff.
#
# The retry count is given by ATTEMPTS (default 5), the initial backoff
# timeout is given by TIMEOUT in seconds (default 1.)
#
# Successive backoffs double the timeout.
function retry {
  local max_attempts=${ATTEMPTS:-5}
  local timeout=${TIMEOUT:-1}
  local attempt=1
  local exitCode=0

  while (( attempt <= max_attempts ))
  do
    if "$@"
    then
      return 0
    fi
    exitCode=$?

    >&2 echo "Attempt #$attempt/$max_attempts failed."
    attempt=$(( attempt + 1 ))
    (( attempt > max_attempts )) && break

    echo "Retrying in $timeout seconds ..."
    sleep "$timeout"
    timeout=$(( timeout * 2 ))
  done

  [[ $exitCode -ne 0 ]] && >&2 echo "You've failed me for the last time! ($*)"

  return $exitCode
}

export retry
