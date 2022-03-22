#!/bin/bash

set -e

echo 'Running pre-commit hook...'

# shellcheck disable=SC1091
source /docker/ci/sanity-checks.sh

NPM_PACKAGE_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB | grep -E "package(-lock){0,1}.json" -c)
HTML_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.html" | wc -l)
SCSS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.scss" | tr '\n' ' ')
TS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.ts" | tr '\n' ' ')
GHERKIN_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.feature" | tr '\n' ' ')
JEST_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.spec.ts" | grep -v "/e2e/" | tr '\n' ' ')
PY_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.py" | tr '\n' ' ')
DOC_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "doc/*.rst" | wc -l)
MONITORING_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "monitoring/grafana/dashboards/*" | wc -l)

readonly NPM_PACKAGE_FILES
readonly HTML_FILES
readonly SCSS_FILES
readonly TS_FILES
readonly GHERKIN_FILES
readonly JEST_FILES
readonly PY_FILES
readonly DOC_FILES
readonly MONITORING_FILES

if [[ "$NPM_PACKAGE_FILES" -gt 0 || -n "$SCSS_FILES" || -n "$TS_FILES" ]]; then
    run_npm_ci
fi

if [[ "$HTML_FILES" -gt 0 && -z "$SCSS_FILES" && -z "$TS_FILES" ]]; then
    run_npm_lint_html
fi

if [[ -n "$SCSS_FILES" || -n "$TS_FILES" || -n "$GHERKIN_FILES" ]]; then
    check_browser_console_calls "$SCSS_FILES $TS_FILES $GHERKIN_FILES"
    run_npm_fix

    # Add fixes to staging:
    cd "$REPO_DIR"
    echo "$SCSS_FILES $TS_FILES $GHERKIN_FILES" | xargs git add

    run_npm_lint
fi

if [[ -n "$JEST_FILES" ]]; then
    run_jest "${JEST_FILES}"
fi

if [[ "$HTML_FILES" -gt 0 || -n "$TS_FILES" ]]; then
    run_npm_i18n \
        || (echo "FIXING: adding $TRANSLATION_FILE to commit..." \
        && cd "$REPO_DIR" \
        && git add "$TRANSLATION_FILE")
fi

if [[ -n "$PY_FILES" ]]; then
    run_tox
    run_mypy "$PY_FILES"
fi

if [[ "$MONITORING_FILES" -gt 0 ]]; then
    run_monitoring
fi

if [[ "$DOC_FILES" -gt 0 ]]; then
    run_build_doc
fi

echo 'Pre-commit hook successfully finished! Congratulations!'
