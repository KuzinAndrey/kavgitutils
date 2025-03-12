#!/bin/sh

# Update all git repository git.tgz/git.info files in current directory
# randomly in forever cycle one file in 15 minutes

TS=$(date +%s)
(cat > /dev/shm/gitdaemon-$TS.sh) << \EOF
#!/bin/sh
TS=$(date +%s)
CWD=$(pwd)
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
		gitupdate.sh $F
		ET=$(date +"%s.%N")
		LC_NUMERIC=C printf "(done in %.03f sec)\n" $(echo "$ET - $ST" | bc) >> /dev/shm/.gitqueue-$TS.log
		sleep 900
	done
	sleep 900
done
EOF
chmod a+x /dev/shm/gitdaemon-$TS.sh
nohup /dev/shm/gitdaemon-$TS.sh 1> /dev/null 2> /dev/null &
sleep 1 && rm /dev/shm/gitdaemon-$TS.sh
