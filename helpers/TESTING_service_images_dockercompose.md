docker-compose test all service images
======================================

This is a docker-compose version of the Lando example tests:

Start up tests
--------------

Run the following commands to get up and running with this example.

```bash
# should remove any previous runs and poweroff
sed -i -e "/###/d" *-docker-compose.yml
cp services-docker-compose.yml docker-compose.yml
docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network
docker-compose down

# pull any required images
docker-compose pull || true

# should start up our services successfully
docker-compose build && docker-compose up -d

# Ensure database pods are ready to connect
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://mariadb-10-4:3306 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://mariadb-10-5:3306 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://mariadb-10-6:3306 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://mariadb-10-11:3306 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://postgres-11:5432 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://postgres-12:5432 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://postgres-13:5432 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://postgres-14:5432 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://postgres-15:5432 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://postgres-16:5432 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://mongo-4:27017 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://rabbitmq:15672 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://redis-6:6379 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://redis-7:6379 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://opensearch-2:9200 -timeout 1m
```

Verification commands
---------------------

Run the following commands to validate things are rolling as they should.

```bash
# should have all the services we expect
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep commons
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep mariadb-10-4
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep mariadb-10-5
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep mariadb-10-6
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep mariadb-10-11
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep mongo-4
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep postgres-11
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep postgres-12
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep postgres-13
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep postgres-14
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep postgres-15
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep postgres-16
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep rabbitmq
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep redis-6
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep redis-7
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep solr-7
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep solr-8
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep nginx
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep varnish-6
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep varnish-7

# commons should be running Alpine Linux
docker-compose exec -T commons sh -c "cat /etc/os-release" | grep "Alpine Linux"

# rabbitmq should have RabbitMQ running 3.10
docker-compose exec -T rabbitmq sh -c "rabbitmqctl version" | grep 3.10

# rabbitmq should have delayed_message_exchange plugin enabled
docker-compose exec -T rabbitmq sh -c "rabbitmq-plugins list" | grep "E" | grep "delayed_message_exchange"

# rabbitmq should have a running RabbitMQ management page running on 15672
docker-compose exec -T commons sh -c "curl -kL http://rabbitmq:15672" | grep "RabbitMQ Management"

# redis-6 should be running Redis v6.0
docker-compose exec -T redis-6 sh -c "redis-server --version" | grep v=6.

# redis-6 should be able to see Redis databases
docker-compose exec -T redis-6 sh -c "redis-cli CONFIG GET databases"

# redis-6 should have initialized database
docker-compose exec -T redis-6 sh -c "redis-cli dbsize"

# redis-6 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/redis?service=redis-6" | grep "SERVICE_HOST=redis-6"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/redis?service=redis-6" | grep "LAGOON_TEST_VAR=all-images"

# redis-7 should be running Redis v7.0
docker-compose exec -T redis-7 sh -c "redis-server --version" | grep v=7.

# redis-7 should be able to see Redis databases
docker-compose exec -T redis-7 sh -c "redis-cli CONFIG GET databases"

# redis-7 should have initialized database
docker-compose exec -T redis-7 sh -c "redis-cli dbsize"

# redis-7 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/redis?service=redis-7" | grep "SERVICE_HOST=redis-7"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/redis?service=redis-7" |grep "LAGOON_TEST_VAR=all-images"

# solr-7 should have a "mycore" Solr core
docker-compose exec -T commons sh -c "curl solr-7:8983/solr/admin/cores?action=STATUS\&core=mycore"

# solr-7 should be able to reload "mycore" Solr core
docker-compose exec -T commons sh -c "curl solr-7:8983/solr/admin/cores?action=RELOAD\&core=mycore"

# solr-7 should have solr 7.7 solrconfig in "mycore" core
docker-compose exec -T solr-7 sh -c "cat /opt/solr/server/solr/mycores/mycore/conf/solrconfig.xml" | grep luceneMatchVersion | grep 7.7

# solr-7 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/solr?service=solr-7" | grep "SERVICE_HOST=solr-7"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/solr?service=solr-7" | grep "LAGOON_TEST_VAR=all-images"

# solr-8 should have a "mycore" Solr core
docker-compose exec -T commons sh -c "curl solr-8:8983/solr/admin/cores?action=STATUS\&core=mycore"

# solr-8 should be able to reload "mycore" Solr core
docker-compose exec -T commons sh -c "curl solr-8:8983/solr/admin/cores?action=RELOAD\&core=mycore"

# solr-8 should have solr 8 solrconfig in "mycore" core
docker-compose exec -T solr-8 sh -c "cat /var/solr/data/mycore/conf/solrconfig.xml" | grep luceneMatchVersion | grep 8.

# solr-8 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/solr?service=solr-8" | grep "SERVICE_HOST=solr-8"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/solr?service=solr-8" | grep "LAGOON_TEST_VAR=all-images"

# mariadb-10-4 should be version 10.4 client
docker-compose exec -T mariadb-10-4 sh -c "mysql -V" | grep "10.4"

# mariadb-10-4 should be version 10.4 server
docker-compose exec -T mariadb-10-4 sh -c "mysql -e \'SHOW variables;\'" | grep "version" | grep "10.4"

# mariadb-10-4 should use default credentials
docker-compose exec -T mariadb-10-4 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW databases;\'" | grep lagoon

# mariadb-10-4 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mariadb?service=mariadb-10-4" | grep "SERVICE_HOST=10.4"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mariadb?service=mariadb-10-4" | grep "LAGOON_TEST_VAR=all-images"

# mariadb-10-5 should be version 10.5 client
docker-compose exec -T mariadb-10-5 sh -c "mysql -V" | grep "10.5"

# mariadb-10-5 should be version 10.5 server
docker-compose exec -T mariadb-10-5 sh -c "mysql -e \'SHOW variables;\'" | grep "version" | grep "10.5"

# mariadb-10-5 should use default credentials
docker-compose exec -T mariadb-10-5 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW databases;\'" | grep lagoon

# mariadb-10-5 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mariadb?service=mariadb-10-5" | grep "SERVICE_HOST=10.5"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mariadb?service=mariadb-10-5" | grep "LAGOON_TEST_VAR=all-images"

# mariadb-10-6 should be version 10.6 client
docker-compose exec -T mariadb-10-6 sh -c "mysql -V" | grep "10.6"

# mariadb-10-6 should be version 10.6 server
docker-compose exec -T mariadb-10-6 sh -c "mysql -e \'SHOW variables;\'" | grep "version" | grep "10.6"

# mariadb-10-6 should have performance schema and slow logging disabled
docker-compose exec -T mariadb-10-6 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW GLOBAL VARIABLES;\'" | grep "performance_schema" | grep "OFF"
docker-compose exec -T mariadb-10-6 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW GLOBAL VARIABLES;\'" | grep "slow_query_log" | grep "OFF"
docker-compose exec -T mariadb-10-6 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW GLOBAL VARIABLES;\'" | grep "long_query_time" | grep "10"
docker-compose exec -T mariadb-10-6 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW GLOBAL VARIABLES;\'" | grep "log_slow_rate_limit" | grep "1"

# mariadb-10-6 should use default credentials
docker-compose exec -T mariadb-10-6 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW databases;\'" | grep lagoon

# mariadb-10-6 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mariadb?service=mariadb-10-6" | grep "SERVICE_HOST=10.6"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mariadb?service=mariadb-10-6" | grep "LAGOON_TEST_VAR=all-images"

# mariadb-10-11 should be version 10.11 client
docker-compose exec -T mariadb-10-11 sh -c "mysql -V" | grep "10.11"

# mariadb-10-11 should be version 10.11 server
docker-compose exec -T mariadb-10-11 sh -c "mysql -e \'SHOW variables;\'" | grep "version" | grep "10.11"

# mariadb-10-11 should have performance schema and slow logging enabled
docker-compose exec -T mariadb-10-11 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW GLOBAL VARIABLES;\'" | grep "performance_schema" | grep "ON"
docker-compose exec -T mariadb-10-11 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW GLOBAL VARIABLES;\'" | grep "slow_query_log" | grep "ON"
docker-compose exec -T mariadb-10-11 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW GLOBAL VARIABLES;\'" | grep "long_query_time" | grep "30"
docker-compose exec -T mariadb-10-11 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW GLOBAL VARIABLES;\'" | grep "log_slow_rate_limit" | grep "5"

# mariadb-10-11 should use default credentials
docker-compose exec -T mariadb-10-11 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW databases;\'" | grep lagoon

# mariadb-10-11 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mariadb?service=mariadb-10-11" | grep "SERVICE_HOST=10.11"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mariadb?service=mariadb-10-11" | grep "LAGOON_TEST_VAR=all-images"

# mongo-4 should be version 4.0 client
docker-compose exec -T mongo-4 sh -c "mongo --version" | grep "shell version" | grep "v4.0"

# mongo-4 should be version 4.0 server
docker-compose exec -T mongo-4 sh -c "mongo --eval \'printjson(db.serverStatus())\'" | grep "server version" | grep "4.0"

# mongo-4 should have test database
docker-compose exec -T mongo-4 sh -c "mongo --eval \'db.stats()\'" | grep "db" | grep "test"

# mongo-4 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mongo?service=mongo-4" | grep "SERVICE_HOST="
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/mongo?service=mongo-4" | grep "LAGOON_TEST_VAR=all"

# postgres-11 should be version 11 client
docker-compose exec -T postgres-11 bash -c "psql --version" | grep "psql" | grep "11."

# postgres-11 should be version 11 server
docker-compose exec -T postgres-11 bash -c "psql -U lagoon -d lagoon -c \'SELECT version();\'" | grep "PostgreSQL" | grep "11."

# postgres-11 should have lagoon database
docker-compose exec -T postgres-11 bash -c "psql -U lagoon -d lagoon -c \'\\l+ lagoon\'" | grep "lagoon"

# postgres-11 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-11" | grep "SERVICE_HOST=PostgreSQL 11"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-11" | grep "LAGOON_TEST_VAR=all-images"

# postgres-12 should be version 12 client
docker-compose exec -T postgres-12 bash -c "psql --version" | grep "psql" | grep "12."

# postgres-12 should be version 12 server
docker-compose exec -T postgres-12 bash -c "psql -U lagoon -d lagoon -c \'SELECT version();\'" | grep "PostgreSQL" | grep "12."

# postgres-12 should have lagoon database
docker-compose exec -T postgres-12 bash -c "psql -U lagoon -d lagoon -c \'\\l+ lagoon\'" | grep "lagoon"

# postgres-12 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-12" | grep "SERVICE_HOST=PostgreSQL 12"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-12" | grep "LAGOON_TEST_VAR=all-images"

# postgres-13 should be version 13 client
docker-compose exec -T postgres-13 bash -c "psql --version" | grep "psql" | grep "13."

# postgres-13 should be version 13 server
docker-compose exec -T postgres-13 bash -c "psql -U lagoon -d lagoon -c \'SELECT version();\'" | grep "PostgreSQL" | grep "13."

# postgres-13 should have lagoon database
docker-compose exec -T postgres-13 bash -c "psql -U lagoon -d lagoon -c \'\\l+ lagoon\'" | grep "lagoon"

# postgres-13 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-13" | grep "SERVICE_HOST=PostgreSQL 13"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-13" | grep "LAGOON_TEST_VAR=all-images"

# postgres-14 should be version 14 client
docker-compose exec -T postgres-14 bash -c "psql --version" | grep "psql" | grep "14."

# postgres-14 should be version 14 server
docker-compose exec -T postgres-14 bash -c "psql -U lagoon -d lagoon -c \'SELECT version();\'" | grep "PostgreSQL" | grep "14."

# postgres-14 should have lagoon database
docker-compose exec -T postgres-14 bash -c "psql -U lagoon -d lagoon -c \'\\l+ lagoon\'" | grep "lagoon"

# postgres-14 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-14" | grep "SERVICE_HOST=PostgreSQL 14"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-14" | grep "LAGOON_TEST_VAR=all-images"

# postgres-15 should be version 15 client
docker-compose exec -T postgres-15 bash -c "psql --version" | grep "psql" | grep "15."

# postgres-15 should be version 15 server
docker-compose exec -T postgres-15 bash -c "psql -U lagoon -d lagoon -c \'SELECT version();\'" | grep "PostgreSQL" | grep "15."

# postgres-15 should have lagoon database
docker-compose exec -T postgres-15 bash -c "psql -U lagoon -d lagoon -c \'\\l+ lagoon\'" | grep "lagoon"

# postgres-15 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-15" | grep "SERVICE_HOST=PostgreSQL 15"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-15" | grep "LAGOON_TEST_VAR=all-images"

# postgres-16 should be version 16 client
docker-compose exec -T postgres-16 bash -c "psql --version" | grep "psql" | grep "16."

# postgres-16 should be version 16 server
docker-compose exec -T postgres-16 bash -c "psql -U lagoon -d lagoon -c \'SELECT version();\'" | grep "PostgreSQL" | grep "16."

# postgres-16 should have lagoon database
docker-compose exec -T postgres-16 bash -c "psql -U lagoon -d lagoon -c \'\\l+ lagoon\'" | grep "lagoon"

# postgres-16 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-16" | grep "SERVICE_HOST=PostgreSQL 16"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/postgres?service=postgres-16" | grep "LAGOON_TEST_VAR=all-images"

# nginx should be served by openresty
docker-compose exec -T commons sh -c "curl -kL http://nginx:8080" | grep "hr" | grep "openresty"

# nginx should have correct headers
docker-compose exec -T commons sh -c "curl -I nginx:8080" | grep -i "Server" | grep -i "openresty"
docker-compose exec -T commons sh -c "curl -I nginx:8080" | grep -i "X-Lagoon"

# varnish-6 should have correct vmods in varnish folder
docker-compose exec -T varnish-6 sh -c "ls -la /usr/lib/varnish/vmods" | grep libvmod_bodyaccess.so
docker-compose exec -T varnish-6 sh -c "ls -la /usr/lib/varnish/vmods" | grep libvmod_dynamic.so

# varnish-6 should be serving pages as version 6
docker-compose exec -T commons sh -c "curl -I varnish-6:8080" | grep -i "Varnish" | grep -i "6."

# varnish-7 should have correct vmods in varnish folder
docker-compose exec -T varnish-7 sh -c "ls -la /usr/lib/varnish/vmods" | grep libvmod_bodyaccess.so
docker-compose exec -T varnish-7 sh -c "ls -la /usr/lib/varnish/vmods" | grep libvmod_dynamic.so

# varnish-7 should be serving pages as version 7
docker-compose exec -T commons sh -c "curl -I varnish-7:8080" | grep -i "Varnish" | grep -i "7."
docker-compose exec -T varnish-7 sh -c "varnishlog -d" | grep User-Agent | grep curl 

# opensearch-2 should have opensearch 2
docker-compose exec -T commons sh -c "curl opensearch-2:9200" | grep number | grep "2."

# opensearch-2 should be healthy
docker-compose exec -T commons sh -c "curl opensearch-2:9200/_cluster/health" | json_pp | grep status | grep -v red

# opensearch-2 should be able to read/write data
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/opensearch?service=opensearch-2" | grep "SERVICE_HOST=opensearch-2"
docker-compose exec -T commons sh -c "curl -kL http://internal-services-test:3000/opensearch?service=opensearch-2" | grep "LAGOON_TEST_VAR=all"
```

Destroy tests
-------------

Run the following commands to trash this app like nothing ever happened.

```bash
# should be able to destroy our services with success
docker-compose down --volumes --remove-orphans
rm docker-compose.yml
```
