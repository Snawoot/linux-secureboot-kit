#!/bin/sh

set -e

SCRIPT='import uuid;print (str(uuid.uuid4()));'

UUID=$(uuidgen 2>&1) || \
UUID=$(python -c "$SCRIPT" 2>&1) || \
UUID=$(python3 -c "$SCRIPT" 2>&1) || \
UUID=$(python2 -c "$SCRIPT" 2>&1)

echo "$UUID"
