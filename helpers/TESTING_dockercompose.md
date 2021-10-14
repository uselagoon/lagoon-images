Docker Compose test all images
==============================

This is a docker-compose version of the Lando example tests:

Start up tests
--------------

Run the following commands to get up and running with this example.

```bash
# Should remove any previous runs and poweroff
sed -i -e "/###/d" docker-compose.yml
docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network
docker-compose down

# Should start up our services successfully
docker-compose build && docker-compose up -d

# Ensure database pods are ready to connect
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://mariadb-10.4:3306 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://mariadb-10.5:3306 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://postgres-11:5432 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://postgres-12:5432 -timeout 1m
docker run --rm --net all-images_default jwilder/dockerize dockerize -wait tcp://mongo:27017 -timeout 1m
```

Verification commands
---------------------

Run the following commands to validate things are rolling as they should.

```bash
# Should have all the services we expect
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_mariadb-10.4_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_mariadb-10.5_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_mongo_1
docker ps -a --filter label=com.docker.compose.project=all-images | grep Exited | grep all-images_node-12_1
docker ps -a --filter label=com.docker.compose.project=all-images | grep Exited | grep all-images_node-14_1
docker ps -a --filter label=com.docker.compose.project=all-images | grep Exited | grep all-images_node-16_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_postgres-11_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_postgres-12_1
docker ps -a --filter label=com.docker.compose.project=all-images | grep Exited | grep all-images_python-3.7_1
docker ps -a --filter label=com.docker.compose.project=all-images | grep Exited | grep all-images_python-3.8_1
docker ps -a --filter label=com.docker.compose.project=all-images | grep Exited | grep all-images_python-3.9_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_rabbitmq_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_redis-5_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_redis-6_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_solr-7_1
docker ps --filter label=com.docker.compose.project=all-images | grep Up | grep all-images_toolbox_1

# toolbox Should be running Alpine Linux
docker-compose exec -T toolbox sh -c "cat /etc/os-release" | grep "Alpine Linux"

# rabbitmq Should have RabbitMQ running 3.8
docker-compose exec -T rabbitmq sh -c "rabbitmqctl version" | grep 3.8

# rabbitmq Should have delayed_message_exchange plugin enabled
docker-compose exec -T rabbitmq sh -c "rabbitmq-plugins list" | grep "E" | grep "delayed_message_exchange"

# rabbitmq Should have a running RabbitMQ management page running on 15672
docker-compose exec -T toolbox sh -c "curl -kL http://rabbitmq:15672" | grep "RabbitMQ Management"

# redis-5 Should be running Redis v5.0
docker-compose exec -T redis-5 sh -c "redis-server --version" | grep v=5.

# redis-5 Should be able to see databases
docker-compose exec -T redis-5 sh -c "redis-cli CONFIG GET databases"

# redis-5  databases should be initialized
docker-compose exec -T redis-5 sh -c "redis-cli dbsize"

# redis-6 Should be running Redis v6.0
docker-compose exec -T redis-6 sh -c "redis-server --version" | grep v=6.

# redis-6 Should be able to see Redis databases
docker-compose exec -T redis-6 sh -c "redis-cli CONFIG GET databases"

# redis-6 databases should be initialized
docker-compose exec -T redis-6 sh -c "redis-cli dbsize"

# solr-7 Should have a "mycore" Solr core
docker-compose exec -T toolbox sh -c "curl solr-7:8983/solr/admin/cores?action=STATUS\&core=mycore"

# solr-7 Should be able to reload "mycore" Solr core
docker-compose exec -T toolbox sh -c "curl solr-7:8983/solr/admin/cores?action=RELOAD\&core=mycore"

# solr-7 Check Solr has 7.7 solrconfig in "mycore" core
docker-compose exec -T solr-7 sh -c "cat /opt/solr/server/solr/mycores/mycore/conf/solrconfig.xml" | grep 7.7

# solr-7.7 Should have a "mycore" Solr core
docker-compose exec -T toolbox sh -c "curl solr-7.7:8983/solr/admin/cores?action=STATUS\&core=mycore"

# solr-7.7 Should be able to reload "mycore" Solr core
docker-compose exec -T toolbox sh -c "curl solr-7.7:8983/solr/admin/cores?action=RELOAD\&core=mycore"

# solr-7.7 Check Solr has 7.7 solrconfig in "mycore" core
docker-compose exec -T solr-7.7 sh -c "cat /opt/solr/server/solr/mycores/mycore/conf/solrconfig.xml" | grep 7.7

# mariadb-10.4 should be version 10.4 client
docker-compose exec -T mariadb-10.4 sh -c "mysql -V" | grep "10.4"

# mariadb-10.4 should be version 10.4 server
docker-compose exec -T mariadb-10.4 sh -c "mysql -e \'SHOW variables;\'" | grep "version" | grep "10.4"

# mariadb-10.4 check default credentials
docker-compose exec -T mariadb-10.4 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW databases;\'" | grep lagoon

# mariadb-10.5 should be version 10.5 client
docker-compose exec -T mariadb-10.5 sh -c "mysql -V" | grep "10.5"

# mariadb-10.5 should be version 10.5 server
docker-compose exec -T mariadb-10.5 sh -c "mysql -e \'SHOW variables;\'" | grep "version" | grep "10.5"

# mariadb-10.5 check default credentials
docker-compose exec -T mariadb-10.5 sh -c "mysql -D lagoon -u lagoon --password=lagoon -e \'SHOW databases;\'" | grep lagoon

# mongo should be version 3.6 client
docker-compose exec -T mongo sh -c "mongo --version" | grep "shell version" | grep "v3.6"

# mongo should be version 3.6 server
docker-compose exec -T mongo sh -c "mongo --eval \'printjson(db.serverStatus())\'" | grep "server version" | grep "3.6"

# mongo should have test database
docker-compose exec -T mongo sh -c "mongo --eval \'db.stats()\'" | grep "db" | grep "test"

# postgres-11 should be version 11 client
docker-compose exec -T postgres-11 bash -c "psql --version" | grep "psql" | grep "11."

# postgres-11 should be version 11 server
docker-compose exec -T postgres-11 bash -c "psql -U lagoon -d lagoon -c \'SELECT version();\'" | grep "PostgreSQL" | grep "11."

# postgres-11 should have lagoon database
docker-compose exec -T postgres-11 bash -c "psql -U lagoon -d lagoon -c \'\\l+ lagoon\'" | grep "lagoon"

# postgres-12 should be version 11 client
docker-compose exec -T postgres-12 bash -c "psql --version" | grep "psql" | grep "12."

# postgres-12 should be version 12 server
docker-compose exec -T postgres-12 bash -c "psql -U lagoon -d lagoon -c \'SELECT version();\'" | grep "PostgreSQL" | grep "12."

# postgres-12 should have lagoon database
docker-compose exec -T postgres-12 bash -c "psql -U lagoon -d lagoon -c \'\\l+ lagoon\'" | grep "lagoon"
```

Destroy tests
-------------

Run the following commands to trash this app like nothing ever happened.

```bash
# Should be able to destroy our Drupal 9 site with success
docker-compose down --volumes --remove-orphans
```
