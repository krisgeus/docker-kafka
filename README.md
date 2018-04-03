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
| SSL_CERT |  |  |  Optional pem certificate |
| SSL_KEY  |  |  |  Optional ssl private key |
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
## SSL key and cert example

1. generate a private key

```
openssl genrsa -des3 -passout pass:apachepass -out pass.key 2048
openssl rsa -passin pass:apachepass -in pass.key -out ssl.key
```

2. generate a cert

```
openssl req -new -key ssl.key -out fqdn.csr -subj "/C=/ST=/L=/O=/CN=domain”
```

3. cert self-signing 

```
openssl x509 -req -days 365 -in fqdn.csr -signkey ssl.key -out selfsign.crt
```

4. passning a key and cert to the docker

```
--env SSL_CERT="`cat selfsign.crt`" \
--env SSL_KEY="`cat /ssl.key`" \
```

5. generate a client truststore

```
keytool -import -alias localhost -keystore client.truststore.jks -file selfsign.crt -noprompt --storepass secretpass --keypass secretpass
```

6. kafka client config

```
security.protocol=SSL
ssl.truststore.location=client.truststore.jks
ssl.truststore.password=secretpass
```

## Kerberos consuming example

You can use the ticket cache or the keytab to configure

### TicketCache
`kinit kafka/$(hostname -f) -kt /kafka.keytab`

`vi /kafka-client.jaas`

```
KafkaClient {
  com.sun.security.auth.module.Krb5LoginModule required
  useTicketCache=true
  serviceName="kafka"
  useKeyTab=false;
};
```

```
export KAFKA_OPTS="-Djava.security.auth.login.config=/kafka-client.jaas -Djava.security.krb5.conf=/etc/krb5.conf -Dsun.security.krb5.debug=false"

${KAFKA_HOME}/kafka-console-consumer.sh --bootstrap-server $(hostname):9092 --topic divolte --from-beginning --consumer-property security.protocol=SASL_PLAINTEXT
```

### Keytab

`vi /kafka-client-keytab.jaas`

```
KafkaClient {
  com.sun.security.auth.module.Krb5LoginModule required
  useKeyTab=true
  storeKey=true
  keyTab="/kafka.keytab"
  principal="kafka/divolte-kafka.divolte_divolte.io";
};
```

```
export KAFKA_OPTS="-Djava.security.auth.login.config=/kafka-client-keytab.jaas -Djava.security.krb5.conf=/etc/krb5.conf -Dsun.security.krb5.debug=false"

${KAFKA_HOME}/kafka-console-consumer.sh --bootstrap-server $(hostname):9092 --topic divolte --from-beginning --consumer-property security.protocol=SASL_PLAINTEXT
```
