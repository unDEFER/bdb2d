module berkeleydb.db;

import berkeleydb.c;
import berkeleydb.dbenv;
import berkeleydb.dbexception;
import berkeleydb.dbtxn;
import berkeleydb.dbt;
import berkeleydb.dbc;
import berkeleydb.dbmpoolfile;

import std.stdint;
import std.stdio;
import std.string;
import std.array;
import std.format;
import std.conv;

alias DB_COMPACT DbCompact;
alias DB_KEY_RANGE DbKeyRange;
alias DB_CACHE_PRIORITY DbCachePriority;

class Db
{
private:
	DB *db = null;
	DbEnv dbenv = null;
    int opened = 0;
    static Db[DB *] db_map;

    static Db from_DB(const DB *_db)
    {
        return db_map[_db];
    }

package:
    @property DB *_DB() {return db;}
    @property DbEnv _dbenv() {return dbenv;}
    @property int _opened() {return opened;}

public:
    DbEnv get_env()
    {
        return dbenv;
    }

    this(DbEnv dbenv, uint32_t flags = 0)
	{
		auto ret = db_create(&db, dbenv?dbenv._DB_ENV:null, flags);
		DbRetCodeToException(ret, dbenv);
        db_map[db] = this;
        this.dbenv = dbenv;
        assert(ret == 0);
	}

    ~this()
	{
		if (opened >= 0) close();
        db_map.remove(db);
	}

    static ~this()
	{
        db_map = null;
    }

    void open(DbTxn txnid, string file,
                string database, DBTYPE type, uint32_t flags, int mode)
    {
		if (opened > 0) {
			throw new DbWrongUsingException("Opening opened Db");
		}
		if (opened < 0) {
			throw new DbWrongUsingException("Opening closed Db");
		}
		auto ret = db.open(db, txnid?txnid._DB_TXN:null, file.toStringz(), database.toStringz(), 
                type, flags, mode);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        opened++;
    }

	void close(uint32_t flags = 0)
	{
		if (opened < 0) {
			throw new DbWrongUsingException("Closing closed Db");
		}
		auto ret = db.close(db, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}

    void remove(string file, string database, uint32_t flags = 0)
    {
		if (opened > 0) {
			throw new DbWrongUsingException("Removing opened Db");
		}
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed Db");
		}
		auto ret = db.remove(db, file.toStringz(), database.toStringz(), flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void rename(string file, string database, string newname, uint32_t flags = 0)
    {
		if (opened > 0) {
			throw new DbWrongUsingException("Renaming opened Db");
		}
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed Db");
		}
		auto ret = db.rename(db, file.toStringz(), database.toStringz(), newname.toStringz(), flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void verify(string file, string database, File outfile, uint32_t flags = 0)
    {
		if (opened > 0) {
			throw new DbWrongUsingException("Verifying opened Db");
		}
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed Db");
		}
		auto ret = db.verify(db, file.toStringz(), database.toStringz(), outfile.getFP(), flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    private
    {
        int function(Db secondary, ref const (Dbt) key, 
                ref const (Dbt) data, out Dbt result) associate_callback_refer;

        extern (C) static int associate_callback(DB *_secondary, 
                const (DBT) *_key, const (DBT) *_data, DBT *_result)
        {
            Db secondary = from_DB(_secondary);
            const (Dbt) *key = cast(const (Dbt) *) _key;
            const (Dbt) *data = cast(const (Dbt) *) _data;
            Dbt *result = cast(Dbt *) _result;
            return secondary.associate_callback_refer(secondary, *key, *data, *result);
        }
    }

    void associate(DbTxn txnid, Db secondary,
                int function(Db secondary,
                    ref const (Dbt) key, ref const (Dbt) data, out Dbt result) callback, 
                uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        secondary.associate_callback_refer = callback;
        auto ret = db.associate(db, txnid?txnid._DB_TXN:null, secondary._DB, 
                callback?&associate_callback:null, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    private
    {
            int function (Db secondary,
                ref const (Dbt) key, out Dbt data, ref const (Dbt) foreignkey, 
                out int changed) associate_foreign_callback_refer;

            extern (C) static int associate_foreign_callback(DB *_secondary,
                const (DBT) *_key, DBT *_data, const (DBT) *_foreignkey, int *changed)
            {
                Db secondary = from_DB(_secondary);
                const (Dbt) *key = cast(const (Dbt) *) _key;
                Dbt *data = cast(Dbt *) _data;
                const (Dbt) *foreignkey = cast(const (Dbt) *) _foreignkey;
                return secondary.associate_foreign_callback_refer(secondary, *key, *data, *foreignkey, *changed);
            }
    }

    void associate_foreign(Db secondary, int function(Db secondary,
                ref const (Dbt) key, out Dbt data, ref const (Dbt) foreignkey, out int changed) callback, 
            uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        secondary.associate_foreign_callback_refer = callback;
        auto ret = db.associate_foreign(db, secondary._DB, 
                callback?&associate_foreign_callback:null, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void compact(DbTxn txnid,
            Dbt *start, Dbt *stop, DbCompact *c_data, uint32_t flags, Dbt *end)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.compact(db, txnid?txnid._DB_TXN:null, &start.dbt, &stop.dbt,
                c_data, flags, &end.dbt);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    int del(DbTxn txnid, Dbt *key, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.del(db, txnid?txnid._DB_TXN:null, &key.dbt, flags);
        return DbRetCodeToException!"Db.del"(ret, dbenv);
    }

    int get(DbTxn txnid, Dbt *key, Dbt *data, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.get(db, txnid?txnid._DB_TXN:null, &key.dbt, &data.dbt, flags);
        DbRetCodeToException!"Db.get"(ret, dbenv, data);
        return DbRetCodeToException!"Db.get"(ret, dbenv);
    }

    int pget(DbTxn txnid, Dbt *key, Dbt *pkey, Dbt *data, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.pget(db, txnid?txnid._DB_TXN:null, &key.dbt, &pkey.dbt, &data.dbt, flags);
        DbRetCodeToException!"Db.get"(ret, dbenv, data);
        return DbRetCodeToException!"Db.get"(ret, dbenv);
    }

    int put(DbTxn txnid, Dbt *key, Dbt *data, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.put(db, txnid?txnid._DB_TXN:null, &key.dbt, &data.dbt, flags);
        return DbRetCodeToException!"Db.put"(ret, dbenv);
    }

    void err(T...)(int error, string fmt, T args)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed Db");
		}
        auto app = appender!string();
        formattedWrite(app, fmt, args);
        db.err(db, error, "%s".toStringz(), app.data.toStringz());
    }

    void errx(T...)(string fmt, T args)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed Db");
		}
        auto app = appender!string();
        formattedWrite(app, fmt, args);
        db.errx(db, "%s".toStringz(), app.data.toStringz());
    }

    int exists(DbTxn txnid, Dbt *key, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.exists(db, txnid?txnid._DB_TXN:null, &key.dbt, flags);
        return DbRetCodeToException!"exists"(ret, dbenv);
    }

    int fd()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        int res;
        auto ret = db.fd(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    int get_byteswapped()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Operation on closed or not opened Db");
        }
        int res;
        auto ret = db.fd(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void get_dbname(ref string filename, ref string dbname)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        const (char) *_filename;
        const (char) *_dbname;
        auto ret = db.get_dbname(db, &_filename, &_dbname);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        filename = to!string(_filename);
        dbname = to!string(_dbname);
    }

    int get_multiple()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Operation on closed or not opened Db");
        }
        return db.get_multiple(db);
    }

    uint32_t get_open_flags()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Operation on closed or not opened Db");
        }
        uint32_t res;
        auto ret = db.get_open_flags(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    DBTYPE get_type()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Operation on closed or not opened Db");
        }
        DBTYPE res;
        auto ret = db.get_type(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    Dbc join(Dbc[] curslist, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }

        // convert Dbc[] to null-terminated array of DBC*
        DBC*[] _curslist = new DBC*[curslist.length + 1];
        foreach(int i, Dbc c; curslist[])
            _curslist[i] = c._DBC;

        DBC *res;
        auto ret = db.join(db, _curslist.ptr, &res, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return new Dbc(res, true, dbenv);
    }

    DbKeyRange key_range(DbTxn txnid, Dbt *key, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        DbKeyRange res;
        auto ret = db.key_range(db, txnid?txnid._DB_TXN:null, &key.dbt, &res, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_priority(DbCachePriority priority)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.set_priority(db, priority);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    DbCachePriority get_priority()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        DbCachePriority res;
        auto ret = db.get_priority(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void stat(DbTxn txnid, void *sp, uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Operation on closed or not opened Db");
        }
        auto ret = db.stat(db, txnid?txnid._DB_TXN:null, sp, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void stat_print(uint32_t flags = 0)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Operation on closed or not opened Db");
        }
        auto ret = db.stat_print(db, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void sync(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.sync(db, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t truncate(DbTxn txnid, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        uint32_t count;
        auto ret = db.truncate(db, txnid?txnid._DB_TXN:null, &count, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return count;
    }

    void upgrade(string file, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        auto ret = db.upgrade(db, file.toStringz(), flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    Dbc cursor(DbTxn txnid, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }

        DBC *res;
        auto ret = db.cursor(db, txnid?txnid._DB_TXN:null, &res, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return new Dbc(res, false, dbenv);
    }

    /* Database Configuration */

    private
    {
        uint32_t function (Db db, Dbt *key) db_partition_callback_refer;

        extern (C) static uint32_t db_partition_callback(DB *_db, DBT *_key)
        {
                Db db = from_DB(_db);
                Dbt *key = cast(Dbt *) _key;
                return db.db_partition_callback_refer(db, key);
        }
    }

    void set_partition(uint32_t parts,  Dbt[] keys,
                uint32_t function (Db db, Dbt *key) db_partition_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if ( (parts-1) != keys.length  )
        {
            throw new DbWrongUsingException("Length of keys must be one less than parts");
        }
        db_partition_callback_refer = db_partition_fcn;
        auto ret = db.set_partition(db, parts, cast(DBT*)keys.ptr, 
                db_partition_fcn?&db_partition_callback:null);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    /*FIXME: What we must return when callback reference is null??? O_o*/
    void get_partition_callback(ref uint32_t parts,
            ref uint32_t function (Db dbp, Dbt *key) callback_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }

        callback_fcn = db_partition_callback_refer;

        extern (C) uint32_t function(DB *_db, DBT *_key) n;
        auto ret = db.get_partition_callback(db, &parts, &n);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void get_partition_keys(ref uint32_t parts, ref Dbt[] keys)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }

        DBT *_keys;
        auto ret = db.get_partition_keys(db, &parts, &_keys);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);

        /*"parts-1" - is not error, it is really length of keys array according
          BerkeleyDb documentation */
        keys = (cast(Dbt*)_keys)[0..parts-1];
    }

    Dbt[] get_partition_keys()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }

        uint32_t parts;
        DBT *_keys;
        auto ret = db.get_partition_keys(db, &parts, &_keys);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);

        /*"parts-1" - is not error, it is really length of keys array according
          BerkeleyDb documentation */
        return (cast(Dbt*)_keys)[0..parts-1];
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
        auto ret = db.set_alloc(db, app_malloc, app_realloc, app_free);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_cachesize(uint32_t gbytes, uint32_t bytes, int ncache)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }

        auto ret = db.set_cachesize(db, gbytes, bytes, ncache);
        DbRetCodeToException(ret, dbenv);
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
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        auto ret = db.get_cachesize(db, &gbytes, &bytes, &ncache);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void get_cachesize(ref uint64_t bytes, ref int ncache)
    {
        uint32_t _gbytes;
        uint32_t _bytes;
        get_cachesize(_gbytes, _bytes, ncache);
        bytes = (1024UL*1024*1024)*_gbytes + _bytes;
    }

    uint64_t get_cachesize(ref int ncache)
    {
        uint64_t bytes;
        get_cachesize(bytes, ncache);
        return bytes;
    }

    void set_create_dir(string dir)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }

        auto ret = db.set_create_dir(db, dir.toStringz());
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    string get_create_dir()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        const (char) *res;
        auto ret = db.get_create_dir(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return to!string(res);
    }

    private
    {
        int function(Db db,
                const (Dbt) *dbt1, const (Dbt) *dbt2, size_t *locp) dup_compare_callback_refer;

        extern (C) static int dup_compare_callback(DB *_db,
                const (DBT) *_dbt1, const (DBT) *_dbt2, size_t *locp)
        {
                Db db = from_DB(_db);
                const (Dbt) *dbt1 = cast(const (Dbt) *) _dbt1;
                const (Dbt) *dbt2 = cast(const (Dbt) *) _dbt2;
                return db.dup_compare_callback_refer(db, dbt1, dbt2, locp);
        }
    }

    void set_dup_compare(int function(Db db,
                const (Dbt) *dbt1, const (Dbt) *dbt2, size_t *locp) dup_compare_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        dup_compare_callback_refer = dup_compare_fcn;
        auto ret = db.set_dup_compare(db, 
                dup_compare_fcn?&dup_compare_callback:null);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_encrypt(string passwd, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_encrypt(db, passwd.toStringz(), flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_encrypt_flags()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        uint32_t res;
        auto ret = db.get_encrypt_flags(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    private File _errfile;

    void set_errfile(File errfile)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (dbenv) dbenv.set_errfile(errfile);
        else
        {
            _errfile = errfile;
            db.set_errfile(db, errfile.getFP());
        }
    }

    File get_errfile()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        if (dbenv) return dbenv.get_errfile();
        else return _errfile;
    }

    void set_errpfx(string errpfx)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        db.set_errpfx(db, errpfx.toStringz());
    }

    string get_errpfx()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        const (char) *res;
        db.get_errpfx(db, &res);
        return to!string(res);
    }

    private
    {
        void function(Db db, int opcode, int percent) db_feedback_callback_refer;

        extern (C) static void db_feedback_callback(DB *dbp, int opcode, int percent)
        {
                Db db = from_DB(dbp);
                return db.db_feedback_callback_refer(db, opcode, percent);
        }
    }

    void set_feedback(void function(Db db, int opcode, int percent) db_feedback_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        db_feedback_callback_refer = db_feedback_fcn;
        auto ret = db.set_feedback(db, db_feedback_fcn?&db_feedback_callback:null);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_flags(uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_flags(db, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_flags()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        uint32_t res;
        auto ret = db.get_flags(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_lk_exclusive(int nowait_onoff)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_lk_exclusive(db, nowait_onoff);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void get_lk_exclusive(ref int onoff, ref int nowait)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        auto ret = db.get_lk_exclusive(db, &onoff, &nowait);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_lorder(int lorder)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_lorder(db, lorder);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    int get_lorder()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        int res;
        auto ret = db.get_lorder(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_msgcall(void function(const DbEnv dbenv, string msg) db_msgcall_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        if (dbenv) dbenv.set_msgcall(db_msgcall_fcn);
        else assert(0, "Use extern(C) version of set_msgcall()");
    }

    extern (C) void set_msgcall(void function(const (DB_ENV) *dbenv, const (char) *msg) db_msgcall_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed DbEnv");
        }
        db.set_msgcall(db, db_msgcall_fcn);
    }

    private File _msgfile;

    void set_msgfile(File msgfile)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (dbenv) dbenv.set_msgfile(msgfile);
        else
        {
            _msgfile = msgfile;
            db.set_msgfile(db, msgfile.getFP());
        }
    }

    File get_msgfile()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        if (dbenv) return dbenv.get_msgfile();
        return _msgfile;
    }

    void set_pagesize(uint32_t pagesize)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_pagesize(db, pagesize);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_pagesize()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Get configuration on closed or not opened Db");
        }
        uint32_t res;
        auto ret = db.get_pagesize(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_partition_dirs(string[] dirs)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }

        const (char) *[]_dirs = new const (char) *[dirs.length+1];
        foreach(int i, string dir; dirs)
            _dirs[i] = dirs[i].toStringz();

        auto ret = db.set_partition_dirs(db, _dirs.ptr);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    string[] get_partition_dirs()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        const (char) **_res;
        auto ret = db.get_partition_dirs(db, &_res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);

        string[] res = [];
        for (const (char) **_r = _res; *_r; _r++)
            res ~= to!string(*_r);

        return res;
    }

    /* Btree/Recno Configuration */

    private
    {
        int function(Db db, Dbt *data, db_recno_t recno) db_append_recno_callback_refer;
        
        extern (C) static int db_append_recno_callback(DB *_db, DBT *_data, db_recno_t recno)
        {
                Db db = from_DB(_db);
                Dbt *data = cast(Dbt *) _data;
                return db.db_append_recno_callback_refer(db, data, recno);
        }
    }

    void set_append_recno(int function(Db db, Dbt *data, db_recno_t recno) db_append_recno_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        db_append_recno_callback_refer = db_append_recno_fcn;
        auto ret = db.set_append_recno(db, db_append_recno_fcn?&db_append_recno_callback:null);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    private
    {
        int function(Db db, const (Dbt) *dbt1, const (Dbt) *dbt2, size_t *locp) bt_compare_callback_refer;

        extern (C) static int bt_compare_callback(DB *_db, const (DBT) *_dbt1, const (DBT) *_dbt2, size_t *locp)
        {
                Db db = from_DB(_db);
                const (Dbt) *dbt1 = cast(const (Dbt) *) _dbt1;
                const (Dbt) *dbt2 = cast(const (Dbt) *) _dbt2;
                return db.bt_compare_callback_refer(db, dbt1, dbt2, locp);
        }
    }

    void set_bt_compare(int function(Db db,
                const (Dbt) *dbt1, const (Dbt) *dbt2, size_t *locp) bt_compare_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        bt_compare_callback_refer = bt_compare_fcn;
        auto ret = db.set_bt_compare(db, bt_compare_fcn?&bt_compare_callback:null);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    private
    {
        int function(Db db, const (Dbt) *prevKey, 
                const (Dbt) *prevData, const (Dbt) *key, const (Dbt) *data, 
                Dbt *dest) bt_compress_callback_refer;

        extern (C) static int bt_compress_callback(DB *_db, const (DBT) *_prevKey, 
                const (DBT) *_prevData, const (DBT) *_key, const (DBT) *_data, DBT *_dest)
        {
                Db db = from_DB(_db);
                const (Dbt) *prevKey = cast(const (Dbt) *) _prevKey;
                const (Dbt) *prevData = cast(const (Dbt) *) _prevData;
                const (Dbt) *key = cast(const (Dbt) *) _key;
                const (Dbt) *data = cast(const (Dbt) *) _data;
                Dbt *dest = cast(Dbt *) _dest;
                return db.bt_compress_callback_refer(db, prevKey, prevData, key, data, dest);
        }

        int function(Db db, const (Dbt) *prevKey, 
            const (Dbt) *prevData, Dbt *compressed, Dbt *destKey, 
            Dbt *destData) bt_decompress_callback_refer;

        extern (C) static int bt_decompress_callback(DB *_db, const (DBT) *_prevKey, 
            const (DBT) *_prevData, DBT *_compressed, DBT *_destKey, 
            DBT *_destData)
        {
                Db db = from_DB(_db);
                const (Dbt) *prevKey = cast(const (Dbt) *) _prevKey;
                const (Dbt) *prevData = cast(const (Dbt) *) _prevData;
                Dbt *compressed = cast(Dbt *) _compressed;
                Dbt *destKey = cast(Dbt *) _destKey;
                Dbt *destData = cast(Dbt *) _destData;
                return db.bt_decompress_callback_refer(db, prevKey, prevData, 
                        compressed, destKey, destData);
        }
    }

    void set_bt_compress(int function(Db db, const (Dbt) *prevKey, const (Dbt) *prevData, 
                const (Dbt) *key, const (Dbt) *data, Dbt *dest) bt_compress_fcn,
                int function(Db db, const (Dbt) *prevKey, 
                    const (Dbt) *prevData, Dbt *compressed, Dbt *destKey, 
                    Dbt *destData) bt_decompress_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        bt_compress_callback_refer = bt_compress_fcn;
        bt_decompress_callback_refer = bt_decompress_fcn;
        auto ret = db.set_bt_compress(db, 
                bt_compress_fcn?&bt_compress_callback:null,
                bt_decompress_fcn?&bt_decompress_callback:null);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_bt_minkey(uint32_t bt_minkey)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_bt_minkey(db, bt_minkey);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_bt_minkey()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        uint32_t res;
        auto ret = db.get_bt_minkey(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    private
    {
        size_t function(Db, const (Dbt) *dbt1, const (Dbt) *dbt2) bt_prefix_callback_refer;

        extern (C) static size_t bt_prefix_callback(DB *_db, const (DBT) *_dbt1, const (DBT) *_dbt2)
        {
                Db db = from_DB(_db);
                const (Dbt) *dbt1 = cast(const (Dbt) *) _dbt1;
                const (Dbt) *dbt2 = cast(const (Dbt) *) _dbt2;
                return db.bt_prefix_callback_refer(db, dbt1, dbt2);
        }
    }

    void set_bt_prefix(size_t function(Db, const (Dbt) *dbt1, const (Dbt) *dbt2) bt_prefix_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        bt_prefix_callback_refer = bt_prefix_fcn;
        auto ret = db.set_bt_prefix(db, &bt_prefix_callback);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_re_delim(int re_delim)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_re_delim(db, re_delim);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    int get_re_delim()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Get configuration on closed or not opened Db");
        }
        int res;
        auto ret = db.get_re_delim(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_re_len(uint32_t re_len)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_re_len(db, re_len);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_re_len()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Get configuration on closed or not opened Db");
        }
        uint32_t res;
        auto ret = db.get_re_len(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_re_pad(int re_pad)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_re_pad(db, re_pad);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    int get_re_pad()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Get configuration on closed or not opened Db");
        }
        int res;
        auto ret = db.get_re_pad(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    void set_re_source(string source)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_re_source(db, source.toStringz());
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    string get_re_source()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Get configuration on closed or not opened Db");
        }
        const (char) *res;
        auto ret = db.get_re_source(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return to!string(res);
    }

    /* Hash Configuration */
    private
    {
        int function(Db db, const (Dbt) *dbt1,
                const (Dbt) *dbt2, size_t *locp) compare_callback_refer;

        extern (C) static int compare_callback(DB *_db,
                const (DBT) *_dbt1, const (DBT) *_dbt2, size_t *locp)
        {
                Db db = from_DB(_db);
                const (Dbt) *dbt1 = cast(const (Dbt) *) _dbt1;
                const (Dbt) *dbt2 = cast(const (Dbt) *) _dbt2;
                return db.compare_callback_refer(db, dbt1, dbt2, locp);
        }
    }

    void set_h_compare(int function(Db db,
                const (Dbt) *dbt1, const (Dbt) *dbt2, size_t *locp) compare_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        compare_callback_refer = compare_fcn;
        auto ret = db.set_h_compare(db, compare_fcn?&compare_callback:null);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_h_ffactor(uint32_t h_ffactor)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_h_ffactor(db, h_ffactor);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_h_ffactor()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        uint32_t res;
        auto ret = db.get_h_ffactor(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    private
    {
        uint32_t function(Db dbp, const (ubyte)[] bytes) h_hash_callback_refer;

        extern (C) static uint32_t h_hash_callback(DB *_db, const (void) *_bytes, uint32_t length)
        {
                Db db = from_DB(_db);
                const (ubyte)[] bytes = (cast(ubyte*) _bytes)[0..length];
                return db.h_hash_callback_refer(db, bytes);
        }
    }

    void set_h_hash(uint32_t function(Db dbp, const (ubyte)[] bytes) h_hash_fcn)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        h_hash_callback_refer = h_hash_fcn;
        auto ret = db.set_h_hash(db, &h_hash_callback);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_h_nelem(uint32_t h_nelem)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_h_nelem(db, h_nelem);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_h_nelem(uint32_t *h_nelemp)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        uint32_t res;
        auto ret = db.get_h_nelem(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    /* Queue Configuration */
    void set_q_extentsize(uint32_t extentsize)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_q_extentsize(db, extentsize);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_q_extentsize()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Get configuration on closed or not opened Db");
        }
        uint32_t res;
        auto ret = db.get_q_extentsize(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    /* Heap */
    void set_heapsize(uint32_t gbytes, uint32_t bytes, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_heapsize(db, gbytes, bytes, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_heapsize(uint64_t bytes, uint32_t flags = 0)
    {
        uint32_t _gbytes = cast(uint32_t) bytes/(1024*1024*1024);
        uint32_t _bytes = bytes%(1024*1024*1024);
        set_heapsize(_gbytes, _bytes, flags);
    }

    void get_heapsize(ref uint32_t gbytes, ref uint32_t bytes)
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Get configuration on closed or not opened Db");
        }
        auto ret = db.get_heapsize(db, &gbytes, &bytes);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint64_t get_heapsize()
    {
        uint32_t _gbytes;
        uint32_t _bytes;
        get_heapsize(_gbytes, _bytes);
        return (1024UL*1024*1024)*_gbytes + _bytes;
    }

    void set_heap_regionsize(uint32_t npages)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_heap_regionsize(db, npages);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_heap_regionsize()
    {
        if (opened <= 0) {
            throw new DbWrongUsingException("Get configuration on closed or not opened Db");
        }
        uint32_t res;
        auto ret = db.get_heap_regionsize(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }

    /* Memory Pools and Related Methods */
    DbMpoolfile get_mpf()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        DB_MPOOLFILE *res = db.get_mpf(db);
        return new DbMpoolfile(res, dbenv);
    }

    /* Transaction Subsystem Configuration */
    int get_transactional()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Operation on closed Db");
        }
        return db.get_transactional(db);
    }

    /* BLOB Configuration */
    void set_blob_dir(string dir)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_blob_dir(db, dir.toStringz());
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    string get_blob_dir()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        const (char) *res;
        auto ret = db.get_blob_dir(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return to!string(res);
    }

    void set_blob_threshold(uint32_t bytes, uint32_t flags = 0)
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Configuration on closed Db");
        }
        if (opened > 0) {
            throw new DbWrongUsingException("Configuration of opened Db");
        }
        auto ret = db.set_blob_threshold(db, bytes, flags);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    uint32_t get_blob_threshold()
    {
        if (opened < 0) {
            throw new DbWrongUsingException("Get configuration on closed Db");
        }
        uint32_t res;
        auto ret = db.get_blob_threshold(db, &res);
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }
}

void db_copy(DbEnv dbenv, string dbfile, string target, 
        string password)
{
        if (dbenv._opened < 0) {
            throw new DbWrongUsingException("Operation on closed DbEnv");
        }
        auto ret = berkeleydb.c.db_copy(dbenv?dbenv._DB_ENV:null, dbfile.toStringz(), 
                target.toStringz(), password.toStringz());
        DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
}

unittest
{
    auto db = new Db(null, 0);
    db.set_partition_dirs(["a", "b", "d"]);
    assert(db.get_partition_dirs() == ["a", "b", "d"]);
}

unittest
{
    import std.file;

    try{
        rmdirRecurse("/tmp/berkeleydb.test");
    } catch (FileException file)
    {
    }

    try{
        mkdir("/tmp/berkeleydb.test");
    } catch (FileException file)
    {
    }
    
    struct customer {
           char cust_id[4];
           char last_name[15];
           char first_name[15];
    };
    struct order {
           char order_id[4];
           int order_number;
           char cust_id[4];
    };

    DbEnv dbenv = new DbEnv(0);

    uint32_t env_flags = DB_CREATE |    /* Create the environment if it does 
                                * not already exist. */
                DB_INIT_TXN  | /* Initialize transactions */
                DB_INIT_LOCK | /* Initialize locking. */
                DB_INIT_LOG  | /* Initialize logging */
                DB_INIT_MPOOL; /* Initialize the in-memory cache. */

    dbenv.open("/tmp/berkeleydb.test/", env_flags, octal!666);

    Db db = new Db(dbenv, 0);
    db.open(null, "orders.db", null, DB_BTREE, DB_CREATE, octal!600);

    Db sdb = new Db(dbenv, 0);
    sdb.set_flags(DB_DUP | DB_DUPSORT);

    sdb.open(null, "orders_cust_ids.db", null, DB_BTREE, DB_CREATE, octal!600);
    
    static int getcustid(Db secondary, ref const (Dbt) pkey, ref const (Dbt) pdata, out Dbt skey)
    {
           /*
            * Since the secondary key is a simple structure member of the
            * record, we don't have to do anything fancy to return it.  If
            * we have composite keys that need to be constructed from the
            * record, rather than simply pointing into it, then the user's
            * function might need to allocate space and copy data.  In
            * this case, the DB_DBT_APPMALLOC flag should be set in the
            * secondary key DBT.
            */
           order *o = pdata.to!(order *)();
           skey = o.cust_id;
           return 0;
    }

    db.associate(null, sdb, &getcustid, 0);

    Db fdb = new Db(dbenv, 0);
    fdb.open(null, "customers.db", null, DB_BTREE, DB_CREATE, octal!600);
    fdb.associate_foreign(sdb, null, DB_FOREIGN_CASCADE);

    string PadString(string str, int len)
    {
        while (str.length < len)
            str ~= '\0';
        return str;
    }

    Dbt key, data;
    customer cust;
    cust.cust_id = "0001";
    cust.last_name = PadString("Last", 15);
    cust.first_name = PadString("First", 15);
    key = cust.cust_id;
    data = cust;
    int res = fdb.put(null, &key, &data, 0);
    assert(res == 0);

    cust.cust_id = "0002";
    cust.last_name = PadString("Petrov", 15);
    cust.first_name = PadString("Ivan", 15);
    res = fdb.put(null, &key, &data, 0);
    assert(res == 0);

    cust.cust_id = "0003";
    cust.last_name = PadString("Smeyana", 15);
    cust.first_name = PadString("Lena", 15);
    res = fdb.put(null, &key, &data, 0);
    assert(res == 0);
    
    order ord;
    ord.order_id = "0001";
    ord.order_number = 1;
    ord.cust_id = "0001";
    key = ord.order_id;
    data = ord;
    res = db.put(null, &key, &data, 0);
    assert(res == 0);

    ord.order_id = "0002";
    ord.order_number = 2;
    ord.cust_id = "0001";
    res = db.put(null, &key, &data, 0);
    assert(res == 0);

    ord.order_id = "0003";
    ord.order_number = 3;
    ord.cust_id = "0002";
    res = db.put(null, &key, &data, 0);
    assert(res == 0);

    ord.order_id = "0004";
    ord.order_number = 4;
    ord.cust_id = "0005";
    int except = 0;
    try
    {
        res = db.put(null, &key, &data, 0);
        assert(res == 0);
    }
    catch (DbException exc)
    {
        assert(exc.dberrno == DB_FOREIGN_CONFLICT);
        except = 1;
    }
    assert(except == 1);

    Dbc cursor = fdb.cursor(null, 0);
    res = cursor.get(&key, &data, DB_NEXT);
    assert(res == 0);
    cust.cust_id = "0001";
    cust.last_name = PadString("Last", 15);
    cust.first_name = PadString("First", 15);
    char[4] cust_key = key.to!(char[])();
    customer *cust_p = data.to!(customer*)();
    assert(cust_key == cust.cust_id);
    assert(*cust_p == cust);

    res = cursor.get(&key, &data, DB_NEXT);
    assert(res == 0);
    cust.cust_id = "0002";
    cust.last_name = PadString("Petrov", 15);
    cust.first_name = PadString("Ivan", 15);
    cust_key = key.to!(char[])();
    cust_p = data.to!(customer*)();
    assert(cust_key == cust.cust_id);
    assert(*cust_p == cust);

    res = cursor.get(&key, &data, DB_NEXT);
    assert(res == 0);
    cust.cust_id = "0003";
    cust.last_name = PadString("Smeyana", 15);
    cust.first_name = PadString("Lena", 15);
    cust_key = key.to!(char[])();
    cust_p = data.to!(customer*)();
    assert(cust_key == cust.cust_id);
    assert(*cust_p == cust);

    res = cursor.get(&key, &data, DB_NEXT);
    assert(res == DB_NOTFOUND);

    cursor.close();
    fdb.close(0);
    sdb.close(0);
    db.close(0);

    dbenv.close(0);
}
