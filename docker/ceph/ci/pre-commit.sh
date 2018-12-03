#!/bin/bash

set -e

echo 'Running pre-commit hook...'

source /docker/ci/sanity-checks.sh

run_npm_lint_html() {
    echo 'Running "npm lint:html"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run lint:html
}

run_npm_fix() {
    echo 'Running "npm fix"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run fix
}

readonly HTML_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.html" | tr '\n' ' ')
readonly SCSS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.scss" | tr '\n' ' ')
readonly TS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.ts" | tr '\n' ' ')
readonly PY_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.py" | tr '\n' ' ')

if [[ ! -z "$HTML_FILES" ]]; then
    run_npm_lint_html
fi

if [[ ! -z "$SCSS_FILES" || ! -z "$TS_FILES" ]]; then
    npm install

    run_npm_fix

    # Add fixes to staging:
    cd "$REPO_DIR"
    echo "$SCSS_FILES $TS_FILES" | xargs git add
fi

if [[ ! -z "$TS_FILES" ]]; then
    run_jest

    run_npm_i18n \
    || echo "FIXING: adding $TRANSLATION_FILE to commit..." \
    && cd "$REPO_DIR" \
    && git add "$TRANSLATION_FILE"
fi

if [[ ! -z "$PY_FILES" ]]; then
    run_tox
fi

echo 'Pre-commit hook successfully finished! Congratulations!'
