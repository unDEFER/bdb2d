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

module berkeleydb.dbstream;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.dbenv;
import berkeleydb.dbt;
import std.stdint;
import std.string;
import std.conv;

class DbStream
{
private:
	DB_STREAM *dbstream = null;
    DbEnv dbenv;
    int opened;

package:
    @property DB_STREAM *_DB_STREAM() {return dbstream;}

	this(DB_STREAM *dbstream, DbEnv dbenv)
	{
        this.dbstream = dbstream;
        this.dbenv = dbenv;
        opened = 1;
	}

public:
	~this()
	{
		if (opened > 0) close();
	}

	void close(uint32_t flags = 0)
	{
		if (opened < 0) {
			throw new DbWrongUsingException("Closing closed DbStream");
		}
		auto ret = dbstream.close(dbstream, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}
    
    void read(Dbt *data, db_off_t offset, 
                uint32_t size, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbStream");
		}
		auto ret = dbstream.read(dbstream, &data.dbt, offset, size, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    db_off_t size(uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbStream");
		}
        db_off_t res;
		auto ret = dbstream.size(dbstream, &res, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }
    
    void write(Dbt *data, db_off_t offset, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbStream");
		}
		auto ret = dbstream.write(dbstream, &data.dbt, offset, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }
}
