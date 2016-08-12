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

module berkeleydb.dbt;

import berkeleydb.c;
import berkeleydb.dbexception;
import std.array;
import std.traits;
import core.memory;

private inout(ubyte[]) tobytes(T)(inout ref T arg)
if (__traits(hasMember, arg, "sizeof"))
{

	static if(__traits(hasMember, arg, "ptr"))
	{
		auto size = arg.length * typeof(arg[0]).sizeof;
		return (cast(ubyte*)arg.ptr)[0..size];
	}
	else
	{
		auto size = arg.sizeof;
		return (cast(ubyte*)&arg)[0..size];
	}
}

private inout(T) frombytes(T)(inout ubyte[] arg)
if (!isPointer!(T) && !isArray!(T) &&
		__traits(hasMember, T, "sizeof") &&
		!__traits(hasMember, T, "ptr"))
{
	assert(T.sizeof == arg.length, "Casting Dbt to structure with not corresponding size");

	T *res = cast(T*) arg;

	return *res;
}

private inout(T*) frombytes(A: T*, T)(inout ubyte[] arg)
if (__traits(hasMember, T, "sizeof") &&
		!__traits(hasMember, T, "ptr"))
{
	assert(T.sizeof == arg.length, "Casting Dbt to structure with not corresponding size");
	return cast(T*) arg;
}

private inout(T[]) frombytes(A : T[], T)(inout ubyte[] arg)
if (__traits(hasMember, T, "sizeof"))
{
	assert((arg.length % T.sizeof) == 0, "Casting Dbt to array with not corresponding entries size");

	return (cast(T*)arg)[0..arg.length/T.sizeof];
}

private inout(ubyte[]) dbttobytes(inout ref DBT dbt)
{
	return (cast(inout ubyte*)dbt.data)[0..dbt.size];
}

struct Dbt
{
	DBT dbt;
	alias dbt this;

	this(T)(ref T arg)
	{
		opAssign(arg);
	}

	void opAssign(T)(ref T arg)
	if (__traits(hasMember, arg, "sizeof"))
	{
		static if(__traits(hasMember, arg, "ptr"))
		{
			size = arg.length * typeof(arg[0]).sizeof;
			data = cast(void*) arg.ptr;
		}
		else
		{
			size = arg.sizeof;
			data = cast(void*) &arg;
		}
	}

	inout(T) to(T)() inout
	{
		return frombytes!T(dbttobytes(dbt));
	}
}

static assert(DBT.sizeof == Dbt.sizeof);

unittest
{
	string hello = "Hello, world!";

	Dbt dbt = hello;
	assert(dbt.size == hello.length);

	assert(dbt.to!string() == "Hello, world!");
	assert(dbt.to!string() is "Hello, world!");

	struct S
	{
		int a;
		byte b;
	}
	
	S s;
	s.a = 5000;
	s.b = 22;

	Dbt dbt_struct;
    dbt_struct = s;
	assert( dbt_struct.size == s.sizeof );
	assert( dbt_struct.to!S() == s );

	S *ps = dbt_struct.to!(S*)();
	assert( *ps == s );
	assert( ps is &s );
}

struct UserMemDbt
{
	DBT dbt = DBT(null, 0, 0, 0, 0, null, DB_DBT_USERMEM);
	alias dbt this;

    invariant()
    {
        assert(dbt.flags & DB_DBT_USERMEM);
    }

    this(ref Dbt dbt)
    {
        if (!(dbt.flags & DB_DBT_USERMEM))
        {
            throw new DbWrongUsingException("Constructing UserMemDbt from Dbt variable without DB_DBT_USERMEM in flags");
        }
        this.dbt = dbt;
    }

	this(T)(ref T arg)
	{
		opAssign(arg);
	}
	
	this(T)(int size, ref T arg)
	in {
		assert(size > 0);
	}
	body {
		ulen = size;
		data = GC.malloc(size);
		opAssign(arg);
	}
	
	this()(int size)
	in {
		assert(size > 0);
	}
	body {
		ulen = size;
		data = GC.malloc(size);
	}

	/*~this()
	{
		GC.free(data);
	}*/

	void opAssign(T)(ref T arg)
	if (__traits(hasMember, arg, "sizeof"))
	{

		static if(__traits(hasMember, arg, "ptr"))
		{
			size = arg.length * typeof(arg[0]).sizeof;

			if (ulen == 0)
			{
				ulen = size;
				data = GC.malloc(size);
			}

			assert(size <= ulen);
			(cast(char*) data)[0..size] = 
				(cast(char*) arg.ptr)[0..size];
		}
		else
		{
			size = arg.sizeof;

			if (ulen == 0)
			{
				ulen = size;
				data = GC.malloc(size);
			}

			assert(size <= ulen);
			(cast(char*) data)[0..size] = 
				(cast(char*) &arg)[0..size];
		}
	}

	inout(T) to(T)() inout
	{
		return frombytes!T(dbttobytes(dbt));
	}
}

unittest
{
	string hello = "Hello, world!";

	UserMemDbt dbt = UserMemDbt(20, hello);
	assert(dbt.size == hello.length);

	assert(dbt.to!string() == "Hello, world!");
	assert(dbt.to!string() !is "Hello, world!");

	struct S
	{
		int a;
		byte b;
	}
	
	S s;
	s.a = 5000;
	s.b = 22;

    dbt = s;
	assert( dbt.size == s.sizeof );
	assert( dbt.to!S() == s );

	S *ps = dbt.to!(S*)();
	assert( *ps == s );
	assert( ps !is &s );
}

import std.stdint;
import std.exception;
import std.range;
import std.typecons;

struct BulkDbt
{
	DBT dbt = DBT(null, 0, 0, 0, 0, null, DB_DBT_BULK | DB_DBT_USERMEM);
	alias dbt this;
	uint32_t *pointer;

    invariant()
    {
        assert(dbt.flags & DB_DBT_BULK);
    }

	struct Range(T) {
		uint32_t *pointer;
		DBT *dbt;

		private this(BulkDbt* b) { 
			dbt = &b.dbt;
			pointer = cast(uint32_t*)(cast(ubyte*)dbt.data + 
					dbt.ulen) - 1;
		}

		/// Forward range primitives.
		@property bool empty() const { 
			return !pointer || *pointer == -1; 
		}
		/// ditto
		@property Range save() { return this; }

		/// ditto
		@property T front() 
		{ 
			uint32_t *__p = pointer;
			if (*__p == -1) return null;

			ubyte *retdata = cast(uint8_t*)dbt.data + *__p--;
			uint32_t retdlen = *__p--;

			return frombytes!T(retdata[0..retdlen]); 
		}

		/// ditto
		void popFront()
		{
			enforce(pointer);
			pointer -= 2;
		}

		T moveFront()
		{
			enforce(pointer);
			return front();
		}
	}

	struct KeyRange(K, V) {
		uint32_t *pointer;
		DBT *dbt;

		struct KeyValuePair{
			K key;
			V value;

			bool opEquals(KeyValuePair arg)
			{
				return key == arg.key && value == arg.value;
			}

		};

		alias KeyValuePair KV;

		private this(BulkDbt* b) { 
			dbt = &b.dbt;
			pointer = cast(uint32_t*)(cast(ubyte*)dbt.data + 
					dbt.ulen) - 1;
		}

		/// Forward range primitives.
		@property bool empty() const { 
			return !pointer || *pointer == -1; 
		}
		/// ditto
		@property KeyRange save() { return this; }

		private @property T _front(T)() 
		{ 
			uint32_t *__p = pointer;
			if (*__p == -1) return null;

			ubyte *retdata = cast(uint8_t*)dbt.data + *__p--;
			uint32_t retdlen = *__p--;

			return frombytes!T(retdata[0..retdlen]); 
		}

		/// ditto
		@property KV front() 
		{ 
			KV res;
			res.key = _front!K();
			pointer -= 2;
			res.value = _front!V();
			pointer += 2;

			return res; 
		}

		/// ditto
		void popFront()
		{
			enforce(pointer);
			pointer -= 4;
		}

		KV moveFront()
		{
			enforce(pointer);
			return front();
		}
	}

	Range!(ubyte[]) opSlice()
	{
		return Range!(ubyte[])(&this);
	}

	Range!(T) range(T)()
	{
		return Range!(T)(&this);
	}

	KeyRange!(K, V) keyrange(K, V)()
	{
		return KeyRange!(K, V)(&this);
	}

    void set_pointer()
    {
		pointer = cast(uint32_t*)(cast(ubyte*)data + ulen) -1;
        while (*pointer != -1)
        {
            pointer -= 2;
            if (pointer < data)
            {
                throw new DbWrongUsingException("Constructing BulkDbt from wrong DBT");
            }
        }
    }

    this(ref Dbt dbt)
    {
        if (!(dbt.flags & DB_DBT_BULK))
        {
            throw new DbWrongUsingException("Constructing BulkDbt from Dbt variable without DB_DBT_BULK in flags");
        }
        this.dbt = dbt;
        set_pointer();
    }

	this(T)(int size, ref T arg)
	if (isForwardRange!T || is(typeof(arg.byKey())))
	in {
		assert(size > 0);
	}
	body {
		ulen = size;
		data = GC.malloc(size);
		pointer = cast(uint32_t*)(cast(ubyte*)data + ulen) -1;
		*pointer = -1;
		insertFronts(arg);
	}

	this()(int size)
	in {
		assert(size > 0);
	}
	body {
		ulen = size;
		data = GC.malloc(size);
		pointer = cast(uint32_t*)(cast(ubyte*)data + ulen) -1;
		*pointer = -1;
	}

	
	/*~this()
	{
		GC.free(data);
	}*/

	@property bool empty() const
	{
		return pointer is null;
	}

	/**
	  Duplicates the container. 

	  Complexity: $(BIGOH n).
	 */
	@property BulkDbt dup()
	{
        auto t = this[];
		return BulkDbt(ulen, t);
	}

	/**
	  Forward to $(D opSlice().front).

	  Complexity: $(BIGOH 1)
	 */
	@property ubyte[] front()
	{
		uint32_t *__p = pointer;
		if (*__p == -1) return null;

		ubyte *retdata = cast(uint8_t*)dbt.data + *__p--;
		uint32_t retdlen = *__p--;

		return retdata[0..retdlen]; 
	}

	/**
	  Inserts $(D stuff) to the front of the container. 

	  Returns: The number of elements inserted

	  Complexity: $(BIGOH log(n))
	 */
	size_t insertFronts(Stuff)(Stuff stuff)
	if (isForwardRange!Stuff && is(typeof(tobytes(stuff.front))) ||
				is(typeof(stuff.front): ubyte[]))
	{
		size_t result;
		foreach (item; stuff)
		{
			insertFront(item);
			++result;
		}
		return result;
	}

	/// ditto
	size_t insertFront(T)(T _value)
	if (is(typeof(tobytes(_value))))
	{
		ubyte[] value = tobytes(_value);

		uint32_t *__p = pointer;
		uint32_t __off = (pointer == 
		  (cast(uint32_t*)(cast(ubyte*)dbt.data + dbt.ulen) - 1)) 
			?  0 : __p[1] + __p[2];
		assert(__p && *__p == -1);

		auto writedlen = value.length * typeof(value[0]).sizeof;

		if ((cast(ubyte*)dbt.data + __off + writedlen) >
				cast(ubyte*)(__p - 2))
			throw new DbWrongUsingException("BulkDbt overflow");
		else {
			ubyte *writedata = cast(uint8_t*)dbt.data + __off;
			writedata[0..writedlen] = value[0..writedlen];
			__p[0] = __off;
			__p[-1] = cast(uint32_t)(writedlen);
			__p[-2] = cast(uint32_t)-1;
			pointer = __p - 2;
		}

		return 1; 
	}

	size_t insertFronts(K, V)(Tuple!(K, V) stuff)
	{
		size_t result;
		insertFront(stuff[0]);
		++result;
		insertFront(stuff[1]);
		++result;
		return result;
	}

	size_t insertFronts(Stuff)(ref Stuff stuff)
	if (is(typeof(stuff.byKey())))
	{
		size_t result;
		foreach (key; stuff.byKey())
		{
			insertFront(key);
			++result;
			insertFront(stuff[key]);
			++result;
		}
		return result;
	}
	
	/// ditto
	alias insertFront insert;

	/// ditto
	alias insert stableInsert;

	/// ditto
	alias insertFront stableInsertFront;

	/**
	  Removes the value at the front of the container. 

	  Precondition: $(D !empty)

	  Complexity: $(BIGOH 1).
	 */
	void removeFront()
	{
		enforce(pointer);
		uint32_t *__p = pointer;

		if ((cast(ubyte*)dbt.data + ulen) == cast(ubyte*)__p)
			throw new DbWrongUsingException("BulkDbt underflow");

		__p[0] = 0;
		__p[1] = 0;
		__p[2] = -1;
		pointer += 2;
	}

	/// ditto
	alias removeFront stableRemoveFront;

	/**
	  Removes $(D howMany) values at the front or back of the
	  container. 

Returns: The number of elements removed

Complexity: $(BIGOH howMany * log(n)).
     */
	size_t removeFront(size_t howMany)
	{
		size_t result;
		while (result < howMany)
		{
			removeFront();
			++result;
		}
		return result;
	}

	/// ditto
	alias removeFront stableRemoveFront;
}

unittest
{
    auto ar = ["Hello", "World!", "The piece"];
	BulkDbt dbt = BulkDbt(100, ar);

	assert(dbt.range!(string).front == "Hello");
	assert(dbt.range!(string).drop(1).front == "World!");
	assert(dbt.range!(string).drop(2).front == "The piece");
	assert(dbt[].walkLength == 3);

	string[string] map;
	map["Hello"] = "Hi!";
	map["Black"] = "White";
	map["Cat"] = "Dog";

	BulkDbt keydbt = BulkDbt(120, map);
    keydbt.insertFronts(tuple("I", "You"));

	auto keyrange = keydbt.keyrange!(string, string);
	
	alias typeof(keyrange).KeyValuePair KeyValuePair;

    /*Map doesn't guarantee any order*/
    int check( typeof(keyrange.front) value )
    {
        return value == KeyValuePair("Hello", "Hi!") ||
            value == KeyValuePair("Cat", "Dog") ||
            value == KeyValuePair("Black", "White");
    }

	assert(check(keyrange.front));
	assert(keyrange.drop(1).front != keyrange.front &&
            check(keyrange.drop(1).front));
	assert(keyrange.drop(2).front != keyrange.front &&
            keyrange.drop(2).front != keyrange.drop(1).front &&
            check(keyrange.drop(2).front));
	assert(keyrange.drop(3).front == KeyValuePair("I", "You"));
	assert(keydbt.keyrange!(ubyte[], ubyte[]).walkLength == 4);

    keydbt.removeFront(2);
    keydbt.insertFronts(tuple("Apple", "Pear"));
	assert(keyrange.drop(3).front == KeyValuePair("Apple", "Pear"));
	assert(keydbt.keyrange!(ubyte[], ubyte[]).walkLength == 4);
}

struct RecnoBulkDbt
{
	DBT dbt = DBT(null, 0, 0, 0, 0, null, DB_DBT_BULK | DB_DBT_USERMEM);
	alias dbt this;
	uint32_t *pointer;

    invariant()
    {
        assert(dbt.flags & DB_DBT_BULK);
    }

	struct KeyRange(K, V)
        if (isNumeric!(K)) {
		uint32_t *pointer;
		DBT *dbt;

		struct KeyValuePair{
			K key;
			V value;

			bool opEquals(KeyValuePair arg)
			{
				return key == arg.key && value == arg.value;
			}

		};

		alias KeyValuePair KV;

		private this(RecnoBulkDbt* b) { 
			dbt = &b.dbt;
			pointer = cast(uint32_t*)(cast(ubyte*)dbt.data + 
					dbt.ulen) - 1;
		}

		/// Forward range primitives.
		@property bool empty() const { 
			return !pointer || *pointer == 0; 
		}
		/// ditto
		@property KeyRange save() { return this; }

		private @property Tuple!(K,V) _front(K, V)() 
		{ 
			uint32_t *__p = pointer;
			if (*__p == 0) return tuple(cast(K) 0, cast(V) null);

            uint32_t key = *__p--;
			ubyte *retdata = cast(uint8_t*)dbt.data + *__p--;
			uint32_t retdlen = *__p--;

			return tuple(cast(K) key, frombytes!V(retdata[0..retdlen]));
		}

		/// ditto
		@property KV front() 
		{ 
			KV res;
			auto v = _front!(K,V)();
            res.key = v[0];
            res.value = v[1];

			return res; 
		}

		/// ditto
		void popFront()
		{
			enforce(pointer);
			pointer -= 3;
		}

		KV moveFront()
		{
			enforce(pointer);
			return front();
		}
	}

	KeyRange!(K, V) keyrange(K, V)()
	{
		return KeyRange!(K, V)(&this);
	}

    void set_pointer()
    {
		pointer = cast(uint32_t*)(cast(ubyte*)data + ulen) -1;
        while (*pointer != 0)
        {
            pointer -= 3;
            if (pointer < data)
            {
                throw new DbWrongUsingException("Constructing BulkDbt from wrong DBT");
            }
        }
    }

    this(ref Dbt dbt)
    {
        if (!(dbt.flags & DB_DBT_BULK))
        {
            throw new DbWrongUsingException("Constructing RecnoBulkDbt from Dbt variable without DB_DBT_BULK in flags");
        }
        this.dbt = dbt;
        set_pointer();
    }

	this(T)(int size, ref T arg)
	if (isForwardRange!T || is(typeof(arg.byKey())))
	in {
		assert(size > 0);
	}
	body {
		ulen = size;
		data = GC.malloc(size);
		pointer = cast(uint32_t*)(cast(ubyte*)data + ulen) -1;
		*pointer = 0;
		insertFronts(arg);
	}

	this()(int size)
	in {
		assert(size > 0);
	}
	body {
		ulen = size;
		data = GC.malloc(size);
		pointer = cast(uint32_t*)(cast(ubyte*)data + ulen) -1;
		*pointer = 0;
	}

	/*~this()
	{
		GC.free(data);
	}*/

	@property bool empty() const
	{
		return pointer is null;
	}

	/**
	  Duplicates the container. The elements themselves are not transitively
	  duplicated.

	  Complexity: $(BIGOH n).
	 */
	/*TODO @property BulkDbt dup()
	{
		return BulkDbt(ulen, this[]);
	}*/

	/**
	  Forward to $(D opSlice().front).

	  Complexity: $(BIGOH 1)
	 */
	@property Tuple!(K, V) front(K,V)()
    if (isNumeric!(K)) {
		uint32_t *__p = pointer;
		if (*__p == 0) return tuple(0, null);

        uint32_t key = *__p--;
		ubyte *retdata = cast(uint8_t*)dbt.data + *__p--;
		uint32_t retdlen = *__p--;

		return tuple(key, retdata[0..retdlen]); 
	}

	/**
	  Inserts $(D stuff) to the front of the container.

	  Returns: The number of elements inserted

	  Complexity: $(BIGOH log(n))
	 */
	size_t insertFront(K, V)(Tuple!(K, V) stuff)
    if (isNumeric!(K)) {
        uint32_t key = stuff[0];
		ubyte[] value = tobytes(stuff[1]);

		uint32_t *__p = pointer;
		uint32_t __off = (pointer == 
		  (cast(uint32_t*)(cast(ubyte*)dbt.data + dbt.ulen) - 1)) 
			?  0 : __p[1] + __p[2];
		assert(__p && *__p == 0);

		auto writedlen = value.length * typeof(value[0]).sizeof;

		if ((cast(ubyte*)dbt.data + __off + writedlen) >
				cast(ubyte*)(__p - 3))
			throw new DbWrongUsingException("RecnoBulkDbt overflow");
		else {
			ubyte *writedata = cast(uint8_t*)dbt.data + __off;
			writedata[0..writedlen] = value[0..writedlen];
			__p[0] = key;
			__p[-1] = __off;
			__p[-2] = cast(uint32_t)(writedlen);
			__p[-3] = 0;
			pointer = __p - 3;
		}

		return 1;
	}

	/// ditto
	size_t insertFronts(Stuff)(Stuff stuff)
	if (is(typeof(stuff.byKey())))
	{
		size_t result;
		foreach (key; stuff.byKey())
		{
			insertFront(tuple(key, stuff[key]));
			++result;
		}
		return result;
	}
	
	/// ditto
	alias insertFront insert;

	/// ditto
	alias insert stableInsert;

	/// ditto
	alias insertFront stableInsertFront;

	/**
	  Removes the value at the front of the container. 

	  Precondition: $(D !empty)

	  Complexity: $(BIGOH 1).
	 */
	void removeFront()
	{
		enforce(pointer);
		uint32_t *__p = pointer;

		if ((cast(ubyte*)dbt.data + ulen) == cast(ubyte*)__p)
			throw new DbWrongUsingException("RecnoBulkDbt underflow");

		__p[0] = 0;
		__p[1] = 0;
		__p[2] = 0;
		__p[3] = 0;
		pointer += 3;
	}

	/// ditto
	alias removeFront stableRemoveFront;

	/**
	  Removes $(D howMany) values at the front or back of the
	  container.

Returns: The number of elements removed

Complexity: $(BIGOH howMany * log(n)).
     */
	size_t removeFront(size_t howMany)
	{
		size_t result;
		while (result < howMany)
		{
			removeFront();
			++result;
		}
		return result;
	}

	/// ditto
	alias removeFront stableRemoveFront;
}

unittest
{
	import std.stdio;

	string[int] map;
	map[1] = "Hi!";
	map[2] = "Dog";
	map[100] = "White";

	RecnoBulkDbt keydbt = RecnoBulkDbt(100, map);

	auto keyrange = keydbt.keyrange!(int, string);
	
	alias typeof(keyrange).KeyValuePair KeyValuePair;

    /*Map doesn't guarantee any order*/
    int check( typeof(keyrange.front) value )
    {
        return value == KeyValuePair(1, "Hi!") ||
            value == KeyValuePair(2, "Dog") ||
            value == KeyValuePair(100, "White");
    }

	assert(check(keyrange.front));
	assert(keyrange.drop(1).front != keyrange.front &&
            check(keyrange.drop(1).front) );
	assert(keyrange.drop(2).front != keyrange.front &&
	        keyrange.drop(2).front != keyrange.drop(1).front &&
            check(keyrange.drop(2).front));
	assert(keydbt.keyrange!(int, ubyte[]).walkLength == 3);

    keydbt.removeFront();
    keydbt.insertFront(tuple(10, "Pear"));
	assert(keyrange.drop(2).front == KeyValuePair(10, "Pear"));
	assert(keydbt.keyrange!(int, ubyte[]).walkLength == 3);
}

Dbt *toDbt(RecnoBulkDbt *dbt)
{
    return cast(Dbt*) dbt;
}

Dbt *toDbt(BulkDbt *dbt)
{
    return cast(Dbt*) dbt;
}

Dbt *toDbt(UserMemDbt *dbt)
{
    return cast(Dbt*) dbt;
}
