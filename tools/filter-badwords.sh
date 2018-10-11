#!/bin/bash
# scrub the topic branches of bad words in the commit comments.
# this script needs to be updated WRT the banned_words file from
# git://kojiclear.jf.intel.com/projects/clr-github-publish-packages

rc=$1
manifest=$2
#badwords=$3

for b in `cat $manifest`; do
	git checkout $b
	git filter-branch -f --msg-filter 'sed "s/\S*\(kojiclear\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(zpn.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(jf.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(sc.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(corp.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(github.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(eclists.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(devtools.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(ith.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(ostc.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(android.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(10.54.39.\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(134.134.\)\S*//g"' $rc..

done
