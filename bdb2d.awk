#   bdb2d is BerkeleyDB for D language
#   It is part of unDE project (http://unde.su)
#
#   Copyright (C) 2009-2014 Nikolay (unDEFER) Krivchenkov <undefer@gmail.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { comment=0; 
	types_ar[0]="T";
	types_ar[1]="U";
       	types_ar[2]="Q";
       	types_ar[3]="R";
       	types_ar[4]="S";
	brackets = 0;
	func_header = 0;
	funcs = 0;
	ifndef_nsi = 0;
	ifndef_def = 0;
	ifdef_cpp = 0;
	ifdef_mixed_size = 0;
	#DB_VERSION_UNIQUE_NAME="_5001";
	DB_VERSION_FAMILY=12
	DB_VERSION_RELEASE=1
	DB_VERSION_MAJOR=6
	DB_VERSION_MINOR=1
	DB_VERSION_PATCH=26
	DB_VERSION_STRING="Berkeley DB 6.1.26: (June 16, 2015)"
	DB_VERSION_FULL="Berkeley DB 12c Release 1, library version 12.1.6.1.26: (June 16, 2015)"
	SKIP_PREDEFINES = 1
}

skip_getting_started_common==1 && /#include "gettingstarted_common.h"/ {
	skip_getting_started_common=0;
	next
}
skip_getting_started_common==1 {next}
/\/\* Function prototypes \*\// { skip_getting_started_common=1; nextfile }
/\/\*/ { comment=1 }
(comment==1 && /\*\//) { comment=0 }
#comment==1 && struct_start==0 { print; next }
/^\/\// { print; next }
/^#ifndef[ \t].*_H_/ { next }
/^#define[ \t].*_H_/ { next }
/^#endif[ \t].*_H_/ { next }
/^#ifndef[ \t].*_IN_/ { next }
/^#define[ \t].*_IN_/ { next }
/^#endif[ \t].*_IN_/ { next }

SKIP_PREDEFINES && /^(int|char|void) +[a-zA-Z0-9_]+\(((const )? *[A-Za-z]+ *\*?,?)+\)/  { next }

/^#ifndef[ \t].*__NO_SYSTEM_INCLUDES/ { ifndef_nsi=1; next }
/@inttypes_h_decl@/ { 
	print "module berkeleydb.c;\n";
	print "import core.stdc.inttypes;"; 
	print "import core.stdc.config;"; 
    next }
/@stdint_h_decl@/ { print "import std.stdint;"; next }
/@stddef_h_decl@/ { print "import core.stdc.stddef;"; next }
/#include <stdio.h>/ { print "import core.stdc.stdio;"; next }
/@unistd_h_decl@/ { print "import std.file;"; next }
/@thread_h_decl@/ { print "import core.sys.posix.pthread;"; next }
ifndef_nsi==1 && /^#endif/ { ifndef_nsi=0; next }
ifndef_nsi==1 { next }

/#include <db.h>/ { print "import db;\nimport std.stdint;"; next }
/#include <stdlib.h>/ { print "import std.c.stdlib;"; next }
/#include <string.h>/ { print "import std.c.string;\nimport std.string;"; next }

/^#ifdef _WIN32/ { ifdef_win32=1; next }
ifdef_win32==1 && /^#endif/ { ifdef_win32=0; next }
ifdef_win32==1  { next }

/^#if defined\(__cplusplus\)/ { ifdef_cpp=1; next }
ifdef_cpp==1 && /^#endif/ { ifdef_cpp=0; next }

/^#if !defined\(__cplusplus\)/ { ifndef_cpp=1; next }
ifndef_cpp==1 && /^#endif/ { ifndef_cpp=0; next }
ifndef_cpp==1 { next }

/^#if defined\(DB_WIN32\) && !defined\(DB_WINCE\)/ {
	print "version(DB_WINCE){} else {";
	print "version(DB_WIN32){";
	ifdef_win32_not_wince=1; 
	next;
}
ifdef_win32_not_wince==1 && /^#endif/ { 
	print "} }";
	ifdef_win32_not_wince=0; 
	next;
}

/@platform_header@/ { next }
/@DB_CONST@/ { next }
/@DB_PROTO1@/ { next }
/@DB_PROTO2@/ { next }

/^#ifndef[ \t].*DEFINED__/ { ifndef_def=1; next }
ifndef_def && /^#define[ \t].*DEFINED__/ { next }
ifndef_def && /^#endif/ { ifndef_def=0; next }
ifndef_def { next }

/^#ifndef[ \t].*__TEST_DB_NO_STATISTICS/ { 
	$0 = "version(TEST_DB_NO_STATISTICS)\n{\n}\nelse\n{";
	ifndef_nostat=1; 
}
/^#ifdef[ \t].*CONFIG_TEST/ { 
	print "version(CONFIG_TEST)\n{";
	ifdef_ct=1; 
	next;
}
ifdef_ct && /^#endif/ { print "}"; ifdef_ct=0; next; }
ifndef_nostat && /^#endif/ { $0 = "}"; ifndef_def=0; }

/^#if DB_DBM_HSEARCH != 0/ { 
	print "version(DB_DBM_HSEARCH)\n{";
	if_dbm_search=1; 
	next;
}

if_dbm_search && /^#if defined\(_XPG4_2\)/ {
	print "version(XPG4_2)\n{";
	ifdef_xpg4=1; 
	next;
}
if_dbm_search && ifdef_xpg4 == 1 && /^#else/ {
	print "}\nelse\n{";
	ifdef_xpg4=2; 
	next;
}
if_dbm_search && ifdef_xpg4 == 2 && /^#endif/ {
	print "}";
	ifdef_xpg4=0; 
	next;
}

if_dbm_search && /^#endif.*DB_DBM_HSEARCH/ { 
	print "}\n";
	if_dbm_search=0; 
	next;
}

/^#ifdef HAVE_MIXED_SIZE_ADDRESSING/ { 
	print "version(HAVE_MIXED_SIZE_ADDRESSING)\n{";
	ifdef_mixed_size=1; 
	next;
}
ifdef_mixed_size && /^#else/ {
	print "}\nelse\n{";
	next;
}
ifdef_mixed_size && /^#endif/ { 
	print "}\n";
	ifdef_mixed_size=0; 
	next;
}


/@u_char_decl@/ { next }
/@u_int_decl@/ { next }
/@u_long_decl@/ { next }
/@u_short_decl@/ { next }

/@uintmax_t_decl@/ { next }
/@uintptr_t_decl@/ { next }
/@FILE_t_decl@/ { next }
/@off_t_decl@/ { next }
/@db_off_t_decl@/ { print "alias int db_off_t;"; next }
/@pid_t_decl@/ { next }
/@size_t_decl@/ { next }
/@ssize_t_decl@/ { next }
/@time_t_decl@/ { next }

/@platform_footer@/ { next }

/@db_seq_decl@/ { print "alias int64_t db_seq_t;"; next }
/@db_threadid_t_decl@/ { print "alias pthread_t db_threadid_t;"; next }

/struct [A-Za-z_]+;/ { 
	name = gensub(/.*struct ([A-Za-z_]+);.*/, "\\1", "g");

	if ( !match(name, /^(__channel|__db_cipher|__db_locker|__db_locktab|__db_log|__db_mpool|__db_mutex_t|__db_mutexmgr|__db_rep|__db_thread_info|__db_txnmgr|__dbc_internal|__env|__fh_t|__fname|__mpoolfile)$/) )
	{
		$0 = gensub(/struct [A-Za-z_]+;[ \t]*/, "", "g");
	}
	if ( name == "__db_logvrfy_config" )
	{
		print "struct __txn_event; struct __txn_logrec; struct __db_foreign_info;";;
	}
}
/u_int32_t/ { $0 = gensub(/u_int32_t/, "uint32_t", "g"); }
/u_int16_t/ { $0 = gensub(/u_int16_t/, "uint16_t", "g"); }
/u_int8_t/ { $0 = gensub(/u_int8_t/, "uint8_t", "g"); }
/u_long/ { $0 = gensub(/u_long/, "ulong", "g"); }
/u_int/ { $0 = gensub(/u_int/, "uint", "g"); }
/unsigned long/ { $0 = gensub(/unsigned long/, "c_ulong", "g"); }
/\<long\>/ { $0 = gensub(/\<long\>/, "c_long", "g"); }
/char \*\*\[\]/ { $0 = gensub(/char \*\*\[\]/, "char ***", "g"); }

/sizeof\(([a-zA-Z0-9_]+)\)/ { $0 = gensub(/sizeof\(([a-zA-Z0-9_]+)\)/, "\\1.sizeof", "g"); }
/->/ { $0 = gensub(/->/, ".", "g"); }
/const ([A-Za-z0-9_]+) \*/ { $0 = gensub(/const ([A-Za-z0-9_]+) \*/, "const (\\1)* ", "g"); }
/\.(data|size) = .*;/ { $0 = gensub(/\.(data|size) = (.*);/, ".\\1 = cast(void*)(\\2);", "g"); }
/strlen\(([a-z]+\.data)\)/ { $0 = gensub(/strlen\(([a-z]+\.data)\)/, "strlen(cast(const(char)*) \\1)", "g"); }
/get_item_name,/ { $0 = gensub(/get_item_name,/, "\\&get_item_name,", "g"); }

/char \*(db_home_dir|itemname_db_name|inventory_db_name|vendor_db_name);/ { 
	$0 = gensub(/char \*(db_home_dir|itemname_db_name|inventory_db_name|vendor_db_name);/, "string \\1;", "g"); 
}
/my_stock\.(db_home_dir|itemname_db_name|inventory_db_name|vendor_db_name),/ { 
	$0 = gensub(/my_stock\.(db_home_dir|itemname_db_name|inventory_db_name|vendor_db_name),/, "my_stock.\\1.toStringz(),", "g"); 
}

/set_db_filenames\(STOCK_DBS \*my_stock\)/ {set_db_filenames = 1}
set_db_filenames == 1 && /size_t size;/ {next;}
set_db_filenames == 1 && /size = strlen\((.*)\) \+ strlen\(.*\) \+ 1;/ {
	concat_fields = gensub(/.*size = strlen\((.*)\) \+ strlen\((.*)\) \+ 1;.*/, "\\1 ~ \\2", "g");
	next;
}
set_db_filenames == 1 && /(my_stock\.[a-z_]+) = malloc\(size\);/ {
	$0 = gensub(/(my_stock\.[a-z_]*) = malloc\(size\);/, sprintf("\\1 = %s;", concat_fields), "g");
}
set_db_filenames == 1 && /snprintf\(.*/ { start_snprintf = 1; next; }
set_db_filenames == 1 && start_snprintf && /.*DB\);/ { start_snprintf = 0; next; }
set_db_filenames == 1 && /^}/ { set_db_filenames = 0 }

/db_home_dir = DEFAULT_HOMEDIR/ { $0 = gensub(/db_home_dir = DEFAULT_HOMEDIR/, "db_home_dir = DEFAULT_HOMEDIR", "g"); }

/^[ \t]*(typedef |)(enum|struct)[ \t]+\{/ { 
	struct_typedef = match($0, /typedef /);
	struct_type=gensub(/^[ \t]*(typedef |)(enum|struct)[ \t]+\{.*/, "\\2", "g");
	struct_lines = "";
	struct_start=1;
	next; 
}

struct_start==1 && /\}[ \t]*([A-Za-z_]+)?;/ { 
	struct_tabs = gensub(/^([ \t]*)\}[ \t]*([A-Za-z_]+)?;.*/, "\\1", "g");
	var_name = gensub(/^[ \t]*\}[ \t]*([A-Za-z_]+)?;.*/, "\\1", "g");
	struct_name = sprintf("%s_t", var_name);
	if (struct_typedef)
	{
		if (struct_type == "enum")
		{
			printf ("%s%s {\n%s}\nalias int %s;\n", struct_tabs, struct_type, struct_lines, var_name);
		}
		else
		{
			printf ("%s%s %s {\n%s}\n", struct_tabs, struct_type, var_name, struct_lines);
		}
	}
	else
	{
		printf ("%s%s %s {\n%s%s}\n", struct_tabs, struct_type, struct_name, struct_lines, struct_tabs, struct_tabs, struct_name, var_name);
		if (var_name != "")
		{
			printf ("%s%s %s;\n", struct_tabs, struct_name, var_name);
		}
	}
	struct_start=0; struct_lines = ""; next; 
}

/^[ \t]+struct[ \t]+([a-z_]+)[ \t]*\{.*/ { 
	named_struct_name = gensub(/^[ \t]+struct[ \t]+([a-z_]+)[ \t]*\{.*/, "\\1", "g");
	named_struct = 1;
}

named_struct && /\}[ \t]*([A-Za-z_]+);/ { 
	struct_tabs = gensub(/^([ \t]*)\}[ \t]*([A-Za-z_]+);.*/, "\\1", "g");
	var_name = gensub(/^[ \t]*\}[ \t]*([A-Za-z_]+);.*/, "\\1", "g");

	named_struct = 0;

	printf ("%s}\n", struct_tabs);
	printf ("%s%s %s;\n", struct_tabs, named_struct_name, var_name);
	next;
}

/struct ([a-z_]+) (\**)([a-z_]+);/ {
	$0 = gensub(/struct ([a-z_]+) (\**)([a-z_]+);/, "\\1\\2 \\3;", "g");
	}

struct_start==1 { 
	struct_lines = sprintf("%s%s\n", struct_lines, $0);
	next;
}

/typedef (const )?struct[ \t]+([A-Za-z_]+)[ \t]*\{/ { 
	struct_modifier = gensub(/typedef (const )?struct[ \t]+([A-Za-z_]+)[ \t]*\{/, "\\1", "g");
	struct_name = gensub(/typedef (const )?struct[ \t]+([A-Za-z_]+)[ \t]*\{/, "\\2", "g");
	struct_typedefined = 1;
	printf "struct %s {\n", struct_name;
	next;
}

struct_typedefined && /\}[ \t]*([A-Za-z_]+);/ { 
	type_name = gensub(/\}[ \t]*([A-Za-z_]+);/, "\\1", "g");
	printf "}\nalias %s %s;\n", struct_name, type_name;
	struct_typedefined = 0;
	next;
}

/typedef struct/ { $0 = gensub(/typedef struct/, "alias", "g"); }
/typedef/ { $0 = gensub(/typedef/, "alias", "g"); }

/NULL/ { $0 = gensub(/NULL/, "null", "g"); }
/__P\((\([^)]*\))\)/ { $0 = gensub(/__P\((\([^)]*\))\)/, "\\1", "g"); }
/__P\(\(/ { pp=1; $0 = gensub(/__P\(\(/, "(", "g"); }
pp==1 && /\)\);/ { pp=0; $0 = gensub(/\)\);/, ");", "g"); }

/extern "C"/ { $0 = gensub(/extern "C"/, "extern (C)", "g"); }

/^(int|char|void)[ \t]+\*?([a-z_]*)[ \t]*\(/ {
	name =  gensub(/^(int|char|void)[ \t]+\*?([a-z_]*).*/, "\\2", "g");
	if (macroses[name])
	{
		name = macroses[name];
		$0 = gensub(/^(int|char|void)([ \t]+)(\*?)[a-z_]*([ \t]*\()/, sprintf("\\1\\3\\2%s\\4", name), "g");
	}
}

/(int|void|uint32_t|DB_[A-Z]+ \*|void \*|char \*)([ \t]*)\((\*)?\*([A-Za-z_]+)\)([ \t]+)(\([0-9A-Za-z_ ,*]*\));/ {
	name = gensub(/.*(int|void|uint32_t|DB_[A-Z]+ \*|void \*|char \*)([ \t]*)\((\*)?\*([A-Za-z_]+)\)([ \t]+)(\([0-9A-Za-z_ ,*]*\));/, "\\4", "g");
	if (name == "version") name = "Version";
	parms = gensub(/.*(int|void|uint32_t|DB_[A-Z]+ \*|void \*|char \*)([ \t]*)\((\*)?\*([A-Za-z_]+)\)([ \t]+)(\([0-9A-Za-z_ ,*]*\));/, "\\6", "g");
	if (parms == "(void)") parms = "()";

	$0 = gensub(/(int|void|uint32_t|DB_[A-Z]+ \*|void \*|char \*)([ \t]*)\((\*)?\*([A-Za-z_]+)\)([ \t]+)(\([0-9A-Za-z_ ,*]*\));/, sprintf("\\1\\2function\\5%s\\3 %s;", parms, name), "g");
	}
/(char|void) \*[a-z_]+, \*[a-z_]+;/ {
	$0 = gensub(/(char|void) \*([a-z_]+), \*([a-z_]+);/, "\\1* \\2, \\3;", "g");
	}
/ ref;/ {
	$0 = gensub(/ ref;/, " Ref;", "g");
	}
/function.* version;/ {
	$0 = gensub(/ version;/, " Version;", "g");
	}
/char \*[a-z]+, \*[a-z]+;/ {
	$0 = gensub(/char \*([a-z]+), \*([a-z]+);/, "char* \\1, \\2;", "g");
	}
/ ref;/ {
	$0 = gensub(/ ref;/, " Ref;", "g");
	}
/function.* version;/ {
	$0 = gensub(/ version;/, " Version;", "g");
	}
/(int|void)([ \t]+)\(\*([A-Za-z_]+)\)([ \t]+)\(/ {
	funcstart=1;
	funcname=gensub(/.*(int|void|uint32_t)([ \t]+)\(\*([A-Za-z_]+)\)([ \t]+)\(.*/, "\\3", "g");
	$0 = gensub(/(int|void|uint32_t)([ \t]+)\(\*([A-Za-z_]+)\)([ \t]+)\(/, "\\1\\2function\\4(", "g");
	}
/(int|void|uint32_t|void \*|size_t|char \*)([ \t]*)\((\*?)\*\)([ \t]*)(\(([0-9A-Za-z_ *.]*,|[0-9A-Za-z_ *.]*\([0-9A-Za-z_ *.]*\)[0-9A-Za-z_ *.]*,)*([0-9A-Za-z_ *.]*|[0-9A-Za-z_ *.]*\([0-9A-Za-z_ *.]*\)[0-9A-Za-z_ *.]*)\))[,\)]/ {
	$0 = gensub(/(int|void|uint32_t|void \*|size_t|char \*)([ \t]*)\((\*?)\*\)([ \t]*)(\(([0-9A-Za-z_ *.]*,|[0-9A-Za-z_ *.]*\([0-9A-Za-z_ *.]*\)[0-9A-Za-z_ *.]*,)*([0-9A-Za-z_ *.]*|[0-9A-Za-z_ *.]*\([0-9A-Za-z_ *.]*\)[0-9A-Za-z_ *.]*)\))([,\)])/, "\\1\\2function\\4\\5\\3\\8", "g");
	}
funcstart==1 && /(int|void|uint32_t|void \*|size_t)([ \t]*)\((\*?)\*\)([ \t]*)(\([0-9A-Za-z_ ,*\t]*)$/ {
	$0 = gensub(/(int|void|uint32_t|void \*|size_t)([ \t]*)\((\*?)\*\)([ \t]*)(\([0-9A-Za-z_ ,*\t]*)/, "\\1\\2function\\4\\5", "g");
	subfunc_pointer = gensub(/(int|void|uint32_t|void \*|size_t)([ \t]*)\((\*?)\*\)([ \t]*)(\([0-9A-Za-z_ ,*\t]*)/, "\\6", "g");
	subfunc = 1;
	}
funcstart==1 && subfunc==1 && /^(\([0-9A-Za-z_ ,*\t]*\))([,)])$/ {
	$0 = gensub(/(\([0-9A-Za-z_ ,*\t]*\))([,)])/, sprintf("\\1%s\\3", subfunc_pointer), "g");
	subfunc = 0;
	}
funcstart==1 && /\);/ {
	funcstart=0;
	$0 = gensub(/\);/, sprintf(") %s;", funcname), "g");
	}

/(int|void|uint32_t)([ \t]+)\(\*([A-Za-z_]+)\)[ \t]*$/ {
	funcstart=1;
	funcname=gensub(/.*(int|void|uint32_t)([ \t]+)\(\*([A-Za-z_]+)\)[ \t]*$/, "\\3", "g");
	$0 = gensub(/(int|void|uint32_t)([ \t]+)\(\*([A-Za-z_]+)\)[ \t]*$/, "\\1\\2function", "g");
	}
funcstart==1 && /\(.*\)[ \t]*;/ {
	funcstart=0;
	$0 = gensub(/\)[ \t]*;/, sprintf(") %s;", funcname), "g");
	}

/^#define[ \t]+(DB_VERSION_[A-Z_]+)([ \t]+)(@[A-Z_]+@)/ {
		if (match($0, /STRING/))
		{
			$0 = gensub(/#define[ \t]+(DB_VERSION_[A-Z_]+)([ \t]+)(@[A-Z_]+@)/, "string \\1\\2= \\3;", "g");
		}
		else
		{
			$0 = gensub(/#define[ \t]+(DB_VERSION_[A-Z_]+)([ \t]+)(@[A-Z_]+@)/, "const int \\1\\2= \\3;", "g");
		}
	}	
/@DB_VERSION_FAMILY@/ { $0 = gensub(/@DB_VERSION_FAMILY@/, DB_VERSION_FAMILY, "g") }
/@DB_VERSION_RELEASE@/ { $0 = gensub(/@DB_VERSION_RELEASE@/, DB_VERSION_RELEASE, "g") }
/@DB_VERSION_MAJOR@/ { $0 = gensub(/@DB_VERSION_MAJOR@/, DB_VERSION_MAJOR, "g") }
/@DB_VERSION_MINOR@/ { $0 = gensub(/@DB_VERSION_MINOR@/, DB_VERSION_MINOR, "g") }
/@DB_VERSION_PATCH@/ { $0 = gensub(/@DB_VERSION_PATCH@/, DB_VERSION_PATCH, "g") }
/@DB_VERSION_STRING@/ { $0 = gensub(/@DB_VERSION_STRING@/, sprintf("\"%s\"", DB_VERSION_STRING), "g") }
/@DB_VERSION_FULL_STRING@/ { $0 = gensub(/@DB_VERSION_FULL_STRING@/, sprintf("\"%s\"", DB_VERSION_FULL_STRING), "g") }

/^#define[ \t]+([A-Z_]*)([ \t]+)("[^"]*")/ {
		$0 = gensub(/#define[ \t]+([A-Z_]*)([ \t]+)("[^"]*")/, "string\t\\1\\2= \\3;", "g");
	}	

!struct_defining_start && /^struct [a-z_]+ \{/ { 
	struct_defining_start = 1; enums_lines = ""; 
}

struct_defining_start == 1 && /^\};/ {
	struct_defining_start = 0; 
	print; 
	if ( enums_lines != "")	print enums_lines;
	next;
}

/^#define[ \t]+([0-9A-Za-z_]+)([ \t]+)\(?(-?[0-9]+|0x[0-9a-f]+)\)?/ {
	$0 = gensub(/#define([ \t]+)([0-9A-Za-z_]+)([ \t]+)\(?(-?[0-9]+|0x[0-9a-f]+)\)?/, "enum\\1\\2\\3= \\4;", "g");
	if (struct_defining_start == 1)
	{
		enums_lines = sprintf("%s\n%s", enums_lines, $0);
	}
	else
	{
		print;
	}

	next;
}

0 && /^#define[ \t]+([0-9A-Z_]+)([ \t]+)\(?(-?[0-9]+)\)?/ {
		if (enum==0) 
		{
			print "enum\n{";
			enum = 1;
		}	
		else
		{
			print ",";
		}

		$0 = gensub(/#define[ \t]+([0-9A-Z_]+)([ \t]+)\(?(-?[0-9]+)\)?/, "\t\\1\\2= \\3", "g");

		printf "%s", $0;
		next; 
	}

/^#define[ \t]+([0-9A-Z_]+_FLAGS)([ \t]+)\(?([A-Z_ |]+)\)?/ {
	$0 = gensub(/#define[ \t]+([0-9A-Z_]+_FLAGS)([ \t]+)\(?([A-Z_ |]+)\)?/, "enum \\1\\2= \\3;", "g");
	print;
	next; 
}

/^#define[ \t]+([0-9A-Z_]+_SZ)([ \t]+)\(?([a-z_ +().]+)\)?$/ {
	$0 = gensub(/#define[ \t]+([0-9A-Z_]+_SZ)([ \t]+)\(([a-z_ +().]+)\)$/, "enum \\1\\2= \\3;", "g");
	$0 = gensub(/#define[ \t]+([0-9A-Z_]+_SZ)([ \t]+)([a-z_ +().]+)$/, "enum \\1\\2= \\3;", "g");
	print;
	next; 
}

0 && enum==1 && !/^[^*]+\*\// { print "\n}\n"; enum=0; }

/^#define[ \t]+[0-9A-Za-z_]+[ \t]*([A-Za-z_@]*)[ \t]*$/ {
	name = gensub(/^#define[ \t]+([0-9A-Za-z_]+)[ \t]*([A-Za-z_@]*)[ \t]*$/, "\\1", "g");
	funct = gensub(/^#define[ \t]+([0-9A-Za-z_]+)[ \t]*([A-Za-z_@]*)[ \t]*$/, "\\2", "g");
	funct = gensub(/@DB_VERSION_UNIQUE_NAME@/, DB_VERSION_UNIQUE_NAME, "g", funct);
	if (name == funct) next;

	macroses[name] = funct;
	$0 = sprintf("alias %s %s;",funct, name);
}

/^#define[ \t]+[A-Za-z_]+\([A-Za-z_, ]+\)[ \t]*(.*)$/ {
	name = gensub(/#define[ \t]+([A-Za-z_]+)\(([A-Za-z_]+)([A-Za-z_ ,]*)?\).*/, "\\1", "g");
	var = gensub(/#define[ \t]+([A-Za-z_]+)\(([A-Za-z_]+)([A-Za-z_ ,]*)?\).*/, "\\2", "g");
	vars = gensub(/#define[ \t]+([A-Za-z_]+)\(([A-Za-z_]+)([A-Za-z_ ,]*)?\).*/, "\\3", "g");
	definition = gensub(/^#define[ \t]+[A-Za-z_]+\([A-Za-z_, ]+\)[ \t]*(.*)$/, "\\1", "g");

	i = 0;
	if ( match(var, /CLASS|TYPE/) )
	{
		typestr = var;
	}
	else
	{
		typestr = types_ar[0];
		varstr = sprintf("%s %s", types_ar[0], var);
		i=1;
	}

	while (match(vars, /[A-Za-z_]/) > 0)
	{
		var = gensub(/^ *, *([A-Za-z_]+)(, *[A-Za-z_ ,]*)?/, "\\1", "g", vars);
		vars = gensub(/^ *, *([A-Za-z_]+)(, *[A-Za-z_ ,]*)?/, "\\2", "g", vars);
		if ( match(var, /CLASS|TYPE/) )
		{
			typestr = sprintf("%s, %s", typestr, var);
		}
		else
		{
			typestr = sprintf("%s, %s", typestr, types_ar[i]);
			varstr = sprintf("%s, %s %s", varstr, types_ar[i], var);
			i++;
		}
	}

	if (varstr == "" && match(name, "CLASS"))
	{
		mixin_define = 1;
		printf "mixin template %s(%s)\n{\n", name, typestr;
	}
	else if (varstr == "")
	{
		printf "auto template %s(%s)\n{\n", name, typestr;
	}
	else
	{
		printf "auto %s(%s)(%s)\n{\n", name, typestr, varstr;
	}

	if (match(definition, /^\\$/))
	{
		define_start = 1;
		define_line = 0;
	}
	else
	{
		if ( match(definition, /@DB_VERSION_UNIQUE_NAME@/) )
		{
			call_name = gensub(/.*([A-Za-z_]*@DB_VERSION_UNIQUE_NAME@).*/, "\\1", "g", vars);
			macroses[name] = call_name;
		}

		definition = gensub(/@DB_VERSION_UNIQUE_NAME@/, DB_VERSION_UNIQUE_NAME, "g", definition);
		printf "\treturn %s;\n}\n", definition;
	}
	next;
}

define_start == 1 {
		slashed = match($0, /\\$/);
		if ( match($0, /[A-Za-z_]+[ \t]+[A-Za-z_*]+\(/) )
		{
			func_header = func_header + 1;
		}

		if ( func_header > 0 && match($0, /{/) )
		{
			funcs = funcs + 1;
		}
		if ( match($0, /do {/) )
		{
			funcs = funcs + 1;
		}
		if ( funcs > 0 && match($0, /}/) )
		{
			funcs = funcs - 1;
			func_header = func_header - 1;
		}

		$0 = gensub(/[ \t]*\\$/, "", "g");
		$0 = gensub(/return([ \t]*)\((.*)\);/, "return\\1\\2;", "g");
		$0 = gensub(/->/, ".", "g");
		$0 = gensub(/::/, ".", "g");
		$0 = gensub(/inline */, "", "g");
		$0 = gensub(/class *.*/, "", "g");
		$0 = gensub(/const ([_A-Za-z]+) +\*/, "const (\\1*) ", "g");
		$0 = gensub(/_##([A-Z_]*TYPE[A-Z_]*)\(\)/, "!(\\1)", "g");
		brackets = brackets + gsub(/\(/, "(");
		brackets = brackets - gsub(/\)/, ")");
		if (brackets == 0 && funcs == 0 && func_header == 0 &&
		    	!match($0, /^[ \t]*$/))
		{
			$0 = sprintf("%s;", $0);
		}
		if (slashed)
		{
			$0 = sprintf("%s\\", $0);
		}
	}

define_start == 1 && /[^\\]$/ {
	define_start = 0;
	if (match($0, /while.*\)$/))
	{
		$0 = sprintf("%s;\n}\n", $0);
	}
	else if (mixin_define == 1 || match($0, /while/))
	{
		$0 = sprintf("%s\n}\n", $0);
	}
	else if (return_bracket)
	{
		return_bracket = 0;
		$0 = gensub(/\);[ \t]*$/, ";\n}\n", "g");
	}
	else
	{
		$0 = gensub(/^([ \t]*)\((.*)\)[ \t]*$/, "\\1\\2", "g");
		$0 = gensub(/[ \t]*(.*)/, "\treturn \\1;\n}\n", "g");
		mixin_define = 0;
	}
}

define_start == 1 && define_line == 0 && /^[ \t]*\(/ {
		$0 = gensub(/^([ \t]*)\(/, "\\1return ", $0);
		return_bracket = 1;
	}

define_start == 1 && /\\$/ {
		$0 = gensub(/\\$/, "", "g");
	}

define_start == 1 {
		define_line = define_line + 1;
	}

/dbfile, \*dbname;/ {
		$0 = gensub(/dbfile, \*dbname;/, "dbfile, dbname;", "g");
	}

/function/ {print; next;}
/\(uint(8|32)_t *\*?\)/ {
		$0 = gensub(/\(uint(8|32)_t *\*?\)/, "cast(uint\\1_t\\2)", "g");
	}

/@DB_VERSION_UNIQUE_NAME@/ { $0 = gensub(/@DB_VERSION_UNIQUE_NAME@/, DB_VERSION_UNIQUE_NAME, "g") }

/^WRAPPED_CLASS/ {
	$0 = gensub(/^WRAPPED_CLASS(.*)$/, "mixin WRAPPED_CLASS!\\1;", "g");
	}

{ print }
