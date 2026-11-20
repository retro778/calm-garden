#!/bin/sh
# Run Calm Garden from the project folder (builds it first if needed).
cd "$(dirname "$0")"
[ -x ./calm_garden ] || ./build_linux.sh || exit 1
exec ./calm_garden "$@"
