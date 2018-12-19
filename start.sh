#!/bin/bash
# Start elasticsearch, sleep to give time for ES to bootup (there is something asynchronous about the bootup of ES via service)
update-rc.d elasticsearch defaults 95 10
ES_JAVA_OPTS=-Xms750m -Xmx750m
service elasticsearch start

for i in 1 2 3 4 5 6 7 8
do
  echo "Connecting to ES, try $i"
  if [ $(curl -s -w "%{http_code}" "http://localhost:9200/?pretty" -o /dev/null) = "200" ]
  then
    echo "ES OK" && break
  else
    echo "ES unable to connect" && sleep 10;
  fi
done

# Start postgres.
sudo -u circleci /usr/lib/postgresql/10/bin/pg_ctl -D /usr/local/pgsql/data -l /usr/local/pgsql/log/logfile start
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
