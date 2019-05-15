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

readonly NPM_PACKAGE_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB | grep -E "package(-lock){0,1}.json" | wc -l)
readonly HTML_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.html" | wc -l)
readonly SCSS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.scss" | tr '\n' ' ')
readonly TS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.ts" | tr '\n' ' ')
readonly PY_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.py" | wc -l)
readonly DOC_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "doc/*.rst" | wc -l)

if [[ "$NPM_PACKAGE_FILES" > 0 || -n "$SCSS_FILES" || -n "$TS_FILES" ]]; then
    run_npm_ci
fi

if [[ "$HTML_FILES" > 0 && -z "$SCSS_FILES" && -z "$TS_FILES" ]]; then
    run_npm_lint_html
fi

if [[ -n "$SCSS_FILES" || -n "$TS_FILES" ]]; then
    run_npm_fix

    # Add fixes to staging:
    cd "$REPO_DIR"
    echo "$SCSS_FILES $TS_FILES" | xargs git add

    run_npm_lint
fi

if [[ -n "$TS_FILES" ]]; then
    run_jest
fi

if [[ "$HTML_FILES" > 0 || -n "$TS_FILES" ]]; then
    run_npm_i18n \
        || (echo "FIXING: adding $TRANSLATION_FILE to commit..." \
        && cd "$REPO_DIR" \
        && git add "$TRANSLATION_FILE")
fi

if [[ "$PY_FILES" > 0 ]]; then
    run_tox
fi

if [[ "$DOC_FILES" > 0 ]]; then
    run_build_doc
fi

echo 'Pre-commit hook successfully finished! Congratulations!'
