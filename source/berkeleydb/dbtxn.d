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

module berkeleydb.dbtxn;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.dbenv;
import std.stdint;
import std.string;
import std.conv;

class DbTxn
{
private:
	DB_TXN *dbtxn = null;
    DbEnv dbenv;
    int opened;

package:
    @property DB_TXN *_DB_TXN() {return dbtxn;}

	this(DB_TXN *dbtxn, DbEnv dbenv)
	{
        this.dbtxn = dbtxn;
        this.dbenv = dbenv;
        opened = 1;
	}

public:
	~this()
	{
		if (opened > 0) abort();
	}

	void abort()
	{
		if (opened < 0) {
			throw new DbWrongUsingException("Aborting committed or discarded/aborted DbTxn");
		}
		auto ret = dbtxn.abort(dbtxn);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

	void discard(uint32_t flags = 0)
	{
		if (opened < 0) {
			throw new DbWrongUsingException("Discarding committed or discarded/aborted DbTxn");
		}
		auto ret = dbtxn.discard(dbtxn, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

	void commit(uint32_t flags = 0)
	{
		if (opened < 0) {
			throw new DbWrongUsingException("Commiting committed or discarded/aborted DbTxn");
		}
		auto ret = dbtxn.commit(dbtxn, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

    void prepare(uint8_t[DB_GID_SIZE] gid)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Preparing committed or discarded/aborted DbTxn");
		}
		auto ret = dbtxn.prepare(dbtxn, gid.ptr);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t id()
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on committed or discarded/aborted DbTxn");
		}
        return dbtxn.id(dbtxn);
    }

    void set_name(string name)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on committed or discarded/aborted DbTxn");
		}
		auto ret = dbtxn.set_name(dbtxn, name.toStringz());
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    string get_name()
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on committed or discarded/aborted DbTxn");
		}
        const (char) *res;
		auto ret = dbtxn.get_name(dbtxn, &res);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return to!string(res);
    }

    void set_priority(uint32_t priority)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on committed or discarded/aborted DbTxn");
		}
		auto ret = dbtxn.set_priority(dbtxn, priority);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_priority()
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on committed or discarded/aborted DbTxn");
		}
        uint32_t res;
		auto ret = dbtxn.get_priority(dbtxn, &res);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }
    
    void set_timeout(db_timeout_t timeout, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on committed or discarded/aborted DbTxn");
		}
		auto ret = dbtxn.set_timeout(dbtxn, timeout, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_commit_token(DbTxnToken *buffer)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on committed or discarded/aborted DbTxn");
		}
		auto ret = dbtxn.set_commit_token(dbtxn, buffer);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }
}
