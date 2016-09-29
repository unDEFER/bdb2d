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

module berkeleydb.dblogc;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.dbenv;
import berkeleydb.dbt;
import std.stdint;
import std.string;

class DbLogc
{
private:
	DB_LOGC *dblogc = null;
    DbEnv dbenv;
    int opened;

package:
    @property DB_LOGC *_DB_LOGC() {return dblogc;}
    @property int _opened() {return opened;}

	this(DB_LOGC *dblogc, DbEnv dbenv)
	{
        this.dblogc = dblogc;
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
			throw new DbWrongUsingException("Closing closed DbLogc");
		}
		auto ret = dblogc.close(dblogc, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

    int get(DbLsn *lsn, Dbt *data, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed DbLogc");
        }
        auto ret = dblogc.get(dblogc, lsn, &data.dbt, flags);
        DbRetCodeToException!"DbLogc.get"(ret, dbenv, data);
        return DbRetCodeToException!"DbLogc.get"(ret, dbenv);
    }
}
