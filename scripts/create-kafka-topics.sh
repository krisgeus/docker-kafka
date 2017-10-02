#!/bin/sh

# Run KafkaTopics to create the topics if they don't exist yet
if [[ -n $KAFKA_CREATE_TOPICS ]]; then
  for TOPIC in ${KAFKA_CREATE_TOPICS//,/ }; do
    echo "creating topic: $TOPIC"
    TOPIC_CONFIG=(${TOPIC//:/ })
    if [ ${TOPIC_CONFIG[3]} ]; then
      $KAFKA_HOME/bin/kafka-topics.sh --create --if-not-exists --zookeeper ${HOSTNAME}:2181 --replication-factor ${TOPIC_CONFIG[2]} --partitions ${TOPIC_CONFIG[1]} --topic "${TOPIC_CONFIG[0]}" --config cleanup.policy="${TOPIC_CONFIG[3]}"
    else
      $KAFKA_HOME/bin/kafka-topics.sh --create --if-not-exists --zookeeper ${HOSTNAME}:2181 --replication-factor ${TOPIC_CONFIG[2]} --partitions ${TOPIC_CONFIG[1]} --topic "${TOPIC_CONFIG[0]}"
    fi
  done
fi

exit 0