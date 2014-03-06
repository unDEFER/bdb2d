module berkeleydb.dbchannel;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.dbenv;
import berkeleydb.dbt;
import std.stdint;
import std.string;
import std.conv;

class DbChannel
{
private:
	DB_CHANNEL *dbchannel = null;
    DbEnv dbenv;
    int opened;
    static DbChannel[DB_CHANNEL *] dbchannel_map;

package:
    static DbChannel from_DB_CHANNEL(const DB_CHANNEL *_dbchannel)
    {
        return dbchannel_map[_dbchannel];
    }

    @property DB_CHANNEL *_DB_CHANNEL() {return dbchannel;}

	this(DB_CHANNEL *dbchannel, DbEnv dbenv)
	{
        this.dbchannel = dbchannel;
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
			throw new DbWrongUsingException("Closing closed DbChannel");
		}
		auto ret = dbchannel.close(dbchannel, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}
    
    void send_msg(Dbt *msg, uint32_t nmsg, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbChannel");
		}
		auto ret = dbchannel.send_msg(dbchannel, &msg.dbt, nmsg, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void send_request(Dbt[] request, Dbt *response,
                     db_timeout_t timeout, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbChannel");
		}
		auto ret = dbchannel.send_request(dbchannel, 
                cast(DBT*)request.ptr, request.length,
                &response.dbt, timeout, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    void set_timeout(db_timeout_t timeout)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbChannel");
		}
		auto ret = dbchannel.set_timeout(dbchannel, timeout);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }
}
