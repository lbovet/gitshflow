#!/bin/bash

# Infrastructure for smart script running (error handling, continuation)

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

## The actual near-gitflow scenario

git init
git checkout --orphan develop

# initial snapshot version
echo v1-snapshot > file1
echo v1-snapshot > file2
echo v1-snapshot > file3

git add . && git commit -m"(develop) Created working version v1-snapshot"

# creating master branch
git branch master

# create first release
git checkout master
git merge develop
sed -i 's/v.*/v1/' file*
git add . && git commit -m"(master) Release v1"

# ...building, some conflicting changes during build

git checkout develop
git rm file3
sed -i 's/v.*/v1-snapshot-mybranch/' file*
echo addition >> file1
echo bar > foo
git add . && git commit -m"(develop) Changes during build (modified file1 and deleted file3)"

# merge back to develop after build and new snapshot version
git checkout develop
git merge master -s ours
sed -i 's/v.*/v2-snasphot/' file*
git add . && git commit -m"(develop) New working version v2-snapshot" --amend

# remove one version file
git checkout develop
git rm file2 && git commit -m"(develop) Removed file2"

# create release
git checkout master
git merge develop
sed -i 's/v.*/v2/' file*
git add . && git commit -m"(master) Release v2"

# merge back to develop after build and new snapshot version
git checkout develop
git merge master -s ours
sed -i 's/v.*/v3-snasphot/' file*
git add . && git commit -m"(develop) New working version v3-snapshot" --amend

# add some file
echo v3-snapshot > file4
echo x >> file4
echo y >> file4
git add . && git commit -m"(develop) Added file4"

# create release
git checkout master
git merge develop
sed -i 's/v.*/v3/' file*
git add . && git commit -m"(master) Release v3"

# merge back to develop after build and new snapshot version
git checkout develop
git merge master -s ours
sed -i 's/v.*/v4-snasphot/' file*
git add . && git commit -m"(develop) New working version v4-snapshot" --amend

# create hotfix branch
git checkout master
git branch hotfix
git checkout hotfix
sed -i 's/v.*/v3.1-snasphot/' file*
git add . && git commit -m"(hotfix) Started hotfix v3.1-snapshot"

# ...some changes during hotfix work
git checkout develop
echo hello > world
cp file1 file5
echo more5 >> file5
sed -i 's/y/Y/' file*
git add . && git commit -m"(develop) Some work on develop during hotfix"

# ...work for hotfix
git checkout hotfix
echo BAR > foo
echo "is coming" > winter
git add . && git commit -m"(hotfix) Work on hotfix"
sed -i 's/v.*/v3.1/' file*
git add . && git commit -m"(hotfix) Release v3.1"

# hotfix release
git checkout master
git merge hotfix

# merge hotfix back to develop from release
git checkout develop
sed -i 's/v.*/v3.1/' file*
git add . && git commit -m"(develop) Artifical commit to align version to hotfix"
git merge master
sed -i 's/v.*/v4-snapshot/' file*
git add . && git commit -m"() New working version v4-snapshot" --amend


git log --graph --all --decorate --oneline
EOF
exit $error
