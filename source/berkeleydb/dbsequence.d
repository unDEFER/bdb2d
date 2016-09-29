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

module berkeleydb.dbsequence;

import berkeleydb.c;
import berkeleydb.dbt;
import berkeleydb.db;
import berkeleydb.dbtxn;
import berkeleydb.dbexception;
import berkeleydb.dbenv;

import std.stdint;
import std.string;
import std.conv;

alias DB_SEQUENCE_STAT DbSequenceStat;

class DbSequence
{
private:
	DB_SEQUENCE *dbsequence = null;
    Db db;
    DbEnv dbenv;
    int opened = 0;

package:
    @property DB_SEQUENCE *_DB_SEQUENCE() {return dbsequence;}
    @property int _opened() {return opened;}

public:
	this(Db db, uint32_t flags = 0)
	{
        this.db = db;
        dbenv = db._dbenv;
		auto ret = db_sequence_create(&dbsequence, db?db._DB:null, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

	~this()
	{
		if (opened >= 0) close();
	}

    void open(DbTxn txnid, Dbt *key, uint32_t flags = 0)
    {
		if (opened > 0) {
			throw new DbWrongUsingException("Opening opened DbSequence");
		}
		if (opened < 0) {
			throw new DbWrongUsingException("Opening closed/removed DbSequence");
		}
		auto ret = dbsequence.open(dbsequence, txnid?txnid._DB_TXN:null, &key.dbt, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        opened++;
    }

	void close(uint32_t flags = 0)
	{
		if (opened < 0) {
			throw new DbWrongUsingException("Closing closed/removed DbSequence");
		}
		auto ret = dbsequence.close(dbsequence, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

    db_seq_t get(DbTxn txnid, uint32_t delta, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed/removed DbSequence");
		}
        db_seq_t res;
        auto ret = dbsequence.get(dbsequence, txnid?txnid._DB_TXN:null, delta, &res, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    Db get_dbp()
    {
        return db;
    }

    void get_key(Dbt *key)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed/removed DbSequence");
		}
        auto ret = dbsequence.get_key(dbsequence, &key.dbt);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void initial_value(db_seq_t value)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Configuration of closed/removed DbSequence");
		}
		if (opened > 0) {
			throw new DbWrongUsingException("Configuration of opened DbSequence");
		}
        auto ret = dbsequence.initial_value(dbsequence, value);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void remove(DbTxn txnid, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Removing closed/removed DbSequence");
		}
		auto ret = dbsequence.remove(dbsequence, txnid?txnid._DB_TXN:null, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    DbSequenceStat *stat(uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed/removed DbSequence");
		}
        DbSequenceStat *res;
		auto ret = dbsequence.stat(dbsequence, &res, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void stat_print(uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed/removed DbSequence");
		}
		auto ret = dbsequence.stat_print(dbsequence, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    /* Sequences Configuration */
    void set_cachesize(uint32_t size)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Configuration of closed/removed DbSequence");
		}
		if (opened > 0) {
			throw new DbWrongUsingException("Configuration of opened DbSequence");
		}
		auto ret = dbsequence.set_cachesize(dbsequence, size);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

version(VERSION_6)
{
    uint32_t get_cachesize()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbSequence");
        }
        uint32_t res;
        auto ret = dbsequence.get_cachesize(dbsequence, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }
}

    void set_flags(uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Configuration of closed/removed DbSequence");
		}
		if (opened > 0) {
			throw new DbWrongUsingException("Configuration of opened DbSequence");
		}
		auto ret = dbsequence.set_flags(dbsequence, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_flags()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbSequence");
        }
        uint32_t res;
        auto ret = dbsequence.get_flags(dbsequence, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_range(db_seq_t min, db_seq_t max)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Configuration of closed/removed DbSequence");
		}
		if (opened > 0) {
			throw new DbWrongUsingException("Configuration of opened DbSequence");
		}
		auto ret = dbsequence.set_range(dbsequence, min, max);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void get_range(ref db_seq_t min, ref db_seq_t max)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Configuration of closed/removed DbSequence");
		}
		auto ret = dbsequence.get_range(dbsequence, &min, &max);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }
}
