#!/bin/sh

# Update all git repository git.tgz/git.info files in current directory
# randomly in forever cycle one file in 15 minutes (default)
# You can set delay by first argv (example for 1 min):
#    ./gitupdatedaemon.sh 60

usage() {
	echo "Use: $0 <sleep> <file>"
}

[ -n "$1" -a -f "$1" ] && echo "You pass file name as delay ($1)" && usage && exit 1
[ ! -z "$(echo -n "$1" | tr -d [0-9])" ] && echo "Sleep delay must be an integer value" && exit 1

TS=$(date +%s)
SLEEP=${1:-900}
[ -n "$1" ] && shift
SCR="/dev/shm/gitdaemon-$TS.sh"
(cat > $SCR) << \EOF
#!/bin/sh
TS=$(date +%s)
CWD=$(pwd)
SLEEP=${1:-900}
export LC_NUMERIC=C

fail_work() {
	echo "Can't create work file"
	exit 1
}

FILE=/dev/shm/.gitqueue-$TS
if [ -z "$2" ]; then
	find $CWD -type f -name "*.git.info" -mtime +1 -print | shuf > $FILE || fail_work
elif [ -r "$2" ]; then
	cat "$2" | shuf > $FILE || fail_work
else
	fail_work
fi

#while [ 1 ]; do
#	cd $CWD
	[ -r $FILE ] && [ -s $FILE ] && \
	while [ 1 ]; do
		cd $CWD
		[ ! -r $FILE ] && break
		[ $(cat $FILE | wc -l) -eq 0 ] && break
		F=$(head -n 1 $FILE && sed -i -e "1d" $FILE)
		[ -z "$F" ] && break
		printf "%s" "$(date +"%F %T") - $F " >> $FILE.log
		ST=$(date +"%s.%N")
		OLD_SIZE=$(egrep "^ORIGSIZE=" $F | cut -f2 -d=)
		gitupdate.sh $F -gc
		ET=$(date +"%s.%N")
		NEW_SIZE=$(egrep "^ORIGSIZE=" $F | cut -f2 -d=)
		printf "(done in %.03f sec," $(echo "$ET - $ST" | bc) >> $FILE.log
		printf " size old=%d" $OLD_SIZE >> $FILE.log
		printf " new=%d" $NEW_SIZE >> $FILE.log
		printf " delta=%d)" $(echo "$NEW_SIZE - $OLD_SIZE" | bc) >> $FILE.log
		echo >> $FILE.log
		sleep $SLEEP
	done
#	sleep $SLEEP
#done
EOF
chmod a+x $SCR
nohup $SCR $SLEEP $@ 1> /dev/null 2> /dev/null &
sleep 1 && rm $SCR
