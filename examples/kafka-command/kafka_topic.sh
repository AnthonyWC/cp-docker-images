#!/bin/bash

# Create topic
kafka-topics --create --topic foo --partitions 1 --replication-factor 1 \
--if-not-exists --zookeeper localhost:32181

kafka-topics --describe --topic foo --zookeeper localhost:32181

bash -c "seq 42 | kafka-console-producer --request-required-acks 1 --broker-list \
localhost:29092 --topic foo && echo 'Produced 42 messages.'"

# Produce message to topic
kafka-console-producer.sh	--broker-list	localhost:9092	--topic	foo

# Consume messages from topic
kafka-console-consumer --bootstrap-server localhost:29092 --topic foo \
--new-consumer --from-beginning --max-messages 42
