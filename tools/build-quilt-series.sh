#!/bin/bash
# this script iterates over the manifest and creates the patch series for each
# branch and the series file.
# assumes you have local mirrors of each DM branch in the manifest and the rc
# is mirrored localy as a branch for git rebase to work off of.

rc=$1
# first arg is the tag name for the RC to use.
manifest=$2

echo \# $rc >> series;
echo -n \# >> series; git log $rc --oneline -n 1 >> series

for b in `cat $manifest`; do 
	echo \# $b >> series;
	echo \# $b >> series-android;
	git checkout $b; 
	mkdir patches;
	git format-patch --suffix=.$b $rc..; 
	ls *.$b >> series;
	ls *.$b >> series-android;
	mv *.$b patches;
done

