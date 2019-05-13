#!/bin/sh

set -e

for i in "$@" ; do
    if [ -h "$i" -o -e "$i" ] ; then
        echo "$i"
        exit 0
    fi
done
exit 1
