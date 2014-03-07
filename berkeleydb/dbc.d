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

module berkeleydb.dbc;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.db;
import berkeleydb.dbt;
import berkeleydb.dbenv;
import berkeleydb.dbstream;
import std.stdint;
import std.string;

class Dbc
{
private:
	DBC *dbc = null;
    DbEnv dbenv;
    int opened;
    bool join; // join cursor may use only get&close methods

package:
    @property DBC *_DBC() {return dbc;}
    @property int _opened() {return opened;}
    @property bool _join() {return join;}

	this(DBC *dbc, bool join, DbEnv dbenv)
	{
        this.dbc = dbc;
        this.join = join;
        this.dbenv = dbenv;
        opened = 1;
	}

public:
	~this()
	{
		if (opened > 0) close();
	}

	void close()
	{
        if (opened < 0) {
			throw new DbWrongUsingException("Closing closed Dbc");
		}
		auto ret = dbc.close(dbc);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

    int cmp(Dbc other_cursor, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc");
        }
        if (join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor");
        }
        if (other_cursor._opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc (other_cursor argument)");
        }
        if (other_cursor._join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor (other_cursor argument)");
        }
        int res;
        auto ret = dbc.cmp(dbc, other_cursor._DBC, &res, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    db_recno_t count(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc");
        }
        if (join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor");
        }
        uint32_t res;
        auto ret = dbc.count(dbc, &res, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    int del(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc");
        }
        if (join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor");
        }
        auto ret = dbc.del(dbc, flags);
        return DbRetCodeToException!"Dbc.del"(ret, dbenv);
    }

    Dbc dup(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc");
        }
        if (join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor");
        }
        DBC *res;
        auto ret = dbc.dup(dbc, &res, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return new Dbc(res, false, dbenv);
    }

    int get(Dbt *key, Dbt *data, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc");
        }
        auto ret = dbc.get(dbc, &key.dbt, &data.dbt, flags);
        DbRetCodeToException!"Dbc.get"(ret, dbenv, key);
        DbRetCodeToException!"Dbc.get"(ret, dbenv, data);
        return DbRetCodeToException!"Dbc.get"(ret, dbenv);
    }

    int pget(Dbt *key, Dbt *pkey, Dbt *data, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc");
        }
        auto ret = dbc.pget(dbc, &key.dbt, &pkey.dbt, &data.dbt, flags);
        DbRetCodeToException!"Dbc.get"(ret, dbenv, key);
        DbRetCodeToException!"Dbc.get"(ret, dbenv, data);
        return DbRetCodeToException!"Dbc.get"(ret, dbenv);
    }

    int put(Dbt *key, Dbt *data, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc");
        }
        if (join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor");
        }
        auto ret = dbc.put(dbc, &key.dbt, &data.dbt, flags);
        return DbRetCodeToException!"Dbc.put"(ret, dbenv);
    }

    void set_priority(DbCachePriority priority)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Dbc");
        }
        if (join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor");
        }
        auto ret = dbc.set_priority(dbc, priority);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    DbCachePriority get_priority()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Dbc");
        }
        if (join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor");
        }
        DbCachePriority res;
        auto ret = dbc.get_priority(dbc, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    /* BLOBs and Related Methods */
    DbStream db_stream(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get DbStream on closed Dbc");
        }
        if (join) {
            throw new DbWrongUsingException("Only get&close operations permitted for join cursor");
        }
        DB_STREAM *res;
        auto ret = dbc.db_stream(dbc, &res, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return new DbStream(res, dbenv);
    }
}
