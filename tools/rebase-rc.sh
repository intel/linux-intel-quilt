#!/bin/bash
# this script iterates over each dm branch and flattens it by rebaseing to the
# rc.  If the rebase has issues beat up the DM to fix it.

rc=$1
manifest=$2

for b in `cat $manifest`; do 
	git checkout $b
	git rebase $rc
done



