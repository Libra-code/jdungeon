#!/bin/bash

REMOTE_SCRIPT=./tools/deploy/remote_prepare_script.sh

echo "Executing remote commands..."
ssh $1 'bash -s' < $REMOTE_SCRIPT
echo "Commands executed successfully."
