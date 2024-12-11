#!/bin/bash

# Kuzin Andrey 2024-08-13
# Clone git repository into tar file
#
# History:
# 2024-11-06 add branch clone support

URL=
BRANCH=
CWD=$(pwd)
PROG=$0

usage() {
	echo "Use: $PROG [-b branch] <url>"
	exit 1
}

while [[ $# -gt 0 ]]; do
	opt="$1"
	case $opt in
	-b)
		shift
		[ ! -z "$1" ] && BRANCH="-b $1" || {
			echo "ERROR: no branch name in -b option"
			usage
		}
		;;
	*) URL=$opt ;;
	esac
	shift
done

[ -z "$URL" ] && {
	echo "ERROR: No any URL was provided"
	usage
}

REPO=$(basename "$URL" | sed 's/\.git$//g')
[ -z "$REPO" ] && {
	echo "ERROR: Can't parse REPO url ($URL)"
	exit 1
}

TMPDIR=$(mktemp -d -p /dev/shm --suffix=$REPO)

exiterr() {
	[ -d $TMPDIR ] && rm -rf $TMPDIR
	echo "$@"
	cd $CWD
}

[ -z "$BRANCH" ] \
	&& echo "--- Clone $URL" \
	|| echo "--- Clone branch $(echo $BRANCH | cut -f2 -d' ') from $URL"

git clone $BRANCH $URL $TMPDIR
[ $? != 0 ] && exiterr "Can't run git clone"

cd $TMPDIR
ORIGSIZE=$(du -bs | awk '{print $1}')
tar -czf ../$REPO.git.tgz ./
[ $? != 0 ] && exiterr "Can't run tar"

cd ..
MD5=$(md5sum -b $REPO.git.tgz | cut -f1 -d' ')
(cat > $REPO.git.info) << EOF
DESC=Repository $URL
REPO=$URL
ORIGSIZE=$ORIGSIZE
FILE=$REPO.git.tgz
MD5=$MD5
EOF

cd $CWD
[ -d $TMPDIR ] && rm -rf $TMPDIR
