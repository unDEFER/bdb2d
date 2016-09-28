#!/bin/bash
wd=`pwd`
mkdir -p "$wd"/berkeleydb/
cat /usr/include/db.h | gawk -f "$wd"/bdb2d.awk > "$wd"/berkeleydb/c.d

