#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
# set -euxo pipefail

## Get the directory of the currently executing script
DIR="$(dirname "$0")"

# Change to that directory
cd "$DIR" || exit

# Check pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo "pandoc could not be found"
    exit 1
fi

# Check roc is installed
if ! command -v roc &> /dev/null; then
    echo "roc could not be found"
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# check the output of each test
for ROC_TEST in tests/*.roc; do

    MD_VERSION="${ROC_TEST%.roc}.md"
    DIFF_NAME="${ROC_TEST%.roc}.diff"

    if ! diff -u <(roc "$ROC_TEST") <(pandoc -s "$MD_VERSION" -t json); then
        echo -e "${RED}FAIL:${RESET} $ROC_TEST"
        echo "exiting ..."
        exit 1
    fi

    echo -e "${GREEN}PASS:${RESET} $ROC_TEST"
done
