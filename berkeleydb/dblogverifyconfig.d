module berkeleydb.dblogverifyconfig;

import berkeleydb.c;

import std.stdint;
import std.string;
import std.c.linux.pthread;

alias DB_LOG_VERIFY_CONFIG DbLogVerifyConfig;

/* Functions to edit DB_LOG_VERIFY_CONFIG */
void set_continue_after_fail(ref DB_LOG_VERIFY_CONFIG config, int value)
{
    config.continue_after_fail = value;
}

void set_verbose(ref DB_LOG_VERIFY_CONFIG config, int value)
{
    config.verbose = value;
}

void set_cachesize(ref DB_LOG_VERIFY_CONFIG config, uint32_t value)
{
    config.cachesize = value;
}

void set_temp_envhome(ref DB_LOG_VERIFY_CONFIG config, string value)
{
    config.temp_envhome = value.toStringz();
}

void set_dbfile(ref DB_LOG_VERIFY_CONFIG config, string value)
{
    config.dbfile = value.toStringz();
}

void set_dbname(ref DB_LOG_VERIFY_CONFIG config, string value)
{
    config.dbname = value.toStringz();
}

void set_start_lsn(ref DB_LOG_VERIFY_CONFIG config, DB_LSN value)
{
    config.start_lsn = value;
}

void set_end_lsn(ref DB_LOG_VERIFY_CONFIG config, DB_LSN value)
{
    config.end_lsn = value;
}

void set_start_time(ref DB_LOG_VERIFY_CONFIG config, time_t value)
{
    config.start_time = value;
}

void set_end_time(ref DB_LOG_VERIFY_CONFIG config, time_t value)
{
    config.end_time = value;
}

unittest
{
    DB_LOG_VERIFY_CONFIG config;
    config.set_continue_after_fail(1);
}
