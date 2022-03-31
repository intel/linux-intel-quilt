#!/usr/bin/env python

import sys
import os
import subprocess

# use this program to harvest topic brahces from staging releases
# use is assumed to be as follows:
# 1: create a base rc (branch rc2 v4.19-rc2)
# 2: run this harvest_topics.py rc2, dev-bkc-rc2-android
# to extract all the topic branches.

def call(cmd):
    P = subprocess.Popen(args=cmd,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out = P.communicate()
    stdout = out[0].decode("utf-8").split('\n')
    stderr = out[1].decode("utf-8").split('\n')
    if len(stderr) > 1:
        print (len(stder), cmd, stderr)
    return (stdout, stderr)


def Fetch(project, remote , rev):
    cmd = ["/usr/bin/git", "fetch", remote, rev];
    call(project, cmd)


def extract_topic_branches(base, head):
    """ extract second parent and the topic branch name."""
    cmd = ["git", "log", "--merges", "--parents",
           "--oneline",  base + ".." + head]
    ret = call(cmd)
    lines = ret[0]
    topics = []
    for l in lines:
        if len(l) > 0:
            fields = l.split()
            sha = fields[2]
            name = fields[5].split("'")[1]
            topics.append((sha, name))
    return topics


def create_topic_branches(prefix, topics):
    for topic in topics:
        cmd = ["git", "branch", prefix + "-" + topic[1], topic[0]]
        ret = call(cmd)


def main( base, head):
    topics = extract_topic_branches(base, head)
    create_topic_branches(base, topics)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
