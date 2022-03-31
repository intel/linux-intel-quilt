#!/bin/bash
# this script runs git filterbranch to add change-Id's to comments not having
# them.

# run this when you need to insert new change-id's for gerrit code review.
# first arg is the tag name for the RC to use.

rc=$1
manifest=$2


for b in `cat $manifest`; do 
	echo $b ;
	git checkout $b; 
	
	tmp=$(mktemp)
	hook=$(readlink -f $(git rev-parse --git-dir))/hooks/commit-msg
	git filter-branch -f --msg-filter "cat > $tmp; \"$hook\" $tmp; cat $tmp" $rc..;

done


