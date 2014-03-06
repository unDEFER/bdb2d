module berkeleydb.dbstream;

import berkeleydb.c;
import berkeleydb.dbexception;
import berkeleydb.dbenv;
import berkeleydb.dbt;
import std.stdint;
import std.string;
import std.conv;

class DbStream
{
private:
	DB_STREAM *dbstream = null;
    DbEnv dbenv;
    int opened;

package:
    @property DB_STREAM *_DB_STREAM() {return dbstream;}

	this(DB_STREAM *dbstream, DbEnv dbenv)
	{
        this.dbstream = dbstream;
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
			throw new DbWrongUsingException("Closing closed DbStream");
		}
		auto ret = dbstream.close(dbstream, flags);
        opened = -1;
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
	}
    
    void read(Dbt *data, db_off_t offset, 
                uint32_t size, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbStream");
		}
		auto ret = dbstream.read(dbstream, &data.dbt, offset, size, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }

    db_off_t size(uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbStream");
		}
        db_off_t res;
		auto ret = dbstream.size(dbstream, &res, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
        return res;
    }
    
    void write(Dbt *data, db_off_t offset, uint32_t flags = 0)
    {
		if (opened < 0) {
			throw new DbWrongUsingException("Operation on closed DbStream");
		}
		auto ret = dbstream.write(dbstream, &data.dbt, offset, flags);
		DbRetCodeToException(ret, dbenv);
        assert(ret == 0);
    }
}
