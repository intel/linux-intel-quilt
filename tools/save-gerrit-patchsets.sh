#!/bin/bash
# this script iterates over the manifest and creates the patch series for each
# branch and the series file.

# run this script after creating the gerrit push directories with all the
# change-id's.

# save these archives for use with the next spin of the dev-bkc to harvest
# change-id's from using patch_tool.py  (these will be the "old" versions)

rc=$1
# first arg is the tag name for the RC to use.
manifest=$2

for b in `cat $manifest`; do 
	mkdir $b-gerrit

	echo \# $b >> series;
	git checkout $b; 
	git format-patch --suffix=.$b $rc..; 
	ls *.$b >> series; 
	mv *.$b series $b-gerrit

done

