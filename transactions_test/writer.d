module main;
import std.algorithm;
import std.stdio;
import berkeleydb.all;
import core.thread;
import std.file;
import std.stdint;
import std.conv;

void main()
{
    try{
        mkdir("/tmp/berkeleydb.locks");
    } catch (FileException file)
    {
    }

    DbEnv dbenv = new DbEnv(0);

    uint32_t env_flags = DB_CREATE |    /* Create the environment if it does 
                                * not already exist. */
                DB_INIT_TXN  | /* Initialize transactions */
                DB_INIT_LOCK | /* Initialize locking. */
                DB_INIT_LOG  | /* Initialize logging */
                DB_INIT_MPOOL; /* Initialize the in-memory cache. */

    dbenv.open("/tmp/berkeleydb.locks/", env_flags, octal!666);

    Db db = new Db(dbenv, 0);
    db.open(null, "numbers.db", null, DB_BTREE, DB_CREATE | DB_AUTO_COMMIT | DB_MULTIVERSION, octal!600);

    uint the_number = 1;
    while (true)
    {
        auto txn = dbenv.txn_begin(null);
        for (int i=0; i <10; i++)
        {
            Dbt key;
            Dbt data;
            string str = "the_number";
            key = str;
            data = the_number;

            auto res = db.put(txn, &key, &data);
            if (res == 0)
                writeln("number is ", the_number);
            else
                writeln("number not written");
            the_number++;
        }
        txn.commit();

        Thread.sleep( dur!("seconds")( 1 ) );
    }
}
