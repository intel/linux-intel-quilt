#!/bin/bash
# this script creates the full dev-bck-rc<n> by doing merge commits of the
# rebased (flattened) dm branches.  Note: this include the Android changes.
# When you are finshed and have checked your work (using quilt or a global
# rebase) you can simply push this branch as the dev-bkc-android and then
# checkout the non-android version but using git log to locate the first
# android patch, and push that as the dev-bck-base)

rc=$1
# first arg is the tag name for the RC to use.
manifest=$2

git checkout $rc
git branch -D dev-bkc-$rc 
git checkout -b dev-bkc-$rc $rc

for b in `cat $manifest`; do 
	git merge --no-ff $b
	while [ "$(git diff | grep '<<<<<<<')" != "" ] || [ "$(git diff --cached | grep '<<<<<<<')" != "" ] ; do
		echo in subshell.  fix merge for ${b} and exit to continue
		bash --rcfile <(cat ~/.bashrc ; echo 'PS1="FIXEME\u@\h:\w\$ \[\033[0;33m\]Fix $b Merge$ \[\033[00m\]"')
		read -n 1 -p "Do you want to continue (y/n)?" answer
		case $answer in
			[Yy]) continue;;
			[Nn]) echo "exit program"; exit;;
		esac

	done
	git commit -as --no-edit
done;

