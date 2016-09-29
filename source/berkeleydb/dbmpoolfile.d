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

module berkeleydb.dbmpoolfile;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.dbenv;
import berkeleydb.dbt;
import berkeleydb.dbtxn;
import std.stdint;
import std.string;

alias DB_CACHE_PRIORITY DbCachePriority;

class DbMpoolfile
{
private:
	DB_MPOOLFILE *dbmpoolfile = null;
    DbEnv dbenv;
    int opened;

package:
    @property DB_MPOOLFILE *_DB_MPOOLFILE() {return dbmpoolfile;}
    @property int _opened() {return opened;}

	this(DB_MPOOLFILE *dbmpoolfile, DbEnv dbenv)
	{
        this.dbmpoolfile = dbmpoolfile;
        this.dbenv = dbenv;
	}

public:
	~this()
	{
		if (opened > 0) close();
	}

	void close(uint32_t flags = 0)
	{
        if (opened < 0) {
			throw new DbWrongUsingException("Closing closed DbMpoolfile");
		}
		auto ret = dbmpoolfile.close(dbmpoolfile, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

    int get(db_pgno_t *pgnoaddr, DbTxn txnid, uint32_t flags, ref ubyte *page)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.get(dbmpoolfile, pgnoaddr, txnid?txnid._DB_TXN:null, flags, &page);
        return DbRetCodeToException!"DbMpoolfile.get"(ret, dbenv);
    }

    void open(string file, uint32_t flags, int mode, size_t pagesize)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.open(dbmpoolfile, file.toStringz(), flags, mode, pagesize);
        opened = 1;
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void put(void *pgaddr, DbCachePriority priority, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.put(dbmpoolfile, pgaddr, priority, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void sync()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.sync(dbmpoolfile);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    /* Memory Pool File Configuration */
    void set_clear_len(uint32_t len)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbMpoolfile");
        }
        auto ret = dbmpoolfile.set_clear_len(dbmpoolfile, len);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_clear_len()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        uint32_t res;
        auto ret = dbmpoolfile.get_clear_len(dbmpoolfile, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_fileid(uint8_t[] fileid)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbMpoolfile");
        }
        if (fileid.length != DB_FILE_ID_LEN)
        {
            throw new DbWrongUsingException("Unique file identifiers must be a DB_FILE_ID_LEN length array of bytes");
        }
        auto ret = dbmpoolfile.set_fileid(dbmpoolfile, fileid.ptr);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void get_fileid(ref uint8_t[DB_FILE_ID_LEN] fileid)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.get_fileid(dbmpoolfile, fileid.ptr);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint8_t[DB_FILE_ID_LEN] get_fileid()
    {
        uint8_t[DB_FILE_ID_LEN] res;
        get_fileid(res);
        return res;
    }

    void set_flags(uint32_t flags, int onoff)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.set_flags(dbmpoolfile, flags, onoff);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_flags()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        uint32_t res;
        auto ret = dbmpoolfile.get_flags(dbmpoolfile, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_ftype(int ftype)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbMpoolfile");
        }
        auto ret = dbmpoolfile.set_ftype(dbmpoolfile, ftype);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    int get_ftype()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        int res;
        auto ret = dbmpoolfile.get_ftype(dbmpoolfile, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_lsn_offset(int32_t lsn_offset)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbMpoolfile");
        }
        auto ret = dbmpoolfile.set_lsn_offset(dbmpoolfile, lsn_offset);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    int32_t get_lsn_offset()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        int32_t res;
        auto ret = dbmpoolfile.get_lsn_offset(dbmpoolfile, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_maxsize(uint32_t gbytes, uint32_t bytes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.set_maxsize(dbmpoolfile, gbytes, bytes);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_maxsize(uint64_t bytes)
    {
        uint32_t _gbytes = cast(uint32_t) bytes/(1024*1024*1024);
        uint32_t _bytes = bytes%(1024*1024*1024);
        set_maxsize(_gbytes, _bytes);
    }

    void get_maxsize(ref uint32_t gbytes, ref uint32_t bytes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.get_maxsize(dbmpoolfile, &gbytes, &bytes);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint64_t get_maxsize()
    {
        uint32_t gbytes;
        uint32_t bytes;
        get_maxsize(gbytes, bytes);
        return (1024UL*1024*1024)*gbytes + bytes;
    }

    void set_pgcookie(Dbt *pgcookie)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbMpoolfile");
        }
        auto ret = dbmpoolfile.set_pgcookie(dbmpoolfile, &pgcookie.dbt);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void get_pgcookie(Dbt *dbt)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.get_pgcookie(dbmpoolfile, &dbt.dbt);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    Dbt get_pgcookie()
    {
        Dbt res;
        get_pgcookie(&res);
        return res;
    }

    void set_priority(DbCachePriority priority)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        auto ret = dbmpoolfile.set_priority(dbmpoolfile, priority);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    DbCachePriority get_priority()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbMpoolfile");
        }
        DbCachePriority res;
        auto ret = dbmpoolfile.get_priority(dbmpoolfile, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }
}
