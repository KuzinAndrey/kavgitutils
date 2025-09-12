#!/bin/sh

# Update git repository git.tgz/git.info files if remote repo has new commits

set -e

CWD=$(pwd)
[ -z "$1" ] && echo "Use: $0 <file.git.info> [-nc]" && exit 1
[ ! -r "$1" ] && echo "Can't read $1 file" && exit 1
CLEAN=1
[ ! -z "$2" -a "$2" = "-nc" ] && CLEAN=0

# target directory for work
# KAVGIT_TARGETDIR=$(pwd) # can be in ~/.kavgitutils
KAVGIT_TARGETDIR="/dev/shm"

[ -d "$HOME" ] && [ -f "$HOME/.kavgitutils" ] && source "$HOME/.kavgitutils"

IF=$(realpath $1)
echo $IF | grep -qE "\.git\.info$" || {
	echo "This is not *.git.info file"
	exit 1
}
SDIR=$(dirname $IF)

FILE=$(grep -E "^FILE=" $IF | sed -e "s#FILE=##g") || {
	echo "Can't find FILE info"
	exit 1
}

REPO=$(grep -E "^REPO=" $IF | sed -e "s#REPO=##g") || {
	echo "Can't find REPO info"
	exit 1
}

MD5=$(grep -E "^MD5=" $IF | sed -e "s#MD5=##g") || {
	echo "Can't find MD5 info"
	exit 1
}

UPDATE=$(grep -E "^UPDATE=" $IF | sed -e "s#UPDATE=##g")
if [ "$UPDATE" = "no" ]; then
	echo "--- !!! no update set for $IF, skip file"
	exit 0
fi

[ ! -r $SDIR/$FILE ] && echo "Can't found git arch $SDIR/$FILE" && exit 1

echo && echo "--- REPO: $REPO"

echo "--- Check MD5 for $FILE ($MD5)"
CHECK=$(md5sum $SDIR/$FILE | cut -f1 -d' ')

[ "$CHECK" != "$MD5" ] && echo "Fail MD5 sum for file $SDIR/$FILE: $CHECK (need to be $MD5)" && exit 1

TD=$(mktemp -p $KAVGIT_TARGETDIR -d)
echo "--- Extract $FILE into $TD"
tar -xzf $SDIR/$FILE -C $TD || {
	echo "Can't extract $FILE"
	rm -rf $TD
	exit 1
}

cd $TD
GIT_OLD_HASH=$(git rev-parse HEAD)
echo "--- Git HEAD hash: $GIT_OLD_HASH"

echo "--- Fetch git repo: $REPO"
git pull || {
	echo "Can't git fetch the repo: $REPO"
	cd $CWD && rm -rf $TD
	exit 1
}

while [ -r ./.git/gc.pid ]; do
	echo "--- Wait 5 sec for background git garbage collector work $(date +"%F %T")"
	sleep 5
done

GIT_NEW_HASH=$(git rev-parse HEAD)
echo "--- New get HEAD hash: $GIT_NEW_HASH"

if [ "$GIT_OLD_HASH" != "$GIT_NEW_HASH" ]; then
	git fetch --prune || {
		echo "Can't git fetch the repo: $REPO"
		cd $CWD && rm -rf $TD
		exit 1
	}

	FNEW=$(mktemp -p $KAVGIT_TARGETDIR --suffix=.tgz)
	ORIGSIZE=$(du -bs | awk '{print $1}')
	echo "--- Size of dir: $ORIGSIZE"
	echo "--- Make new git archive $FNEW"
	tar -czf $FNEW ./ || {
		echo "Can't create $FNEW git arch"
		cd $CWD && rm -rf $TD
		exit 1
	}

	MD5NEW=$(md5sum -b $FNEW | cut -f1 -d' ')
	echo "--- New MD5: $MD5NEW"

	echo "--- Move file $FNEW to $SDIR/$FILE-temp"
	mv $FNEW $SDIR/$FILE-temp || {
		echo "Can't move git arch $FNEW"
		cd $CWD && rm -rf $TD $FNEW
		exit 1
	}

	echo "--- Delete old file $SDIR/$FILE"
	rm -f $SDIR/$FILE || {
		echo "Can't delete $SDIR/$FILE"
		cd $CWD && rm -rf $TD $SDIR/$FILE-temp
		exit 1
	}

	echo "--- Rename file $SDIR/$FILE-temp to $SDIR/$FILE"
	mv -f $SDIR/$FILE-temp $SDIR/$FILE || {
		echo "Can't rename git arch $SDIR/$FILE-temp"
		cd $CWD && rm -rf $TD $SDIR/$FILE-temp
		exit 1
	}

	grep -qE "^ORIGSIZE=" $IF || echo "ORIGSIZE=0" >> $IF

	echo "--- Update $IF"
	sed -i \
		-e "s#^MD5=.*\$#MD5=$MD5NEW#g" \
		-e "s#^ORIGSIZE=.*\$#ORIGSIZE=$ORIGSIZE#g" \
		$IF
else
	echo "--- Nothing to do (touch $IF)"
	touch $IF
fi

cd $CWD

if [ $CLEAN -eq 1 ]; then
	echo "--- Clean from $TD"
	rm -rf $TD
else
	NAME=$(basename $IF | sed 's/.git.info$//g')
	if [ ! -d $KAVGIT_TARGETDIR/$NAME ]; then
		echo "--- !!! REPO directory available at $KAVGIT_TARGETDIR/$NAME"
		mv $TD $KAVGIT_TARGETDIR/$NAME
	else
		echo "--- Can't rename to $KAVGIT_TARGETDIR/$NAME (directory already exists)"
		echo "--- !!! REPO directory available at $TD"
	fi
fi
