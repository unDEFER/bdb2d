#!/bin/bash
. config.sh

wd=`pwd`
cd $BDBPATH/src/dbinc
mkdir -p "$wd"/berkeleydb/
cat db.in ../dbinc_auto/api_flags.in ../dbinc_auto/ext_def.in ../dbinc_auto/ext_prot.in | awk -f "$wd"/bdb2d.awk > "$wd"/berkeleydb/c.d

