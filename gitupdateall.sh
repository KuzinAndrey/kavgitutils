#!/bin/sh

find . -type f -name "*.git.info" -exec gitupdate.sh {} \;
