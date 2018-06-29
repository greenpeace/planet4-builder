#!/usr/bin/env bash
set -e

perl -pe 's/^(v?(\d+\.)*)(\d+)(.*)$/$1.($3+1).$4/e' <<< $1
