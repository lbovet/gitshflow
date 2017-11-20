#!/bin/bash

root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dir=$root/repo
mkdir -p $dir
error=0

# Infrastructure for stopping on errors
function run() {
    if [ $error ]; then
        cd $dir
        ( $* ) || ( export e=$?; cd $root; echo "Terminating [$e]"; exit $e )
        error=$?
        cd $root
        return $error
    fi
}

function runAll() {
    i=0
    while read line; do
        if 
        i=`expr $i + 1`
        echo -e "\033[1;34m[$i]\033[0m $line"
        run $line
        error=$?
        echo $error
    done
}

cat << EOF | runAll

ls -la
ls d
echo hello
EOF

exit $error
