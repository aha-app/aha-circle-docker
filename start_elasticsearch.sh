#!/bin/bash
# Start elasticsearch, sleep to give time for ES to bootup (there is something asynchronous about the bootup of ES via service)
update-rc.d elasticsearch defaults 95 10
echo '-Xms200m\n-Xmx200m' >> /etc/elasticsearch/jvm.options
service elasticsearch start

for i in 1 2 3 4 5 6 7 8
do
  echo "Connecting to ES, try $i"
  if [ $(curl -s -w "%{http_code}" "http://localhost:9200/?pretty" -o /dev/null) = "200" ]
  then
    echo "ES OK" && break
  else
    echo "ES unable to connect" && sleep 3;
  fi
done
