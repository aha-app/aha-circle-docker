#!/bin/bash
# Start postgres.
sudo -u circleci /usr/lib/postgresql/9.3/bin/pg_ctl -D /usr/local/pgsql/data -l /usr/local/pgsql/log/logfile start
sleep 1 # wait for pg to start up
for i in 1 2 3 4 5 6 7 8 9 10 11
do
  sudo -u circleci createuser root --superuser && createdb && break
  echo "createuser retry: $i"
  sleep 1
done

# Set up postgres default template to use UTF-8.
psql -c "UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';"
psql -c "DROP DATABASE template1;"
psql -c "CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UNICODE';"
psql -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';"
psql -d template1 -c "VACUUM FREEZE;"

# Start redis.
redis-server --daemonize yes

# Start memcached.
sudo -u circleci memcached -d
