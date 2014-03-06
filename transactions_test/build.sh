#!/bin/bash
. ../config.sh

[[ "$1" == "clean" ]] &&
    {
        rm -f reader reader.o writer writer.o
        exit 0
    }

dmd -g -unittest reader.d ../berkeleydb/*.d ~/Programs/db-6.0.20.NC/build_unix/libdb.a
dmd -g -unittest writer.d ../berkeleydb/*.d ~/Programs/db-6.0.20.NC/build_unix/libdb.a
