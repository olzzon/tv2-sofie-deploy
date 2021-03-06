#!/bin/bash
docker stop server-core
docker stop inews-gateway
docker stop playout-gateway
docker stop sisyfos
docker stop mongo
docker rm mongo
docker run --network sofie --name=mongo --hostname=mongodb --volume=/opt/mongo/db:/data/db --volume=/opt/mongo/backup:/data/backup --volume=/etc/timezone:/etc/timezone:ro -p 127.0.0.1:27017:27017 --detach=true mongo:3.6.18 mongod --replSet rs0
sleep 30
docker exec -it mongo mongo --eval  'db.adminCommand( { setFeatureCompatibilityVersion: "3.6" } )'
docker stop mongo
docker rm mongo
docker run --restart always --network sofie --name=mongo --hostname=mongodb --volume=/opt/mongo/db:/data/db --volume=/opt/mongo/backup:/data/backup --volume=/etc/timezone:/etc/timezone:ro -p 127.0.0.1:27017:27017 --detach=true mongo:4.0.18 mongod --replSet rs0
sleep 30
docker exec -it mongo mongo --eval  'db.adminCommand( { setFeatureCompatibilityVersion: "4.0" } )'
docker exec -it mongo mongo --eval  'db.adminCommand( { replSetStepDown: 30, secondaryCatchUpPeriodSecs: 10, force: true } )'
docker restart mongo
docker stop mongo
docker rm mongo
docker run --restart always --network sofie --name=mongo --hostname=mongodb --volume=/opt/mongo/db:/data/db --volume=/opt/mongo/backup:/data/backup --volume=/etc/timezone:/etc/timezone:ro -p 127.0.0.1:27017:27017 --detach=true mongo:4.2.7 mongod --replSet rs0
sleep 30
docker exec -it mongo mongo --eval  'db.adminCommand( { setFeatureCompatibilityVersion: "4.2" } )'
docker exec -it mongo mongo --eval  'db.adminCommand( { replSetStepDown: 30, secondaryCatchUpPeriodSecs: 10, force: true } )'
docker restart mongo
