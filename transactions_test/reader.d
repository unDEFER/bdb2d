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
                DB_INIT_MPOOL|
                DB_RECOVER; /* Initialize the in-memory cache. */

    dbenv.open("/tmp/berkeleydb.locks/", env_flags, octal!666);

    Db db = new Db(dbenv, 0);
    db.open(null, "numbers.db", null, DB_BTREE, DB_CREATE | DB_AUTO_COMMIT | DB_MULTIVERSION, octal!600);

    while (true)
    {
        auto txn = dbenv.txn_begin(null, DB_TXN_SNAPSHOT);

        for (int i=0; i <5; i++)
        {
            Dbt key;
            Dbt data;
            string str = "the_number";
            key = str;

            auto res = db.get(txn, &key, &data);
            if (res == 0)
            {
                uint the_number = data.to!uint;
                writeln("number is ", the_number);
            }
            else
            {
                dbenv.err(res, "number not readed");
            }

            Thread.sleep( dur!("seconds")( 1 ) );
        }

        txn.commit();
    }
}
