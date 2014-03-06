module berkeleydb.dbexception;

import berkeleydb.c;
import berkeleydb.dbenv;
import berkeleydb.dbt;
import std.conv;

/* 
 * This method fully coming from macroses DB_RETOK_*
 * from db/src/dbinc/db_int.in
 */
package auto DbRetCodeToException(string Func)(int ret, DbEnv dbenv = null, Dbt *dbt = null,
        db_lockop_t op = 0, db_lockmode_t mode = 0, const (DB_LOCK) *lock = null, int index = 0)
{
	switch(ret)
	{
		case 0:

		static if(Func == "std")
		{
			return;
		}	
		else static if(Func == "Dbc.del" 
				|| Func == "Db.del")
		{
		case DB_KEYEMPTY:
		case DB_NOTFOUND:
			return ret;
		}
		else static if(Func == "Dbc.get" 
				|| Func == "Db.get" 
				|| Func == "exists")
		{
		case DB_KEYEMPTY:
		case DB_NOTFOUND:
			return ret;
		}
		else static if(Func == "Dbc.put")
		{
		case DB_KEYEXIST:
		case DB_NOTFOUND:
			return ret;
		}
		else static if(Func == "Db.put")
		{
		case DB_KEYEXIST:
			return ret;
		}
		else static if(Func == "DbLogc.get")
		{
		case DB_NOTFOUND:
			return ret;
		}
		else static if(Func == "DbMpoolfile.get")
		{
		case DB_PAGE_NOTFOUND:
			return ret;
		}
		else static if(Func == "rep_process_message")
		{
		case DB_REP_IGNORE:
		case DB_REP_ISPERM:
		case DB_REP_NEWMASTER:
		case DB_REP_NEWSITE:
		case DB_REP_NOTPERM:
		case DB_REP_WOULDROLLBACK:
			return ret;
		}
		else static if(Func == "repmgr_localsite")
		{
		case DB_NOTFOUND:
			return ret;
		}
		else static if(Func == "repmgr_start")
		{
		case DB_REP_IGNORE:
			return ret;
		}
		else static if(Func == "txn_applied")
		{
		case DB_NOTFOUND:
		case DB_TIMEOUT:
		case DB_KEYEMPTY:
			return ret;
		}
		else
		{
			static assert(0, "Bad func name for DbRetCodeToException");
		}

        case DB_LOCK_DEADLOCK:
            throw new DbDeadlockException("BerkeleyDB error", ret, dbenv);

        case DB_LOCK_NOTGRANTED:
            throw new DbLockNotGrantedException("BerkeleyDB error", ret, dbenv,
                    op, mode, dbt, lock, index);

        case DB_REP_HANDLE_DEAD:
            throw new DbRepHandleDeadException("BerkeleyDB error", ret, dbenv);

        case DB_RUNRECOVERY:
            throw new DbRunRecoveryException("BerkeleyDB error", ret, dbenv);

		static if(Func == "Dbc.get" 
				|| Func == "Db.get" 
				|| Func == "DbLogc.get")
		{
        case DB_BUFFER_SMALL:
            if (dbt is null)
            {
                throw new DbException("BerkeleyDB error", ret, dbenv);
            }
            else if (dbt.flags & DB_DBT_USERMEM && dbt.size > dbt.ulen)
            {
                throw new DbMemoryException("BerkeleyDB error", ret, dbenv, dbt);
            }
            else
            {
                return ret;
            }
        }

		default:
			throw new DbException("BerkeleyDB error", ret, dbenv);
	}
}

package auto DbRetCodeToException()(int ret, DbEnv dbenv = null, Dbt *dbt = null,
        db_lockop_t op = 0, db_lockmode_t mode = 0, const (DB_LOCK) *lock = null, int index = 0)
{
	DbRetCodeToException!"std"(ret, dbenv, dbt, op, mode, lock, index);
}

class DbException : Exception
{
	int dberrno;
	DbEnv dbenv;

	package this(string msg_prefix, int errno, DbEnv env, string file = __FILE__, size_t line = __LINE__)
	{
		dberrno = errno;
		dbenv = env;

		char *strerror = db_strerror(dberrno);
		super(msg_prefix~": "~to!string(strerror), file, line);
	}
}

class DbWrongUsingException : Exception
{
	package this(string msg, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg, file, line);
	}
}


class DbDeadlockException : DbException
{
	package this(string msg_prefix, int errno, DbEnv env, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg_prefix, errno, env, file, line);
	}
}

class DbLockNotGrantedException : DbException
{
    db_lockop_t op;
    db_lockmode_t mode;
    const (Dbt) *obj;
    const (DB_LOCK) *lock;
    int index;
	package this(string msg_prefix, int errno, DbEnv env, 
            db_lockop_t _op, db_lockmode_t _mode, const (Dbt) *_obj, const (DB_LOCK) *_lock, int _index,
            string file = __FILE__, size_t line = __LINE__)
	{
        op = _op;
        mode = _mode;
        obj = _obj;
        lock = _lock;
        index = _index;
		super(msg_prefix, errno, env, file, line);
	}
}

class DbMemoryException : DbException
{
	Dbt *dbt;
	package this(string msg_prefix, int errno, DbEnv env, Dbt *t, string file = __FILE__, size_t line = __LINE__)
	{
		dbt = t;
		super(msg_prefix, errno, env, file, line);
	}
}

class DbRepHandleDeadException : DbException
{
	package this(string msg_prefix, int errno, DbEnv env, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg_prefix, errno, env, file, line);
	}
}

class DbRunRecoveryException : DbException
{
	package this(string msg_prefix, int errno, DbEnv env, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg_prefix, errno, env, file, line);
	}
}

