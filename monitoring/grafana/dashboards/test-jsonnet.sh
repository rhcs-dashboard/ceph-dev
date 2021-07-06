#!/usr/bin/env bash

set -e
TEMPDIR=`mktemp -d`
BASEDIR=$(dirname "$0")

for file in $BASEDIR/jsonnet/*; do
    name=$(basename $file)
    jsonnet $file > ${TEMPDIR}/${name%.jsonnet}.json
done

truncate -s 0 ${TEMPDIR}/json_difference.log
for json_files in $BASEDIR/*.json
do
    JSON_FILE_NAME=$(basename $json_files)
    for generated_files in ${TEMPDIR}/*.json
    do
        GENERATED_FILE_NAME=$(basename $generated_files)
        if [ $JSON_FILE_NAME == $GENERATED_FILE_NAME ]; then
            jsondiff --indent 2 $generated_files $json_files >> ${TEMPDIR}/json_difference.log
            jsondiff --indent 2 $generated_files $json_files
        fi
    done
done

if grep -Fxq "{}" ${TEMPDIR}/json_difference.log
then
        rm -rf ${TEMPDIR}
        echo "Congratulations! Grafonnet Check Passed"
else
        rm -rf ${TEMPDIR}
        echo "Grafonnet Check Failed"
        exit 1
fi
