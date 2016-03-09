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

module berkeleydb.dblogverifyconfig;

import berkeleydb.c;

import std.stdint;
import std.string;
import core.sys.posix.pthread;

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
