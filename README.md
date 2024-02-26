1) Create a postgres database called 'cost' and give yourself access, eg

```
$ su - postgres
postgres@bacon:~$ psql
postgres=# create database cost;
CREATE DATABASE
postgres=# GRANT ALL PRIVILEGES ON DATABASE cost to <USERNAME>;
GRANT
```

2) Download report from Billing
   
   a) => Cost Table => Table configuration (Select No Grouping)

   b) Download and copy/move to `raw_billing_csvs/` folder

4) `./run.sh`

5) `psql cost < queries.sql`

The queries can be adjusted for your particular needs in analysis.
