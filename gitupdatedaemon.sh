#!/bin/sh

# Update all git repository git.tgz/git.info files in current directory
# randomly in forever cycle one file in 15 minutes (default)
# You can set delay by first argv (example for 1 min):
#    ./gitupdatedaemon.sh 60

TS=$(date +%s)
SLEEP=${1:-900}
(cat > /dev/shm/gitdaemon-$TS.sh) << \EOF
#!/bin/sh
TS=$(date +%s)
CWD=$(pwd)
SLEEP=${1:-900}
export LC_NUMERIC=C
while [ 1 ]; do
	cd $CWD && find . -type f -name "*.git.info" -mtime +1 -print | shuf > /dev/shm/.gitqueue-$TS;
	[ -r /dev/shm/.gitqueue-$TS ] && [ -s /dev/shm/.gitqueue-$TS ] && \
	while [ 1 ]; do
		cd $CWD
		[ ! -r /dev/shm/.gitqueue-$TS ] && break
		[ $(cat /dev/shm/.gitqueue-$TS | wc -l) -eq 0 ] && break
		F=$(head -n 1 /dev/shm/.gitqueue-$TS && sed -i -e "1d" /dev/shm/.gitqueue-$TS)
		[ -z "$F" ] && break
		printf "%s" "$(date +"%F %T") - $F " >> /dev/shm/.gitqueue-$TS.log
		ST=$(date +"%s.%N")
		OLD_SIZE=$(egrep "^ORIGSIZE=" $F | cut -f2 -d=)
		gitupdate.sh $F -gc
		ET=$(date +"%s.%N")
		NEW_SIZE=$(egrep "^ORIGSIZE=" $F | cut -f2 -d=)
		printf "(done in %.03f sec," $(echo "$ET - $ST" | bc) >> /dev/shm/.gitqueue-$TS.log
		printf " size old=%d" $OLD_SIZE >> /dev/shm/.gitqueue-$TS.log
		printf " new=%d" $NEW_SIZE >> /dev/shm/.gitqueue-$TS.log
		printf " delta=%d)" $(echo "$NEW_SIZE - $OLD_SIZE" | bc) >> /dev/shm/.gitqueue-$TS.log
		echo >> /dev/shm/.gitqueue-$TS.log
		sleep $SLEEP
	done
	sleep $SLEEP
done
EOF
chmod a+x /dev/shm/gitdaemon-$TS.sh
nohup /dev/shm/gitdaemon-$TS.sh $SLEEP 1> /dev/null 2> /dev/null &
sleep 1 && rm /dev/shm/gitdaemon-$TS.sh
