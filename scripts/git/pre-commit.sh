#!/bin/bash

set -e

echo 'Running pre-commit hook...'

readonly PY_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB "*.py" | tr '\n' ' ')
readonly TS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB "*.ts" | tr '\n' ' ')
readonly SCSS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB "*.scss" | tr '\n' ' ')
readonly HTML_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB "*.html" | tr '\n' ' ')

if [[ ! -z "$PY_FILES" ]]; then
    #printf "PY_FILES:\n$PY_FILES\n\n"

    cd src/pybind/mgr/dashboard

    echo 'Setting up Python Virtual Env...'

    readonly PYTHON_VIRTUAL_ENV='venv'

    if [ ! -d "$PYTHON_VIRTUAL_ENV" ]; then
        python3 -m venv "$PYTHON_VIRTUAL_ENV"
        #printf "\n\nexport PYTHONDONTWRITEBYTECODE=1" >> "$PYTHON_VIRTUAL_ENV"/bin/activate
    fi

    source "$PYTHON_VIRTUAL_ENV"/bin/activate

    pip install -U pip
    pip install -r requirements.txt

    echo 'Running Tox...'
    export WITH_PYTHON3="OFF"
    export MGR_DASHBOARD_VIRTUALENV="$PYTHON_VIRTUAL_ENV"
    ./run-tox.sh

    cd -

    find . -iname "*.pyc" -delete
fi

if [[ ! -z "$TS_FILES" ]]; then
    #printf "TS_FILES:\n$TS_FILES\n\n"

    cd src/pybind/mgr/dashboard/frontend

    echo 'Running "ng lint"...'
    ng lint ceph-dashboard ceph-dashboard-e2e --fix

    echo 'Running Frontend unit tests...'
    ./node_modules/jest/bin/jest.js --clearCache
    ./node_modules/jest/bin/jest.js

    echo 'Running Prettier for .ts files...'
    echo "$TS_FILES" | awk -F "/frontend/" '{print $2}' | xargs ./node_modules/.bin/prettier --write

    cd -

    # Add Prettier changes to staging:
    echo "$TS_FILES" | xargs git add
fi

if [[ ! -z "$SCSS_FILES" ]]; then
    #printf "SCSS_FILES:\n$SCSS_FILES\n\n"

    cd src/pybind/mgr/dashboard/frontend

    echo 'Running Prettier for .scss files...'
    echo "$SCSS_FILES" | awk -F "/frontend/" '{print $2}' | xargs ./node_modules/.bin/prettier --write

    cd -

    # Add Prettier changes to staging:
    echo "$SCSS_FILES" | xargs git add
fi

if [[ ! -z "$HTML_FILES" ]]; then
    #printf "HTML_FILES:\n$HTML_FILES\n\n"

    cd src/pybind/mgr/dashboard/frontend

    echo 'Running html-linter for .html files...'
    echo "$HTML_FILES" | awk -F "/frontend/" '{print $2}' | xargs ./node_modules/.bin/html-linter --config html-linter.config.json

    cd -
fi

echo 'Pre-commit hook successfully finished! Congratulations!'
