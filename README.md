# Docker kafka plus zookeeper image

## Building the image
```
docker build -f Dockerfile -t docker-zk-kafka
```

## Configuring the image

Configuration of kafka can be changed/influenced by setting a set of environment variables



|env var|default|options|description|
| --- | --- | --- | --- |  
| ADVERTISED_HOST |  |  | Hostname the application binds on |
| ADVERTISED_PORT  | 9092 |  | The port the application runs on |
| LOG\_RETENTION_HOURS | 168 |   | Number of hours the messages are kept in the topic log |
| LOG\_RETENTION_BYTES | 1073741824 |  | Size of the topic logs at which pruning will take place|
| NUM_PARTITIONS | 1 |  | Default number of partitions for a topic | 
| AUTO\_CREATE_TOPICS | true | true, false | Automatically create a topic when messages are produced | 
| KAFKA\_CREATE_TOPICS |  |  | Comma separated list op topics to create. Topic can specify partitions, replication and cleanup.policy by appending a colon separated list of these configurations | 



## Running the image
To run the image with 2 topics

```
docker run -p 2181:2181 -p 9092:9092 \
  --env ADVERTISED_HOST=127.0.0.1 \
  --env ADVERTISED_PORT=9092 \
  --env KAFKA_CREATE_TOPICS="test:36:1,krisgeus:12:1:compact" \
  docker-zk-kafka
```

## Testing

Testing if the image works can be done by using the kafka console producer/consumer

```
kafka-console-producer --broker-list localhost:9092 \
  --topic test
```

Sending messages can be done by typeing the following in the console
```
message1
message2
```

To consume this use the following in a separate terminal window

```
kafka-console-consumer --bootstrap-server localhost:9092 \
  --topic test \
  --from-beginning
  
message1
message2
```

__A compact topic needs a key so remember to start the producer with the mandatory parse.key and key.separator options!__

```
kafka-console-producer --broker-list localhost:9092 \
  --topic krisgeus \
  --property "parse.key=true" \
  --property "key.separator=:"
```

Sending messages can be done by typeing the following in the console
```
key1:value1
key2:value2
```

To consume this use the following in a separate terminal window

```
kafka-console-consumer --bootstrap-server localhost:9092 \
  --topic krisgeus \
  --from-beginning
  
value1
value2
```