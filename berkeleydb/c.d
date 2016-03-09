/*
 * See the file LICENSE for redistribution information.
 *
 * Copyright (c) 1996, 2015 Oracle and/or its affiliates.  All rights reserved.
 *
 * $Id$
 *
 * db.h include file layout:
 *	General.
 *	Database Environment.
 *	Locking subsystem.
 *	Logging subsystem.
 *	Shared buffer cache (mpool) subsystem.
 *	Transaction subsystem.
 *	Access methods.
 *	Access method cursors.
 *	Dbm/Ndbm, Hsearch historic interfaces.
 */


module berkeleydb.c;

import core.stdc.inttypes;
import core.stdc.config;
import std.stdint;
import core.stdc.stddef;
import core.stdc.stdio;
import std.file;
import core.sys.posix.pthread;

extern (C) {


/*
 * Berkeley DB version information.
 */
const int DB_VERSION_FAMILY	= 11;
const int DB_VERSION_RELEASE	= 2;
const int DB_VERSION_MAJOR	= 5;
const int DB_VERSION_MINOR	= 1;
const int DB_VERSION_PATCH	= 25;
string DB_VERSION_STRING	= "5.1.25";
string DB_VERSION_FULL_STRING	= "";

/*
 * !!!
 * Berkeley DB uses specifically sized types.  If they're not provided by
 * the system, alias them here.
 *
 * We protect them against multiple inclusion using __BIT_TYPES_DEFINED__,
 * as does BIND and Kerberos, since we don't know for sure what #include
 * files the user is using.
 *
 * !!!
 * We also provide the standard uint, ulong etc., if they're not provided
 * by the system.
 */


/*
 * Missing ANSI types.
 *
 * uintmax_t --
 * Largest unsigned type, used to align structures in memory.  We don't store
 * floating point types in structures, so integral types should be sufficient
 * (and we don't have to worry about systems that store floats in other than
 * power-of-2 numbers of bytes).  Additionally this fixes compilers that rewrite
 * structure assignments and ANSI C memcpy calls to be in-line instructions
 * that happen to require alignment.
 *
 * uintptr_t --
 * Unsigned type that's the same size as a pointer.  There are places where
 * DB modifies pointers by discarding the bottom bits to guarantee alignment.
 * We can't use uintmax_t, it may be larger than the pointer, and compilers
 * get upset about that.  So far we haven't run on any machine where there's
 * no unsigned type the same size as a pointer -- here's hoping.
 */

alias int db_off_t;
version(HAVE_MIXED_SIZE_ADDRESSING)
{
alias uint32_t db_size_t;
}
else
{
alias size_t db_size_t;
}

version(HAVE_MIXED_SIZE_ADDRESSING)
{
alias int32_t db_ssize_t;
}
else
{
alias ssize_t db_ssize_t;
}


/*
 * Sequences are only available on machines with 64-bit integral types.
 */
alias int64_t db_seq_t;

/* Thread and process identification. */
alias pthread_t db_threadid_t;

/* Basic types that are exported or quasi-exported. */
alias	uint32_t	db_pgno_t;	/* Page number type. */
alias	uint16_t	db_indx_t;	/* Page offset type. */
enum	DB_MAX_PAGES	= 0xffffffff;	/* >= # of pages in a file */

alias	uint32_t	db_recno_t;	/* Record number type. */
enum	DB_MAX_RECORDS	= 0xffffffff;	/* >= # of records in a recno tree. */

alias uint32_t	db_timeout_t;	/* Type of a timeout in microseconds. */

/*
 * Region offsets are the difference between a pointer in a region and the
 * region's base address.  With private environments, both addresses are the
 * result of calling malloc, and we can't assume anything about what malloc
 * will return, so region offsets have to be able to hold differences between
 * arbitrary pointers.
 */
alias	db_size_t	roff_t;

/*
 * Forward structure declarations, so we can declare pointers and
 * applications can get type checking.
 */
struct __channel;	alias __channel CHANNEL;
alias __db DB;
alias __db_bt_stat DB_BTREE_STAT;
alias __db_channel DB_CHANNEL;
struct __db_cipher;	alias __db_cipher DB_CIPHER;
alias __db_compact DB_COMPACT;
alias __db_dbt DBT;
alias __db_distab DB_DISTAB;
alias __db_env DB_ENV;

	alias __db_event_mutex_died_info DB_EVENT_MUTEX_DIED_INFO;

	alias __db_event_failchk_info DB_EVENT_FAILCHK_INFO;
alias __db_h_stat DB_HASH_STAT;
alias __db_heap_rid DB_HEAP_RID;
alias __db_heap_stat DB_HEAP_STAT;
alias __db_ilock DB_LOCK_ILOCK;
alias __db_lock_hstat DB_LOCK_HSTAT;
alias __db_lock_pstat DB_LOCK_PSTAT;
alias __db_lock_stat DB_LOCK_STAT;
alias __db_lock_u DB_LOCK;
struct __db_locker;	alias __db_locker DB_LOCKER;
alias __db_lockreq DB_LOCKREQ;
struct __db_locktab;	alias __db_locktab DB_LOCKTAB;
struct __db_log;	alias __db_log DB_LOG;
alias __db_log_cursor DB_LOGC;
alias __db_log_stat DB_LOG_STAT;
alias __db_lsn DB_LSN;
struct __db_mpool;	alias __db_mpool DB_MPOOL;
alias __db_mpool_fstat DB_MPOOL_FSTAT;
alias __db_mpool_stat DB_MPOOL_STAT;
alias __db_mpoolfile DB_MPOOLFILE;
alias __db_mutex_stat DB_MUTEX_STAT;
struct __db_mutex_t;	alias __db_mutex_t DB_MUTEX;
struct __db_mutexmgr;	alias __db_mutexmgr DB_MUTEXMGR;
alias __db_preplist DB_PREPLIST;
alias __db_qam_stat DB_QUEUE_STAT;
struct __db_rep;	alias __db_rep DB_REP;
alias __db_rep_stat DB_REP_STAT;

	alias __db_repmgr_conn_err DB_REPMGR_CONN_ERR;
alias __db_repmgr_site DB_REPMGR_SITE;
alias __db_repmgr_stat DB_REPMGR_STAT;
alias __db_seq_record DB_SEQ_RECORD;
alias __db_seq_stat DB_SEQUENCE_STAT;
alias __db_stream DB_STREAM;
alias __db_site DB_SITE;
alias __db_sequence DB_SEQUENCE;
struct __db_thread_info;alias __db_thread_info DB_THREAD_INFO;
alias __db_txn DB_TXN;
alias __db_txn_active DB_TXN_ACTIVE;
alias __db_txn_stat DB_TXN_STAT;
alias __db_txn_token DB_TXN_TOKEN;
struct __db_txnmgr;	alias __db_txnmgr DB_TXNMGR;
alias __dbc DBC;
struct __dbc_internal;	alias __dbc_internal DBC_INTERNAL;
struct __env;		alias __env ENV;
struct __fh_t;		alias __fh_t DB_FH;
struct __fname;		alias __fname FNAME;
alias __key_range DB_KEY_RANGE;
struct __mpoolfile;	alias __mpoolfile MPOOLFILE;
struct __txn_event; struct __txn_logrec; struct __db_foreign_info;

alias __db_logvrfy_config DB_LOG_VERIFY_CONFIG;

/*
 * The Berkeley DB API flags are automatically-generated -- the following flag
 * names are no longer used, but remain for compatibility reasons.
 */
alias DB_READ_COMMITTED DB_DEGREE_2;
alias DB_READ_UNCOMMITTED DB_DIRTY_READ;
enum	DB_JOINENV	      = 0x0;

/* Key/data structure -- a Data-Base Thang. */
struct __db_dbt {
	void	 *data;			/* Key/data */
	uint32_t size;			/* key/data length */

	uint32_t ulen;			/* RO: length of user buffer. */
	uint32_t dlen;			/* RO: get/put record length. */
	uint32_t doff;			/* RO: get/put record offset. */

	void *app_data;

	uint32_t flags;
};

enum	DB_DBT_APPMALLOC	= 0x0001;	/* Callback allocated memory. */
enum	DB_DBT_BULK		= 0x0002;	/* Internal: Insert if duplicate. */
enum	DB_DBT_DUPOK		= 0x0004;	/* Internal: Insert if duplicate. */
enum	DB_DBT_ISSET		= 0x0008;	/* Lower level calls set value. */
enum	DB_DBT_MALLOC		= 0x0010;	/* Return in malloc'd memory. */
enum	DB_DBT_MULTIPLE		= 0x0020;	/* References multiple records. */
enum	DB_DBT_PARTIAL		= 0x0040;	/* Partial put/get. */
enum	DB_DBT_REALLOC		= 0x0080;	/* Return in realloc'd memory. */
enum	DB_DBT_READONLY		= 0x0100;	/* Readonly, don't update. */
enum	DB_DBT_STREAMING	= 0x0200;	/* Internal: DBT is being streamed. */
enum	DB_DBT_USERCOPY		= 0x0400;	/* Use the user-supplied callback. */
enum	DB_DBT_USERMEM		= 0x0800;	/* Return in user's memory. */
enum	DB_DBT_BLOB		= 0x1000;	/* Data item is a blob. */
enum	DB_DBT_BLOB_REC		= 0x2000;	/* Internal: Blob database record. */

/*******************************************************
 * Mutexes.
 *******************************************************/
/* 
 * When mixed size addressing is supported mutexes need to be the same size
 * independent of the process address size is.
 */
version(HAVE_MIXED_SIZE_ADDRESSING)
{
alias db_size_t	db_mutex_t;
}
else
{
alias uintptr_t	db_mutex_t;
}


struct __db_mutex_stat { /* SHARED */
	/* The following fields are maintained in the region's copy. */
	uint32_t st_mutex_align;	/* Mutex alignment */
	uint32_t st_mutex_tas_spins;	/* Mutex test-and-set spins */
	uint32_t st_mutex_init;	/* Initial mutex count */
	uint32_t st_mutex_cnt;		/* Mutex count */
	uint32_t st_mutex_max;		/* Mutex max */
	uint32_t st_mutex_free;	/* Available mutexes */
	uint32_t st_mutex_inuse;	/* Mutexes in use */
	uint32_t st_mutex_inuse_max;	/* Maximum mutexes ever in use */

	/* The following fields are filled-in from other places. */
version(TEST_DB_NO_STATISTICS)
{
}
else
{
	uintmax_t st_region_wait;	/* Region lock granted after wait. */
	uintmax_t st_region_nowait;	/* Region lock granted without wait. */
	roff_t	  st_regsize;		/* Region size. */
	roff_t	  st_regmax;		/* Region max. */
}
};

/* Buffers passed to __mutex_describe() must be at least this large. */
enum	DB_MUTEX_DESCRIBE_STRLEN	= 128;

/* This is the info of a DB_EVENT_MUTEX_DIED event notification. */
struct __db_event_mutex_died_info {
	pid_t         pid;	/* Process which last owned the mutex */
	db_threadid_t tid;	/* Thread which last owned the mutex */
	db_mutex_t    mutex;	/* ID of the mutex */
	char	      desc[DB_MUTEX_DESCRIBE_STRLEN];
};

/* This is the info of a DB_EVENT_FAILCHK event notification. */
enum DB_FAILURE_SYMPTOM_SIZE	= 120;
struct __db_event_failchk_info {
	int	error;
	char	symptom[DB_FAILURE_SYMPTOM_SIZE];
};
/* This is the length of the buffer passed to DB_ENV.thread_id_string() */
enum	DB_THREADID_STRLEN	= 128;

/*******************************************************
 * Locking.
 *******************************************************/
enum	DB_LOCKVERSION	= 1;

enum	DB_FILE_ID_LEN		= 20;	/* Unique file ID length. */

/*
 * Deadlock detector modes; used in the DB_ENV structure to configure the
 * locking subsystem.
 */
enum	DB_LOCK_NORUN		= 0;
enum	DB_LOCK_DEFAULT		= 1;	/* Default policy. */
enum	DB_LOCK_EXPIRE		= 2;	/* Only expire locks, no detection. */
enum	DB_LOCK_MAXLOCKS	= 3;	/* Select locker with max locks. */
enum	DB_LOCK_MAXWRITE	= 4;	/* Select locker with max writelocks. */
enum	DB_LOCK_MINLOCKS	= 5;	/* Select locker with min locks. */
enum	DB_LOCK_MINWRITE	= 6;	/* Select locker with min writelocks. */
enum	DB_LOCK_OLDEST		= 7;	/* Select oldest locker. */
enum	DB_LOCK_RANDOM		= 8;	/* Select random locker. */
enum	DB_LOCK_YOUNGEST	= 9;	/* Select youngest locker. */

/*
 * Simple R/W lock modes and for multi-granularity intention locking.
 *
 * !!!
 * These values are NOT random, as they are used as an index into the lock
 * conflicts arrays, i.e., DB_LOCK_IWRITE must be == 3, and DB_LOCK_IREAD
 * must be == 4.
 */
enum {
	DB_LOCK_NG=0,			/* Not granted. */
	DB_LOCK_READ=1,			/* Shared/read. */
	DB_LOCK_WRITE=2,		/* Exclusive/write. */
	DB_LOCK_WAIT=3,			/* Wait for event */
	DB_LOCK_IWRITE=4,		/* Intent exclusive/write. */
	DB_LOCK_IREAD=5,		/* Intent to share/read. */
	DB_LOCK_IWR=6,			/* Intent to read and write. */
	DB_LOCK_READ_UNCOMMITTED=7,	/* Degree 1 isolation. */
	DB_LOCK_WWRITE=8		/* Was Written. */
}
alias int db_lockmode_t;

/*
 * Request types.
 */
enum {
	DB_LOCK_DUMP=0,			/* Display held locks. */
	DB_LOCK_GET=1,			/* Get the lock. */
	DB_LOCK_GET_TIMEOUT=2,		/* Get lock with a timeout. */
	DB_LOCK_INHERIT=3,		/* Pass locks to parent. */
	DB_LOCK_PUT=4,			/* Release the lock. */
	DB_LOCK_PUT_ALL=5,		/* Release locker's locks. */
	DB_LOCK_PUT_OBJ=6,		/* Release locker's locks on obj. */
	DB_LOCK_PUT_READ=7,		/* Release locker's read locks. */
	DB_LOCK_TIMEOUT=8,		/* Force a txn to timeout. */
	DB_LOCK_TRADE=9,		/* Trade locker ids on a lock. */
	DB_LOCK_UPGRADE_WRITE=10	/* Upgrade writes for dirty reads. */
}
alias int db_lockop_t;

/*
 * Status of a lock.
 */
enum {
	DB_LSTAT_ABORTED=1,		/* Lock belongs to an aborted txn. */
	DB_LSTAT_EXPIRED=2,		/* Lock has expired. */
	DB_LSTAT_FREE=3,		/* Lock is unallocated. */
	DB_LSTAT_HELD=4,		/* Lock is currently held. */
	DB_LSTAT_PENDING=5,		/* Lock was waiting and has been
					 * promoted; waiting for the owner
					 * to run and upgrade it to held. */
	DB_LSTAT_WAITING=6		/* Lock is on the wait queue. */
}
alias int db_status_t;

/* Lock statistics structure. */
struct __db_lock_stat { /* SHARED */
	uint32_t st_id;		/* Last allocated locker ID. */
	uint32_t st_cur_maxid;		/* Current maximum unused ID. */
	uint32_t st_initlocks;		/* Initial number of locks in table. */
	uint32_t st_initlockers;	/* Initial num of lockers in table. */
	uint32_t st_initobjects;	/* Initial num of objects in table. */
	uint32_t st_locks;		/* Current number of locks in table. */
	uint32_t st_lockers;		/* Current num of lockers in table. */
	uint32_t st_objects;		/* Current num of objects in table. */
	uint32_t st_maxlocks;		/* Maximum number of locks in table. */
	uint32_t st_maxlockers;	/* Maximum num of lockers in table. */
	uint32_t st_maxobjects;	/* Maximum num of objects in table. */
	uint32_t st_partitions;	/* number of partitions. */
	uint32_t st_tablesize;		/* Size of object hash table. */
	int32_t   st_nmodes;		/* Number of lock modes. */
	uint32_t st_nlockers;		/* Current number of lockers. */
version(TEST_DB_NO_STATISTICS)
{
}
else
{
	uint32_t st_nlocks;		/* Current number of locks. */
	uint32_t st_maxnlocks;		/* Maximum number of locks so far. */
	uint32_t st_maxhlocks;		/* Maximum number of locks in any bucket. */
	uintmax_t st_locksteals;	/* Number of lock steals so far. */
	uintmax_t st_maxlsteals;	/* Maximum number steals in any partition. */
	uint32_t st_maxnlockers;	/* Maximum number of lockers so far. */
	uint32_t st_nobjects;		/* Current number of objects. */
	uint32_t st_maxnobjects;	/* Maximum number of objects so far. */
	uint32_t st_maxhobjects;	/* Maximum number of objectsin any bucket. */
	uintmax_t st_objectsteals;	/* Number of objects steals so far. */
	uintmax_t st_maxosteals;	/* Maximum number of steals in any partition. */
	uintmax_t st_nrequests;		/* Number of lock gets. */
	uintmax_t st_nreleases;		/* Number of lock puts. */
	uintmax_t st_nupgrade;		/* Number of lock upgrades. */
	uintmax_t st_ndowngrade;	/* Number of lock downgrades. */
	uintmax_t st_lock_wait;		/* Lock conflicts w/ subsequent wait */
	uintmax_t st_lock_nowait;	/* Lock conflicts w/o subsequent wait */
	uintmax_t st_ndeadlocks;	/* Number of lock deadlocks. */
	db_timeout_t st_locktimeout;	/* Lock timeout. */
	uintmax_t st_nlocktimeouts;	/* Number of lock timeouts. */
	db_timeout_t st_txntimeout;	/* Transaction timeout. */
	uintmax_t st_ntxntimeouts;	/* Number of transaction timeouts. */
	uintmax_t st_part_wait;		/* Partition lock granted after wait. */
	uintmax_t st_part_nowait;	/* Partition lock granted without wait. */
	uintmax_t st_part_max_wait;	/* Max partition lock granted after wait. */
	uintmax_t st_part_max_nowait;	/* Max partition lock granted without wait. */
	uintmax_t st_objs_wait;	/* 	Object lock granted after wait. */
	uintmax_t st_objs_nowait;	/* Object lock granted without wait. */
	uintmax_t st_lockers_wait;	/* Locker lock granted after wait. */
	uintmax_t st_lockers_nowait;	/* Locker lock granted without wait. */
	uintmax_t st_region_wait;	/* Region lock granted after wait. */
	uintmax_t st_region_nowait;	/* Region lock granted without wait. */
	uintmax_t st_nlockers_hit;	/* Lockers found in thread info. */
	uintmax_t st_nlockers_reused;	/* Lockers reallocated from thread info. */
	uint32_t st_hash_len;		/* Max length of bucket. */
	roff_t	  st_regsize;		/* Region size. */
}
};

struct __db_lock_hstat { /* SHARED */
	uintmax_t st_nrequests;		/* Number of lock gets. */
	uintmax_t st_nreleases;		/* Number of lock puts. */
	uintmax_t st_nupgrade;		/* Number of lock upgrades. */
	uintmax_t st_ndowngrade;	/* Number of lock downgrades. */
	uint32_t st_nlocks;		/* Current number of locks. */
	uint32_t st_maxnlocks;		/* Maximum number of locks so far. */
	uint32_t st_nobjects;		/* Current number of objects. */
	uint32_t st_maxnobjects;	/* Maximum number of objects so far. */
	uintmax_t st_lock_wait;		/* Lock conflicts w/ subsequent wait */
	uintmax_t st_lock_nowait;	/* Lock conflicts w/o subsequent wait */
	uintmax_t st_nlocktimeouts;	/* Number of lock timeouts. */
	uintmax_t st_ntxntimeouts;	/* Number of transaction timeouts. */
	uint32_t st_hash_len;		/* Max length of bucket. */
};

struct __db_lock_pstat { /* SHARED */
	uint32_t st_nlocks;		/* Current number of locks. */
	uint32_t st_maxnlocks;		/* Maximum number of locks so far. */
	uint32_t st_nobjects;		/* Current number of objects. */
	uint32_t st_maxnobjects;	/* Maximum number of objects so far. */
	uintmax_t st_locksteals;	/* Number of lock steals so far. */
	uintmax_t st_objectsteals;	/* Number of objects steals so far. */
};

/*
 * DB_LOCK_ILOCK --
 *	Internal DB access method lock.
 */
struct __db_ilock { /* SHARED */
	db_pgno_t pgno;			/* Page being locked. */
	uint8_t fileid[DB_FILE_ID_LEN];/* File id. */
	uint32_t type;			/* Type of lock. */
};

enum	DB_HANDLE_LOCK		= 1;
enum	DB_RECORD_LOCK		= 2;
enum	DB_PAGE_LOCK		= 3;
enum	DB_DATABASE_LOCK	= 4;

/*
 * DB_LOCK --
 *	The structure is allocated by the caller and filled in during a
 *	lock_get request (or a lock_vec/DB_LOCK_GET).
 */
struct __db_lock_u { /* SHARED */
	roff_t		off;		/* Offset of the lock in the region */
	uint32_t	ndx;		/* Index of the object referenced by
					 * this lock; used for locking. */
	uint32_t	gen;		/* Generation number of this lock. */
	db_lockmode_t	mode;		/* mode of this lock. */
};

/* Lock request structure. */
struct __db_lockreq {
	db_lockop_t	 op;		/* Operation. */
	db_lockmode_t	 mode;		/* Requested mode. */
	db_timeout_t	 timeout;	/* Time to expire lock. */
	DBT		*obj;		/* Object being locked. */
	DB_LOCK		 lock;		/* Lock returned. */
};

/*******************************************************
 * Logging.
 *******************************************************/
enum	DB_LOGVERSION	= 22;		/* Current log version. */
enum	DB_LOGVERSION_LATCHING = 15;	/* Log version using latching: db-4.8 */
enum	DB_LOGCHKSUM	= 12;		/* Check sum headers: db-4.5 */
enum	DB_LOGOLDVER	= 8;		/* Oldest version supported: db-4.2 */
enum	DB_LOGMAGIC	= 0x040988;

/*
 * A DB_LSN has two parts, a fileid which identifies a specific file, and an
 * offset within that file.  The fileid is an unsigned 4-byte quantity that
 * uniquely identifies a file within the log directory -- currently a simple
 * counter inside the log.  The offset is also an unsigned 4-byte value.  The
 * log manager guarantees the offset is never more than 4 bytes by switching
 * to a new log file before the maximum length imposed by an unsigned 4-byte
 * offset is reached.
 */
struct __db_lsn { /* SHARED */
	uint32_t	file;		/* File ID. */
	uint32_t	offset;		/* File offset. */
};

/*
 * Application-specified log record types start at DB_user_BEGIN, and must not
 * equal or exceed DB_debug_FLAG.
 *
 * DB_debug_FLAG is the high-bit of the uint32_t that specifies a log record
 * type.  If the flag is set, it's a log record that was logged for debugging
 * purposes only, even if it reflects a database change -- the change was part
 * of a non-durable transaction.
 */
enum	DB_user_BEGIN		= 10000;
enum	DB_debug_FLAG		= 0x80000000;

/*
 * DB_LOGC --
 *	Log cursor.
 */
struct __db_log_cursor {
	ENV	 *env;			/* Environment */

	DB_FH	 *fhp;			/* File handle. */
	DB_LSN	  lsn;			/* Cursor: LSN */
	uint32_t len;			/* Cursor: record length */
	uint32_t prev;			/* Cursor: previous record's offset */

	DBT	  dbt;			/* Return DBT. */
	DB_LSN    p_lsn;		/* Persist LSN. */
	uint32_t p_version;		/* Persist version. */

	uint8_t *bp;			/* Allocated read buffer. */
	uint32_t bp_size;		/* Read buffer length in bytes. */
	uint32_t bp_rlen;		/* Read buffer valid data length. */
	DB_LSN	  bp_lsn;		/* Read buffer first byte LSN. */

	uint32_t bp_maxrec;		/* Max record length in the log file. */

	/* DB_LOGC PUBLIC HANDLE LIST BEGIN */
	int function (DB_LOGC *, uint32_t) close;
	int function (DB_LOGC *, DB_LSN *, DBT *, uint32_t) get;
	int function (DB_LOGC *, uint32_t *, uint32_t) Version;
	/* DB_LOGC PUBLIC HANDLE LIST END */

	uint32_t flags;
};

enum	DB_LOG_DISK		= 0x01;	/* Log record came from disk. */
enum	DB_LOG_LOCKED		= 0x02;	/* Log region already locked */
enum	DB_LOG_SILENT_ERR	= 0x04;	/* Turn-off error messages. */

/* Log statistics structure. */
struct __db_log_stat { /* SHARED */
	uint32_t st_magic;		/* Log file magic number. */
	uint32_t st_version;		/* Log file version number. */
	int32_t   st_mode;		/* Log file permissions mode. */
	uint32_t st_lg_bsize;		/* Log buffer size. */
	uint32_t st_lg_size;		/* Log file size. */
	uint32_t st_wc_bytes;		/* Bytes to log since checkpoint. */
	uint32_t st_wc_mbytes;		/* Megabytes to log since checkpoint. */
	uint32_t st_fileid_init;	/* Initial allocation for fileids. */
version(TEST_DB_NO_STATISTICS)
{
}
else
{
	uint32_t st_nfileid;		/* Current number of fileids. */
	uint32_t st_maxnfileid;	/* Maximum number of fileids used. */
	uintmax_t st_record;		/* Records entered into the log. */
	uint32_t st_w_bytes;		/* Bytes to log. */
	uint32_t st_w_mbytes;		/* Megabytes to log. */
	uintmax_t st_wcount;		/* Total I/O writes to the log. */
	uintmax_t st_wcount_fill;	/* Overflow writes to the log. */
	uintmax_t st_rcount;		/* Total I/O reads from the log. */
	uintmax_t st_scount;		/* Total syncs to the log. */
	uintmax_t st_region_wait;	/* Region lock granted after wait. */
	uintmax_t st_region_nowait;	/* Region lock granted without wait. */
	uint32_t st_cur_file;		/* Current log file number. */
	uint32_t st_cur_offset;	/* Current log file offset. */
	uint32_t st_disk_file;		/* Known on disk log file number. */
	uint32_t st_disk_offset;	/* Known on disk log file offset. */
	uint32_t st_maxcommitperflush;	/* Max number of commits in a flush. */
	uint32_t st_mincommitperflush;	/* Min number of commits in a flush. */
	roff_t	  st_regsize;		/* Region size. */
}
};

/*
 * We need to record the first log record of a transaction.  For user
 * defined logging this macro returns the place to put that information,
 * if it is need in rlsnp, otherwise it leaves it unchanged.  We also
 * need to track the last record of the transaction, this returns the
 * place to put that info.
 */
auto DB_SET_TXN_LSNP(T, U, Q)(T txn, U blsnp, Q llsnp)
{
	return ((txn).set_txn_lsnp(txn, blsnp, llsnp));;
}


/*
 * Definition of the structure which specifies marshalling of log records.
 */
enum {
	LOGREC_Done,
	LOGREC_ARG,
	LOGREC_HDR,
	LOGREC_DATA,
	LOGREC_DB,
	LOGREC_DBOP,
	LOGREC_DBT,
	LOGREC_LOCKS,
	LOGREC_OP,
	LOGREC_PGDBT,
	LOGREC_PGDDBT,
	LOGREC_PGLIST,
	LOGREC_POINTER,
	LOGREC_TIME,
	LOGREC_LONGARG
}
alias int log_rec_type_t;

struct __log_rec_spec {
	log_rec_type_t	type;
	uint32_t	offset;
	const char 	*name;
	const char	fmt[4];
}
alias __log_rec_spec DB_LOG_RECSPEC;

/*
 * Size of a DBT in a log record.
 */
auto LOG_DBT_SIZE(T)(T dbt)
{
	return (uint32_t.sizeof + ((dbt) == null ? 0 : (dbt).size));;
}


/*******************************************************
 * Shared buffer cache (mpool).
 *******************************************************/
/* Priority values for DB_MPOOLFILE.{put,set_priority}. */
enum {
	DB_PRIORITY_UNCHANGED=0,
	DB_PRIORITY_VERY_LOW=1,
	DB_PRIORITY_LOW=2,
	DB_PRIORITY_DEFAULT=3,
	DB_PRIORITY_HIGH=4,
	DB_PRIORITY_VERY_HIGH=5
}
alias int DB_CACHE_PRIORITY;

/* Per-process DB_MPOOLFILE information. */
struct __db_mpoolfile {
	DB_FH	  *fhp;			/* Underlying file handle. */

	/*
	 * !!!
	 * The ref, pinref and q fields are protected by the region lock.
	 */
	uint32_t  Ref;			/* Reference count. */

	uint32_t pinref;		/* Pinned block reference count. */

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_ENTRY(__db_mpoolfile) q;
	 */
	struct q_t {
		__db_mpoolfile* tqe_next;
		__db_mpoolfile** tqe_prev;
	}
	q_t q;

	/*
	 * !!!
	 * The rest of the fields (with the exception of the MP_FLUSH flag)
	 * are not thread-protected, even when they may be modified at any
	 * time by the application.  The reason is the DB_MPOOLFILE handle
	 * is single-threaded from the viewpoint of the application, and so
	 * the only fields needing to be thread-protected are those accessed
	 * by checkpoint or sync threads when using DB_MPOOLFILE structures
	 * to flush buffers from the cache.
	 */
	ENV	       *env;		/* Environment */
	MPOOLFILE      *mfp;		/* Underlying MPOOLFILE. */

	uint32_t	clear_len;	/* Cleared length on created pages. */
	uint8_t			/* Unique file ID. */
			fileid[DB_FILE_ID_LEN];
	int		ftype;		/* File type. */
	int32_t		lsn_offset;	/* LSN offset in page. */
	uint32_t	gbytes, bytes;	/* Maximum file size. */
	DBT	       *pgcookie;	/* Byte-string passed to pgin/pgout. */
	int32_t		priority;	/* Cache priority. */

	void	       *addr;		/* Address of mmap'd region. */
	size_t		len;		/* Length of mmap'd region. */

	uint32_t	config_flags;	/* Flags to DB_MPOOLFILE.set_flags. */

	/* DB_MPOOLFILE PUBLIC HANDLE LIST BEGIN */
	int function (DB_MPOOLFILE *, uint32_t) close;
	int function
	    (DB_MPOOLFILE *, db_pgno_t *, DB_TXN *, uint32_t, void *) get;
	int function (DB_MPOOLFILE *, uint32_t *) get_clear_len;
	int function (DB_MPOOLFILE *, uint8_t *) get_fileid;
	int function (DB_MPOOLFILE *, uint32_t *) get_flags;
	int function (DB_MPOOLFILE *, int *) get_ftype;
	int function (DB_MPOOLFILE *, db_pgno_t *) get_last_pgno;
	int function (DB_MPOOLFILE *, int32_t *) get_lsn_offset;
	int function (DB_MPOOLFILE *, uint32_t *, uint32_t *) get_maxsize;
	int function (DB_MPOOLFILE *, DBT *) get_pgcookie;
	int function (DB_MPOOLFILE *, DB_CACHE_PRIORITY *) get_priority;
	int function (DB_MPOOLFILE *, const (char)* , uint32_t, int, size_t) open;
	int function (DB_MPOOLFILE *, void *, DB_CACHE_PRIORITY, uint32_t) put;
	int function (DB_MPOOLFILE *, uint32_t) set_clear_len;
	int function (DB_MPOOLFILE *, uint8_t *) set_fileid;
	int function (DB_MPOOLFILE *, uint32_t, int) set_flags;
	int function (DB_MPOOLFILE *, int) set_ftype;
	int function (DB_MPOOLFILE *, int32_t) set_lsn_offset;
	int function (DB_MPOOLFILE *, uint32_t, uint32_t) set_maxsize;
	int function (DB_MPOOLFILE *, DBT *) set_pgcookie;
	int function (DB_MPOOLFILE *, DB_CACHE_PRIORITY) set_priority;
	int function (DB_MPOOLFILE *) sync;
	/* DB_MPOOLFILE PUBLIC HANDLE LIST END */

	/*
	 * MP_FILEID_SET, MP_OPEN_CALLED and MP_READONLY do not need to be
	 * thread protected because they are initialized before the file is
	 * linked onto the per-process lists, and never modified.
	 *
	 * MP_FLUSH is thread protected because it is potentially read/set by
	 * multiple threads of control.
	 */
	uint32_t  flags;
};

enum	MP_FILEID_SET	= 0x001;		/* Application supplied a file ID. */
enum	MP_FLUSH	= 0x002;		/* Was used to flush a buffer. */
enum	MP_FOR_FLUSH	= 0x004;		/* Was opened to flush a buffer. */
enum	MP_MULTIVERSION	= 0x008;		/* Opened for multiversion access. */
enum	MP_OPEN_CALLED	= 0x010;		/* File opened. */
enum	MP_READONLY	= 0x020;		/* File is readonly. */
enum	MP_DUMMY	= 0x040;		/* File is dummy for __memp_fput. */

/* Mpool statistics structure. */
struct __db_mpool_stat { /* SHARED */
	uint32_t st_gbytes;		/* Total cache size: GB. */
	uint32_t st_bytes;		/* Total cache size: B. */
	uint32_t st_ncache;		/* Number of cache regions. */
	uint32_t st_max_ncache;	/* Maximum number of regions. */
	db_size_t st_mmapsize;		/* Maximum file size for mmap. */
	int32_t st_maxopenfd;		/* Maximum number of open fd's. */
	int32_t st_maxwrite;		/* Maximum buffers to write. */
	db_timeout_t st_maxwrite_sleep;	/* Sleep after writing max buffers. */
	uint32_t st_pages;		/* Total number of pages. */
version(TEST_DB_NO_STATISTICS)
{
}
else
{
	uint32_t st_map;		/* Pages from mapped files. */
	uintmax_t st_cache_hit;	/* Pages found in the cache. */
	uintmax_t st_cache_miss;	/* Pages not found in the cache. */
	uintmax_t st_page_create;	/* Pages created in the cache. */
	uintmax_t st_page_in;		/* Pages read in. */
	uintmax_t st_page_out;		/* Pages written out. */
	uintmax_t st_ro_evict;		/* Clean pages forced from the cache. */
	uintmax_t st_rw_evict;		/* Dirty pages forced from the cache. */
	uintmax_t st_page_trickle;	/* Pages written by memp_trickle. */
	uint32_t st_page_clean;	/* Clean pages. */
	uint32_t st_page_dirty;	/* Dirty pages. */
	uint32_t st_hash_buckets;	/* Number of hash buckets. */
	uint32_t st_hash_mutexes;	/* Number of hash bucket mutexes. */
	uint32_t st_pagesize;		/* Assumed page size. */
	uint32_t st_hash_searches;	/* Total hash chain searches. */
	uint32_t st_hash_longest;	/* Longest hash chain searched. */
	uintmax_t st_hash_examined;	/* Total hash entries searched. */
	uintmax_t st_hash_nowait;	/* Hash lock granted with nowait. */
	uintmax_t st_hash_wait;		/* Hash lock granted after wait. */
	uintmax_t st_hash_max_nowait;	/* Max hash lock granted with nowait. */
	uintmax_t st_hash_max_wait;	/* Max hash lock granted after wait. */
	uintmax_t st_region_nowait;	/* Region lock granted with nowait. */
	uintmax_t st_region_wait;	/* Region lock granted after wait. */
	uintmax_t st_mvcc_frozen;	/* Buffers frozen. */
	uintmax_t st_mvcc_thawed;	/* Buffers thawed. */
	uintmax_t st_mvcc_freed;	/* Frozen buffers freed. */
	uintmax_t st_mvcc_reused;	/* Outdated invisible buffers reused. */
	uintmax_t st_alloc;		/* Number of page allocations. */
	uintmax_t st_alloc_buckets;	/* Buckets checked during allocation. */
	uintmax_t st_alloc_max_buckets;/* Max checked during allocation. */
	uintmax_t st_alloc_pages;	/* Pages checked during allocation. */
	uintmax_t st_alloc_max_pages;	/* Max checked during allocation. */
	uintmax_t st_io_wait;		/* Thread waited on buffer I/O. */
	uintmax_t st_sync_interrupted;	/* Number of times sync interrupted. */
	uint32_t st_oddfsize_detect;	/* Odd file size detected. */
	uint32_t st_oddfsize_resolve;	/* Odd file size resolved. */
	roff_t	  st_regsize;		/* Region size. */
	roff_t	  st_regmax;		/* Region max. */
}
};

/*
 * Mpool file statistics structure.
 * The first fields in this structure must mirror the __db_mpool_fstat_int
 * structure, since content is mem copied between the two.
 */
struct __db_mpool_fstat {
	uint32_t st_pagesize;		/* Page size. */
version(TEST_DB_NO_STATISTICS)
{
}
else
{
	uint32_t st_map;		/* Pages from mapped files. */
	uintmax_t st_cache_hit;	/* Pages found in the cache. */
	uintmax_t st_cache_miss;	/* Pages not found in the cache. */
	uintmax_t st_page_create;	/* Pages created in the cache. */
	uintmax_t st_page_in;		/* Pages read in. */
	uintmax_t st_page_out;		/* Pages written out. */
	uintmax_t st_backup_spins;	/* Number of spins during a copy. */
}
	char *file_name;	/* File name. */
};

/*******************************************************
 * Transactions and recovery.
 *******************************************************/
enum	DB_TXNVERSION	= 1;

enum {
	DB_TXN_ABORT=0,			/* Public. */
	DB_TXN_APPLY=1,			/* Public. */
	DB_TXN_BACKWARD_ROLL=3,		/* Public. */
	DB_TXN_FORWARD_ROLL=4,		/* Public. */
	DB_TXN_OPENFILES=5,		/* Internal. */
	DB_TXN_POPENFILES=6,		/* Internal. */
	DB_TXN_PRINT=7,			/* Public. */
	DB_TXN_LOG_VERIFY=8		/* Internal. */
}
alias int db_recops;

/*
 * BACKWARD_ALLOC is used during the forward pass to pick up any aborted
 * allocations for files that were created during the forward pass.
 * The main difference between _ALLOC and _ROLL is that the entry for
 * the file not exist during the rollforward pass.
 */
auto DB_UNDO(T)(T op)
{
	return ((op) == DB_TXN_ABORT || (op) == DB_TXN_BACKWARD_ROLL);
}
auto DB_REDO(T)(T op)
{
	return ((op) == DB_TXN_FORWARD_ROLL || (op) == DB_TXN_APPLY);
}

struct __db_txn {
	DB_TXNMGR	*mgrp;		/* Pointer to transaction manager. */
	DB_TXN		*parent;	/* Pointer to transaction's parent. */
	DB_THREAD_INFO	*thread_info;	/* Pointer to thread information. */

	uint32_t	txnid;		/* Unique transaction id. */
	char		*name;		/* Transaction name. */
	DB_LOCKER	*locker;	/* Locker for this txn. */

	void		*td;		/* Detail structure within region. */
	db_timeout_t	lock_timeout;	/* Timeout for locks for this txn. */
	void		*txn_list;	/* Undo information for parent. */

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_ENTRY(__db_txn) links;
	 */
	struct links_t {
		__db_txn* tqe_next;
		__db_txn** tqe_prev;
	}
	links_t links;

	/*
	 * !!!
	 * Explicit representations of structures from shqueue.h.
	 * SH_TAILQ_ENTRY xa_links;
	 * These links link together transactions that are active in
	 * the same thread of control.
	 */
	struct xa_links_t {
		db_ssize_t stqe_next;
		db_ssize_t stqe_prev;
	}
	xa_links_t xa_links;

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_HEAD(__kids, __db_txn) kids;
	 */
	struct __kids {
		__db_txn* tqh_first;
		__db_txn** tqh_last;
	}
	__kids kids;

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_HEAD(__events, __txn_event) events;
	 */
	struct events_t {
		__txn_event* tqh_first;
		__txn_event** tqh_last;
	}
	events_t events;

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * STAILQ_HEAD(__logrec, __txn_logrec) logs;
	 */
	struct logs_t {
		__txn_logrec* stqh_first;
		__txn_logrec** stqh_last;
	}
	logs_t logs;

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_ENTRY(__db_txn) klinks;
	 */
	struct klinks_t {
		__db_txn* tqe_next;
		__db_txn** tqe_prev;
	}
	klinks_t klinks;

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_HEAD(__my_cursors, __dbc) my_cursors;
	 */
	struct __my_cursors {
		__dbc* tqh_first;
		__dbc** tqh_last;
	}
	__my_cursors my_cursors;

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_HEAD(__femfs, MPOOLFILE) femfs;
	 *
	 * These are DBs involved in file extension in this transaction.
	 */
	struct __femfs {
		DB *tqh_first;
		DB **tqh_last;
	}
	__femfs femfs;

	DB_TXN_TOKEN	*token_buffer;	/* User's commit token buffer. */
	void	*api_internal;		/* C++ API private. */
	void	*xml_internal;		/* XML API private. */

	uint32_t	cursors;	/* Number of cursors open for txn */

	/* DB_TXN PUBLIC HANDLE LIST BEGIN */
	int	  function (DB_TXN *) abort;
	int	  function (DB_TXN *, uint32_t) commit;
	int	  function (DB_TXN *, uint32_t) discard;
	int	  function (DB_TXN *, const (char)* *) get_name;
	int	  function (DB_TXN *, uint32_t *) get_priority;
	uint32_t function (DB_TXN *) id;
	int	  function (DB_TXN *, uint8_t *) prepare;
	int	  function (DB_TXN *, DB_TXN_TOKEN *) set_commit_token;
	int	  function (DB_TXN *, const (char)* ) set_name;
	int	  function (DB_TXN *, uint32_t) set_priority;
	int	  function (DB_TXN *, db_timeout_t, uint32_t) set_timeout;
	/* DB_TXN PUBLIC HANDLE LIST END */

	/* DB_TXN PRIVATE HANDLE LIST BEGIN */
	void	  function (DB_TXN *txn, DB_LSN **, DB_LSN **) set_txn_lsnp;
	/* DB_TXN PRIVATE HANDLE LIST END */

	uint32_t	xa_thr_status;

	uint32_t	flags;
};

enum	TXN_XA_THREAD_NOTA		= 0;
enum	TXN_XA_THREAD_ASSOCIATED	= 1;
enum	TXN_XA_THREAD_SUSPENDED		= 2;
enum	TXN_XA_THREAD_UNASSOCIATED 	= 3;
enum	TXN_CHILDCOMMIT		= 0x00001;	/* Txn has committed. */
enum	TXN_COMPENSATE		= 0x00002;	/* Compensating transaction. */
enum	TXN_DEADLOCK		= 0x00004;	/* Txn has deadlocked. */
enum	TXN_FAMILY		= 0x00008;	/* Cursors/children are independent. */
enum	TXN_IGNORE_LEASE	= 0x00010;	/* Skip lease check at commit time. */
enum	TXN_INFAMILY		= 0x00020;	/* Part of a transaction family. */
enum	TXN_LOCKTIMEOUT		= 0x00040;	/* Txn has a lock timeout. */
enum	TXN_MALLOC		= 0x00080;	/* Structure allocated by TXN system. */
enum	TXN_NOSYNC		= 0x00100;	/* Do not sync on prepare and commit. */
enum	TXN_NOWAIT		= 0x00200;	/* Do not wait on locks. */
enum	TXN_PRIVATE		= 0x00400;	/* Txn owned by cursor. */
enum	TXN_READONLY		= 0x00800;	/* CDS group handle. */
enum	TXN_READ_COMMITTED	= 0x01000;	/* Txn has degree 2 isolation. */
enum	TXN_READ_UNCOMMITTED	= 0x02000;	/* Txn has degree 1 isolation. */
enum	TXN_RESTORED		= 0x04000;	/* Txn has been restored. */
enum	TXN_SNAPSHOT		= 0x08000;	/* Snapshot Isolation. */
enum	TXN_SYNC		= 0x10000;	/* Write and sync on prepare/commit. */
enum	TXN_WRITE_NOSYNC	= 0x20000;	/* Write only on prepare/commit. */
enum	TXN_BULK		= 0x40000; /* Enable bulk loading optimization. */

enum TXN_SYNC_FLAGS = TXN_SYNC | TXN_NOSYNC | TXN_WRITE_NOSYNC;

/*
 * Structure used for two phase commit interface.
 * We set the size of our global transaction id (gid) to be 128 in order
 * to match that defined by the XA X/Open standard.
 */
enum	DB_GID_SIZE	= 128;
struct __db_preplist {
	DB_TXN	*txn;
	uint8_t gid[DB_GID_SIZE];
};

/* Transaction statistics structure. */
struct __db_txn_active {
	uint32_t txnid;		/* Transaction ID */
	uint32_t parentid;		/* Transaction ID of parent */
	pid_t     pid;			/* Process owning txn ID */
	db_threadid_t tid;		/* Thread owning txn ID */

	DB_LSN	  lsn;			/* LSN when transaction began */

	DB_LSN	  read_lsn;		/* Read LSN for MVCC */
	uint32_t mvcc_ref;		/* MVCC reference count */

	uint32_t priority;		/* Deadlock resolution priority */

	uint32_t status;		/* Status of the transaction */

	uint32_t xa_status;		/* XA status */

	uint8_t  gid[DB_GID_SIZE];	/* Global transaction ID */
	char	  name[51];		/* 50 bytes of name, nul termination */
};

enum	TXN_ABORTED		= 1;
enum	TXN_COMMITTED		= 2;
enum	TXN_NEED_ABORT		= 3;
enum	TXN_PREPARED		= 4;
enum	TXN_RUNNING		= 5;
enum	TXN_XA_ACTIVE		= 1;
enum	TXN_XA_DEADLOCKED	= 2;
enum	TXN_XA_IDLE		= 3;
enum	TXN_XA_PREPARED		= 4;
enum	TXN_XA_ROLLEDBACK	= 5;

struct __db_txn_stat {
	uint32_t st_nrestores;		/* number of restored transactions
					   after recovery. */
version(TEST_DB_NO_STATISTICS)
{
}
else
{
	DB_LSN	  st_last_ckp;		/* lsn of the last checkpoint */
	time_t	  st_time_ckp;		/* time of last checkpoint */
	uint32_t st_last_txnid;	/* last transaction id given out */
	uint32_t st_inittxns;		/* inital txns allocated */
	uint32_t st_maxtxns;		/* maximum txns possible */
	uintmax_t st_naborts;		/* number of aborted transactions */
	uintmax_t st_nbegins;		/* number of begun transactions */
	uintmax_t st_ncommits;		/* number of committed transactions */
	uint32_t st_nactive;		/* number of active transactions */
	uint32_t st_nsnapshot;		/* number of snapshot transactions */
	uint32_t st_maxnactive;	/* maximum active transactions */
	uint32_t st_maxnsnapshot;	/* maximum snapshot transactions */
	uintmax_t st_region_wait;	/* Region lock granted after wait. */
	uintmax_t st_region_nowait;	/* Region lock granted without wait. */
	roff_t	  st_regsize;		/* Region size. */
	DB_TXN_ACTIVE *st_txnarray;	/* array of active transactions */
}
};

enum	DB_TXN_TOKEN_SIZE		= 20;
struct __db_txn_token {
	uint8_t buf[DB_TXN_TOKEN_SIZE];
};

/*******************************************************
 * Replication.
 *******************************************************/
/* Special, out-of-band environment IDs. */
enum	DB_EID_BROADCAST	= -1;
enum	DB_EID_INVALID		= -2;
enum	DB_EID_MASTER		= -3;

enum	DB_REP_DEFAULT_PRIORITY		= 100;

/* Acknowledgement policies; 0 reserved as OOB. */
enum	DB_REPMGR_ACKS_ALL		= 1;
enum	DB_REPMGR_ACKS_ALL_AVAILABLE	= 2;
enum	DB_REPMGR_ACKS_ALL_PEERS	= 3;
enum	DB_REPMGR_ACKS_NONE		= 4;
enum	DB_REPMGR_ACKS_ONE		= 5;
enum	DB_REPMGR_ACKS_ONE_PEER		= 6;
enum	DB_REPMGR_ACKS_QUORUM		= 7;

/* Replication timeout configuration values. */
enum	DB_REP_ACK_TIMEOUT		= 1;	/* RepMgr acknowledgements. */
enum	DB_REP_CHECKPOINT_DELAY		= 2;	/* Master checkpoint delay. */
enum	DB_REP_CONNECTION_RETRY		= 3;	/* RepMgr connections. */
enum	DB_REP_ELECTION_RETRY		= 4;	/* RepMgr elect retries. */
enum	DB_REP_ELECTION_TIMEOUT		= 5;	/* Rep normal elections. */
enum	DB_REP_FULL_ELECTION_TIMEOUT	= 6;	/* Rep full elections. */
enum	DB_REP_HEARTBEAT_MONITOR	= 7;	/* RepMgr client HB monitor. */
enum	DB_REP_HEARTBEAT_SEND		= 8;	/* RepMgr master send freq. */
enum	DB_REP_LEASE_TIMEOUT		= 9;	/* Master leases. */

/*
 * Event notification types.  (Tcl testing interface currently assumes there are
 * no more than 32 of these.). Comments include any relevant event_info types.
 */
enum	DB_EVENT_PANIC			 = 0;
enum	DB_EVENT_REG_ALIVE		 = 1;	/* int: pid which was in env */
enum	DB_EVENT_REG_PANIC		 = 2;	/* int: error causing the panic. */
enum	DB_EVENT_REP_AUTOTAKEOVER_FAILED = 3;
enum	DB_EVENT_REP_CLIENT		 = 4;
enum	DB_EVENT_REP_CONNECT_BROKEN	 = 5;	/* DB_REPMGR_CONN_ERR */
enum	DB_EVENT_REP_CONNECT_ESTD	 = 6;	/* int: EID of remote site */
enum	DB_EVENT_REP_CONNECT_TRY_FAILED	 = 7;	/* DB_REPMGR_CONN_ERR */
enum	DB_EVENT_REP_DUPMASTER		 = 8;
enum	DB_EVENT_REP_ELECTED		 = 9;
enum	DB_EVENT_REP_ELECTION_FAILED	= 10;
enum	DB_EVENT_REP_INIT_DONE		= 11;
enum	DB_EVENT_REP_INQUEUE_FULL	= 12;
enum	DB_EVENT_REP_JOIN_FAILURE	= 13;
enum	DB_EVENT_REP_LOCAL_SITE_REMOVED	= 14;
enum	DB_EVENT_REP_MASTER		= 15;
enum	DB_EVENT_REP_MASTER_FAILURE	= 16;
enum	DB_EVENT_REP_NEWMASTER		= 17;	/* int: new master's site id */
enum	DB_EVENT_REP_PERM_FAILED	= 18;
enum	DB_EVENT_REP_SITE_ADDED		= 19;	/* int: eid */
enum	DB_EVENT_REP_SITE_REMOVED	= 20;	/* int: eid */
enum	DB_EVENT_REP_STARTUPDONE	= 21;
enum	DB_EVENT_REP_WOULD_ROLLBACK	= 22;	/* Undocumented; C API only. */
enum	DB_EVENT_WRITE_FAILED		= 23;
enum	DB_EVENT_MUTEX_DIED		= 24;	/* DB_EVENT_MUTEX_DIED_INFO */
enum	DB_EVENT_FAILCHK_PANIC		= 25;	/* DB_EVENT_FAILCHK_INFO */
enum	DB_EVENT_NO_SUCH_EVENT		 = 0xffffffff; /* OOB sentinel value */

/* Replication Manager site status. */
struct __db_repmgr_site {
	int eid;
	char *host;
	uint port;

	uint32_t status;

	uint32_t flags;
};

enum	DB_REPMGR_CONNECTED	= 1;
enum	DB_REPMGR_DISCONNECTED	= 2;
enum	DB_REPMGR_ISPEER	= 0x01;
enum	DB_REPMGR_ISVIEW	= 0x02;

/* Replication statistics. */
struct __db_rep_stat { /* SHARED */
	/* !!!
	 * Many replication statistics fields cannot be protected by a mutex
	 * without an unacceptable performance penalty, since most message
	 * processing is done without the need to hold a region-wide lock.
	 * Fields whose comments end with a '+' may be updated without holding
	 * the replication or log mutexes (as appropriate), and thus may be
	 * off somewhat (or, on unreasonable architectures under unlucky
	 * circumstances, garbaged).
	 */
	uint32_t st_startup_complete;	/* Site completed client sync-up. */
	uint32_t st_view;		/* Site is a view. */
version(TEST_DB_NO_STATISTICS)
{
}
else
{
	uintmax_t st_log_queued;	/* Log records currently queued.+ */
	uint32_t st_status;		/* Current replication status. */
	DB_LSN st_next_lsn;		/* Next LSN to use or expect. */
	DB_LSN st_waiting_lsn;		/* LSN we're awaiting, if any. */
	DB_LSN st_max_perm_lsn;		/* Maximum permanent LSN. */
	db_pgno_t st_next_pg;		/* Next pg we expect. */
	db_pgno_t st_waiting_pg;	/* pg we're awaiting, if any. */

	uint32_t st_dupmasters;	/* # of times a duplicate master
					   condition was detected.+ */
	db_ssize_t st_env_id;		/* Current environment ID. */
	uint32_t st_env_priority;	/* Current environment priority. */
	uintmax_t st_bulk_fills;	/* Bulk buffer fills. */
	uintmax_t st_bulk_overflows;	/* Bulk buffer overflows. */
	uintmax_t st_bulk_records;	/* Bulk records stored. */
	uintmax_t st_bulk_transfers;	/* Transfers of bulk buffers. */
	uintmax_t st_client_rerequests;/* Number of forced rerequests. */
	uintmax_t st_client_svc_req;	/* Number of client service requests
					   received by this client. */
	uintmax_t st_client_svc_miss;	/* Number of client service requests
					   missing on this client. */
	uint32_t st_gen;		/* Current generation number. */
	uint32_t st_egen;		/* Current election gen number. */
	uintmax_t st_lease_chk;		/* Lease validity checks. */
	uintmax_t st_lease_chk_misses;	/* Lease checks invalid. */
	uintmax_t st_lease_chk_refresh;	/* Lease refresh attempts. */
	uintmax_t st_lease_sends;	/* Lease messages sent live. */

	uintmax_t st_log_duplicated;	/* Log records received multiply.+ */
	uintmax_t st_log_queued_max;	/* Max. log records queued at once.+ */
	uintmax_t st_log_queued_total;	/* Total # of log recs. ever queued.+ */
	uintmax_t st_log_records;	/* Log records received and put.+ */
	uintmax_t st_log_requested;	/* Log recs. missed and requested.+ */
	db_ssize_t st_master;		/* Env. ID of the current master. */
	uintmax_t st_master_changes;	/* # of times we've switched masters. */
	uintmax_t st_msgs_badgen;	/* Messages with a bad generation #.+ */
	uintmax_t st_msgs_processed;	/* Messages received and processed.+ */
	uintmax_t st_msgs_recover;	/* Messages ignored because this site
					   was a client in recovery.+ */
	uintmax_t st_msgs_send_failures;/* # of failed message sends.+ */
	uintmax_t st_msgs_sent;	/* # of successful message sends.+ */
	uintmax_t st_newsites;		/* # of NEWSITE msgs. received.+ */
	uint32_t st_nsites;		/* Current number of sites we will
					   assume during elections. */
	uintmax_t st_nthrottles;	/* # of times we were throttled. */
	uintmax_t st_outdated;		/* # of times we detected and returned
					   an OUTDATED condition.+ */
	uintmax_t st_pg_duplicated;	/* Pages received multiply.+ */
	uintmax_t st_pg_records;	/* Pages received and stored.+ */
	uintmax_t st_pg_requested;	/* Pages missed and requested.+ */
	uintmax_t st_txns_applied;	/* # of transactions applied.+ */
	uintmax_t st_startsync_delayed;/* # of STARTSYNC msgs delayed.+ */

	/* Elections generally. */
	uintmax_t st_elections;	/* # of elections held.+ */
	uintmax_t st_elections_won;	/* # of elections won by this site.+ */

	/* Statistics about an in-progress election. */
	db_ssize_t st_election_cur_winner;	/* Current front-runner. */
	uint32_t st_election_gen;	/* Election generation number. */
	uint32_t st_election_datagen;	/* Election data generation number. */
	DB_LSN st_election_lsn;		/* Max. LSN of current winner. */
	uint32_t st_election_nsites;	/* # of "registered voters". */
	uint32_t st_election_nvotes;	/* # of "registered voters" needed. */
	uint32_t st_election_priority;	/* Current election priority. */
	int32_t   st_election_status;	/* Current election status. */
	uint32_t st_election_tiebreaker;/* Election tiebreaker value. */
	uint32_t st_election_votes;	/* Votes received in this round. */
	uint32_t st_election_sec;	/* Last election time seconds. */
	uint32_t st_election_usec;	/* Last election time useconds. */
	uint32_t st_max_lease_sec;	/* Maximum lease timestamp seconds. */
	uint32_t st_max_lease_usec;	/* Maximum lease timestamp useconds. */

	/* Undocumented statistics only used by the test system. */
version(CONFIG_TEST)
{
	uint32_t st_filefail_cleanups;	/* # of FILE_FAIL cleanups done. */
	uintmax_t st_log_futuredup;	/* Future log records that are dups. */
}
}
};

/* Replication Manager statistics. */
struct __db_repmgr_stat { /* SHARED */
	uintmax_t st_perm_failed;	/* # of insufficiently ack'ed msgs. */
	uintmax_t st_msgs_queued;	/* # msgs queued for network delay. */
	uintmax_t st_msgs_dropped;	/* # msgs discarded due to excessive
					   queue length. */
	uint32_t st_incoming_queue_gbytes;	/* Incoming queue size: GB. */
	uint32_t st_incoming_queue_bytes;	/* Incoming queue size: B. */
	uintmax_t st_incoming_msgs_dropped;	/* # of msgs discarded due to
						   incoming queue full. */
	uintmax_t st_connection_drop;	/* Existing connections dropped. */
	uintmax_t st_connect_fail;	/* Failed new connection attempts. */
	uint32_t st_elect_threads;	/* # of active election threads. */
	uint32_t st_max_elect_threads;	/* Max concurrent e-threads ever. */
	uint32_t st_site_participants;	/* # of repgroup participant sites. */
	uint32_t st_site_total;	/* # of repgroup total sites. */
	uint32_t st_site_views;	/* # of repgroup view sites. */
	uintmax_t st_takeovers;		/* # of automatic listener takeovers. */
};

/* Replication Manager connection error. */
struct __db_repmgr_conn_err {
	int		eid;		/* Replication Environment ID. */
	int		error;		/* System networking error code. */
};

/*******************************************************
 * Sequences.
 *******************************************************/
/*
 * The storage record for a sequence.
 */
struct __db_seq_record {
	uint32_t	seq_version;	/* Version size/number. */
	uint32_t	flags;		/* DB_SEQ_XXX Flags. */
	db_seq_t	seq_value;	/* Current value. */
	db_seq_t	seq_max;	/* Max permitted. */
	db_seq_t	seq_min;	/* Min permitted. */
};

/*
 * Handle for a sequence object.
 */
struct __db_sequence {
	DB		*seq_dbp;	/* DB handle for this sequence. */
	db_mutex_t	mtx_seq;	/* Mutex if sequence is threaded. */
	DB_SEQ_RECORD	*seq_rp;	/* Pointer to current data. */
	DB_SEQ_RECORD	seq_record;	/* Data from DB_SEQUENCE. */
	uint32_t	seq_cache_size; /* Number of values cached. */
	db_seq_t	seq_last_value;	/* Last value cached. */
	db_seq_t	seq_prev_value;	/* Last value returned. */
	DBT		seq_key;	/* DBT pointing to sequence key. */
	DBT		seq_data;	/* DBT pointing to seq_record. */

	/* API-private structure: used by C++ and Java. */
	void		*api_internal;

	/* DB_SEQUENCE PUBLIC HANDLE LIST BEGIN */
	int		function (DB_SEQUENCE *, uint32_t) close;
	int		function (DB_SEQUENCE *,
			      DB_TXN *, uint32_t, db_seq_t *, uint32_t) get;
	int		function (DB_SEQUENCE *, uint32_t *) get_cachesize;
	int		function (DB_SEQUENCE *, DB **) get_db;
	int		function (DB_SEQUENCE *, uint32_t *) get_flags;
	int		function (DB_SEQUENCE *, DBT *) get_key;
	int		function (DB_SEQUENCE *,
			     db_seq_t *, db_seq_t *) get_range;
	int		function (DB_SEQUENCE *, db_seq_t) initial_value;
	int		function (DB_SEQUENCE *,
			    DB_TXN *, DBT *, uint32_t) open;
	int		function (DB_SEQUENCE *, DB_TXN *, uint32_t) remove;
	int		function (DB_SEQUENCE *, uint32_t) set_cachesize;
	int		function (DB_SEQUENCE *, uint32_t) set_flags;
	int		function (DB_SEQUENCE *, db_seq_t, db_seq_t) set_range;
	int		function (DB_SEQUENCE *,
			    DB_SEQUENCE_STAT **, uint32_t) stat;
	int		function (DB_SEQUENCE *, uint32_t) stat_print;
	/* DB_SEQUENCE PUBLIC HANDLE LIST END */
};

struct __db_seq_stat { /* SHARED */
	uintmax_t st_wait;		/* Sequence lock granted w/o wait. */
	uintmax_t st_nowait;		/* Sequence lock granted after wait. */
	db_seq_t  st_current;		/* Current value in db. */
	db_seq_t  st_value;		/* Current cached value. */
	db_seq_t  st_last_value;	/* Last cached value. */
	db_seq_t  st_min;		/* Minimum value. */
	db_seq_t  st_max;		/* Maximum value. */
	uint32_t st_cache_size;	/* Cache size. */
	uint32_t st_flags;		/* Flag value. */
};

/*******************************************************
 * Access methods.
 *******************************************************/
/*
 * Any new methods need to retain the original numbering.  The type
 * is written in a log record so must be maintained.
 */
enum {
	DB_BTREE=1,
	DB_HASH=2,
	DB_HEAP=6,
	DB_RECNO=3,
	DB_QUEUE=4,
	DB_UNKNOWN=5			/* Figure it out on open. */
}
alias int DBTYPE;

enum	DB_RENAMEMAGIC	= 0x030800;	/* File has been renamed. */

enum	DB_BTREEVERSION	= 10;		/* Current btree version. */
enum	DB_BTREEOLDVER	= 8;		/* Oldest btree version supported. */
enum	DB_BTREEMAGIC	= 0x053162;

enum	DB_HASHVERSION	= 10;		/* Current hash version. */
enum	DB_HASHOLDVER	= 7;		/* Oldest hash version supported. */
enum	DB_HASHMAGIC	= 0x061561;

enum	DB_HEAPVERSION	= 2;		/* Current heap version. */
enum	DB_HEAPOLDVER	= 1;		/* Oldest heap version supported. */
enum	DB_HEAPMAGIC	= 0x074582;

enum	DB_QAMVERSION	= 4;		/* Current queue version. */
enum	DB_QAMOLDVER	= 3;		/* Oldest queue version supported. */
enum	DB_QAMMAGIC	= 0x042253;

enum	DB_SEQUENCE_VERSION = 2;		/* Current sequence version. */
enum	DB_SEQUENCE_OLDVER  = 1;		/* Oldest sequence version supported. */

/*
 * DB access method and cursor operation values.  Each value is an operation
 * code to which additional bit flags are added.
 */
enum	DB_AFTER		 = 1;	/* Dbc.put */
enum	DB_APPEND		 = 2;	/* Db.put */
enum	DB_BEFORE		 = 3;	/* Dbc.put */
enum	DB_CONSUME		 = 4;	/* Db.get */
enum	DB_CONSUME_WAIT		 = 5;	/* Db.get */
enum	DB_CURRENT		 = 6;	/* Dbc.get, Dbc.put, DbLogc.get */
enum	DB_FIRST		 = 7;	/* Dbc.get, DbLogc.get */
enum	DB_GET_BOTH		 = 8;	/* Db.get, Dbc.get */
enum	DB_GET_BOTHC		 = 9;	/* Dbc.get (internal) */
enum	DB_GET_BOTH_RANGE	= 10;	/* Db.get, Dbc.get */
enum	DB_GET_RECNO		= 11;	/* Dbc.get */
enum	DB_JOIN_ITEM		= 12;	/* Dbc.get; don't do primary lookup */
enum	DB_KEYFIRST		= 13;	/* Dbc.put */
enum	DB_KEYLAST		= 14;	/* Dbc.put */
enum	DB_LAST			= 15;	/* Dbc.get, DbLogc.get */
enum	DB_NEXT			= 16;	/* Dbc.get, DbLogc.get */
enum	DB_NEXT_DUP		= 17;	/* Dbc.get */
enum	DB_NEXT_NODUP		= 18;	/* Dbc.get */
enum	DB_NODUPDATA		= 19;	/* Db.put, Dbc.put */
enum	DB_NOOVERWRITE		= 20;	/* Db.put */
enum	DB_OVERWRITE_DUP	= 21;	/* Dbc.put, Db.put; no DB_KEYEXIST */
enum	DB_POSITION		= 22;	/* Dbc.dup */
enum	DB_PREV			= 23;	/* Dbc.get, DbLogc.get */
enum	DB_PREV_DUP		= 24;	/* Dbc.get */
enum	DB_PREV_NODUP		= 25;	/* Dbc.get */
enum	DB_SET			= 26;	/* Dbc.get, DbLogc.get */
enum	DB_SET_RANGE		= 27;	/* Dbc.get */
enum	DB_SET_RECNO		= 28;	/* Db.get, Dbc.get */
enum	DB_UPDATE_SECONDARY	= 29;	/* Dbc.get, Dbc.del (internal) */
enum	DB_SET_LTE		= 30;	/* Dbc.get (internal) */
enum	DB_GET_BOTH_LTE		= 31;	/* Dbc.get (internal) */

/* This has to change when the max opcode hits 255. */
enum	DB_OPFLAGS_MASK	= 0x000000ff;	/* Mask for operations flags. */

/*
 * DB (user visible) error return codes.
 *
 * !!!
 * We don't want our error returns to conflict with other packages where
 * possible, so pick a base error value that's hopefully not common.  We
 * document that we own the error name space from -30,800 to -30,999.
 */
/* DB (public) error return codes. */
enum	DB_BUFFER_SMALL		= -30999;/* User memory too small for return. */
enum	DB_DONOTINDEX		= -30998;/* "Null" return from 2ndary callbk. */
enum	DB_FOREIGN_CONFLICT	= -30997;/* A foreign db constraint triggered. */
enum	DB_HEAP_FULL		= -30996;/* No free space in a heap file. */
enum	DB_KEYEMPTY		= -30995;/* Key/data deleted or never created. */
enum	DB_KEYEXIST		= -30994;/* The key/data pair already exists. */
enum	DB_LOCK_DEADLOCK	= -30993;/* Deadlock. */
enum	DB_LOCK_NOTGRANTED	= -30992;/* Lock unavailable. */
enum	DB_LOG_BUFFER_FULL	= -30991;/* In-memory log buffer full. */
enum	DB_LOG_VERIFY_BAD	= -30990;/* Log verification failed. */
enum	DB_META_CHKSUM_FAIL	= -30968;/* Metadata page checksum failed. */
enum	DB_NOSERVER		= -30989;/* Server panic return. */
enum	DB_NOTFOUND		= -30988;/* Key/data pair not found (EOF). */
enum	DB_OLD_VERSION		= -30987;/* Out-of-date version. */
enum	DB_PAGE_NOTFOUND	= -30986;/* Requested page not found. */
enum	DB_REP_DUPMASTER	= -30985;/* There are two masters. */
enum	DB_REP_HANDLE_DEAD	= -30984;/* Rolled back a commit. */
enum	DB_REP_HOLDELECTION	= -30983;/* Time to hold an election. */
enum	DB_REP_IGNORE		= -30982;/* This msg should be ignored.*/
enum	DB_REP_ISPERM		= -30981;/* Cached not written perm written.*/
enum	DB_REP_JOIN_FAILURE	= -30980;/* Unable to join replication group. */
enum	DB_REP_LEASE_EXPIRED	= -30979;/* Master lease has expired. */
enum	DB_REP_LOCKOUT		= -30978;/* API/Replication lockout now. */
enum	DB_REP_NEWSITE		= -30977;/* New site entered system. */
enum	DB_REP_NOTPERM		= -30976;/* Permanent log record not written. */
enum	DB_REP_UNAVAIL		= -30975;/* Site cannot currently be reached. */
enum	DB_REP_WOULDROLLBACK	= -30974;/* UNDOC: rollback inhibited by app. */
enum	DB_RUNRECOVERY		= -30973;/* Panic return. */
enum	DB_SECONDARY_BAD	= -30972;/* Secondary index corrupt. */
enum	DB_TIMEOUT		= -30971;/* Timed out on read consistency. */
enum	DB_VERIFY_BAD		= -30970;/* Verify failed; bad format. */
enum	DB_VERSION_MISMATCH	= -30969;/* Environment version mismatch. */

/* DB (private) error return codes. */
enum	DB_ALREADY_ABORTED	= -30899;
enum	DB_CHKSUM_FAIL		= -30898;/* Checksum failed. */
enum	DB_DELETED		= -30897;/* Recovery file marked deleted. */
enum	DB_EVENT_NOT_HANDLED	= -30896;/* Forward event to application. */
enum	DB_NEEDSPLIT		= -30895;/* Page needs to be split. */
enum	DB_NOINTMP		= -30886;/* Sequences not supported in temporary
					   or in-memory databases. */
enum	DB_REP_BULKOVF		= -30894;/* Rep bulk buffer overflow. */
enum	DB_REP_LOGREADY		= -30893;/* Rep log ready for recovery. */
enum	DB_REP_NEWMASTER	= -30892;/* We have learned of a new master. */
enum	DB_REP_PAGEDONE		= -30891;/* This page was already done. */
enum	DB_SURPRISE_KID		= -30890;/* Child commit where parent
					   didn't know it was a parent. */
enum	DB_SWAPBYTES		= -30889;/* Database needs byte swapping. */
enum	DB_TXN_CKP		= -30888;/* Encountered ckp record in log. */
enum	DB_VERIFY_FATAL		= -30887;/* DB.verify cannot proceed. */

/*
 * This exit status indicates that a BDB utility failed because it needed a
 * resource which had been held by a process which crashed or otherwise did
 * not exit cleanly.
 */
enum DB_EXIT_FAILCHK		= 3;

/* Database handle. */
struct __db {
	/*******************************************************
	 * Public: owned by the application.
	 *******************************************************/
	uint32_t pgsize;		/* Database logical page size. */
	DB_CACHE_PRIORITY priority;	/* Database priority in cache. */

					/* Callbacks. */
	int function (DB *, DBT *, db_recno_t) db_append_recno;
	void function (DB *, int, int) db_feedback;
	int function (DB *, const (DBT)* , const (DBT)* , size_t *) dup_compare;

	void	*app_private;		/* Application-private handle. */

	/*******************************************************
	 * Private: owned by DB.
	 *******************************************************/
	DB_ENV	*dbenv;			/* Backing public environment. */
	ENV	*env;			/* Backing private environment. */

	DBTYPE	 type;			/* DB access method type. */

	DB_MPOOLFILE *mpf;		/* Backing buffer pool. */

	db_mutex_t mutex;		/* Synchronization for free threading */

	char* fname, dname;		/* File/database passed to DB.open. */
	const (char)* dirname;		/* Directory of DB file. */
	uint32_t open_flags;		/* Flags passed to DB.open. */

	uint8_t fileid[DB_FILE_ID_LEN];/* File's unique ID for locking. */

	uint32_t adj_fileid;		/* File's unique ID for curs. adj. */

	uint32_t blob_threshold;	/* Blob threshold record size. */

	FNAME *log_filename;		/* File's naming info for logging. */

	db_pgno_t meta_pgno;		/* Meta page number */
	DB_LOCKER *locker;		/* Locker for handle locking. */
	DB_LOCKER *cur_locker;		/* Current handle lock holder. */
	DB_TXN *cur_txn;		/* Opening transaction. */
	DB_LOCKER *associate_locker;	/* Locker for DB.associate call. */
	DB_LOCK	 handle_lock;		/* Lock held on this handle. */

	time_t	 timestamp;		/* Handle timestamp for replication. */
	uint32_t fid_gen;		/* Rep generation number for fids. */

	/*
	 * Returned data memory for DB.get() and friends.
	 */
	DBT	 my_rskey;		/* Secondary key. */
	DBT	 my_rkey;		/* [Primary] key. */
	DBT	 my_rdata;		/* Data. */

	/*
	 * !!!
	 * Some applications use DB but implement their own locking outside of
	 * DB.  If they're using fcntl(2) locking on the underlying database
	 * file, and we open and close a file descriptor for that file, we will
	 * discard their locks.  The DB_FCNTL_LOCKING flag to DB.open is an
	 * undocumented interface to support this usage which leaves any file
	 * descriptors we open until DB.close.  This will only work with the
	 * DB.open interface and simple caches, e.g., creating a transaction
	 * thread may open/close file descriptors this flag doesn't protect.
	 * Locking with fcntl(2) on a file that you don't own is a very, very
	 * unsafe thing to do.  'Nuff said.
	 */
	DB_FH	*saved_open_fhp;	/* Saved file handle. */

	/*
	 * Linked list of DBP's, linked from the ENV, used to keep track
	 * of all open db handles for cursor adjustment.
	 *
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_ENTRY(__db) dblistlinks;
	 */
	struct dblistlinks_t {
		__db* tqe_next;
		__db** tqe_prev;
	}
	dblistlinks_t dblistlinks;

	/*
	 * Cursor queues.
	 *
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_HEAD(__cq_fq, __dbc) free_queue;
	 * TAILQ_HEAD(__cq_aq, __dbc) active_queue;
	 * TAILQ_HEAD(__cq_jq, __dbc) join_queue;
	 */
	struct __cq_fq {
		__dbc* tqh_first;
		__dbc** tqh_last;
	}
	__cq_fq free_queue;
	struct __cq_aq {
		__dbc* tqh_first;
		__dbc** tqh_last;
	}
	__cq_aq active_queue;
	struct __cq_jq {
		__dbc* tqh_first;
		__dbc** tqh_last;
	}
	__cq_jq join_queue;

	/*
	 * Secondary index support.
	 *
	 * Linked list of secondary indices -- set in the primary.
	 *
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * LIST_HEAD(s_secondaries, __db);
	 */
	struct s_secondaries_t {
		__db* lh_first;
	}
	s_secondaries_t s_secondaries;

	/*
	 * List entries for secondaries, and reference count of how many
	 * threads are updating this secondary (see Dbc.put).
	 *
	 * !!!
	 * Note that these are synchronized by the primary's mutex, but
	 * filled in in the secondaries.
	 *
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * LIST_ENTRY(__db) s_links;
	 */
	struct s_links_t {
		__db* le_next;
		__db** le_prev;
	}
	s_links_t s_links;
	uint32_t s_refcnt;

	/* Secondary callback and free functions -- set in the secondary. */
	int	function (DB *, const (DBT)* , const (DBT)* , DBT *) s_callback;

	/* Reference to primary -- set in the secondary. */
	DB	*s_primary;


	/* Flags passed to associate -- set in the secondary. */
	uint32_t s_assoc_flags;

	/*
	 * Foreign key support.
	 *
	 * Linked list of primary dbs -- set in the foreign db
	 *
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * LIST_HEAD(f_primaries, __db);
	 */
	struct f_primaries_t {
		__db_foreign_info* lh_first;
	}
	f_primaries_t f_primaries;

	/*
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_ENTRY(__db) felink;
	 *
	 * Links in a list of DBs involved in file extension
	 * during a transaction.  These are to be used only while the
	 * metadata is locked.
	 */
	struct felink_t {
		__db* tqe_next;
		__db** tqe_prev;
	}
	felink_t felink;

	/* Reference to foreign -- set in the secondary. */
	DB      *s_foreign;

	DB		*blob_meta_db;	/* Databases holding blob metadata. */
	DB_SEQUENCE	*blob_seq;	/* Sequence of blob ids. */
	char		*blob_sub_dir;	/* Subdirectory for blob files */
	db_seq_t	blob_file_id;	/* Id of the file blob directory. */
	db_seq_t	blob_sdb_id;	/* Id of the subdb blob directory. */

	/* API-private structure: used by DB 1.85, C++, Java, Perl and Tcl */
	void	*api_internal;

	/* Subsystem-private structure. */
	void	*bt_internal;		/* Btree/Recno access method. */
	void	*h_internal;		/* Hash access method. */
	void	*heap_internal;		/* Heap access method. */
	void	*p_internal;		/* Partition informaiton. */
	void	*q_internal;		/* Queue access method. */

	/* DB PUBLIC HANDLE LIST BEGIN */
	int  function (DB *, DB_TXN *, DB *,
		int function(DB *, const (DBT)* , const (DBT)* , DBT *), uint32_t) associate;
	int  function (DB *, DB *,
		int function(DB *, const (DBT)* , DBT *, const (DBT)* , int *),
		uint32_t) associate_foreign;
	int  function (DB *, uint32_t) close;
	int  function (DB *,
		DB_TXN *, DBT *, DBT *, DB_COMPACT *, uint32_t, DBT *) compact;
	int  function (DB *, DB_TXN *, DBC **, uint32_t) cursor;
	int  function (DB *, DB_TXN *, DBT *, uint32_t) del;
	void function (DB *, int, const (char)* , ...) err;
	void function (DB *, const (char)* , ...) errx;
	int  function (DB *, DB_TXN *, DBT *, uint32_t) exists;
	int  function (DB *, int *) fd;
	int  function (DB *, DB_TXN *, DBT *, DBT *, uint32_t) get;
	int  function (DB *, void *function(size_t)*,
		void *function(void *, size_t)*, void function(void *)*) get_alloc;
	int  function (DB *, int function(DB *, DBT *, db_recno_t)*) get_append_recno;
	int  function (DB *, uint32_t *) get_assoc_flags;
	int  function (DB *, const (char)* *) get_blob_dir;
	int  function (DB *, const (char)* *) get_blob_sub_dir;
	int  function (DB *, uint32_t *) get_blob_threshold;
	int  function
		(DB *, int function(DB *, const (DBT)* , const (DBT)* , size_t *)*) get_bt_compare;
	int  function (DB *,
		int function(DB *,
		const (DBT)* , const (DBT)* , const (DBT)* , const (DBT)* , DBT *),
		int function(DB *, const (DBT)* , const (DBT)* , DBT *, DBT *, DBT *)*) get_bt_compress;
	int  function (DB *, uint32_t *) get_bt_minkey;
	int  function
		(DB *, size_t function(DB *, const (DBT)* , const (DBT)* )*) get_bt_prefix;
	int  function (DB *, int *) get_byteswapped;
	int  function (DB *, uint32_t *, uint32_t *, int *) get_cachesize;
	int  function (DB *, const (char)* *) get_create_dir;
	int  function (DB *, const (char)* *, const (char)* *) get_dbname;
	int  function
		(DB *, int function(DB *, const (DBT)* , const (DBT)* , size_t *)*) get_dup_compare;
	int  function (DB *, uint32_t *) get_encrypt_flags;
	DB_ENV *function (DB *) get_env;
	void function (DB *,
		void function(const (DB_ENV)* , const (char)* , const (char)* )*) get_errcall;
	void function (DB *, FILE **) get_errfile;
	void function (DB *, const (char)* *) get_errpfx;
	int  function (DB *, void function(DB *, int, int)*) get_feedback;
	int  function (DB *, uint32_t *) get_flags;
	int  function
		(DB *, int function(DB *, const (DBT)* , const (DBT)* , size_t *)*) get_h_compare;
	int  function (DB *, uint32_t *) get_h_ffactor;
	int  function
		(DB *, uint32_t function(DB *, const (void)* , uint32_t)*) get_h_hash;
	int  function (DB *, uint32_t *) get_h_nelem;
	int  function (DB *, uint32_t *, uint32_t *) get_heapsize;
	int  function (DB *, uint32_t *) get_heap_regionsize;
	int  function (DB *, int *, int *) get_lk_exclusive;
	int  function (DB *, int *) get_lorder;
	DB_MPOOLFILE *function (DB *) get_mpf;
	void function (DB *,
	    void function(const (DB_ENV)* , const (char)* )*) get_msgcall;
	void function (DB *, FILE **) get_msgfile;
	int  function (DB *) get_multiple;
	int  function (DB *, uint32_t *) get_open_flags;
	int  function (DB *, uint32_t *) get_pagesize;
	int  function (DB *,
		uint32_t *, uint32_t function(DB *, DBT *key)*) get_partition_callback;
	int  function (DB *, const (char)* **) get_partition_dirs;
	int  function (DB *, uint32_t *, DBT **) get_partition_keys;
	int  function (DB *, DB_CACHE_PRIORITY *) get_priority;
	int  function (DB *, uint32_t *) get_q_extentsize;
	int  function (DB *, int *) get_re_delim;
	int  function (DB *, uint32_t *) get_re_len;
	int  function (DB *, int *) get_re_pad;
	int  function (DB *, const (char)* *) get_re_source;
	int  function (DB *) get_transactional;
	int  function (DB *, DBTYPE *) get_type;
	int  function (DB *, DBC **, DBC **, uint32_t) join;
	int  function
		(DB *, DB_TXN *, DBT *, DB_KEY_RANGE *, uint32_t) key_range;
	int  function (DB *,
		DB_TXN *, const (char)* , const (char)* , DBTYPE, uint32_t, int) open;
	int  function (DB *, DB_TXN *, DBT *, DBT *, DBT *, uint32_t) pget;
	int  function (DB *, DB_TXN *, DBT *, DBT *, uint32_t) put;
	int  function (DB *, const (char)* , const (char)* , uint32_t) remove;
	int  function (DB *,
		const (char)* , const (char)* , const (char)* , uint32_t) rename;
	int  function (DB *, void *function(size_t),
		void *function(void *, size_t), void function(void *)) set_alloc;
	int  function (DB *, int function(DB *, DBT *, db_recno_t)) set_append_recno;
	int  function (DB *, const (char)* ) set_blob_dir;
	int  function (DB *, uint32_t, uint32_t) set_blob_threshold;
	int  function
		(DB *, int function(DB *, const (DBT)* , const (DBT)* , size_t *)) set_bt_compare;
	int  function (DB *,
		int function(DB *, const (DBT)* , const (DBT)* , const (DBT)* , const (DBT)* , DBT *),
		int function(DB *, const (DBT)* , const (DBT)* , DBT *, DBT *, DBT *)) set_bt_compress;
	int  function (DB *, uint32_t) set_bt_minkey;
	int  function
		(DB *, size_t function(DB *, const (DBT)* , const (DBT)* )) set_bt_prefix;
	int  function (DB *, uint32_t, uint32_t, int) set_cachesize;
	int  function (DB *, const (char)* ) set_create_dir;
	int  function
		(DB *, int function(DB *, const (DBT)* , const (DBT)* , size_t *)) set_dup_compare;
	int  function (DB *, const (char)* , uint32_t) set_encrypt;
	void function (DB *,
		void function(const (DB_ENV)* , const (char)* , const (char)* )) set_errcall;
	void function (DB *, FILE *) set_errfile;
	void function (DB *, const (char)* ) set_errpfx;
	int  function (DB *, void function(DB *, int, int)) set_feedback;
	int  function (DB *, uint32_t) set_flags;
	int  function
		(DB *, int function(DB *, const (DBT)* , const (DBT)* , size_t *)) set_h_compare;
	int  function (DB *, uint32_t) set_h_ffactor;
	int  function
		(DB *, uint32_t function(DB *, const (void)* , uint32_t)) set_h_hash;
	int  function (DB *, uint32_t) set_h_nelem;
	int  function (DB *, uint32_t, uint32_t, uint32_t) set_heapsize;
	int  function (DB *, uint32_t) set_heap_regionsize;
	int  function (DB *, int) set_lk_exclusive;
	int  function (DB *, int) set_lorder;
	void function (DB *, void function(const (DB_ENV)* , const (char)* )) set_msgcall;
	void function (DB *, FILE *) set_msgfile;
	int  function (DB *, uint32_t) set_pagesize;
	int  function (DB *, void function(DB_ENV *, int)) set_paniccall;
	int  function (DB *,
		uint32_t, DBT *, uint32_t function(DB *, DBT *key)) set_partition;
	int  function (DB *, const (char)* *) set_partition_dirs;
	int  function (DB *, DB_CACHE_PRIORITY) set_priority;
	int  function (DB *, uint32_t) set_q_extentsize;
	int  function (DB *, int) set_re_delim;
	int  function (DB *, uint32_t) set_re_len;
	int  function (DB *, int) set_re_pad;
	int  function (DB *, const (char)* ) set_re_source;
	int  function (DB *, DBT *, DBT *, uint32_t) sort_multiple;
	int  function (DB *, DB_TXN *, void *, uint32_t) stat;
	int  function (DB *, uint32_t) stat_print;
	int  function (DB *, uint32_t) sync;
	int  function (DB *, DB_TXN *, uint32_t *, uint32_t) truncate;
	int  function (DB *, const (char)* , uint32_t) upgrade;
	int  function
		(DB *, const (char)* , const (char)* , FILE *, uint32_t) verify;
	/* DB PUBLIC HANDLE LIST END */

	/* DB PRIVATE HANDLE LIST BEGIN */
	int  function (DB *, const (char)* ,
		int function(void *, const (void)* ), void *, int, int) dump;
	int  function (DB *, DB_THREAD_INFO *,
		DB_TXN *, const (char)* , const (char)* , uint32_t) db_am_remove;
	int  function (DB *, DB_THREAD_INFO *,
		DB_TXN *, const (char)* , const (char)* , const (char)* ) db_am_rename;
	/* DB PRIVATE HANDLE LIST END */

	/*
	 * Never called; these are a place to save function pointers
	 * so that we can undo an associate.
	 */
	int  function (DB *, DB_TXN *, DBT *, DBT *, uint32_t) stored_get;
	int  function (DB *, uint32_t) stored_close;

	/* Alternative handle close function, used by C++ API. */
	int  function (DB *, uint32_t) alt_close;

	uint32_t	am_ok;		/* Legal AM choices. */

	/*
	 * This field really ought to be an AM_FLAG, but we have
	 * have run out of bits.  If/when we decide to split up
	 * the flags, we can incorporate it.
	 */
	int	 preserve_fid;		/* Do not free fileid on close. */

	uint32_t orig_flags;		   /* Flags at  open, for refresh */
	uint32_t flags;

	uint32_t flags2;		   /* Second flags word */
};

enum	DB_LOGFILEID_INVALID	= -1;
enum	DB_ASSOC_IMMUTABLE_KEY    = 0x00000001; /* Secondary key is immutable. */
enum	DB_ASSOC_CREATE    = 0x00000002; /* Secondary db populated on open. */
enum	DB_OK_BTREE	= 0x01;
enum	DB_OK_HASH	= 0x02;
enum	DB_OK_HEAP	= 0x04;
enum	DB_OK_QUEUE	= 0x08;
enum	DB_OK_RECNO	= 0x10;
enum	DB_AM_CHKSUM		= 0x00000001; /* Checksumming */
enum	DB_AM_COMPENSATE	= 0x00000002; /* Created by compensating txn */
enum	DB_AM_COMPRESS		= 0x00000004; /* Compressed BTree */
enum	DB_AM_CREATED		= 0x00000008; /* Database was created upon open */
enum	DB_AM_CREATED_MSTR	= 0x00000010; /* Encompassing file was created */
enum	DB_AM_DBM_ERROR		= 0x00000020; /* Error in DBM/NDBM database */
enum	DB_AM_DELIMITER		= 0x00000040; /* Variable length delimiter set */
enum	DB_AM_DISCARD		= 0x00000080; /* Discard any cached pages */
enum	DB_AM_DUP		= 0x00000100; /* DB_DUP */
enum	DB_AM_DUPSORT		= 0x00000200; /* DB_DUPSORT */
enum	DB_AM_ENCRYPT		= 0x00000400; /* Encryption */
enum	DB_AM_FIXEDLEN		= 0x00000800; /* Fixed-length records */
enum	DB_AM_INMEM		= 0x00001000; /* In-memory; no sync on close */
enum	DB_AM_INORDER		= 0x00002000; /* DB_INORDER */
enum	DB_AM_NOT_DURABLE	= 0x00008000; /* Do not log changes */
enum	DB_AM_OPEN_CALLED	= 0x00010000; /* DB.open called */
enum	DB_AM_PAD		= 0x00020000; /* Fixed-length record pad */
enum	DB_AM_PARTDB		= 0x00040000; /* Handle for a database partition */
enum	DB_AM_PGDEF		= 0x00080000; /* Page size was defaulted */
enum	DB_AM_RDONLY		= 0x00100000; /* Database is readonly */
enum	DB_AM_READ_UNCOMMITTED	= 0x00200000; /* Support degree 1 isolation */
enum	DB_AM_RECNUM		= 0x00400000; /* DB_RECNUM */
enum	DB_AM_RECOVER		= 0x00800000; /* DB opened by recovery routine */
enum	DB_AM_RENUMBER		= 0x01000000; /* DB_RENUMBER */
enum	DB_AM_REVSPLITOFF	= 0x02000000; /* DB_REVSPLITOFF */
enum	DB_AM_SECONDARY		= 0x04000000; /* Database is a secondary index */
enum	DB_AM_SNAPSHOT		= 0x08000000; /* DB_SNAPSHOT */
enum	DB_AM_SUBDB		= 0x10000000; /* Subdatabases supported */
enum	DB_AM_SWAP		= 0x20000000; /* Pages need to be byte-swapped */
enum	DB_AM_TXN		= 0x40000000; /* Opened in a transaction */
enum	DB_AM_VERIFYING		= 0x80000000; /* DB handle is in the verifier */
enum	DB2_AM_EXCL		= 0x00000001; /* Exclusively lock the handle */ 
enum	DB2_AM_INTEXCL		= 0x00000002; /* Internal exclusive lock. */
enum	DB2_AM_NOWAIT		= 0x00000004; /* Do not wait for handle lock */ 

/* 
 * Stream interface for blob files.
 */
struct __db_stream {
	DBC		*dbc;	/* Cursor pointing to the db blob record. */
	DB_FH		*fhp;

	/* DB_STREAM PUBLIC HANDLE LIST BEGIN */
	int  function (DB_STREAM *, uint32_t) close;
	int  function (DB_STREAM *, DBT *, db_off_t, uint32_t, uint32_t) read;
	int  function (DB_STREAM *, db_off_t *, uint32_t) size;
	int  function (DB_STREAM *, DBT *, db_off_t, uint32_t) write;
	/* DB_STREAM PUBLIC HANDLE LIST END */

	uint32_t	flags;
	db_seq_t	blob_id;
	db_off_t	file_size;
};

enum	DB_STREAM_READ		= 0x00000001; /* Stream is read only. */
enum	DB_STREAM_WRITE		= 0x00000002; /* Stream is writeable. */
enum	DB_STREAM_SYNC_WRITE	= 0x00000004; /* Sync file on each write. */

/*
 * Macros for bulk operations.  These are only intended for the C API.
 * For C++, use DbMultiple*Iterator or DbMultiple*Builder.
 *
 * Bulk operations store multiple entries into a single DBT structure. The
 * following macros assist with creating and reading these Multiple DBTs.
 *
 * The basic layout for single data items is:
 *
 * -------------------------------------------------------------------------
 * | data1 | ... | dataN | ..... |-1 | dNLen | dNOff | ... | d1Len | d1Off |
 * -------------------------------------------------------------------------
 *
 * For the DB_MULTIPLE_KEY* macros, the items are in key/data pairs, so data1
 * would be a key, and data2 its corresponding value (N is always even).
 *
 * For the DB_MULTIPLE_RECNO* macros, the record number is stored along with
 * the len/off pair in the "header" section, and the list is zero terminated
 * (since -1 is a valid record number):
 *
 * --------------------------------------------------------------------------
 * | d1 |..| dN |..| 0 | dNLen | dNOff | recnoN |..| d1Len | d1Off | recno1 |
 * --------------------------------------------------------------------------
 */
auto DB_MULTIPLE_INIT(T, U)(T pointer, U dbt)
{
	return pointer = cast(uint8_t)(dbt).data +
	    (dbt).ulen - uint32_t.sizeof;
}


auto DB_MULTIPLE_NEXT(T, U, Q, R)(T pointer, U dbt, Q retdata, R retdlen)
{
	do {
		uint32_t *__p = cast(uint32_t)(pointer);
		if (*__p == cast(uint32_t)-1) {
			retdata = null;
			pointer = null;
			break;
		}
		retdata = cast(uint8_t)(dbt).data + *__p--;
		retdlen = *__p--;
		pointer = __p;
		if (retdlen == 0 && retdata == cast(uint8_t)(dbt).data)
			retdata = null;
	} while (0);
}


auto DB_MULTIPLE_KEY_NEXT(T, U, Q, R, S, )(T pointer, U dbt, Q retkey, R retklen, S retdata,  retdlen)
{
	do {
		uint32_t *__p = cast(uint32_t)(pointer);
		if (*__p == cast(uint32_t)-1) {
			retdata = null;
			retkey = null;
			pointer = null;
			break;
		}
		retkey = cast(uint8_t)(dbt).data + *__p--;
		retklen = *__p--;
		retdata = cast(uint8_t)(dbt).data + *__p--;
		retdlen = *__p--;
		pointer = __p;
	} while (0);
}


auto DB_MULTIPLE_RECNO_NEXT(T, U, Q, R, S)(T pointer, U dbt, Q recno, R retdata, S retdlen)
{
	do {
		uint32_t *__p = cast(uint32_t)(pointer);
		if (*__p == cast(uint32_t)0) {
			recno = 0;
			retdata = null;
			pointer = null;
			break;
		}
		recno = *__p--;
		retdata = cast(uint8_t)(dbt).data + *__p--;
		retdlen = *__p--;
		pointer = __p;
	} while (0);
}


auto DB_MULTIPLE_WRITE_INIT(T, U)(T pointer, U dbt)
{
	do {
		(dbt).flags |= DB_DBT_BULK;
		pointer = cast(uint8_t)(dbt).data +
		    (dbt).ulen - uint32_t.sizeof;
		*cast(uint32_t)(pointer) = cast(uint32_t)-1;
	} while (0);
}


auto DB_MULTIPLE_RESERVE_NEXT(T, U, Q, R)(T pointer, U dbt, Q writedata, R writedlen)
{
	do {
		uint32_t *__p = cast(uint32_t)(pointer);
		uint32_t __off = ((pointer) ==	cast(uint8_t)(dbt).data +
		    (dbt).ulen - uint32_t.sizeof) ?  0 : __p[1] + __p[2];
		if (cast(uint8_t)(dbt).data + __off + (writedlen) >
		    cast(uint8_t)(__p - 2))
			writedata = null;
		else {
			writedata = cast(uint8_t)(dbt).data + __off;
			__p[0] = __off;
			__p[-1] = cast(uint32_t)(writedlen);
			__p[-2] = cast(uint32_t)-1;
			pointer = __p - 2;
		}
	} while (0);
}


auto DB_MULTIPLE_WRITE_NEXT(T, U, Q, R)(T pointer, U dbt, Q writedata, R writedlen)
{
	do {
		void *__destd;
		DB_MULTIPLE_RESERVE_NEXT((pointer), (dbt),
		    __destd, (writedlen));
		if (__destd == null)
			pointer = null;
		else
			memcpy(__destd, (writedata), (writedlen));
	} while (0);
}


auto DB_MULTIPLE_KEY_RESERVE_NEXT(T, U, Q, R, S, )(T pointer, U dbt, Q writekey, R writeklen, S writedata,  writedlen)
{
	do {
		uint32_t *__p = cast(uint32_t)(pointer);
		uint32_t __off = ((pointer) == cast(uint8_t)(dbt).data +
		    (dbt).ulen - uint32_t.sizeof) ?  0 : __p[1] + __p[2];
		if (cast(uint8_t)(dbt).data + __off + (writeklen) +
		    (writedlen) > cast(uint8_t)(__p - 4)) {
			writekey = null;
			writedata = null;
		} else {
			writekey = cast(uint8_t)(dbt).data + __off;
			__p[0] = __off;
			__p[-1] = cast(uint32_t)(writeklen);
			__p -= 2;
			__off += cast(uint32_t)(writeklen);
			writedata = cast(uint8_t)(dbt).data + __off;
			__p[0] = __off;
			__p[-1] = cast(uint32_t)(writedlen);
			__p[-2] = cast(uint32_t)-1;
			pointer = __p - 2;
		}
	} while (0);
}


auto DB_MULTIPLE_KEY_WRITE_NEXT(T, U, Q, R, S, )(T pointer, U dbt, Q writekey, R writeklen, S writedata,  writedlen)
{
	do {
		void* __destk, __destd;
		DB_MULTIPLE_KEY_RESERVE_NEXT((pointer), (dbt),
		    __destk, (writeklen), __destd, (writedlen));
		if (__destk == null)
			pointer = null;
		else {
			memcpy(__destk, (writekey), (writeklen));
			if (__destd != null)
				memcpy(__destd, (writedata), (writedlen));
		}
	} while (0);
}


auto DB_MULTIPLE_RECNO_WRITE_INIT(T, U)(T pointer, U dbt)
{
	do {
		(dbt).flags |= DB_DBT_BULK;
		pointer = cast(uint8_t)(dbt).data +
		    (dbt).ulen - uint32_t.sizeof;
		*cast(uint32_t)(pointer) = 0;
	} while (0);
}


auto DB_MULTIPLE_RECNO_RESERVE_NEXT(T, U, Q, R, S)(T pointer, U dbt, Q recno, R writedata, S writedlen)
{
	do {
		uint32_t *__p = cast(uint32_t)(pointer);
		uint32_t __off = ((pointer) == cast(uint8_t)(dbt).data +
		    (dbt).ulen - uint32_t.sizeof) ? 0 : __p[1] + __p[2];
		if ((cast(uint8_t)(dbt).data + __off) + (writedlen) >
		    cast(uint8_t)(__p - 3))
			writedata = null;
		else {
			writedata = cast(uint8_t)(dbt).data + __off;
			__p[0] = cast(uint32_t)(recno);
			__p[-1] = __off;
			__p[-2] = cast(uint32_t)(writedlen);
			__p[-3] = 0;
			pointer = __p - 3;
		}
	} while (0);
}


auto DB_MULTIPLE_RECNO_WRITE_NEXT(T, U, Q, R, S)(T pointer, U dbt, Q recno, R writedata, S writedlen)
{
	do {
		void *__destd;
		DB_MULTIPLE_RECNO_RESERVE_NEXT((pointer), (dbt),
		    (recno), __destd, (writedlen));
		if (__destd == null)
			pointer = null;
		else if ((writedlen) != 0)
			memcpy(__destd, (writedata), (writedlen));
	} while (0);
}


struct __db_heap_rid {
	db_pgno_t pgno;			/* Page number. */
	db_indx_t indx;			/* Index in the offset table. */
};
enum DB_HEAP_RID_SZ	= db_pgno_t.sizeof + db_indx_t.sizeof;

/*******************************************************
 * Access method cursors.
 *******************************************************/
struct __dbc {
	DB *dbp;			/* Backing database */
	DB_ENV *dbenv;			/* Backing environment */
	ENV *env;			/* Backing environment */

	DB_THREAD_INFO *thread_info;	/* Thread that owns this cursor. */
	DB_TXN	 *txn;			/* Associated transaction. */
	DB_CACHE_PRIORITY priority;	/* Priority in cache. */

	/*
	 * Active/free cursor queues.
	 *
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_ENTRY(__dbc) links;
	 */
	struct links_t {
		DBC *tqe_next;
		DBC **tqe_prev;
	}
	links_t links;

	/*
	 * Cursor queue of the owning transaction.
	 *
	 * !!!
	 * Explicit representations of structures from queue.h.
	 * TAILQ_ENTRY(__dbc) txn_cursors;
	 */
	struct txn_cursors_t {
		DBC *tqe_next;	/* next element */
		DBC **tqe_prev;	/* address of previous next element */
	}
	txn_cursors_t txn_cursors;

	/*
	 * The DBT *'s below are used by the cursor routines to return
	 * data to the user when DBT flags indicate that DB should manage
	 * the returned memory.  They point at a DBT containing the buffer
	 * and length that will be used, and "belonging" to the handle that
	 * should "own" this memory.  This may be a "my_*" field of this
	 * cursor--the default--or it may be the corresponding field of
	 * another cursor, a DB handle, a join cursor, etc.  In general, it
	 * will be whatever handle the user originally used for the current
	 * DB interface call.
	 */
	DBT	 *rskey;		/* Returned secondary key. */
	DBT	 *rkey;			/* Returned [primary] key. */
	DBT	 *rdata;		/* Returned data. */

	DBT	  my_rskey;		/* Space for returned secondary key. */
	DBT	  my_rkey;		/* Space for returned [primary] key. */
	DBT	  my_rdata;		/* Space for returned data. */

	DB_LOCKER *lref;		/* Reference to default locker. */
	DB_LOCKER *locker;		/* Locker for this operation. */
	DBT	  lock_dbt;		/* DBT referencing lock. */
	DB_LOCK_ILOCK lock;		/* Object to be locked. */
	DB_LOCK	  mylock;		/* CDB lock held on this cursor. */

	DBTYPE	  dbtype;		/* Cursor type. */

	DBC_INTERNAL *internal;		/* Access method private. */

	/* DBC PUBLIC HANDLE LIST BEGIN */
	int function (DBC *) close;
	int function (DBC *, DBC *, int *, uint32_t) cmp;
	int function (DBC *, db_recno_t *, uint32_t) count;
	int function (DBC *, DB_STREAM **, uint32_t) db_stream;
	int function (DBC *, uint32_t) del;
	int function (DBC *, DBC **, uint32_t) dup;
	int function (DBC *, DBT *, DBT *, uint32_t) get;
	int function (DBC *, DB_CACHE_PRIORITY *) get_priority;
	int function (DBC *, DBT *, DBT *, DBT *, uint32_t) pget;
	int function (DBC *, DBT *, DBT *, uint32_t) put;
	int function (DBC *, DB_CACHE_PRIORITY) set_priority;
	/* DBC PUBLIC HANDLE LIST END */

	/* The following are the method names deprecated in the 4.6 release. */
	int function (DBC *) c_close;
	int function (DBC *, db_recno_t *, uint32_t) c_count;
	int function (DBC *, uint32_t) c_del;
	int function (DBC *, DBC **, uint32_t) c_dup;
	int function (DBC *, DBT *, DBT *, uint32_t) c_get;
	int function (DBC *, DBT *, DBT *, DBT *, uint32_t) c_pget;
	int function (DBC *, DBT *, DBT *, uint32_t) c_put;

	/* DBC PRIVATE HANDLE LIST BEGIN */
	int function (DBC *, DBT *, uint32_t) am_bulk;
	int function (DBC *, db_pgno_t, int *) am_close;
	int function (DBC *, uint32_t) am_del;
	int function (DBC *) am_destroy;
	int function (DBC *, DBT *, DBT *, uint32_t, db_pgno_t *) am_get;
	int function (DBC *, DBT *, DBT *, uint32_t, db_pgno_t *) am_put;
	int function (DBC *) am_writelock;
	/* DBC PRIVATE HANDLE LIST END */

/*
 * DBC_DONTLOCK and DBC_RECOVER are used during recovery and transaction
 * abort.  If a transaction is being aborted or recovered then DBC_RECOVER
 * will be set and locking and logging will be disabled on this cursor.  If
 * we are performing a compensating transaction (e.g. free page processing)
 * then DB_DONTLOCK will be set to inhibit locking, but logging will still
 * be required. DB_DONTLOCK is also used if the whole database is locked.
 */
	uint32_t flags;
};

enum	DBC_ACTIVE		= 0x00001;	/* Cursor in use. */
enum	DBC_BULK		= 0x00002;	/* Bulk update cursor. */
enum	DBC_DONTLOCK		= 0x00004;	/* Don't lock on this cursor. */
enum	DBC_DOWNREV		= 0x00008;	/* Down rev replication master. */
enum	DBC_DUPLICATE		= 0x00010;	/* Create a duplicate cursor. */
enum	DBC_ERROR		= 0x00020;	/* Error in this request. */
enum	DBC_FAMILY		= 0x00040; /* Part of a locker family. */
enum	DBC_FROM_DB_GET		= 0x00080; /* Called from the DB.get() method. */
enum	DBC_MULTIPLE		= 0x00100;	/* Return Multiple data. */
enum	DBC_MULTIPLE_KEY	= 0x00200;	/* Return Multiple keys and data. */
enum	DBC_OPD			= 0x00400;	/* Cursor references off-page dups. */
enum	DBC_OWN_LID		= 0x00800;	/* Free lock id on destroy. */
enum	DBC_PARTITIONED		= 0x01000;	/* Cursor for a partitioned db. */
enum	DBC_READ_COMMITTED	= 0x02000;	/* Cursor has degree 2 isolation. */
enum	DBC_READ_UNCOMMITTED	= 0x04000;	/* Cursor has degree 1 isolation. */
enum	DBC_RECOVER		= 0x08000;	/* Recovery cursor; don't log/lock. */
enum	DBC_RMW			= 0x10000;	/* Acquire write flag in read op. */
enum	DBC_TRANSIENT		= 0x20000;	/* Cursor is transient. */
enum	DBC_WAS_READ_COMMITTED	= 0x40000;	/* Cursor holds a read commited lock. */
enum	DBC_WRITECURSOR		= 0x80000;	/* Cursor may be used to write (CDB). */
enum	DBC_WRITER	       = 0x100000;	/* Cursor immediately writing (CDB). */

/* Key range statistics structure */
struct __key_range {
	double less;
	double equal;
	double greater;
};

/* Btree/Recno statistics structure. */
struct __db_bt_stat { /* SHARED */
	uint32_t bt_magic;		/* Magic number. */
	uint32_t bt_version;		/* Version number. */
	uint32_t bt_metaflags;		/* Metadata flags. */
	uint32_t bt_nkeys;		/* Number of unique keys. */
	uint32_t bt_ndata;		/* Number of data items. */
	uint32_t bt_pagecnt;		/* Page count. */
	uint32_t bt_pagesize;		/* Page size. */
	uint32_t bt_minkey;		/* Minkey value. */
	uint32_t bt_nblobs;		/* Number of blobs. */
	uint32_t bt_re_len;		/* Fixed-length record length. */
	uint32_t bt_re_pad;		/* Fixed-length record pad. */
	uint32_t bt_levels;		/* Tree levels. */
	uint32_t bt_int_pg;		/* Internal pages. */
	uint32_t bt_leaf_pg;		/* Leaf pages. */
	uint32_t bt_dup_pg;		/* Duplicate pages. */
	uint32_t bt_over_pg;		/* Overflow pages. */
	uint32_t bt_empty_pg;		/* Empty pages. */
	uint32_t bt_free;		/* Pages on the free list. */
	uintmax_t bt_int_pgfree;	/* Bytes free in internal pages. */
	uintmax_t bt_leaf_pgfree;	/* Bytes free in leaf pages. */
	uintmax_t bt_dup_pgfree;	/* Bytes free in duplicate pages. */
	uintmax_t bt_over_pgfree;	/* Bytes free in overflow pages. */
};

struct __db_compact {
	/* Input Parameters. */
	uint32_t	compact_fillpercent;	/* Desired fillfactor: 1-100 */
	db_timeout_t	compact_timeout;	/* Lock timeout. */
	uint32_t	compact_pages;		/* Max pages to process. */
	/* Output Stats. */
	uint32_t	compact_empty_buckets;	/* Empty hash buckets found. */
	uint32_t	compact_pages_free;	/* Number of pages freed. */
	uint32_t	compact_pages_examine;	/* Number of pages examine. */
	uint32_t	compact_levels;		/* Number of levels removed. */
	uint32_t	compact_deadlock;	/* Number of deadlocks. */
	db_pgno_t	compact_pages_truncated; /* Pages truncated to OS. */
	/* Internal. */
	db_pgno_t	compact_truncate;	/* Exchange pages above here. */
};

/* Hash statistics structure. */
struct __db_h_stat { /* SHARED */
	uint32_t hash_magic;		/* Magic number. */
	uint32_t hash_version;		/* Version number. */
	uint32_t hash_metaflags;	/* Metadata flags. */
	uint32_t hash_nkeys;		/* Number of unique keys. */
	uint32_t hash_ndata;		/* Number of data items. */
	uint32_t hash_nblobs;		/* Number of blobs. */
	uint32_t hash_pagecnt;		/* Page count. */
	uint32_t hash_pagesize;	/* Page size. */
	uint32_t hash_ffactor;		/* Fill factor specified at create. */
	uint32_t hash_buckets;		/* Number of hash buckets. */
	uint32_t hash_free;		/* Pages on the free list. */
	uintmax_t hash_bfree;		/* Bytes free on bucket pages. */
	uint32_t hash_bigpages;	/* Number of big key/data pages. */
	uintmax_t hash_big_bfree;	/* Bytes free on big item pages. */
	uint32_t hash_overflows;	/* Number of overflow pages. */
	uintmax_t hash_ovfl_free;	/* Bytes free on ovfl pages. */
	uint32_t hash_dup;		/* Number of dup pages. */
	uintmax_t hash_dup_free;	/* Bytes free on duplicate pages. */
};

/* Heap statistics structure. */
struct __db_heap_stat { /* SHARED */
	uint32_t heap_magic;		/* Magic number. */
	uint32_t heap_version;		/* Version number. */
	uint32_t heap_metaflags;	/* Metadata flags. */
	uint32_t heap_nblobs;		/* Number of blobs. */
	uint32_t heap_nrecs;		/* Number of records. */
	uint32_t heap_pagecnt;		/* Page count. */
	uint32_t heap_pagesize;	/* Page size. */
	uint32_t heap_nregions;	/* Number of regions. */
	uint32_t heap_regionsize;	/* Number of pages in a region. */
};

/* Queue statistics structure. */
struct __db_qam_stat { /* SHARED */
	uint32_t qs_magic;		/* Magic number. */
	uint32_t qs_version;		/* Version number. */
	uint32_t qs_metaflags;		/* Metadata flags. */
	uint32_t qs_nkeys;		/* Number of unique keys. */
	uint32_t qs_ndata;		/* Number of data items. */
	uint32_t qs_pagesize;		/* Page size. */
	uint32_t qs_extentsize;	/* Pages per extent. */
	uint32_t qs_pages;		/* Data pages. */
	uint32_t qs_re_len;		/* Fixed-length record length. */
	uint32_t qs_re_pad;		/* Fixed-length record pad. */
	uint32_t qs_pgfree;		/* Bytes free in data pages. */
	uint32_t qs_first_recno;	/* First not deleted record. */
	uint32_t qs_cur_recno;		/* Next available record number. */
};

/*******************************************************
 * Environment.
 *******************************************************/
enum	DB_REGION_MAGIC	= 0x120897;	/* Environment magic number. */

/*
 * Database environment structure.
 *
 * This is the public database environment handle.  The private environment
 * handle is the ENV structure.   The user owns this structure, the library
 * owns the ENV structure.  The reason there are two structures is because
 * the user's configuration outlives any particular DB_ENV.open call, and
 * separate structures allows us to easily discard internal information without
 * discarding the user's configuration.
 *
 * Fields in the DB_ENV structure should normally be set only by application
 * DB_ENV handle methods.
 */

/*
 * Memory configuration types.
 */
enum {
	DB_MEM_LOCK=1,
	DB_MEM_LOCKOBJECT=2,
	DB_MEM_LOCKER=3,
	DB_MEM_LOGID=4,
	DB_MEM_TRANSACTION=5,
	DB_MEM_THREAD=6
}
alias int DB_MEM_CONFIG;

/*
 * Backup configuration types.
 */
enum {
	DB_BACKUP_READ_COUNT=1,
	DB_BACKUP_READ_SLEEP=2,
	DB_BACKUP_SIZE=3,
	DB_BACKUP_WRITE_DIRECT=4
}
alias int DB_BACKUP_CONFIG;

struct __db_env {
	ENV *env;			/* Linked ENV structure */

					/* Error message callback */
	void function (const (DB_ENV)* , const (char)* , const (char)* ) db_errcall;
	FILE		*db_errfile;	/* Error message file stream */
	const char	*db_errpfx;	/* Error message prefix */

					/* Other message callback */
	void function (const (DB_ENV)* , const (char)* ) db_msgcall;
	FILE		*db_msgfile;	/* Other message file stream */

	/* Other application callback functions */
	int   function (DB_ENV *, DBT *, DB_LSN *, db_recops) app_dispatch;
	void  function (DB_ENV *, uint32_t, void *) db_event_func;
	void  function (DB_ENV *, int, int) db_feedback;
	void  function (void *) db_free;
	void  function (DB_ENV *, int) db_paniccall;
	void *function (size_t) db_malloc;
	void *function (void *, size_t) db_realloc;
	int   function (DB_ENV *, pid_t, db_threadid_t, uint32_t) is_alive;
	void  function (DB_ENV *, pid_t *, db_threadid_t *) thread_id;
	char *function (DB_ENV *, pid_t, db_threadid_t, char *) thread_id_string;

	/* Application specified paths */
	char	*db_blob_dir;		/* Blob file directory */
	char	*db_log_dir;		/* Database log file directory */
	char	*db_md_dir;		/* Persistent metadata directory */
	char	*db_tmp_dir;		/* Database tmp file directory */

	char    *db_create_dir;		/* Create directory for data files */
	char   **db_data_dir;		/* Database data file directories */
	int	 data_cnt;		/* Database data file slots */
	int	 data_next;		/* Next database data file slot */

	char	*intermediate_dir_mode;	/* Intermediate directory perms */

	c_long	 shm_key;		/* shmget key */

	char	*passwd;		/* Cryptography support */
	size_t	 passwd_len;

	/* Private handle references */
	void	*app_private;		/* Application-private handle */
	void	*api1_internal;		/* C++, Perl API private */
	void	*api2_internal;		/* Java API private */

	uint32_t	verbose;	/* DB_VERB_XXX flags */

	uint32_t	blob_threshold;	/* Blob threshold record size */

	/* Mutex configuration */
	uint32_t	mutex_align;	/* Mutex alignment */
	uint32_t	mutex_cnt;	/* Number of mutexes to configure */
	uint32_t	mutex_inc;	/* Number of mutexes to add */
	uint32_t	mutex_max;	/* Max number of mutexes */
	uint32_t	mutex_tas_spins;/* Test-and-set spin count */

	/* Locking configuration */
	uint8_t       *lk_conflicts;	/* Two dimensional conflict matrix */
	int		lk_modes;	/* Number of lock modes in table */
	uint32_t	lk_detect;	/* Deadlock detect on all conflicts */
	uint32_t	lk_max;	/* Maximum number of locks */
	uint32_t	lk_max_lockers;/* Maximum number of lockers */
	uint32_t	lk_max_objects;/* Maximum number of locked objects */
	uint32_t	lk_init;	/* Initial number of locks */
	uint32_t	lk_init_lockers;/* Initial number of lockers */
	uint32_t	lk_init_objects;/* Initial number of locked objects */
	uint32_t	lk_partitions ;/* Number of object partitions */
	db_timeout_t	lk_timeout;	/* Lock timeout period */
	/* Used during initialization */
	uint32_t	locker_t_size;	/* Locker hash table size. */
	uint32_t	object_t_size;	/* Object hash table size. */

	/* Logging configuration */
	uint32_t	lg_bsize;	/* Buffer size */
	uint32_t	lg_fileid_init;	/* Initial allocation for fname structs */
	int		lg_filemode;	/* Log file permission mode */
	uint32_t	lg_regionmax;	/* Region size */
	uint32_t	lg_size;	/* Log file size */
	uint32_t	lg_flags;	/* Log configuration */

	/* Memory pool configuration */
	uint32_t	mp_gbytes;	/* Cache size: GB */
	uint32_t	mp_bytes;	/* Cache size: bytes */
	uint32_t	mp_max_gbytes;	/* Maximum cache size: GB */
	uint32_t	mp_max_bytes;	/* Maximum cache size: bytes */
	size_t		mp_mmapsize;	/* Maximum file size for mmap */
	int		mp_maxopenfd;	/* Maximum open file descriptors */
	int		mp_maxwrite;	/* Maximum buffers to write */
	uint		mp_ncache;	/* Initial number of cache regions */
	uint32_t	mp_pagesize;	/* Average page size */
	uint32_t	mp_tablesize;	/* Approximate hash table size */
	uint32_t	mp_mtxcount;	/* Number of mutexs */
					/* Sleep after writing max buffers */
	db_timeout_t	mp_maxwrite_sleep;

	/* Transaction configuration */
	uint32_t	tx_init;	/* Initial number of transactions */
	uint32_t	tx_max;		/* Maximum number of transactions */
	time_t		tx_timestamp;	/* Recover to specific timestamp */
	db_timeout_t	tx_timeout;	/* Timeout for transactions */

	/* Thread tracking configuration */
	uint32_t	thr_init;	/* Thread count */
	uint32_t	thr_max;	/* Thread max */
	roff_t		memory_max;	/* Maximum region memory */

	/*
	 * The following fields are not strictly user-owned, but they outlive
	 * the ENV structure, and so are stored here.
	 */
	DB_FH		*registry;	/* DB_REGISTER file handle */
	uint32_t	registry_off;	/*
					 * Offset of our slot.  We can't use
					 * off_t because its size depends on
					 * build settings.
					 */
        db_timeout_t	envreg_timeout; /* DB_REGISTER wait timeout */
	/*
	 * When failchk broadcasting is active, any wait for a mutex will wake
	 * up this frequently in order to check whether the mutex has died.
	 */
	db_timeout_t	mutex_failchk_timeout;

	uint32_t flags;

	/* DB_ENV PUBLIC HANDLE LIST BEGIN */
	int  function (DB_ENV *, const (char)* ) add_data_dir;
	int  function	(DB_ENV *, const (char)* , uint32_t) backup;
	int  function (DB_ENV *, DB_TXN **) cdsgroup_begin;
	int  function (DB_ENV *, uint32_t) close;
	int  function (DB_ENV *, const (char)* , const (char)* , uint32_t) dbbackup;
	int  function (DB_ENV *,
		DB_TXN *, const (char)* , const (char)* , uint32_t) dbremove;
	int  function (DB_ENV *,
		DB_TXN *, const (char)* , const (char)* , const (char)* , uint32_t) dbrename;
	void function (const (DB_ENV)* , int, const (char)* , ...) err;
	void function (const (DB_ENV)* , const (char)* , ...) errx;
	int  function (DB_ENV *, uint32_t) failchk;
	int  function (DB_ENV *, const (char)* , uint32_t) fileid_reset;
	int  function (DB_ENV *, void *function(size_t)*,
		void *function(void *, size_t)*, void function(void *)*) get_alloc;
	int  function
		(DB_ENV *, int function(DB_ENV *, DBT *, DB_LSN *, db_recops)*) get_app_dispatch;
	int  function (DB_ENV *, const (char)* *) get_blob_dir;
	int  function (DB_ENV*, uint32_t *) get_blob_threshold;
	int  function (DB_ENV *, uint32_t *, uint32_t *) get_cache_max;
	int  function (DB_ENV *, uint32_t *, uint32_t *, int *) get_cachesize;
	int  function (DB_ENV *, const (char)* *) get_create_dir;
	int  function (DB_ENV *, const (char)* **) get_data_dirs;
	int  function (DB_ENV *, uint32_t *) get_data_len;
	int  function (DB_ENV *,
		int function(DB_ENV *, const (char)* , const (char)* , void **)*,
		int function(DB_ENV *, uint32_t, uint32_t, uint32_t, uint8_t *, void *)*,
		int function(DB_ENV *, const (char)* , void *)*) get_backup_callbacks;
	int  function (DB_ENV *, DB_BACKUP_CONFIG, uint32_t *) get_backup_config;
	int  function (DB_ENV *, uint32_t *) get_encrypt_flags;
	void function (DB_ENV *,
		void function(const (DB_ENV)* , const (char)* , const (char)* )*) get_errcall;
	void function (DB_ENV *, FILE **) get_errfile;
	void function (DB_ENV *, const (char)* *) get_errpfx;
	int  function (DB_ENV *, void function(DB_ENV *, int, int)*) get_feedback;
	int  function (DB_ENV *, uint32_t *) get_flags;
	int  function (DB_ENV *, const (char)* *) get_home;
	int  function (DB_ENV *, const (char)* *) get_intermediate_dir_mode;
	int  function (DB_ENV *,
		int function(DB_ENV *, pid_t, db_threadid_t, uint32_t)*) get_isalive;
	int  function (DB_ENV *, uint32_t *) get_lg_bsize;
	int  function (DB_ENV *, const (char)* *) get_lg_dir;
	int  function (DB_ENV *, int *) get_lg_filemode;
	int  function (DB_ENV *, uint32_t *) get_lg_max;
	int  function (DB_ENV *, uint32_t *) get_lg_regionmax;
	int  function (DB_ENV *, const (uint8_t)* *, int *) get_lk_conflicts;
	int  function (DB_ENV *, uint32_t *) get_lk_detect;
	int  function (DB_ENV *, uint32_t *) get_lk_max_lockers;
	int  function (DB_ENV *, uint32_t *) get_lk_max_locks;
	int  function (DB_ENV *, uint32_t *) get_lk_max_objects;
	int  function (DB_ENV *, uint32_t *) get_lk_partitions;
	int  function (DB_ENV *, uint32_t, uint32_t *) get_lk_priority;
	int  function (DB_ENV *, uint32_t *) get_lk_tablesize;
	int  function (DB_ENV *, DB_MEM_CONFIG, uint32_t *) get_memory_init;
	int  function (DB_ENV *, uint32_t *, uint32_t *) get_memory_max;
	int  function (DB_ENV *, const (char)* *) get_metadata_dir;
	int  function (DB_ENV *, int *) get_mp_max_openfd;
	int  function (DB_ENV *, int *, db_timeout_t *) get_mp_max_write;
	int  function (DB_ENV *, size_t *) get_mp_mmapsize;
	int  function (DB_ENV *, uint32_t *) get_mp_mtxcount;
	int  function (DB_ENV *, uint32_t *) get_mp_pagesize;
	int  function (DB_ENV *, uint32_t *) get_mp_tablesize;
	void function
		(DB_ENV *, void function(const (DB_ENV)* , const (char)* )*) get_msgcall;
	void function (DB_ENV *, FILE **) get_msgfile;
	int  function (DB_ENV *, uint32_t *) get_open_flags;
	int  function (DB_ENV *, c_long *) get_shm_key;
	int  function (DB_ENV *, uint32_t *) get_thread_count;
	int  function
		(DB_ENV *, void function(DB_ENV *, pid_t *, db_threadid_t *)*) get_thread_id_fn;
	int  function (DB_ENV *,
		char *function(DB_ENV *, pid_t, db_threadid_t, char *)*) get_thread_id_string_fn;
	int  function (DB_ENV *, db_timeout_t *, uint32_t) get_timeout;
	int  function (DB_ENV *, const (char)* *) get_tmp_dir;
	int  function (DB_ENV *, uint32_t *) get_tx_max;
	int  function (DB_ENV *, time_t *) get_tx_timestamp;
	int  function (DB_ENV *, uint32_t, int *) get_verbose;
	int  function () is_bigendian;
	int  function (DB_ENV *, uint32_t, uint32_t, int *) lock_detect;
	int  function (DB_ENV *,
		uint32_t, uint32_t, DBT *, db_lockmode_t, DB_LOCK *) lock_get;
	int  function (DB_ENV *, uint32_t *) lock_id;
	int  function (DB_ENV *, uint32_t) lock_id_free;
	int  function (DB_ENV *, DB_LOCK *) lock_put;
	int  function (DB_ENV *, DB_LOCK_STAT **, uint32_t) lock_stat;
	int  function (DB_ENV *, uint32_t) lock_stat_print;
	int  function (DB_ENV *,
		uint32_t, uint32_t, DB_LOCKREQ *, int, DB_LOCKREQ **) lock_vec;
	int  function (DB_ENV *, char ***, uint32_t) log_archive;
	int  function (DB_ENV *, DB_LOGC **, uint32_t) log_cursor;
	int  function (DB_ENV *, const (DB_LSN)* , char *, size_t) log_file;
	int  function (DB_ENV *, const (DB_LSN)* ) log_flush;
	int  function (DB_ENV *, uint32_t, int *) log_get_config;
	int  function (DB_ENV *, DB_TXN *, const (char)* , ...) log_printf;
	int  function (DB_ENV *, DB_LSN *, const (DBT)* , uint32_t) log_put;
	int  function (DB_ENV *, DB *, DB_TXN *, DB_LSN *,
		uint32_t, uint32_t, uint32_t, uint32_t,
		DB_LOG_RECSPEC *, ...) log_put_record;
	int  function (DB_ENV *, DB **,
		void *, void *, DB_LOG_RECSPEC *, uint32_t, void **) log_read_record;
	int  function (DB_ENV *, uint32_t, int) log_set_config;
	int  function (DB_ENV *, DB_LOG_STAT **, uint32_t) log_stat;
	int  function (DB_ENV *, uint32_t) log_stat_print;
	int  function (DB_ENV *, const (DB_LOG_VERIFY_CONFIG)* ) log_verify;
	int  function (DB_ENV *, const (char)* , uint32_t) lsn_reset;
	int  function (DB_ENV *, DB_MPOOLFILE **, uint32_t) memp_fcreate;
	int  function (DB_ENV *, int, int function(DB_ENV *, db_pgno_t,
		void *, DBT *), int function(DB_ENV *, db_pgno_t, void *, DBT *)) memp_register;
	int  function (DB_ENV *,
		DB_MPOOL_STAT **, DB_MPOOL_FSTAT ***, uint32_t) memp_stat;
	int  function (DB_ENV *, uint32_t) memp_stat_print;
	int  function (DB_ENV *, DB_LSN *) memp_sync;
	int  function (DB_ENV *, int, int *) memp_trickle;
	int  function (DB_ENV *, uint32_t, db_mutex_t *) mutex_alloc;
	int  function (DB_ENV *, db_mutex_t) mutex_free;
	int  function (DB_ENV *, uint32_t *) mutex_get_align;
	int  function (DB_ENV *, uint32_t *) mutex_get_increment;
	int  function (DB_ENV *, uint32_t *) mutex_get_init;
	int  function (DB_ENV *, uint32_t *) mutex_get_max;
	int  function (DB_ENV *, uint32_t *) mutex_get_tas_spins;
	int  function (DB_ENV *, db_mutex_t) mutex_lock;
	int  function (DB_ENV *, uint32_t) mutex_set_align;
	int  function (DB_ENV *, uint32_t) mutex_set_increment;
	int  function (DB_ENV *, uint32_t) mutex_set_init;
	int  function (DB_ENV *, uint32_t) mutex_set_max;
	int  function (DB_ENV *, uint32_t) mutex_set_tas_spins;
	int  function (DB_ENV *, DB_MUTEX_STAT **, uint32_t) mutex_stat;
	int  function (DB_ENV *, uint32_t) mutex_stat_print;
	int  function (DB_ENV *, db_mutex_t) mutex_unlock;
	int  function (DB_ENV *, const (char)* , uint32_t, int) open;
	int  function (DB_ENV *, const (char)* , uint32_t) remove;
	int  function (DB_ENV *, uint32_t, uint32_t, uint32_t) rep_elect;
	int  function (DB_ENV *) rep_flush;
	int  function (DB_ENV *, uint32_t *, uint32_t *) rep_get_clockskew;
	int  function (DB_ENV *, uint32_t, int *) rep_get_config;
	int  function (DB_ENV *, uint32_t *, uint32_t *) rep_get_limit;
	int  function (DB_ENV *, uint32_t *) rep_get_nsites;
	int  function (DB_ENV *, uint32_t *) rep_get_priority;
	int  function (DB_ENV *, uint32_t *, uint32_t *) rep_get_request;
	int  function (DB_ENV *, int, uint32_t *) rep_get_timeout;
	int  function
		(DB_ENV *, DBT *, DBT *, int, DB_LSN *) rep_process_message;
	int  function (DB_ENV *, uint32_t, uint32_t) rep_set_clockskew;
	int  function (DB_ENV *, uint32_t, int) rep_set_config;
	int  function (DB_ENV *, uint32_t, uint32_t) rep_set_limit;
	int  function (DB_ENV *, uint32_t) rep_set_nsites;
	int  function (DB_ENV *, uint32_t) rep_set_priority;
	int  function (DB_ENV *, uint32_t, uint32_t) rep_set_request;
	int  function (DB_ENV *, int, db_timeout_t) rep_set_timeout;
	int  function (DB_ENV *, int, int function(DB_ENV *,
		const (DBT)* , const (DBT)* , const (DB_LSN)* , int, uint32_t)) rep_set_transport;
	int  function (DB_ENV *, int function(DB_ENV *,
		const (char)* , int *, uint32_t)) rep_set_view;
	int  function (DB_ENV *, DBT *, uint32_t) rep_start;
	int  function (DB_ENV *, DB_REP_STAT **, uint32_t) rep_stat;
	int  function (DB_ENV *, uint32_t) rep_stat_print;
	int  function (DB_ENV *, uint32_t) rep_sync;
	int  function (DB_ENV *, int, DB_CHANNEL **, uint32_t) repmgr_channel;
	int  function (DB_ENV *, int *) repmgr_get_ack_policy;
	int  function
		(DB_ENV *, uint32_t *, uint32_t *) repmgr_get_incoming_queue_max;
	int  function (DB_ENV *, DB_SITE **) repmgr_local_site;
	int  function (DB_ENV *,
		void function(DB_ENV *, DB_CHANNEL *, DBT *, uint32_t, uint32_t),
		uint32_t) repmgr_msg_dispatch;
	int  function (DB_ENV *, int) repmgr_set_ack_policy;
	int  function
		(DB_ENV *, uint32_t, uint32_t) repmgr_set_incoming_queue_max;
	int  function
		(DB_ENV *, const (char)* , uint, DB_SITE**, uint32_t) repmgr_site;
	int  function (DB_ENV *, int, DB_SITE**) repmgr_site_by_eid;
	int  function (DB_ENV *, uint *, DB_REPMGR_SITE **) repmgr_site_list;
	int  function (DB_ENV *, int, uint32_t) repmgr_start;
	int  function (DB_ENV *, DB_REPMGR_STAT **, uint32_t) repmgr_stat;
	int  function (DB_ENV *, uint32_t) repmgr_stat_print;
	int  function (DB_ENV *, void *function(size_t),
		void *function(void *, size_t), void function(void *)) set_alloc;
	int  function
		(DB_ENV *, int function(DB_ENV *, DBT *, DB_LSN *, db_recops)) set_app_dispatch;
	int  function (DB_ENV *, const (char)* ) set_blob_dir;
	int  function (DB_ENV *, uint32_t, uint32_t) set_blob_threshold;
	int  function (DB_ENV *, uint32_t, uint32_t) set_cache_max;
	int  function (DB_ENV *, uint32_t, uint32_t, int) set_cachesize;
	int  function (DB_ENV *, const (char)* ) set_create_dir;
	int  function (DB_ENV *, const (char)* ) set_data_dir;
	int  function (DB_ENV *, uint32_t) set_data_len;
	int  function (DB_ENV *,
		int function(DB_ENV *, const (char)* , const (char)* , void **),
		int function(DB_ENV *, uint32_t,
		    uint32_t, uint32_t, uint8_t *, void *),
		int function(DB_ENV *, const (char)* , void *)) set_backup_callbacks;
	int  function (DB_ENV *, DB_BACKUP_CONFIG, uint32_t) set_backup_config;
	int  function (DB_ENV *, const (char)* , uint32_t) set_encrypt;
	void function (DB_ENV *,
		void function(const (DB_ENV)* , const (char)* , const (char)* )) set_errcall;
	void function (DB_ENV *, FILE *) set_errfile;
	void function (DB_ENV *, const (char)* ) set_errpfx;
	int  function
		(DB_ENV *, void function(DB_ENV *, uint32_t, void *)) set_event_notify;
	int  function (DB_ENV *, void function(DB_ENV *, int, int)) set_feedback;
	int  function (DB_ENV *, uint32_t, int) set_flags;
	int  function (DB_ENV *, const (char)* ) set_intermediate_dir_mode;
	int  function (DB_ENV *,
		int function(DB_ENV *, pid_t, db_threadid_t, uint32_t)) set_isalive;
	int  function (DB_ENV *, uint32_t) set_lg_bsize;
	int  function (DB_ENV *, const (char)* ) set_lg_dir;
	int  function (DB_ENV *, int) set_lg_filemode;
	int  function (DB_ENV *, uint32_t) set_lg_max;
	int  function (DB_ENV *, uint32_t) set_lg_regionmax;
	int  function (DB_ENV *, uint8_t *, int) set_lk_conflicts;
	int  function (DB_ENV *, uint32_t) set_lk_detect;
	int  function (DB_ENV *, uint32_t) set_lk_max_lockers;
	int  function (DB_ENV *, uint32_t) set_lk_max_locks;
	int  function (DB_ENV *, uint32_t) set_lk_max_objects;
	int  function (DB_ENV *, uint32_t) set_lk_partitions;
	int  function (DB_ENV *, uint32_t, uint32_t) set_lk_priority;
	int  function (DB_ENV *, uint32_t) set_lk_tablesize;
	int  function (DB_ENV *, DB_MEM_CONFIG, uint32_t) set_memory_init;
	int  function (DB_ENV *, uint32_t, uint32_t) set_memory_max;
	int  function (DB_ENV *, const (char)* ) set_metadata_dir;
	int  function (DB_ENV *, int) set_mp_max_openfd;
	int  function (DB_ENV *, int, db_timeout_t) set_mp_max_write;
	int  function (DB_ENV *, size_t) set_mp_mmapsize;
	int  function (DB_ENV *, uint32_t) set_mp_mtxcount;
	int  function (DB_ENV *, uint32_t) set_mp_pagesize;
	int  function (DB_ENV *, uint32_t) set_mp_tablesize;
	void function
		(DB_ENV *, void function(const (DB_ENV)* , const (char)* )) set_msgcall;
	void function (DB_ENV *, FILE *) set_msgfile;
	int  function (DB_ENV *, void function(DB_ENV *, int)) set_paniccall;
	int  function (DB_ENV *, c_long) set_shm_key;
	int  function (DB_ENV *, uint32_t) set_thread_count;
	int  function
		(DB_ENV *, void function(DB_ENV *, pid_t *, db_threadid_t *)) set_thread_id;
	int  function (DB_ENV *,
		char *function(DB_ENV *, pid_t, db_threadid_t, char *)) set_thread_id_string;
	int  function (DB_ENV *, db_timeout_t, uint32_t) set_timeout;
	int  function (DB_ENV *, const (char)* ) set_tmp_dir;
	int  function (DB_ENV *, uint32_t) set_tx_max;
	int  function (DB_ENV *, time_t *) set_tx_timestamp;
	int  function (DB_ENV *, uint32_t, int) set_verbose;
	int  function (DB_ENV *,
		DB_TXN_TOKEN *, db_timeout_t, uint32_t) txn_applied;
	int  function (DB_ENV *, uint32_t) stat_print;
	int  function (DB_ENV *, DB_TXN *, DB_TXN **, uint32_t) txn_begin;
	int  function (DB_ENV *, uint32_t, uint32_t, uint32_t) txn_checkpoint;
	int  function (DB_ENV *,
		DB_PREPLIST *, c_long, c_long *, uint32_t) txn_recover;
	int  function (DB_ENV *, DB_TXN_STAT **, uint32_t) txn_stat;
	int  function (DB_ENV *, uint32_t) txn_stat_print;
	/* DB_ENV PUBLIC HANDLE LIST END */

	/* DB_ENV PRIVATE HANDLE LIST BEGIN */
	int  function (DBT *, int, const (char)* , void *,
		int function(void *, const (void)* ), int, int, int) prdbt;
	/* DB_ENV PRIVATE HANDLE LIST END */
};

enum	DB_ENV_AUTO_COMMIT	= 0x00000001; /* DB_AUTO_COMMIT */
enum	DB_ENV_CDB_ALLDB	= 0x00000002; /* CDB environment wide locking */
enum	DB_ENV_FAILCHK		= 0x00000004; /* Failchk is running */
enum	DB_ENV_DIRECT_DB	= 0x00000008; /* DB_DIRECT_DB set */
enum	DB_ENV_DSYNC_DB		= 0x00000010; /* DB_DSYNC_DB set */
enum	DB_ENV_DATABASE_LOCKING	= 0x00000020; /* Try database-level locking */
enum	DB_ENV_MULTIVERSION	= 0x00000040; /* DB_MULTIVERSION set */
enum	DB_ENV_NOLOCKING	= 0x00000080; /* DB_NOLOCKING set */
enum	DB_ENV_NOMMAP		= 0x00000100; /* DB_NOMMAP set */
enum	DB_ENV_NOPANIC		= 0x00000200; /* Okay if panic set */
enum	DB_ENV_OVERWRITE	= 0x00000400; /* DB_OVERWRITE set */
enum	DB_ENV_REGION_INIT	= 0x00000800; /* DB_REGION_INIT set */
enum	DB_ENV_TIME_NOTGRANTED	= 0x00001000; /* DB_TIME_NOTGRANTED set */
enum	DB_ENV_TXN_NOSYNC	= 0x00002000; /* DB_TXN_NOSYNC set */
enum	DB_ENV_TXN_NOWAIT	= 0x00004000; /* DB_TXN_NOWAIT set */
enum	DB_ENV_TXN_SNAPSHOT	= 0x00008000; /* DB_TXN_SNAPSHOT set */
enum	DB_ENV_TXN_WRITE_NOSYNC	= 0x00010000; /* DB_TXN_WRITE_NOSYNC set */
enum	DB_ENV_YIELDCPU		= 0x00020000; /* DB_YIELDCPU set */
enum	DB_ENV_NOFLUSH		= 0x00080000; /* DB_NOFLUSH set */

/*
 * Dispatch structure for recovery, log verification and print routines. Since
 * internal and external routines take different arguments (ENV versus DB_ENV),
 * we need something more elaborate than a single pointer and size.
 */
struct __db_distab {
	int   function (ENV *, DBT *, DB_LSN *, db_recops, void *)* int_dispatch;
	size_t	int_size;
	int   function (DB_ENV *, DBT *, DB_LSN *, db_recops)* ext_dispatch;
	size_t	ext_size;
};

/*
 * Log verification configuration structure.
 */
struct __db_logvrfy_config {
	int continue_after_fail, verbose;
	uint32_t cachesize;
	const (char)* temp_envhome;
	const (char)* dbfile, dbname;
	DB_LSN start_lsn, end_lsn;
	time_t start_time, end_time;
};

struct __db_channel {
	CHANNEL *channel;	/* Pointer to internal state details. */
	int eid;		/* Env. ID passed in constructor. */
	db_timeout_t timeout;

	/* DB_CHANNEL PUBLIC HANDLE LIST BEGIN */
	int function (DB_CHANNEL *, uint32_t) close;
	int function (DB_CHANNEL *, DBT *, uint32_t, uint32_t) send_msg;
	int function (DB_CHANNEL *,
		DBT *, uint32_t, DBT *, db_timeout_t, uint32_t) send_request;
	int  function (DB_CHANNEL *, db_timeout_t) set_timeout;
	/* DB_CHANNEL PUBLIC HANDLE LIST END */
};

struct __db_site {
	ENV *env;
	int eid;
	const (char)* host;
	uint port;
	uint32_t flags;

	/* DB_SITE PUBLIC HANDLE LIST BEGIN */
	int function (DB_SITE *, const (char)* *, uint *) get_address;
	int function (DB_SITE *, uint32_t, uint32_t *) get_config;
	int function (DB_SITE *, int *) get_eid;
	int function (DB_SITE *, uint32_t, uint32_t) set_config;
	int function (DB_SITE *) remove;
	int function (DB_SITE *) close;
	/* DB_SITE PUBLIC HANDLE LIST END */
};

version(DB_DBM_HSEARCH)
{
/*******************************************************
 * Dbm/Ndbm historic interfaces.
 *******************************************************/
alias __db DBM;

enum	DBM_INSERT	= 0;		/* Flags to dbm_store(). */
enum	DBM_REPLACE	= 1;

/*
 * The DB support for ndbm(3) always appends this suffix to the
 * file name to avoid overwriting the user's original database.
 */
string	DBM_SUFFIX	= ".db";

version(XPG4_2)
{
struct datum {
	char *dptr;
	size_t dsize;
}
}
else
{
struct datum {
	char *dptr;
	int dsize;
}
}

/*
 * Translate NDBM calls into DB calls so that DB doesn't step on the
 * application's name space.
 */
auto dbm_clearerr(T)(T a)
{
	return __db_ndbm_clearerr(a);
}
auto dbm_close(T)(T a)
{
	return __db_ndbm_close(a);
}
auto dbm_delete(T, U)(T a, U b)
{
	return __db_ndbm_delete(a, b);
}
auto dbm_dirfno(T)(T a)
{
	return __db_ndbm_dirfno(a);
}
auto dbm_error(T)(T a)
{
	return __db_ndbm_error(a);
}
auto dbm_fetch(T, U)(T a, U b)
{
	return __db_ndbm_fetch(a, b);
}
auto dbm_firstkey(T)(T a)
{
	return __db_ndbm_firstkey(a);
}
auto dbm_nextkey(T)(T a)
{
	return __db_ndbm_nextkey(a);
}
auto dbm_open(T, U, Q)(T a, U b, Q c)
{
	return __db_ndbm_open(a, b, c);
}
auto dbm_pagfno(T)(T a)
{
	return __db_ndbm_pagfno(a);
}
auto dbm_rdonly(T)(T a)
{
	return __db_ndbm_rdonly(a);
}
auto dbm_store(T, U, Q, R)(T a, U b, Q c, R d)
{
	return __db_ndbm_store(a, b, c, d);
}


/*
 * Translate DBM calls into DB calls so that DB doesn't step on the
 * application's name space.
 *
 * The global variables dbrdonly, dirf and pagf were not retained when 4BSD
 * replaced the dbm interface with ndbm, and are not supported here.
 */
auto dbminit(T)(T a)
{
	return __db_dbm_init(a);
}
alias __db_dbm_close dbmclose;
auto fetch(T)(T a)
{
	return __db_dbm_fetch(a);
}
alias __db_dbm_firstkey firstkey;
auto nextkey(T)(T a)
{
	return __db_dbm_nextkey(a);
}
auto store(T, U)(T a, U b)
{
	return __db_dbm_store(a, b);
}

/*******************************************************
 * Hsearch historic interface.
 *******************************************************/
enum {
	FIND, ENTER
}
alias int ACTION;

struct entry {
	char *key;
	char *data;
}
alias entry ENTRY;

auto hcreate(T)(T a)
{
	return __db_hcreate(a);
}
alias __db_hdestroy hdestroy;
auto hsearch(T, U)(T a, U b)
{
	return __db_hsearch(a, b);
}

}

}

/* DO NOT EDIT: automatically built by dist/s_apiflags. */
enum	DB_AGGRESSIVE				= 0x00000001;
enum	DB_ARCH_ABS				= 0x00000001;
enum	DB_ARCH_DATA				= 0x00000002;
enum	DB_ARCH_LOG				= 0x00000004;
enum	DB_ARCH_REMOVE				= 0x00000008;
enum	DB_AUTO_COMMIT				= 0x00000100;
enum	DB_BACKUP_CLEAN				= 0x00000002;
enum	DB_BACKUP_FILES				= 0x00000008;
enum	DB_BACKUP_NO_LOGS			= 0x00000010;
enum	DB_BACKUP_SINGLE_DIR			= 0x00000020;
enum	DB_BACKUP_UPDATE			= 0x00000040;
enum	DB_BOOTSTRAP_HELPER			= 0x00000001;
enum	DB_CDB_ALLDB				= 0x00000040;
enum	DB_CHKSUM				= 0x00000008;
enum	DB_CKP_INTERNAL				= 0x00000002;
enum	DB_CREATE				= 0x00000001;
enum	DB_CURSOR_BULK				= 0x00000001;
enum	DB_CURSOR_TRANSIENT			= 0x00000008;
enum	DB_CXX_NO_EXCEPTIONS			= 0x00000002;
enum	DB_DATABASE_LOCKING			= 0x00000080;
enum	DB_DIRECT				= 0x00000020;
enum	DB_DIRECT_DB				= 0x00000200;
enum	DB_DSYNC_DB				= 0x00000400;
enum	DB_DUP					= 0x00000010;
enum	DB_DUPSORT				= 0x00000002;
enum	DB_DURABLE_UNKNOWN			= 0x00000040;
enum	DB_ENCRYPT				= 0x00000001;
enum	DB_ENCRYPT_AES				= 0x00000001;
enum	DB_EXCL					= 0x00000004;
enum	DB_EXTENT				= 0x00000100;
enum	DB_FAILCHK				= 0x00000010;
enum	DB_FAILCHK_ISALIVE			= 0x00000040;
enum	DB_FAST_STAT				= 0x00000001;
enum	DB_FCNTL_LOCKING			= 0x00000800;
enum	DB_FLUSH				= 0x00000002;
enum	DB_FORCE				= 0x00000001;
enum	DB_FORCESYNC				= 0x00000001;
enum	DB_FORCESYNCENV				= 0x00000002;
enum	DB_FOREIGN_ABORT			= 0x00000001;
enum	DB_FOREIGN_CASCADE			= 0x00000002;
enum	DB_FOREIGN_nullIFY			= 0x00000004;
enum	DB_FREELIST_ONLY			= 0x00000001;
enum	DB_FREE_SPACE				= 0x00000002;
enum	DB_GROUP_CREATOR			= 0x00000002;
enum	DB_IGNORE_LEASE				= 0x00001000;
enum	DB_IMMUTABLE_KEY			= 0x00000002;
enum	DB_INIT_CDB				= 0x00000080;
enum	DB_INIT_LOCK				= 0x00000100;
enum	DB_INIT_LOG				= 0x00000200;
enum	DB_INIT_MPOOL				= 0x00000400;
enum	DB_INIT_MUTEX				= 0x00000800;
enum	DB_INIT_REP				= 0x00001000;
enum	DB_INIT_TXN				= 0x00002000;
enum	DB_INORDER				= 0x00000020;
enum	DB_INTERNAL_BLOB_DB			= 0x00001000;
enum	DB_INTERNAL_PERSISTENT_DB		= 0x00002000;
enum	DB_INTERNAL_TEMPORARY_DB		= 0x00004000;
enum	DB_JOIN_NOSORT				= 0x00000001;
enum	DB_LEGACY				= 0x00000004;
enum	DB_LOCAL_SITE				= 0x00000008;
enum	DB_LOCKDOWN				= 0x00004000;
enum	DB_LOCK_CHECK				= 0x00000001;
enum	DB_LOCK_IGNORE_REC			= 0x00000002;
enum	DB_LOCK_NOWAIT				= 0x00000004;
enum	DB_LOCK_RECORD				= 0x00000008;
enum	DB_LOCK_SET_TIMEOUT			= 0x00000010;
enum	DB_LOCK_SWITCH				= 0x00000020;
enum	DB_LOCK_UPGRADE				= 0x00000040;
enum	DB_LOG_AUTO_REMOVE			= 0x00000001;
enum	DB_LOG_BLOB				= 0x00000002;
enum	DB_LOG_CHKPNT				= 0x00000001;
enum	DB_LOG_COMMIT				= 0x00000004;
enum	DB_LOG_DIRECT				= 0x00000004;
enum	DB_LOG_DSYNC				= 0x00000008;
enum	DB_LOG_NOCOPY				= 0x00000008;
enum	DB_LOG_NOSYNC				= 0x00000020;
enum	DB_LOG_NOT_DURABLE			= 0x00000010;
enum	DB_LOG_NO_DATA				= 0x00000002;
enum	DB_LOG_VERIFY_CAF			= 0x00000001;
enum	DB_LOG_VERIFY_DBFILE			= 0x00000002;
enum	DB_LOG_VERIFY_ERR			= 0x00000004;
enum	DB_LOG_VERIFY_FORWARD			= 0x00000008;
enum	DB_LOG_VERIFY_INTERR			= 0x00000010;
enum	DB_LOG_VERIFY_PARTIAL			= 0x00000020;
enum	DB_LOG_VERIFY_VERBOSE			= 0x00000040;
enum	DB_LOG_VERIFY_WARNING			= 0x00000080;
enum	DB_LOG_WRNOSYNC				= 0x00000020;
enum	DB_LOG_ZERO				= 0x00000040;
enum	DB_MPOOL_CREATE				= 0x00000001;
enum	DB_MPOOL_DIRTY				= 0x00000002;
enum	DB_MPOOL_DISCARD			= 0x00000001;
enum	DB_MPOOL_EDIT				= 0x00000004;
enum	DB_MPOOL_FREE				= 0x00000008;
enum	DB_MPOOL_LAST				= 0x00000010;
enum	DB_MPOOL_NEW				= 0x00000020;
enum	DB_MPOOL_NOFILE				= 0x00000001;
enum	DB_MPOOL_NOLOCK				= 0x00000004;
enum	DB_MPOOL_TRY				= 0x00000040;
enum	DB_MPOOL_UNLINK				= 0x00000002;
enum	DB_MULTIPLE				= 0x00000800;
enum	DB_MULTIPLE_KEY				= 0x00004000;
enum	DB_MULTIVERSION				= 0x00000008;
enum	DB_MUTEX_ALLOCATED			= 0x00000001;
enum	DB_MUTEX_LOCKED				= 0x00000002;
enum	DB_MUTEX_LOGICAL_LOCK			= 0x00000004;
enum	DB_MUTEX_OWNER_DEAD			= 0x00000020;
enum	DB_MUTEX_PROCESS_ONLY			= 0x00000008;
enum	DB_MUTEX_SELF_BLOCK			= 0x00000010;
enum	DB_MUTEX_SHARED				= 0x00000040;
enum	DB_NOERROR				= 0x00008000;
enum	DB_NOFLUSH				= 0x00001000;
enum	DB_NOLOCKING				= 0x00002000;
enum	DB_NOMMAP				= 0x00000010;
enum	DB_NOORDERCHK				= 0x00000002;
enum	DB_NOPANIC				= 0x00004000;
enum	DB_NOSYNC				= 0x00000001;
enum	DB_NO_AUTO_COMMIT			= 0x00010000;
enum	DB_NO_CHECKPOINT			= 0x00008000;
enum	DB_ODDFILESIZE				= 0x00000080;
enum	DB_ORDERCHKONLY				= 0x00000004;
enum	DB_OVERWRITE				= 0x00008000;
enum	DB_PANIC_ENVIRONMENT			= 0x00010000;
enum	DB_PRINTABLE				= 0x00000008;
enum	DB_PRIVATE				= 0x00010000;
enum	DB_PR_PAGE				= 0x00000010;
enum	DB_PR_RECOVERYTEST			= 0x00000020;
enum	DB_RDONLY				= 0x00000400;
enum	DB_RDWRMASTER				= 0x00020000;
enum	DB_READ_COMMITTED			= 0x00000400;
enum	DB_READ_UNCOMMITTED			= 0x00000200;
enum	DB_RECNUM				= 0x00000040;
enum	DB_RECOVER				= 0x00000002;
enum	DB_RECOVER_FATAL			= 0x00020000;
enum	DB_REGION_INIT				= 0x00020000;
enum	DB_REGISTER				= 0x00040000;
enum	DB_RENUMBER				= 0x00000080;
enum	DB_REPMGR_CONF_2SITE_STRICT		= 0x00000001;
enum	DB_REPMGR_CONF_ELECTIONS		= 0x00000002;
enum	DB_REPMGR_CONF_PREFMAS_CLIENT		= 0x00000004;
enum	DB_REPMGR_CONF_PREFMAS_MASTER		= 0x00000008;
enum	DB_REPMGR_NEED_RESPONSE			= 0x00000001;
enum	DB_REPMGR_PEER				= 0x00000010;
enum	DB_REP_ANYWHERE				= 0x00000001;
enum	DB_REP_CLIENT				= 0x00000001;
enum	DB_REP_CONF_AUTOINIT			= 0x00000010;
enum	DB_REP_CONF_AUTOROLLBACK		= 0x00000020;
enum	DB_REP_CONF_BULK			= 0x00000040;
enum	DB_REP_CONF_DELAYCLIENT			= 0x00000080;
enum	DB_REP_CONF_ELECT_LOGLENGTH		= 0x00000100;
enum	DB_REP_CONF_INMEM			= 0x00000200;
enum	DB_REP_CONF_LEASE			= 0x00000400;
enum	DB_REP_CONF_NOWAIT			= 0x00000800;
enum	DB_REP_ELECTION				= 0x00000004;
enum	DB_REP_MASTER				= 0x00000002;
enum	DB_REP_NOBUFFER				= 0x00000002;
enum	DB_REP_PERMANENT			= 0x00000004;
enum	DB_REP_REREQUEST			= 0x00000008;
enum	DB_REVSPLITOFF				= 0x00000100;
enum	DB_RMW					= 0x00002000;
enum	DB_SALVAGE				= 0x00000040;
enum	DB_SA_SKIPFIRSTKEY			= 0x00000080;
enum	DB_SA_UNKNOWNKEY			= 0x00000100;
enum	DB_SEQ_DEC				= 0x00000001;
enum	DB_SEQ_INC				= 0x00000002;
enum	DB_SEQ_RANGE_SET			= 0x00000004;
enum	DB_SEQ_WRAP				= 0x00000008;
enum	DB_SEQ_WRAPPED				= 0x00000010;
enum	DB_SET_LOCK_TIMEOUT			= 0x00000001;
enum	DB_SET_MUTEX_FAILCHK_TIMEOUT		= 0x00000004;
enum	DB_SET_REG_TIMEOUT			= 0x00000008;
enum	DB_SET_TXN_NOW				= 0x00000010;
enum	DB_SET_TXN_TIMEOUT			= 0x00000002;
enum	DB_SHALLOW_DUP				= 0x00000100;
enum	DB_SNAPSHOT				= 0x00000200;
enum	DB_STAT_ALL				= 0x00000004;
enum	DB_STAT_ALLOC				= 0x00000008;
enum	DB_STAT_CLEAR				= 0x00000001;
enum	DB_STAT_LOCK_CONF			= 0x00000010;
enum	DB_STAT_LOCK_LOCKERS			= 0x00000020;
enum	DB_STAT_LOCK_OBJECTS			= 0x00000040;
enum	DB_STAT_LOCK_PARAMS			= 0x00000080;
enum	DB_STAT_MEMP_HASH			= 0x00000010;
enum	DB_STAT_MEMP_NOERROR			= 0x00000020;
enum	DB_STAT_SUBSYSTEM			= 0x00000002;
enum	DB_STAT_SUMMARY				= 0x00000010;
enum	DB_ST_DUPOK				= 0x00000200;
enum	DB_ST_DUPSET				= 0x00000400;
enum	DB_ST_DUPSORT				= 0x00000800;
enum	DB_ST_IS_RECNO				= 0x00001000;
enum	DB_ST_OVFL_LEAF				= 0x00002000;
enum	DB_ST_RECNUM				= 0x00004000;
enum	DB_ST_RELEN				= 0x00008000;
enum	DB_ST_TOPLEVEL				= 0x00010000;
enum	DB_SYSTEM_MEM				= 0x00080000;
enum	DB_THREAD				= 0x00000020;
enum	DB_TIME_NOTGRANTED			= 0x00040000;
enum	DB_TRUNCATE				= 0x00040000;
enum	DB_TXN_BULK				= 0x00000010;
enum	DB_TXN_FAMILY				= 0x00000040;
enum	DB_TXN_NOSYNC				= 0x00000001;
enum	DB_TXN_NOT_DURABLE			= 0x00000004;
enum	DB_TXN_NOWAIT				= 0x00000002;
enum	DB_TXN_SNAPSHOT				= 0x00000004;
enum	DB_TXN_SYNC				= 0x00000008;
enum	DB_TXN_WAIT				= 0x00000080;
enum	DB_TXN_WRITE_NOSYNC			= 0x00000020;
enum	DB_UNREF				= 0x00020000;
enum	DB_UPGRADE				= 0x00000001;
enum	DB_USE_ENVIRON				= 0x00000004;
enum	DB_USE_ENVIRON_ROOT			= 0x00000008;
enum	DB_VERB_BACKUP				= 0x00000001;
enum	DB_VERB_DEADLOCK			= 0x00000002;
enum	DB_VERB_FILEOPS				= 0x00000004;
enum	DB_VERB_FILEOPS_ALL			= 0x00000008;
enum	DB_VERB_MVCC				= 0x00000010;
enum	DB_VERB_RECOVERY			= 0x00000020;
enum	DB_VERB_REGISTER			= 0x00000040;
enum	DB_VERB_REPLICATION			= 0x00000080;
enum	DB_VERB_REPMGR_CONNFAIL			= 0x00000100;
enum	DB_VERB_REPMGR_MISC			= 0x00000200;
enum	DB_VERB_REP_ELECT			= 0x00000400;
enum	DB_VERB_REP_LEASE			= 0x00000800;
enum	DB_VERB_REP_MISC			= 0x00001000;
enum	DB_VERB_REP_MSGS			= 0x00002000;
enum	DB_VERB_REP_SYNC			= 0x00004000;
enum	DB_VERB_REP_SYSTEM			= 0x00008000;
enum	DB_VERB_REP_TEST			= 0x00010000;
enum	DB_VERB_WAITSFOR			= 0x00020000;
enum	DB_VERIFY				= 0x00000002;
enum	DB_VERIFY_PARTITION			= 0x00040000;
enum	DB_WRITECURSOR				= 0x00000010;
enum	DB_WRITELOCK				= 0x00000020;
enum	DB_WRITEOPEN				= 0x00080000;
enum	DB_XA_CREATE				= 0x00000001;
enum	DB_YIELDCPU				= 0x00080000;

/* DO NOT EDIT: automatically built by dist/s_include. */

version(DB_WINCE){} else {
version(DB_WIN32){
} }
version(DB_DBM_HSEARCH)
{
}
version(DB_DBM_HSEARCH)
{
}


/* DO NOT EDIT: automatically built by dist/s_include. */

extern (C) {

int db_copy (DB_ENV *, const (char)* , const (char)* , const (char)* );
int db_create (DB **, DB_ENV *, uint32_t);
char *db_strerror (int);
int db_env_set_func_assert (void function(const (char)* , const (char)* , int));
int db_env_set_func_close (int function(int));
int db_env_set_func_dirfree (void function(char **, int));
int db_env_set_func_dirlist (int function(const (char)* , char ***, int *));
int db_env_set_func_exists (int function(const (char)* , int *));
int db_env_set_func_free (void function(void *));
int db_env_set_func_fsync (int function(int));
int db_env_set_func_ftruncate (int function(int, off_t));
int db_env_set_func_ioinfo (int function(const (char)* , int, uint32_t *, uint32_t *, uint32_t *));
int db_env_set_func_malloc (void *function(size_t));
int db_env_set_func_file_map (int function(DB_ENV *, char *, size_t, int, void **), int function(DB_ENV *, void *));
int db_env_set_func_region_map (int function(DB_ENV *, char *, size_t, int *, void **), int function(DB_ENV *, void *));
int db_env_set_func_pread (ssize_t function(int, void *, size_t, off_t));
int db_env_set_func_pwrite (ssize_t function(int, const (void)* , size_t, off_t));
int db_env_set_func_open (int function(const (char)* , int, ...));
int db_env_set_func_read (ssize_t function(int, void *, size_t));
int db_env_set_func_realloc (void *function(void *, size_t));
int db_env_set_func_rename (int function(const (char)* , const (char)* ));
int db_env_set_func_seek (int function(int, off_t, int));
int db_env_set_func_unlink (int function(const (char)* ));
int db_env_set_func_write (ssize_t function(int, const (void)* , size_t));
int db_env_set_func_yield (int function(ulong, ulong));
int db_env_create (DB_ENV **, uint32_t);
char *db_version (int *, int *, int *);
char *db_full_version (int *, int *, int *, int *, int *);
int log_compare (const (DB_LSN)* , const (DB_LSN)* );
version(DB_WINCE){} else {
version(DB_WIN32){
int db_env_set_win_security (SECURITY_ATTRIBUTES *sa);
} }
int db_sequence_create (DB_SEQUENCE **, DB *, uint32_t);
version(DB_DBM_HSEARCH)
{
int	 __db_ndbm_clearerr (DBM *);
void	 __db_ndbm_close (DBM *);
int	 __db_ndbm_delete (DBM *, datum);
int	 __db_ndbm_dirfno (DBM *);
int	 __db_ndbm_error (DBM *);
datum __db_ndbm_fetch (DBM *, datum);
datum __db_ndbm_firstkey (DBM *);
datum __db_ndbm_nextkey (DBM *);
DBM	*__db_ndbm_open (const (char)* , int, int);
int	 __db_ndbm_pagfno (DBM *);
int	 __db_ndbm_rdonly (DBM *);
int	 __db_ndbm_store (DBM *, datum, datum, int);
int	 __db_dbm_close (void);
int	 __db_dbm_delete (datum);
datum __db_dbm_fetch (datum);
datum __db_dbm_firstkey (void);
int	 __db_dbm_init (char *);
datum __db_dbm_nextkey (datum);
int	 __db_dbm_store (datum, datum);
}
version(DB_DBM_HSEARCH)
{
int __db_hcreate (size_t);
ENTRY *__db_hsearch (ENTRY, ACTION);
void __db_hdestroy (void);
}

}
