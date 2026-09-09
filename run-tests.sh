#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
roc fmt --check package examples
roc check package/Pandoc.roc --no-cache
roc test package/Pandoc.roc --no-cache
roc check examples/hello-world.roc --no-cache
