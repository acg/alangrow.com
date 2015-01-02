
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "PostgreSQL Tip: Bulk Copying Data Between Tables",
        "date": "2011-06-17T00:00:00-0000",
        "root": ".."
      }
    }

Suppose you have two different PostgreSQL databases, db1 and db2. You want to populate db2.table2 with data from db1.table1. How?

Try this:

    psql -c 'COPY table1 TO STDOUT' db1 | \
    psql -c 'COPY table2 FROM STDIN' db2

Is there a more efficient way to do this if the two databases are hosted by the same server instance? Probably.

Then again, if the databases are on different servers, this works:

    psql -c 'COPY table1 TO STDOUT' db1 | \
    ssh host2 psql -c 'COPY table2 FROM STDIN' db2

Bonus: with [pv(1)](http://www.ivarch.com/programs/pv.shtml), you can see how quickly the data is flowing:

    psql -c 'COPY table1 TO STDOUT' db1 | pv | \
    psql -c 'COPY table2 FROM STDIN' db2

