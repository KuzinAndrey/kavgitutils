#!/bin/sh

FORCEGC="-gc"
[ -n "$1" ] && [ "$1" = "-nogc" ] && FORCEGC=""

find . -type f -name "*.git.info" -mtime +1 -exec gitupdate.sh {} $FORCEGC \;
