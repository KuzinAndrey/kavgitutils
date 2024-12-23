#!/bin/sh

# Refresh all git projects (detected by .git directory)

CWD=`pwd`
SCRIPT=/tmp/git-$(cat /proc/sys/kernel/random/uuid).sh
cat > $SCRIPT <<EOF
#!/bin/sh

ORANGE='\033[0;33m'
CLEAR='\033[0m'
[ -z \$1 ] && echo "No param" && exit
[ ! -r \$1/config ] && echo "No file config" && exit
cd $CWD
cd \$1 && cd .. && printf "\n\nGIT DIR \${ORANGE}\$(pwd)\${CLEAR}\n" && git pull --rebase
EOF
chmod +x $SCRIPT

find ./ -type d -name ".git" -exec $SCRIPT {} \;

rm $SCRIPT
