#!/bin/sh

set -e

SCRIPT='import uuid;print (str(uuid.uuid4()));'

UUID=$(uuidgen 2>/dev/null) || \
UUID=$(python -c "$SCRIPT" 2>/dev/null) || \
UUID=$(python3 -c "$SCRIPT" 2>/dev/null) || \
UUID=$(python2 -c "$SCRIPT" 2>/dev/null)

echo "$UUID"
