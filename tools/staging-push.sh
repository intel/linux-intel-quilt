#!/bin/bash
# this script pushes local version of the dm branches to my sandbox.
# assumes origin points to coe-tracker git remote.
# running this scrip is optional as the merged dev-bkc can be used to pull out
# the same branches.

manifest=$1

for b in `cat $manifest`; do 
	git push -f origin $b:sandbox/mgross/4.19/$b
done

