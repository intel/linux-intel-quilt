#! /bin/bash

# build quiltimport gerrit branches to push to gerrit.

rc=$1
manifest=$2


for b in `cat $manifest`; do
	git checkout -b gerrit-$b $rc
	rm -rf .pc patches
	mkdir patches
	cp $rc/$rc-$b/* patches/.

	git quiltimport
done

