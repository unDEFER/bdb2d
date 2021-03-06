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

module berkeleydb.dbsite;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.dbenv;
import berkeleydb.dbt;
import std.stdint;
import std.string;
import std.conv;

class DbSite
{
private:
	DB_SITE *dbsite = null;
    DbEnv dbenv;
    int opened;

package:
    @property DB_SITE *_DB_SITE() {return dbsite;}

	this(DB_SITE *dbsite, DbEnv dbenv)
	{
        this.dbsite = dbsite;
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
			throw new DbWrongUsingException("Closing closed/removed DbSite");
		}
		auto ret = dbsite.close(dbsite);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}
    
    void get_address(ref string host, ref uint port)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed/removed DbSite");
		}
        const (char) *_host;
		auto ret = dbsite.get_address(dbsite, &_host, &port);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        host = to!string(_host);
    }

    int get_eid()
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed/removed DbSite");
		}
        int res;
		auto ret = dbsite.get_eid(dbsite, &res);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void remove()
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Removing closed/removed DbSite");
		}
		auto ret = dbsite.remove(dbsite);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_config(uint32_t which, uint32_t value)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed/removed DbSite");
		}
		auto ret = dbsite.set_config(dbsite, which, value);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_config(uint32_t which)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed/removed DbSite");
		}
        uint32_t res;
		auto ret = dbsite.get_config(dbsite, which, &res);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }
}
