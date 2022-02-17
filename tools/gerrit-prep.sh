#!/bin/bash
# inserts Change-ID's into each patch for each branch...  (mostly works)

rc=$1
manifest=$2

tmp=$(mktemp)
hook=$(readlink -f $(git rev-parse --git-dir))/hooks/commit-msg

for b in `cat $manifest`; do 
	git checkout $b
	git filter-branch -f --msg-filter "cat > $tmp; \"$hook\" $tmp; cat $tmp" $rc..
done

