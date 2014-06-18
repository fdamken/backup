#!/bin/bash

if [[ ${EUID} != 0 ]]; then
    echo "E: Execution not possible, are you root?"
    exit 3
fi

# backup process
PREFIX="The automatic backup will be started"
echo "$PREFIX in 10 minutes!" | wall
sleep 5m
echo "$PREFIX in 5 minutes!" | wall
sleep 2m
echo "$PREFIX in 3 minutes!" | wall
sleep 1m
echo "$PREFIX in 2 minutes!" | wall
sleep 1m
echo "$PREFIX in 1 Minute $SUFFIX" | wall
sleep 1m
echo "$PREFIX now!" | wall

backup backup


# shutdown process
shutdown -P +10
