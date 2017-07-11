# Docker kafka plus zookeeper image

## Building the image
```
docker build -f Dockerfile -t docker-kafka .
```

## Configuring the image

Configuration of kafka can be changed/influenced by setting a set of environment variables



|env var|default|options|description|
| --- | --- | --- | --- |  
| ADVERTISED_LISTENERS |  |  | the listeners advertised to the outside world with associated listener name |
| LISTENERS  |  |  | the listeners being created by the broker with their associated name |
| SECURITY_PROTOCOL_MAP  |  |  |  mapping from the listener names to security protocol |
| SSL_CERT |  |  |  Optional pem certificate and key |
| SSL_DN |  |  |  Optional subject to use for the generated certificate, e.g. CN=kafka.example.com,OU=data,O=example,L=Kris,S=Geus,C=NL |
| SSL_PASSWORD |  |  |  Optional password to use for the store and key otherwise will be automatically generated |
| INTER_BROKER  |  |  |  the listener name the internal connections will use |
| LOG\_RETENTION_HOURS | 168 |   | Number of hours the messages are kept in the topic log |
| LOG\_RETENTION_BYTES | 1073741824 |  | Size of the topic logs at which pruning will take place|
| NUM_PARTITIONS | 1 |  | Default number of partitions for a topic | 
| AUTO\_CREATE_TOPICS | true | true, false | Automatically create a topic when messages are produced | 
| KAFKA\_CREATE_TOPICS |  |  | Comma separated list op topics to create. Topic can specify partitions, replication and cleanup.policy by appending a colon separated list of these configurations | 



## Running the image
To run the image with 2 topics, advertising an internal (9092) and external listener (443). This example is useful when you have some kind 
of edge termination for ssl externally or port mapping, e.g. port 443 external SSL --> port 9092 internal.

```
docker run --rm -p 2181:2181 -p 9092:9092 -p 9093:9093 \
  --env ADVERTISED_LISTENERS=PLAINTEXT://kafka:443,INTERNAL://localhost:9093 \
  --env LISTENERS=PLAINTEXT://0.0.0.0:9092,INTERNAL://0.0.0.0:9093 \
  --env SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,INTERNAL:PLAINTEXT \
  --env INTER_BROKER=INTERNAL \
  --env KAFKA_CREATE_TOPICS="test:36:1,krisgeus:12:1:compact" \
  --name kafka \
  krisgeus/docker-kafka
```

## Testing

Testing if the image works can be done by using the kafka console producer/consumer
since we named the image we need to add an entry to the `/etc/hosts` file to connect the name kafka to the local ip 127.0.0.1

```
127.0.0.1	kafka
```

Now we can use that hostname (the same as the advertised host) to connect the producer and consumer

```
kafka-console-producer --broker-list kafka:9092 \
  --topic test
```

Sending messages can be done by typeing the following in the console
```
message1
message2
```

To consume this use the following in a separate terminal window

```
kafka-console-consumer --bootstrap-server kafka:9092 \
  --topic test \
  --from-beginning
  
message1
message2
```

__A compact topic needs a key so remember to start the producer with the mandatory parse.key and key.separator options!__

```
kafka-console-producer --broker-list kafka:9092 \
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
kafka-console-consumer --bootstrap-server kafka:9092 \
  --topic krisgeus \
  --from-beginning
  
value1
value2
```
