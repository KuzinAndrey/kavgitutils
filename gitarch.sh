#!/bin/sh

# Create TGZ archive from current work directory if it git managed dir (by .git directory)
# Save space on disk and store all content in one file with MD5 checksum

set -e

CWD=$(pwd)

[ ! -d $CWD/.git ] && echo "Can't found .git directory in $CWD" && exit 1
[ ! -r $CWD/.git/config ] && echo "Can't found .git/config file in $CWD" && exit 2

REPOURL=$(git config --get remote.origin.url)
[ -z "$REPOURL" ] && echo "Can't get origin URL for git repo" && exit 3
echo "--- Work with [$REPOURL] repository"

TMPDIR=$(mktemp -d -p /dev/shm)

echo "--- rsync $CWD/ => $TMPDIR/" \
&& rsync -avzq $CWD/ $TMPDIR/ \
&& cd $TMPDIR

echo "--- Git pull $REPOURL"
git pull || {
	echo "Can't pull repo $REPOURL"
	cd $CWD && rm -rf $TMPDIR
	exit 1
}

echo "--- Git fetch $REPOURL"
git fetch --prune || {
	echo "Can't fetch repo $REPOURL"
	cd $CWD && rm -rf $TMPDIR
	exit 1
}

ORIGSIZE=$(du -bs | awk '{print $1}')
echo "--- Dir original size: $ORIGSIZE"

PRGNAME=$(basename $CWD)
echo "--- Make $PRGNAME.git.tgz"
tar -czf ../$PRGNAME.git.tgz ./
cd ../
echo "--- Calc MD5 for $PRGNAME.git.tgz"
MD5SUM=$(md5sum -b $PRGNAME.git.tgz | cut -f1 -d' ')

(cat > $PRGNAME.git.info) << EOF
DESC=Repo at $REPOURL
REPO=$REPOURL
ORIGSIZE=$ORIGSIZE
FILE=$PRGNAME.git.tgz
MD5=$MD5SUM
EOF

rm -rf $TMPDIR

cd /dev/shm && rm -rf $CWD && mkdir $CWD && cd $CWD \
&& echo "--- Move $PRGNAME.git.info to $CWD" \
&& mv /dev/shm/$PRGNAME.git.info /dev/shm/$PRGNAME.git.tgz ./
