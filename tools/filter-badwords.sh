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
	
	git filter-branch -f --msg-filter 'sed "s/\S*\(tm.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(sh.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(ra.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(png.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(or.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(lm.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(ld.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(ka.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(jf.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(ikor.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(iind.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(iam.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(hf.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(gv.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(fm.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(fi.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(ch.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(bj.intel.com\)\S*//g"' $rc..
	git filter-branch -f --msg-filter 'sed "s/\S*\(an.intel.com\)\S*//g"' $rc..
	
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
