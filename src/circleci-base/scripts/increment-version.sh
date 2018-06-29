#!/usr/bin/env bash
set -e

# Takes a semantic version number as argument and increments the trailing value
#
# eg: v1.0.0 => v1.0.1
#     1.2.9  => 1.2.10
#     1.5    => 1.6
#     99     => 100

perl -pe 's/^(v?(\d+\.)*)(\d+)(.*)$/$1.($3+1).$4/e' <<< $1
