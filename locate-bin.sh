#!/bin/sh

set -e

for i in "$@" ; do
    if which "$i" > /dev/null 2>&1 ; then
        echo "$i"
        exit 0
    fi
done

echo "false"
exit 1
