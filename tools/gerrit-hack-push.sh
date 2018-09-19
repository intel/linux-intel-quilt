#!/bin/bash
# pushes patches to gerrit for code review. it assumes you ahve run gerrit-prep
# to insert the Change-Id's.  note: some commits this doesn't work well for.
# gerrit needs the change-id in the last paragraph of the commit comment and
# there shold be only one in the last paragraph.  I've seen this fail.  
#if you are reading this far ask for help if you attempt this.  Because you'll
# need to had "git --ammend" to  fix it based on the error reported back from
# gerrit if it fails....

rc=$1
manifest=$2

git push -f codereview $rc:master

for b in `cat $manifest`; do 
	rm -rf patches .pc
	echo $b
	git push -f codereview $rc:dev/4.19/$b
	git push codereview $b-gerrit:refs/for/4.19/$b 2>$b.gerrit
done


