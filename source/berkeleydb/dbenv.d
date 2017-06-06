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

module berkeleydb.dbenv;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.dbtxn;
import berkeleydb.dbt;
import berkeleydb.dblogc;
import berkeleydb.dblogverifyconfig;
import berkeleydb.dbmpoolfile;
import berkeleydb.dbchannel;
import berkeleydb.dbsite;

import core.stdc.config;
import std.stdint;
import std.stdio;
import std.string;
import std.conv;
import std.array;
import std.format;
import core.sys.posix.pthread;

version(Windows)
{
alias long bdb_time_t;
}
else
{
alias time_t bdb_time_t;
}

alias DB_MEM_CONFIG DbMemConfig;
alias DB_LOCK DbLock;
alias DB_LOCK_STAT DbLockStat;
alias DB_LOCKREQ DbLockreq;
alias DB_LSN DbLsn;
alias DB_BACKUP_CONFIG DbBackupConfig;
alias DB_LOG_STAT DbLogStat;
alias DB_MPOOL_STAT DbMpoolStat;
alias DB_MPOOL_FSTAT DbMpoolFstat;
alias DB_TXN_STAT DbTxnStat;
alias DB_MUTEX_STAT DbMutexStat;
alias DB_REPMGR_SITE DbRepmgrSite;
alias DB_REPMGR_STAT DbRepmgrStat;
alias DB_REP_STAT DbRepStat;
alias DB_TXN_TOKEN DbTxnToken;

class DbEnv
{
private:
	DB_ENV *dbenv = null;
    int opened = 0;
    int rep_transport = 0;
    int rep_started = 0;
    int repmgr_started = 0;
    static DbEnv[DB_ENV *] dbenv_map;

    static DbEnv from_DB_ENV(const DB_ENV *_dbenv)
    {
        return dbenv_map[_dbenv];
    }

package:
    @property DB_ENV *_DB_ENV() {return dbenv;}
    @property int _opened() {return opened;}

public:
	this(uint32_t flags = 0)
	{
		auto ret = db_env_create(&dbenv, flags);
		DbRetCodeToException(ret, this);
        dbenv_map[dbenv] = this;
        assert(ret == 0);
	}

	~this()
	{
		if (opened >= 0) close();
        dbenv_map.remove(dbenv);
	}

	static ~this()
	{
        dbenv_map = null;
    }

    void open(string db_home, uint32_t flags, int mode)
    {
		if (opened > 0) {
			throw new DbWrongUsingException("Opening opened DbEnv");
		}
		if (opened < 0) {
			throw new DbWrongUsingException("Opening closed DbEnv");
		}
		auto ret = dbenv.open(dbenv, db_home.toStringz(), flags, mode);
		DbRetCodeToException(ret, this);
        assert(ret == 0);
        opened++;
    }

	void close(uint32_t flags = 0)
	{
		if (opened < 0) {
			throw new DbWrongUsingException("Closing closed DbEnv");
		}
		auto ret = dbenv.close(dbenv, flags);
        opened = -1;
		DbRetCodeToException(ret, this);
        assert(ret == 0);
	}

    void backup(string target, uint32_t flags = 0)
    {
		if (opened <= 0) {
			throw new DbWrongUsingException("Operation on closed or not opened DbEnv");
		}
        auto ret = dbenv.backup(dbenv, target.toStringz(), flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void dbbackup(string dbfile, string target, uint32_t flags = 0)
    {
		if (opened <= 0) {
			throw new DbWrongUsingException("Operation on closed or not opened DbEnv");
		}
        auto ret = dbenv.dbbackup(dbenv, dbfile.toStringz(), target.toStringz(), flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void dbremove(DbTxn txnid, string file, string database, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
		if (txnid && !txnid._DB_TXN) {
			throw new DbWrongUsingException("Operation on closed DbTxn");
		}
        auto ret = dbenv.dbremove(dbenv, txnid?txnid._DB_TXN:null, file.toStringz(), database.toStringz(), flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void dbrename(DbTxn txnid, string file, string database, string newname, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
		if (txnid && !txnid._DB_TXN) {
			throw new DbWrongUsingException("Operation on closed DbTxn");
		}
        auto ret = dbenv.dbrename(dbenv, txnid?txnid._DB_TXN:null, file.toStringz(), database.toStringz(), newname.toStringz(), flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void err(T...)(int error, string fmt, T args)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
        auto app = appender!string();
        formattedWrite(app, fmt, args);
        dbenv.err(dbenv, error, "%s".toStringz(), app.data.toStringz());
    }

    void errx(T...)(string fmt, T args)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
        auto app = appender!string();
        formattedWrite(app, fmt, args);
        dbenv.errx(dbenv, "%s".toStringz(), app.data.toStringz());
    }

    void failchk(uint32_t flags = 0)
    {
		if (opened <= 0) {
			throw new DbWrongUsingException("Operation on closed or not opened DbEnv");
		}
        auto ret = dbenv.failchk(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void fileid_reset(string file, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
        auto ret = dbenv.fileid_reset(dbenv, file.toStringz(), flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    static string db_full_version(int *family, int *release, int *major, int *minor, int *patch)
    {
        char *res = .db_full_version(family, release, major, minor, patch);
        return to!string(res);
    }

    static string db_full_version(out int family, out int release, out int major, out int minor, out int patch)
    {
        char *res = .db_full_version(&family, &release, &major, &minor, &patch);
        return to!string(res);
    }

    string get_home()
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
        const (char) *res;
        auto ret = dbenv.get_home(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return to!string(res);
    }

    uint32_t get_open_flags()
    {
		if (opened <= 0) {
			throw new DbWrongUsingException("Operation on closed or not opened DbEnv");
		}
        uint32_t res;
        auto ret = dbenv.get_open_flags(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void log_verify(ref const DbLogVerifyConfig config)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
        auto ret = dbenv.log_verify(dbenv, &config);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void lsn_reset(string file, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
        auto ret = dbenv.lsn_reset(dbenv, file.toStringz(), flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void remove(string db_home, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbEnv");
		}
		if (opened > 0) {
			throw new DbWrongUsingException("Removing opened DbEnv");
		}
        auto ret = dbenv.remove(dbenv, db_home.toStringz(), flags);
        opened = -1;
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void stat_print(uint32_t flags = 0)
    {
		if (opened <= 0) {
			throw new DbWrongUsingException("Operation on closed or not opened DbEnv");
		}
        auto ret = dbenv.stat_print(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    static string db_version(int *major, int *minor, int *patch)
    {
        char *res = .db_version(major, minor, patch);
        return to!string(res);
    }

    static string db_version(out int major, out int minor, out int patch)
    {
        char *res = .db_version(&major, &minor, &patch);
        return to!string(res);
    }

    /* Environment Configuration */

    void add_data_dir(string dir)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Configuration on closed DbEnv");
		}
		if (opened > 0) {
			throw new DbWrongUsingException("Configuration of opened DbEnv");
		}
        auto ret = dbenv.add_data_dir(dbenv, dir.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    extern (C) void set_alloc(void *function(size_t) app_malloc,
        void *function(void *, size_t) app_realloc, 
        void function(void *) app_free)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }
        auto ret = dbenv.set_alloc(dbenv, app_malloc, app_realloc, app_free);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    private
    {
        int function(DbEnv dbenv, Dbt *log_rec, DbLsn *lsn, db_recops op)
            tx_recover_callback_refer;

        extern (C) static int tx_recover_callback(DB_ENV *_dbenv,
                DBT *_log_rec, DB_LSN *lsn, db_recops op)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            Dbt *log_rec = cast(Dbt *) _log_rec;
            return dbenv.tx_recover_callback_refer(dbenv, log_rec, lsn, op);
        }
    }

    void set_app_dispatch(int function(DbEnv dbenv,
            Dbt *log_rec, DbLsn *lsn, db_recops op) tx_recover)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }
        tx_recover_callback_refer = tx_recover;
        auto ret = dbenv.set_app_dispatch(dbenv, tx_recover?&tx_recover_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    private
    {
        int function(DbEnv, string dbname, string target, void **handle) open_callback_refer;

        extern (C) static int open_callback(DB_ENV *_dbenv, const (char) *_dbname, 
                const (char) *_target, void **handle)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            string dbname = to!string(_dbname);
            string target = to!string(_target);
            return dbenv.open_callback_refer(dbenv, dbname, target, handle);
        }

        int function(DbEnv, uint64_t offset, uint32_t size, 
                uint8_t *buf, void *handle) write_callback_refer;

        extern (C) static int write_callback(
                DB_ENV *_dbenv, uint32_t offset_gbytes, 
                uint32_t offset_bytes, uint32_t size, 
                uint8_t *buf, void *handle)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            return dbenv.write_callback_refer(dbenv, 
                    (1024UL*1024*1024)*offset_gbytes + offset_bytes, 
                    size, buf, handle);
        }

        int function(DbEnv, string dbname, void *handle) close_callback_refer;

        extern (C) static int close_callback(DB_ENV *_dbenv, const (char) *_dbname, void *handle)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            string dbname = to!string(_dbname);
            return dbenv.close_callback_refer(dbenv, dbname, handle);
        }
    }

    void set_backup_callbacks(int function(DbEnv, string dbname, 
            string target, void **handle) open_func,
        int function(DbEnv, uint64_t offset, uint32_t size, 
            uint8_t *buf, void *handle) write_func,
        int function(DbEnv, string dbname, void *handle) close_func)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        open_callback_refer = open_func;
        write_callback_refer = write_func;
        close_callback_refer = close_func;
        auto ret = dbenv.set_backup_callbacks(dbenv, 
                open_func?&open_callback:null, 
                write_func?&write_callback:null, 
                close_func?&close_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    /*FIXME: What we must return when callback references is null??? O_o*/
    void get_backup_callbacks(ref int function(DbEnv, string dbname, 
            string target, void **handle) open_func,
        ref int function(DbEnv, uint64_t offset, uint32_t size, 
            uint8_t *buf, void *handle) write_func,
        ref int function(DbEnv, string dbname, void *handle) close_func)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        open_func = open_callback_refer;
        write_func = write_callback_refer;
        close_func = close_callback_refer;
    }

    void set_backup_config(DbBackupConfig option, uint32_t value)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }

        auto ret = dbenv.set_backup_config(dbenv, option, value);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_backup_config(DbBackupConfig option)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }

        uint32_t res;
        auto ret = dbenv.get_backup_config(dbenv, option, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_data_dir(string dir)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }

        auto ret = dbenv.set_data_dir(dbenv, dir.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    string[] get_data_dirs(const (char) ***dirpp)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }

        const(char) **_res;
        auto ret = dbenv.get_data_dirs(dbenv, &_res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        string[] res = [];
        for (const(char) **p=_res; *p; p++)
            res ~= to!string(*p);

        return res;
    }

    void set_create_dir(string dir)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }

        auto ret = dbenv.set_create_dir(dbenv, dir.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    string get_create_dir()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }

        const (char) *_res;
        auto ret = dbenv.get_create_dir(dbenv, &_res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return to!string(_res);
    }

    void set_encrypt(string passwd, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }

        auto ret = dbenv.set_encrypt(dbenv, passwd.toStringz(), flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_encrypt_flags()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_encrypt_flags(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    private
    {
        void function(DbEnv dbenv, uint32_t event, void *event_info) db_event_callback_refer;

        extern (C) static void db_event_callback(DB_ENV *_dbenv, uint32_t event, void *event_info)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            dbenv.db_event_callback_refer(dbenv, event, event_info);
        }
    }

    void set_event_notify(void function(DbEnv dbenv, uint32_t event, 
                void *event_info) db_event_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        db_event_callback_refer = db_event_fcn;
        auto ret = dbenv.set_event_notify(dbenv, db_event_fcn?&db_event_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    private
    {
        void function (const DbEnv dbenv, string errpfx, string msg) db_err_callback_refer;

        extern (C) static void db_err_callback (const (DB_ENV) *_dbenv, const (char) *_errpfx, const (char) *_msg)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            string errpfx = to!string(_errpfx);
            string msg = to!string(_msg);
            dbenv.db_err_callback_refer(dbenv, errpfx, msg);
        }
    }

    void set_errcall(void function (const DbEnv dbenv, string errpfx, string msg) db_errcall_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        db_err_callback_refer = db_errcall_fcn;
        dbenv.set_errcall(dbenv, db_errcall_fcn?&db_err_callback:null);
    }

    private File _errfile;

    void set_errfile(File errfile)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        _errfile = errfile;
        dbenv.set_errfile(dbenv, errfile.getFP());
    }

    File get_errfile()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        return _errfile;
    }

    void set_errpfx(string errpfx)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        dbenv.set_errpfx(dbenv, errpfx.toStringz());
    }

    string get_errpfx()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        const (char) *res;
        dbenv.get_errpfx(dbenv, &res);
        return to!string(res);
    }

    private
    {
        void function(DbEnv dbenv, int opcode, int percent) db_feedback_callback_refer;

        extern (C) static void db_feedback_callback(DB_ENV *_dbenv, int opcode, int percent)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            dbenv.db_feedback_callback_refer(dbenv, opcode, percent);
        }
    }
    
    void set_feedback(void function(DbEnv dbenv, int opcode, int percent) db_feedback_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        db_feedback_callback_refer = db_feedback_fcn;
        auto ret = dbenv.set_feedback(dbenv, db_feedback_fcn?&db_feedback_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void set_flags(uint32_t flags, int onoff)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        auto ret = dbenv.set_flags(dbenv, flags, onoff);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_flags()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_flags(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_intermediate_dir_mode(string mode)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }

        auto ret = dbenv.set_intermediate_dir_mode(dbenv, mode.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    string get_intermediate_dir_mode()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        const (char) *res;
        auto ret = dbenv.get_intermediate_dir_mode(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return to!string(res);
    }

    private
    {
        int function(DbEnv dbenv, 
                pid_t pid, db_threadid_t tid, uint32_t flags = 0) is_alive_callback_refer;

        extern (C) static int is_alive_callback(DB_ENV *_dbenv, 
                pid_t pid, db_threadid_t tid, uint32_t flags = 0)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            return dbenv.is_alive_callback_refer(dbenv, pid, tid, flags);
        }
    }

    void set_isalive(int function(DbEnv dbenv, 
                pid_t pid, db_threadid_t tid, uint32_t flags = 0) is_alive)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        is_alive_callback_refer = is_alive;
        auto ret = dbenv.set_isalive(dbenv, is_alive?&is_alive_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void set_memory_init(DbMemConfig type, uint32_t count)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }

        auto ret = dbenv.set_memory_init(dbenv, type, count);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_memory_init(DbMemConfig type)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_memory_init(dbenv, type, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_memory_max(uint32_t gbytes, uint32_t bytes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }

        auto ret = dbenv.set_memory_max(dbenv, gbytes, bytes);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void set_memory_max(uint64_t bytes)
    {
        uint32_t _gbytes = cast(uint32_t) bytes/(1024*1024*1024);
        uint32_t _bytes = bytes%(1024*1024*1024);
        set_memory_max(_gbytes, _bytes);
    }

    void get_memory_max(ref uint32_t gbytes, ref uint32_t bytes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        auto ret = dbenv.get_memory_max(dbenv, &gbytes, &bytes);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint64_t get_memory_max()
    {
        uint32_t gbytes;
        uint32_t bytes;
        get_memory_max(gbytes, bytes);
        return (1024UL*1024*1024)*gbytes + bytes;
    }

    void set_metadata_dir(string dir)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }

        auto ret = dbenv.set_metadata_dir(dbenv, dir.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    string get_metadata_dir()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        const (char) *res;
        auto ret = dbenv.get_metadata_dir(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return to!string(res);
    }

    private
    {
        void function(const DbEnv dbenv, string msg) db_msg_callback_refer;

        extern (C) static void db_msg_callback(const (DB_ENV) *_dbenv, const (char) *_msg)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            string msg = to!string(_msg);
            return dbenv.db_msg_callback_refer(dbenv, msg);
        }
    }

    void set_msgcall(void function(const DbEnv dbenv, string msg) db_msgcall_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        db_msg_callback_refer = db_msgcall_fcn;
        dbenv.set_msgcall(dbenv, db_msgcall_fcn?&db_msg_callback:null);
    }

    private File _msgfile;

    void set_msgfile(File msgfile)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        _msgfile = msgfile;
        dbenv.set_msgfile(dbenv, msgfile.getFP());
    }

    File get_msgfile()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        return _msgfile;
    }

    void set_shm_key(c_long shm_key)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }

        auto ret = dbenv.set_shm_key(dbenv, shm_key);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    c_long get_shm_key()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        c_long res;
        auto ret = dbenv.get_shm_key(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_thread_count(uint32_t count)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened DbEnv");
        }

        auto ret = dbenv.set_thread_count(dbenv, count);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_thread_count()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_thread_count(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    private
    {
        void function(DbEnv dbenv, pid_t *pid, db_threadid_t *tid) thread_id_callback_refer;

        extern (C) static void thread_id_callback(DB_ENV *_dbenv, pid_t *pid, db_threadid_t *tid)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            return dbenv.thread_id_callback_refer(dbenv, pid, tid);
        }
    }

    void set_thread_id(void function(DbEnv dbenv, pid_t *pid, db_threadid_t *tid) thread_id)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        thread_id_callback_refer = thread_id;
        auto ret = dbenv.set_thread_id(dbenv, thread_id?&thread_id_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    private
    {
        char *function(DbEnv dbenv,
                pid_t pid, db_threadid_t tid, char *buf) thread_id_string_callback_refer;

        extern (C) static char *thread_id_string_callback(DB_ENV *_dbenv,
                pid_t pid, db_threadid_t tid, char *buf)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            return dbenv.thread_id_string_callback_refer(dbenv, pid, tid, buf);
        }
    }

    void set_thread_id_string(char *function(DbEnv dbenv,
                pid_t pid, db_threadid_t tid, char *buf) thread_id_string)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        thread_id_string_callback_refer = thread_id_string;
        auto ret = dbenv.set_thread_id_string(dbenv, thread_id_string?&thread_id_string_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void set_timeout(db_timeout_t timeout, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        auto ret = dbenv.set_timeout(dbenv, timeout, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    db_timeout_t get_timeout(uint32_t flag)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        db_timeout_t res;
        auto ret = dbenv.get_timeout(dbenv, &res, flag);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_tmp_dir(string dir)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        auto ret = dbenv.set_tmp_dir(dbenv, dir.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    string get_tmp_dir()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        const (char) *res;
        auto ret = dbenv.get_tmp_dir(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return to!string(res);
    }

    void set_verbose(uint32_t which, int onoff)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        auto ret = dbenv.set_verbose(dbenv, which, onoff);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    int get_verbose(uint32_t which)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        int res;
        auto ret = dbenv.get_verbose(dbenv, which, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_cachesize(uint32_t gbytes, uint32_t bytes, int ncache)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        auto ret = dbenv.set_cachesize(dbenv, gbytes, bytes, ncache);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void set_cachesize(uint64_t bytes, int ncache)
    {
        uint32_t _gbytes = cast(uint32_t) bytes/(1024*1024*1024);
        uint32_t _bytes = bytes%(1024*1024*1024);
        set_cachesize(_gbytes, _bytes, ncache);
    }

    void get_cachesize(ref uint32_t gbytes, ref uint32_t bytes, ref int ncache)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed DbEnv");
        }
        auto ret = dbenv.get_cachesize(dbenv, &gbytes, &bytes, &ncache);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint64_t get_memory_max(ref int ncache)
    {
        uint32_t gbytes;
        uint32_t bytes;
        get_cachesize(gbytes, bytes, ncache);
        return (1024UL*1024*1024)*gbytes + bytes;
    }

    void get_memory_max(ref uint64_t _bytes, ref int ncache)
    {
        uint32_t gbytes;
        uint32_t bytes;
        get_cachesize(gbytes, bytes, ncache);
        _bytes = (1024UL*1024*1024)*gbytes + bytes;
    }

    /* Locking Subsystem and Related Methods */
    void lock_detect(uint32_t flags, uint32_t atype, int *rejected)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock operation on closed DbEnv");
        }
        auto ret = dbenv.lock_detect(dbenv, flags, atype, rejected);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void lock_get(uint32_t locker, uint32_t flags, Dbt *object,
        db_lockmode_t lock_mode, DbLock *lock)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock operation on closed DbEnv");
        }
        auto ret = dbenv.lock_get(dbenv, locker, flags, &object.dbt,
                lock_mode, lock);
        DbRetCodeToException(ret, this, object, DB_LOCK_GET, lock_mode, lock, -1);
        assert(ret == 0);
    }

    DbLock lock_get(uint32_t locker, uint32_t flags, Dbt *object,
        db_lockmode_t lock_mode)
    {
        DbLock res;
        lock_get(locker, flags, object, lock_mode, &res);
        return res;
    }

    uint32_t lock_id()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock operation on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.lock_id(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void lock_id_free(uint32_t id)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock operation on closed DbEnv");
        }
        auto ret = dbenv.lock_id_free(dbenv, id);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }
    
    void lock_put(ref DbLock lock)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock operation on closed DbEnv");
        }
        auto ret = dbenv.lock_put(dbenv, &lock);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    DbLockStat *lock_stat(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Lock operation on closed or not opened DbEnv");
        }
        DbLockStat *res;
        auto ret = dbenv.lock_stat(dbenv, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void lock_stat_print(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Lock operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.lock_stat_print(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void lock_vec(uint32_t locker, uint32_t flags, DbLockreq[] list)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock operation on closed DbEnv");
        }
        DbLockreq *elist;
        auto ret = dbenv.lock_vec(dbenv, locker, flags, list.ptr, cast(uint)list.length, &elist);
        if (ret && elist) DbRetCodeToException(ret, this, 
                cast(Dbt*)elist.obj, elist.op, elist.mode, &elist.lock, cast(int)(elist-list.ptr));
        else DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    DbTxn cdsgroup_begin()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock operation on closed DbEnv");
        }
        DB_TXN *_tid;
        auto ret = dbenv.cdsgroup_begin(dbenv, &_tid);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return new DbTxn(_tid, this);
    }

    /* Locking Subsystem Configuration */

    void set_lk_conflicts(uint8_t[] conflicts, int nmodes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Lock configuration of opened DbEnv");
        }
        if (conflicts.length != nmodes*nmodes)
        {
            throw new DbWrongUsingException("conflicts must have nmodes x nmodes size");
        }
        auto ret = dbenv.set_lk_conflicts(dbenv, conflicts.ptr, nmodes);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void get_lk_conflicts(ref const (uint8_t)[] lk_conflicts, ref int lk_modes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        const(uint8_t) *conflicts;
        auto ret = dbenv.get_lk_conflicts(dbenv, &conflicts, &lk_modes);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        lk_conflicts = conflicts[0..lk_modes*lk_modes];
    }

    void set_lk_detect(uint32_t detect)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        auto ret = dbenv.set_lk_detect(dbenv, detect);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lk_detect()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lk_detect(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lk_max_lockers(uint32_t max)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Lock configuration of opened DbEnv");
        }
        auto ret = dbenv.set_lk_max_lockers(dbenv, max);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lk_max_lockers()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lk_max_lockers(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lk_max_locks(uint32_t max)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Lock configuration of opened DbEnv");
        }
        auto ret = dbenv.set_lk_max_locks(dbenv, max);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lk_max_locks()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lk_max_locks(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lk_max_objects(uint32_t max)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Lock configuration of opened DbEnv");
        }
        auto ret = dbenv.set_lk_max_objects(dbenv, max);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lk_max_objects()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lk_max_objects(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lk_partitions(uint32_t partitions)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Lock configuration of opened DbEnv");
        }
        auto ret = dbenv.set_lk_partitions(dbenv, partitions);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lk_partitions()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lk_partitions(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lk_priority(uint32_t lockerid, uint32_t priority)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        auto ret = dbenv.set_lk_priority(dbenv, lockerid, priority);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lk_priority(uint32_t lockerid)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lk_priority(dbenv, lockerid, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lk_tablesize(uint32_t tablesize)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Lock configuration of opened DbEnv");
        }
        auto ret = dbenv.set_lk_tablesize(dbenv, tablesize);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lk_tablesize()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Lock configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lk_tablesize(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    /* Logging Subsystem and Related Methods */
    string[] log_archive(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log operation on closed DbEnv");
        }
        string[] list;
        char **_list;
        auto ret = dbenv.log_archive(dbenv, &_list, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);

        if (!_list)
        {
            list = null;
        }
        else
        {
            list = [];
            char **ptr;
            for (ptr = _list; *ptr; ptr++)
            {
                list ~= to!string(*ptr);
            }
        }
        return list;
    }

    string log_file(const (DbLsn) *lsn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log operation on closed DbEnv");
        }
        /* According documentation "Log filenames are always 14 characters long" */
        char[16] name;
        auto ret = dbenv.log_file(dbenv, lsn, name.ptr, name.length);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return to!string(name.ptr);
    }

    void log_flush(const (DbLsn) *lsn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log operation on closed DbEnv");
        }
        auto ret = dbenv.log_flush(dbenv, lsn);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void log_printf(T...)(DbTxn *txnid, string fmt, T args)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log operation on closed DbEnv");
        }
        auto app = appender!string();
        formattedWrite(app, fmt, args);
        auto ret = dbenv.log_printf(dbenv, txnid?txnid._DB_TXN:null, "%s".toStringz(), app.data.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void log_put(DbLsn *lsn, const (Dbt) *data, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log operation on closed DbEnv");
        }
        auto ret = dbenv.log_put(dbenv, lsn, &data.dbt, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    DbLogStat *log_stat(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log operation on closed DbEnv");
        }
        DbLogStat *res;
        auto ret = dbenv.log_stat(dbenv, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void log_stat_print(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log operation on closed DbEnv");
        }
        auto ret = dbenv.log_stat_print(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    /* Logging Subsystem Cursors */
    DbLogc log_cursor(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log operation on closed DbEnv");
        }
        DB_LOGC *res;
        auto ret = dbenv.log_cursor(dbenv, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return new DbLogc(res, this);
    }

    /* Logging Subsystem Configuration */
    void log_set_config(uint32_t flags, int onoff)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        auto ret = dbenv.log_set_config(dbenv, flags, onoff);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    int log_get_config(uint32_t which)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        int res;
        auto ret = dbenv.log_get_config(dbenv, which, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lg_bsize(uint32_t lg_bsize)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Log configuration of opened DbEnv");
        }
        auto ret = dbenv.set_lg_bsize(dbenv, lg_bsize);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lg_bsize()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lg_bsize(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lg_dir(string dir)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Log configuration of opened DbEnv");
        }
        auto ret = dbenv.set_lg_dir(dbenv, dir.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    string get_lg_dir()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        const (char) *res;
        auto ret = dbenv.get_lg_dir(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return to!string(res);
    }

    void set_lg_filemode(int lg_filemode)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        auto ret = dbenv.set_lg_filemode(dbenv, lg_filemode);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    int get_lg_filemode()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        int res;
        auto ret = dbenv.get_lg_filemode(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lg_max(uint32_t lg_max)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        auto ret = dbenv.set_lg_max(dbenv, lg_max);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lg_max()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lg_max(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_lg_regionmax(uint32_t lg_regionmax)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Log configuration of opened DbEnv");
        }
        auto ret = dbenv.set_lg_regionmax(dbenv, lg_regionmax);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_lg_regionmax()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Log configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_lg_regionmax(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    /* Memory Pools and Related Methods */
    void memp_stat(ref DbMpoolStat *gs, ref DbMpoolFstat*[] fs, uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Memory pool operation on closed or not opened DbEnv");
        }
        DbMpoolFstat **fsp;
        auto ret = dbenv.memp_stat(dbenv, &gs, &fsp, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);

        if (fsp == null) fs = null;
        else
        {
            DbMpoolFstat **ptr;
            for (ptr = fsp; *ptr; ptr++)
                fs ~= *ptr;
        }
    }

    void memp_stat_print(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Memory pool operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.memp_stat_print(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void memp_sync(DbLsn *lsn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory pool operation on closed DbEnv");
        }
        auto ret = dbenv.memp_sync(dbenv, lsn);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    int memp_trickle(int percent)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory pool operation on closed DbEnv");
        }
        int nwrote;
        auto ret = dbenv.memp_trickle(dbenv, percent, &nwrote);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return nwrote;
    }

    /* Memory Pool Configuration */
    private
    {
        int function(DbEnv env, db_pgno_t pgno, void *pgaddr, 
                Dbt *pgcookie) pgin_callback_refer;

        extern (C) static int pgin_callback(DB_ENV *_env, db_pgno_t pgno, void *pgaddr, 
                DBT *_pgcookie)
        {
            DbEnv dbenv = from_DB_ENV(_env);
            Dbt *pgcookie = cast(Dbt*)_pgcookie;
            return dbenv.pgin_callback_refer(dbenv, pgno, pgaddr, pgcookie);
        }

        int function(DbEnv env, db_pgno_t pgno, 
                void *pgaddr, Dbt *pgcookie) pgout_callback_refer;

        extern (C) static int pgout_callback(DB_ENV *_env, db_pgno_t pgno, 
                void *pgaddr, DBT *_pgcookie)
        {
            DbEnv dbenv = from_DB_ENV(_env);
            Dbt *pgcookie = cast(Dbt*)_pgcookie;
            return dbenv.pgout_callback_refer(dbenv, pgno, pgaddr, pgcookie);
        }
    }
    
    void memp_register(int ftype,
        int function(DbEnv env, db_pgno_t pgno, void *pgaddr, 
        Dbt *pgcookie) pgin_fcn, int function(DbEnv env, db_pgno_t pgno, 
        void *pgaddr, Dbt *pgcookie) pgout_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        pgin_callback_refer = pgin_fcn;
        pgout_callback_refer = pgout_fcn;
        auto ret = dbenv.memp_register(dbenv, ftype, 
                pgin_fcn?&pgin_callback:null,
                pgout_fcn?&pgout_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void set_cache_max(uint32_t gbytes, uint32_t bytes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Memory Pool configuration of opened DbEnv");
        }
        auto ret = dbenv.set_cache_max(dbenv, gbytes, bytes);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void set_cache_max(uint64_t bytes)
    {
        uint32_t _gbytes = cast(uint32_t) bytes/(1024*1024*1024);
        uint32_t _bytes = bytes%(1024*1024*1024);
        set_cache_max(_gbytes, _bytes);
    }

    void get_cache_max(ref uint32_t gbytes, uint32_t bytes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        auto ret = dbenv.get_cache_max(dbenv, &gbytes, &bytes);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint64_t get_cache_max()
    {
        uint32_t gbytes;
        uint32_t bytes;
        get_cache_max(gbytes, bytes);
        return (1024UL*1024*1024)*gbytes + bytes;
    }

    void set_mp_max_openfd(int maxopenfd)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        auto ret = dbenv.set_mp_max_openfd(dbenv, maxopenfd);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    int get_mp_max_openfd()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        int res;
        auto ret = dbenv.get_mp_max_openfd(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_mp_max_write(int maxwrite, db_timeout_t maxwrite_sleep)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        auto ret = dbenv.set_mp_max_write(dbenv, maxwrite, maxwrite_sleep);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void get_mp_max_write(ref int maxwrite, 
                         ref db_timeout_t maxwrite_sleep)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        auto ret = dbenv.get_mp_max_write(dbenv, &maxwrite, &maxwrite_sleep);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void set_mp_mmapsize(size_t mp_mmapsize)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        auto ret = dbenv.set_mp_mmapsize(dbenv, mp_mmapsize);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    size_t get_mp_mmapsize(DB_ENV *dbenv)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        size_t res;
        auto ret = dbenv.get_mp_mmapsize(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_mp_mtxcount(uint32_t mtxcount)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Memory Pool configuration of opened DbEnv");
        }
        auto ret = dbenv.set_mp_mtxcount(dbenv, mtxcount);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_mp_mtxcount()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_mp_mtxcount(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_mp_pagesize(uint32_t pagesize)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Memory Pool configuration of opened DbEnv");
        }
        auto ret = dbenv.set_mp_pagesize(dbenv, pagesize);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_mp_pagesize()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_mp_pagesize(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_mp_tablesize(uint32_t tablesize)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Memory Pool configuration of opened DbEnv");
        }
        auto ret = dbenv.set_mp_tablesize(dbenv, tablesize);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_mp_tablesize()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_mp_tablesize(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    /* Memory Pool Files */
    DbMpoolfile memp_fcreate(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Memory Pool operation on closed DbEnv");
        }
        DB_MPOOLFILE *dbmf;
        auto ret = dbenv.memp_fcreate(dbenv, &dbmf, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return new DbMpoolfile(dbmf, this);
    }

    /* Transaction Subsystem and Related Methods */
    c_long txn_recover(DB_PREPLIST[] preplist, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        c_long res;
        auto ret = dbenv.txn_recover(dbenv, preplist.ptr, cast(int)preplist.count, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void txn_checkpoint(uint32_t kbyte, uint32_t min, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        auto ret = dbenv.txn_checkpoint(dbenv, kbyte, min, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    DbTxnStat *txn_stat(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Transaction configuration on closed or not opened DbEnv");
        }
        DbTxnStat *res;
        auto ret = dbenv.txn_stat(dbenv, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void txn_stat_print(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Transaction configuration on closed or not opened DbEnv");
        }
        auto ret = dbenv.txn_stat_print(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    /* Transaction Subsystem Configuration */
    void set_tx_max(uint32_t max)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Transaction configuration of opened DbEnv");
        }
        auto ret = dbenv.set_tx_max(dbenv, max);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_tx_max()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_tx_max(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void set_tx_timestamp(ref bdb_time_t timestamp)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Transaction configuration of opened DbEnv");
        }
        auto ret = dbenv.set_tx_timestamp(dbenv, &timestamp);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    bdb_time_t get_tx_timestamp()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        bdb_time_t res;
        auto ret = dbenv.get_tx_timestamp(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    /* Transaction Operations */
    DbTxn txn_begin(DbTxn parent, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        DB_TXN *res;
        auto ret = dbenv.txn_begin(dbenv, parent?parent._DB_TXN:null, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return new DbTxn(res, this);
    }
    
    /* BLOB Configuration */
version(VERSION_6)
{
    void set_blob_dir(string dir)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("BLOB configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("BLOB configuration of opened DbEnv");
        }
        auto ret = dbenv.set_blob_dir(dbenv, dir.toStringz());
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    string get_blob_dir()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("BLOB configuration on closed DbEnv");
        }
        const (char) *res;
        auto ret = dbenv.get_blob_dir(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return to!string(res);
    }

    void set_blob_threshold(uint32_t bytes, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        auto ret = dbenv.set_blob_threshold(dbenv, bytes, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t get_blob_threshold()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Transaction configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.get_blob_threshold(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }
}
    /* Mutex Methods */
    void mutex_alloc(uint32_t flags, ref db_mutex_t mutex)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Mutex operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.mutex_alloc(dbenv, flags, &mutex);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void mutex_free(db_mutex_t mutex)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Mutex operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.mutex_free(dbenv, mutex);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void mutex_lock(db_mutex_t mutex)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Mutex operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.mutex_lock(dbenv, mutex);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    DbMutexStat *mutex_stat(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Mutex operation on closed or not opened DbEnv");
        }
        DbMutexStat *res;
        auto ret = dbenv.mutex_stat(dbenv, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void mutex_stat_print(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Mutex operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.mutex_stat_print(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void mutex_unlock(db_mutex_t mutex)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Mutex operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.mutex_unlock(dbenv, mutex);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    /* Mutex Configuration */
    void mutex_set_align(uint32_t alignment)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Mutex configuration on opened DbEnv");
        }
        auto ret = dbenv.mutex_set_align(dbenv, alignment);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t mutex_get_align()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.mutex_get_align(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void mutex_set_increment(uint32_t increment)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Mutex configuration on opened DbEnv");
        }
        auto ret = dbenv.mutex_set_increment(dbenv, increment);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t mutex_get_increment()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.mutex_get_increment(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void mutex_set_init(uint32_t init)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Mutex configuration on opened DbEnv");
        }
        auto ret = dbenv.mutex_set_init(dbenv, init);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t mutex_get_init()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.mutex_get_init(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void mutex_set_max(uint32_t max)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Mutex configuration on opened DbEnv");
        }
        auto ret = dbenv.mutex_set_max(dbenv, max);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t mutex_get_max()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.mutex_get_max(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void mutex_set_tas_spins(uint32_t tas_spins)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        auto ret = dbenv.mutex_set_tas_spins(dbenv, tas_spins);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t mutex_get_tas_spins()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Mutex configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.mutex_get_tas_spins(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    /* Replication and Related Methods */
    DbChannel repmgr_channel(int eid, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication operation on closed DbEnv");
        }
        if (repmgr_started <= 0) {
            throw new DbWrongUsingException("Replication operation before repmgr_start() on DbEnv");
        }
        DB_CHANNEL *res;
        auto ret = dbenv.repmgr_channel(dbenv, eid, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return new DbChannel(res, this);
    }

    /* This version throws DB_NOTFOUND as exception */
    DbSite repmgr_local_site()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication operation on closed DbEnv");
        }
        DB_SITE *res;
        auto ret = dbenv.repmgr_local_site(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return new DbSite(res, this);
    }

    int repmgr_local_site(ref DbSite dbsite)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication operation on closed DbEnv");
        }
        DB_SITE *res;
        auto ret = dbenv.repmgr_local_site(dbenv, &res);
        dbsite = new DbSite(res, this);
        return DbRetCodeToException!"repmgr_localsite"(ret, this);
    }

    private
    {
        void function (DbEnv env, DbChannel channel, 
                Dbt[] request, uint32_t cb_flags) msg_dispatch_callback_refer;

        extern (C) static void msg_dispatch_callback (DB_ENV *_env, DB_CHANNEL *_channel, 
                DBT *_request, uint32_t nrequest,
                uint32_t cb_flags)
        {
            DbEnv env = from_DB_ENV(_env);
            DbChannel channel = DbChannel.from_DB_CHANNEL(_channel);
            Dbt[] request = (cast(Dbt *)_request)[0..nrequest];
            return env.msg_dispatch_callback_refer(env, channel, request, cb_flags);
        }
    }

    void repmgr_msg_dispatch(void function (DbEnv env, DbChannel channel, 
                Dbt[] request, uint32_t cb_flags) msg_dispatch_fcn, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        if (repmgr_started > 0) {
            throw new DbWrongUsingException("Replication configuration after repmgr_start() on DbEnv");
        }
        msg_dispatch_callback_refer = msg_dispatch_fcn;
        auto ret = dbenv.repmgr_msg_dispatch(dbenv, msg_dispatch_fcn?&msg_dispatch_callback:null, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void repmgr_set_ack_policy(int ack_policy)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.repmgr_set_ack_policy(dbenv, ack_policy);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    int repmgr_get_ack_policy()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        int res;
        auto ret = dbenv.repmgr_get_ack_policy(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    DbSite repmgr_site(string host, uint port, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication operation on closed DbEnv");
        }
        DB_SITE *res;
        auto ret = dbenv.repmgr_site(dbenv, host.toStringz(), port, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return new DbSite(res, this);
    }

    DbSite repmgr_site_by_eid(int eid)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication operation on closed DbEnv");
        }
        DB_SITE *res;
        auto ret = dbenv.repmgr_site_by_eid(dbenv, eid, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return new DbSite(res, this);
    }

    DbRepmgrSite[] repmgr_site_list()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        if (repmgr_started <= 0) {
            throw new DbWrongUsingException("Replication configuration before repmgr_start() on DbEnv");
        }
        DbRepmgrSite *list;
        uint count;
        auto ret = dbenv.repmgr_site_list(dbenv, &count, &list);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return list[0..count];
    }

    int repmgr_start(int nthreads, uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.repmgr_start(dbenv, nthreads, flags);
        int res = DbRetCodeToException!"repmgr_start"(ret, this);
        if (res == 0) repmgr_started = 1;
        return res;
    }

    DbRepmgrStat *repmgr_stat(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication configuration on closed or not opened DbEnv");
        }
        DbRepmgrStat *res;
        auto ret = dbenv.repmgr_stat(dbenv, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void repmgr_stat_print(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication configuration on closed or not opened DbEnv");
        }
        auto ret = dbenv.repmgr_stat_print(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    /* Base Replication API Methods */
    void rep_elect(uint32_t nsites, uint32_t nvotes, uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication operation on closed or not opened DbEnv");
        }
        if (rep_transport <= 0) {
            throw new DbWrongUsingException("Replication operation before rep_set_transport() on DbEnv");
        }
        if (rep_started <= 0) {
            throw new DbWrongUsingException("Replication operation before rep_start() on DbEnv");
        }
        auto ret = dbenv.rep_elect(dbenv, nsites, nvotes, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    int rep_process_message(Dbt *control, Dbt *rec, int envid, DbLsn *ret_lsn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication operation on closed DbEnv");
        }
        if (rep_transport <= 0) {
            throw new DbWrongUsingException("Replication operation before rep_set_transport() on DbEnv");
        }
        auto ret = dbenv.rep_process_message(dbenv, 
                &control.dbt, &rec.dbt, envid, ret_lsn);
        return DbRetCodeToException!"rep_process_message"(ret, this);
    }

    private
    {
        int function(DbEnv dbenv,
                const (Dbt) *control, const (Dbt) *rec, const (DbLsn) *lsnp,
                int envid, uint32_t flags = 0) send_callback_refer;

        extern (C) static int send_callback(DB_ENV *_dbenv,
                const (DBT) *_control, const (DBT) *_rec, const (DB_LSN) *lsnp,
                int envid, uint32_t flags = 0)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            const (Dbt) *control = cast(const (Dbt)*) _control;
            const (Dbt) *rec = cast(const (Dbt)*) _rec;
            return dbenv.send_callback_refer(dbenv, control, rec, lsnp,
                    envid, flags);
        }
    }

    void rep_set_transport(int envid,
            int function(DbEnv dbenv,
                const (Dbt) *control, const (Dbt) *rec, const (DbLsn) *lsnp,
                int envid, uint32_t flags = 0) send)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication operation on closed DbEnv");
        }
        send_callback_refer = send;
        auto ret = dbenv.rep_set_transport(dbenv, envid, send?&send_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        rep_transport = 1;
    }

    void rep_start(Dbt *cdata, uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication operation on closed or not opened DbEnv");
        }
        if (rep_transport <= 0) {
            throw new DbWrongUsingException("Replication operation before rep_set_transport() on DbEnv");
        }
        auto ret = dbenv.rep_start(dbenv, &cdata.dbt, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        rep_started = 1;
    }

    /* Additional Replication Methods */
    DbRepStat *rep_stat(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication operation on closed or not opened DbEnv");
        }
        DbRepStat *res;
        auto ret = dbenv.rep_stat(dbenv, &res, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void rep_stat_print(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication operation on closed or not opened DbEnv");
        }
        auto ret = dbenv.rep_stat_print(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void rep_sync(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication operation on closed or not opened DbEnv");
        }
        if (rep_transport <= 0) {
            throw new DbWrongUsingException("Replication operation before rep_set_transport() on DbEnv");
        }
        auto ret = dbenv.rep_sync(dbenv, flags);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    /* Replication Configuration */
    void rep_set_clockskew(uint32_t fast_clock, uint32_t slow_clock)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        if (rep_started > 0 || repmgr_started > 0) {
            throw new DbWrongUsingException("Replication operation after rep_start()/repmgr_start() on DbEnv");
        }
        auto ret = dbenv.rep_set_clockskew(dbenv, fast_clock, slow_clock);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }
    
    void rep_get_clockskew(ref uint32_t fast_clock, ref uint32_t slow_clock)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.rep_get_clockskew(dbenv, &fast_clock, &slow_clock);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void rep_set_config(uint32_t which, int onoff)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.rep_set_config(dbenv, which, onoff);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    int rep_get_config(uint32_t which)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        int res;
        auto ret = dbenv.rep_get_config(dbenv, which, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void rep_set_limit(uint32_t gbytes, uint32_t bytes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.rep_set_limit(dbenv, gbytes, bytes);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void rep_set_limit(uint64_t bytes)
    {
        uint32_t _gbytes = cast(uint32_t) bytes/(1024*1024*1024);
        uint32_t _bytes = bytes%(1024*1024*1024);
        rep_set_limit(_gbytes, _bytes);
    }

    int rep_get_limit(ref uint32_t gbytes, ref uint32_t bytes)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        int res;
        auto ret = dbenv.rep_get_limit(dbenv, &gbytes, &bytes);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    uint64_t rep_get_limit()
    {
        uint32_t gbytes;
        uint32_t bytes;
        rep_get_limit(gbytes, bytes);
        return (1024UL*1024*1024)*gbytes + bytes;
    }

    void rep_set_nsites(uint32_t nsites)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.rep_set_nsites(dbenv, nsites);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t rep_get_nsites()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.rep_get_nsites(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    void rep_set_priority(uint32_t priority)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.rep_set_priority(dbenv, priority);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t rep_get_priority()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.rep_get_priority(dbenv, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    } 

    void rep_set_request(uint32_t min, uint32_t max)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.rep_set_request(dbenv, min, max);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void rep_get_request(ref uint32_t min, ref uint32_t max)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.rep_get_request(dbenv, &min, &max);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    void rep_set_timeout(int which, uint32_t timeout)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        auto ret = dbenv.rep_set_timeout(dbenv, which, timeout);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }

    uint32_t rep_get_timeout(int which)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Replication configuration on closed DbEnv");
        }
        uint32_t res;
        auto ret = dbenv.rep_get_timeout(dbenv, which, &res);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
        return res;
    }

    private
    {
        int function(DbEnv dbenv, string name, 
                ref int result, uint32_t flags = 0) partial_callback_refer;

        extern (C) static int partial_callback(DB_ENV *_dbenv,
                const (char) *_name, int *result, uint32_t flags = 0)
        {
            DbEnv dbenv = from_DB_ENV(_dbenv);
            string name = to!string(_name);
            return dbenv.partial_callback_refer(dbenv, name, *result, flags);
        }
    }

version(VERSION_6)
{
    void rep_set_view(int function(DbEnv dbenv,
                string name, ref int result, uint32_t flags = 0) partial_func)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration on opened DbEnv");
        }
        partial_callback_refer = partial_func;
        auto ret = dbenv.rep_set_view(dbenv, partial_func?&partial_callback:null);
        DbRetCodeToException(ret, this);
        assert(ret == 0);
    }
}

    /* Transaction Operations */
    int txn_applied(DbTxnToken *token, db_timeout_t timeout, uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Replication configuration on closed or not opened DbEnv");
        }
        auto ret = dbenv.txn_applied(dbenv, token, timeout, flags);
        return DbRetCodeToException!"txn_applied"(ret, this);
    }
}

/* This function used as is from berkeleydb.c module:
   int log_compare(const (DbLsn) *lsn0, const (DbLsn) *lsn1); */
