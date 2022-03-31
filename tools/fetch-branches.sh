#!/bin/bash
# this script mirrors the dm staging branches to your local work space.  run
# this early in the process to setup your enviornment.
# be sure to first checkout and name the rc for later.  (i.e. run
# git checkout -b rc<n> v4.18-rc<n>  assuming you have the kernel.org upstream
# as a git remote that is up to date....

rc=$1
# first arg is the tag name for the RC to use.
manifest=$2

git checkout $rc

for b in `cat $manifest`; do 
	git branch -D $b
	git checkout -b $b origin/dev/4.19/staging/$b
	head Makefile
done


