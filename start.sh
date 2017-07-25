#!/bin/bash
# Setup & start postgres.
sudo -u circleci initdb -D /usr/local/pgsql/data
sudo -u circleci pg_ctl start -D /usr/local/pgsql/data
sleep 1 # wait for pg to start up
sudo -u circleci createuser root --createdb --superuser

# Start redis.
redis-server --daemonize yes

# Start memcached.
sudo -u circleci memcached -d
