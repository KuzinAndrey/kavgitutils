#!/bin/bash

cd /dev/shm/manifest-4x

for B in $(git branch -r | grep -v HEAD | sed 's/  origin\///g'); do
	echo "Branch = $B"
	git checkout $B && git pull
	if git log --follow -p -- manifest.dev-ctc-arm64 | grep -q 5.7.6-slnx4u1 ; then
		echo "found"
		exit
	fi
done