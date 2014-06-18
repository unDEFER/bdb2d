#!/bin/bash
. ../config.sh

[[ "$1" == "clean" ]] &&
    {
        rm -f reader reader.o writer writer.o
        exit 0
    }

dmd -g -unittest reader.d ../berkeleydb/*.d $BDBPATH/build_unix/libdb.a
dmd -g -unittest writer.d ../berkeleydb/*.d $BDBPATH/build_unix/libdb.a
