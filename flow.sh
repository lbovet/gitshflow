#!/bin/bash
root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dir=$root/repo
error=0
start=$1
stop=$2
if [ -z $start ] || [ $start -eq 0 ]; then
    start=0
    rm -fr $dir
    echo -e "\033[0;34m[0] Cleaned $dir\033[0m"
fi
mkdir -p $dir

# Infrastructure for smart script running (error handling, continuation)
function run() {
    if [ $error ]; then
        cd $dir
        ( eval $1 ) || ( export e=$?; cd $root; echo -e "\033[1;34mError (status=$e)\033[0m"; exit $e )
        error=$?
        cd $root
        return $error
    fi
}

function runAll() {
    i=0
    while read line; do
        if [ "$line" != "" ] && [[ $line != \#\#* ]] && [ $error -eq 0 ]; then
            i=`expr $i + 1`
            if [[ $line != \#* ]]; then
                color="1;36"
            else
                color="0;37"
            fi
            if [ $start -le $i ] && ( [ -z $stop ] || [ $stop -ge $i ]); then
                echo
                echo -e "\033[0;34m[$i]\033[${color}m $line\033[0m"
                if [[ $line != \#* ]]; then
                    run "$line"
                    error=$?
                fi
            fi
        fi
    done
    echo
}

cat << EOF | runAll

## The actual flow scenario

git init
git checkout --orphan develop

# initial snapshot version
echo v1-snapshot > file1
echo v1-snapshot > file2
git add . && git commit -m"Created files v1-snapshot"

# creating master branch
git branch master

# creating first release
git checkout master
git merge develop
sed -i 's/v.*/v1/' file1
sed -i 's/v.*/v1/' file2
git add . && git commit -m"Release v1"

# ...building, some conflicting changes during build

git checkout develop
sed -i 's/v.*/v1-snapshot-mybranch/' file1
echo addition >> file1
echo bar > foo
git add . && git commit -m"Changes during build"

# merging back after build to develop and new snapshot version
git checkout develop
git merge master -s ours
sed -i 's/v.*/v2-snasphot/' file1
sed -i 's/v.*/v2-snasphot/' file2
git add . && git commit -m"New snapshot version v2-snapshot" --amend

# remove one version file
rm file2
git rm file2 && git commit -m"Removed file2"

# creating release
git checkout master
git merge develop
sed -i 's/v.*/v2/' file1
cat file1
git add . && git commit -m"Release v2"

# merging back after build to develop and new snapshot version
git checkout develop
git merge master -s ours
sed -i 's/v.*/v3-snasphot/' file1
echo v3-snasphot > file3
git add . && git commit -m"New snapshot Version v3-snapshot" --amend

# creating release
git checkout master
git merge develop
sed -i 's/v.*/v3/' file1
cat file1
git add . && git commit -m"Release v3"


EOF
exit $error
