/*
   bdb2d is BerkeleyDB for D language
   It is part of unDE project (http://unde.su)

   Copyright (C) 2009-2014 Nikolay (unDEFER) Krivchenkov <undefer@gmail.com>

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

module main;
import std.algorithm;
import std.stdio;
import std.string;
import berkeleydb.all;
import core.thread;
import core.sys.posix.stdlib;
import std.file;
import std.stdint;
import std.conv;

void main()
{
    string tmp = fromStringz(getenv("TMP".toStringz())).idup();
    if (tmp == "") tmp = "/tmp";
    try{
        mkdir(tmp~"/berkeleydb.locks");
    } catch (Exception file)
    {
    }

    DbEnv dbenv = new DbEnv(0);

    uint32_t env_flags = DB_CREATE |    /* Create the environment if it does 
                                * not already exist. */
                DB_INIT_TXN  | /* Initialize transactions */
                DB_INIT_LOCK | /* Initialize locking. */
                DB_INIT_LOG  | /* Initialize logging */
                DB_INIT_MPOOL| /* Initialize the in-memory cache. */
                DB_RECOVER;

    dbenv.open(tmp~"/berkeleydb.locks/", env_flags, octal!666);

    Db db = new Db(dbenv, 0);
    db.open(null, "numbers.db", null, DB_BTREE, DB_CREATE | DB_AUTO_COMMIT | DB_MULTIVERSION, octal!600);

    while (true)
    {
        auto txn = dbenv.txn_begin(null, DB_TXN_SNAPSHOT);

        for (int i=0; i <5; i++)
        {
            Dbt key;
            Dbt data;
            string str = "the_number";
            key = str;

            auto res = db.get(txn, &key, &data);
            if (res == 0)
            {
                uint the_number = data.to!uint;
                writeln("number is ", the_number);
		stdout.flush();
            }
            else
            {
                dbenv.err(res, "number not readed");
            }

            Thread.sleep( dur!("seconds")( 1 ) );
        }

        txn.commit();
    }
}
