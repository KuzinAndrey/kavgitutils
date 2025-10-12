#!/bin/sh

# Kuzin Andrey 2024-08-13
# Clone git repository into tar file
#
# History:
# 2024-11-06 add branch clone support

URL=
BRANCH=
SUBMODULE=1
CWD=$(pwd)
PROG=$0
GHA=
UPDATE=

# target directory for work
# KAVGIT_TARGETDIR=$(pwd) # can be in ~/.kavgitutils
KAVGIT_TARGETDIR="/dev/shm"

usage() {
	echo "Use: $PROG [-n] [-b <branch>] <url>"
	echo " -b - branch for cloning"
	echo " -n - ignore submodules for cloning"
	exit 1
}

while [ $# -gt 0 ]; do
	opt="$1"
	case $opt in
	-b)
		shift
		[ ! -z "$1" ] && BRANCH="-b $1" || {
			echo "ERROR: no branch name in -b option"
			usage
		}
		;;
	-n) SUBMODULE=0 ;;
	*) URL=$opt ;;
	esac
	shift
done

[ -d "$HOME" ] && [ -f "$HOME/.kavgitutils" ] && source "$HOME/.kavgitutils"

[ -z "$URL" ] && {
	echo "ERROR: No any URL was provided"
	usage
}

REPO=$(basename "$URL" | sed 's/\.git$//g')
[ -z "$REPO" ] && {
	echo "ERROR: Can't parse REPO url ($URL)"
	exit 1
}
DESC="Repository $URL"

# Make github API call for description
$(echo "$URL" | grep -qE "^(http|https|git):\/\/(|www\.)github\.com\/.*") && while true; do
	GHREPO=`echo "$URL" | sed -e 's/.*:\/\/.*github\.com\///g' -e 's/\.git$//g'`
	[ -z "$GHREPO" ] && break
	echo -n "--- Make API call to github.com for repo [$GHREPO]: "
	GHA=$(mktemp -p $KAVGIT_TARGETDIR)
	wget -q -O $GHA https://api.github.com/repos/$GHREPO
	if [ $? -eq 0 -a -s $GHA ]; then
		echo "OK"
		GHDESCR=`grep "  \"description\":" $GHA | sed 's/^  \"description\": \"\(.*\)\",/\1/g'`
		if [ ! -z "$GHDESCR" ]; then
			echo "--- Github description: $GHDESCR"
			DESC="$GHDESCR"
		fi
		grep -q "\"archived\": true," $GHA && UPDATE=no
	else
		echo "Fail"
		rm $GHA && GHA=
	fi
	break
done

TMPDIR=$(mktemp -d -p $KAVGIT_TARGETDIR ${REPO}XXXXXX)

exiterr() {
	[ -d $TMPDIR ] && rm -rf $TMPDIR
	echo "$@"
	cd $CWD
	exit 1
}

[ -z "$BRANCH" ] \
	&& echo "--- Clone $URL" \
	|| echo "--- Clone branch $(echo $BRANCH | cut -f2 -d' ') from $URL"

git clone $BRANCH $URL $TMPDIR \
	&& echo "--- Cloned directory $TMPDIR" \
	|| exiterr "Can't run git clone"

cd $TMPDIR || exiterr "Can't change directory to $TMPDIR"

if [ -r .gitmodules -a "$SUBMODULE" = "1" ]; then
	echo "--- Clone submodules"
	git submodule update --init --recursive \
		&& echo "--- Submodules cloned" \
		|| exiterr "Can't clone submodules"
fi

echo "--- git gc --aggressive"
git gc --aggressive || exiterr "Can't git GC"

ORIGSIZE=$(du -bs | awk '{print $1}')
tar -czf ../$REPO.git.tgz ./ \
	&& echo "--- TGZ archive $REPO.git.tgz created" \
	|| exiterr "Can't create archive $REPO.git.tgz"

cd ..
MD5=$(md5sum -b $REPO.git.tgz | cut -f1 -d' ')
(cat > $REPO.git.info) << EOF
DESC=$DESC
REPO=$URL
ORIGSIZE=$ORIGSIZE
FILE=$REPO.git.tgz
MD5=$MD5
EOF
[ -n "$UPDATE" ] && echo "UPDATE=$UPDATE" >> $REPO.git.info
[ -n "$GHA" ] && {
	echo "--- Save Github API result in $REPO.git.githubapi.json"
	mv $GHA $REPO.git.githubapi.json
}

cd $CWD
[ -d $TMPDIR ] && rm -rf $TMPDIR
