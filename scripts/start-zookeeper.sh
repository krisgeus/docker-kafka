#!/bin/sh

# Run Zookeeper
export EXTRA_ARGS='-name zookeeper' # no -loggc to minimize logging
$KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties