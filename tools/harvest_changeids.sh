#!/bin/bash
# this script iterates over the old and new manifests and creates the patch series for each
# branch and the series file.
# assumes you have local mirrors of each DM branch in the manifest and the rc
# is mirrored localy as a branch for git rebase to work off of.
# 

rcOld=$1
rcNew=$2
manifest=$3

for b in `cat $manifest`; do 
	
    python3 patch_tool.py $rcOld/$rcOld-$b $rcNew/$rcNew-$b
	mv *.$rcNew-$b $rcNew/$rcNew-$b;
done

