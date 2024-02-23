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
   b) Download

4) ./run.sh
