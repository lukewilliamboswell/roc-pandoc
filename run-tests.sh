#!/usr/bin/env bash

if ! command -v pandoc &> /dev/null; then
    echo "pandoc could not be found"
    exit 1
fi

if ! command -v roc &> /dev/null; then
    echo "roc could not be found"
    exit 1
fi

# Get the directory of the currently executing script, and change to that directory
DIR="$(dirname "$0")"
cd "$DIR" || exit

ANSI_RED='\033[0;31m'
ANSI_GREEN='\033[0;32m'
ANSI_RESET='\033[0m'

for ROC_TEST in tests/*.roc; do

    MD_VERSION="${ROC_TEST%.roc}.md"
    DIFF_NAME="${ROC_TEST%.roc}.diff"

    if ! diff -u <(roc "$ROC_TEST") <(pandoc -s "$MD_VERSION" -t json); then
        echo -e "${ANSI_RED}FAIL:${ANSI_RESET} $ROC_TEST"
        echo "exiting ..."
        exit 1
    fi

    echo -e "${ANSI_GREEN}PASS:${ANSI_RESET} $ROC_TEST"
done
