#!/bin/bash
# Setup & start postgres.
sudo -u circleci initdb -D /usr/local/pgsql/data
sudo -u circleci pg_ctl start -D /usr/local/pgsql/data
sleep 1 # wait for pg to start up
for i in 1 2 3 4 5 6 7 8 9 10 11
do
  sudo -u circleci createuser root --createdb --superuser && break
  echo "createuser retry: $i"
  sleep 1
done

# Start redis.
redis-server --daemonize yes

# Start memcached.
sudo -u circleci memcached -d
