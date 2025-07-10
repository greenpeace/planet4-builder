#!/bin/bash
[[ $(git "$@" | wc -c) -ne 0 ]]
