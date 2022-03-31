#!/bin/bash
# this script iterates over the manifest and creates the patch series for each
# branch and the series file.
# assumes you have local mirrors of each DM branch in the manifest and the rc
# is mirrored localy as a branch for git rebase to work off of.

rc=$1
# first arg is the tag name for the RC to use.
manifest=$2

rm -rf $rc;
mkdir $rc;
for b in `cat $manifest`; do 
	echo \# $b >> series;
	git checkout $b; 
	mkdir $rc/$b
	git format-patch --suffix=.$b $rc..; 
	ls *.$b >> series; 
	mv series $rc/$b;
	mv *.$b $rc/$b;
done

