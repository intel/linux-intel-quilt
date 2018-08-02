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

for b in `cat $manifest`; do 
	echo $b
	git checkout $rc
	git push -f gerrit $rc:dev/staging/$b
	git checkout $b
	git push gerrit HEAD:refs/for/dev/staging/$b
	read -n 1 -p "Do you want to continue (y/n)?" answer
	case $answer in
		[Yy]) continue;;
		[Nn]) echo "exit program"; exit;;
	esac
done


