#!/bin/sh

find . -type f -name "*.git.info" -mtime +1 -exec gitupdate.sh {} -gc \;
