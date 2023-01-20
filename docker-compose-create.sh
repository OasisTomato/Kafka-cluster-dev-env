#!/bin/bash

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

sudo rm -rf ./broker1/kafka-data/*
sudo rm -f ./broker1/kafka-data/.kafka*
sudo rm -f ./broker1/kafka-data/.lock
sudo rm -rf ./broker2/kafka-data/*
sudo rm -f ./broker2/kafka-data/.kafka*
sudo rm -f ./broker2/kafka-data/.lock
sudo rm -rf ./broker3/kafka-data/*
sudo rm -f ./broker3/kafka-data/.kafka*
sudo rm -f ./broker3/kafka-data/.lock
sudo rm -rf ./zookeeper/zk-data/*
sudo rm -rf ./zookeeper/zk-txn-logs/*

sudo docker container prune

# Create Kafka Data Folders
for i in broker1 broker2 broker3; do
	echo -e "------------------------------------------------------"
	echo -e "${YELLOW}Making DIR for Component (if any)...${i}${NC}"
	echo -e "------------------------------------------------------"

	mkdir -p ./${i}/kafka-data
	sudo chown 1000:1000 ${i}
	sudo chown -R 1000:1000 ./${i}/kafka-data
done

# Create Zookeeper Data Folders
echo -e "\n"
echo -e "--------------------------------------------------"
echo -e "${YELLOW}Making DIR for Zookeeper (if any)...${NC}"
echo -e "--------------------------------------------------"

mkdir -p ./zookeeper/zk-data
mkdir -p ./zookeeper/zk-txn-logs
sudo chown 1000:1000 zookeeper
sudo chown -R 1000:1000 ./zookeeper/zk-data
sudo chown -R 1000:1000 ./zookeeper/zk-txn-logs

# Create Secrets folder
echo -e "\n"
echo -e "------------------------------------------------"
echo -e "${YELLOW}Making DIR for Secrets (if any)...${NC}"
echo -e "------------------------------------------------"

mkdir -p ./secrets
sudo chown 1000:1000 ./secrets
