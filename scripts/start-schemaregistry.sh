#!/bin/sh

# Optional ENV variables:
# * SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: kafka broker address

echo "Make sure new config items are put at end of config file even if no newline is present as final character in the config"
echo >> $SCHEMA_REGISTRY_HOME/config/schema-registry.properties    


if [ ! -z "$SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS" ]; then
    echo "Schema Registry Bootstrap Server: $SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS"
    sed -r -i "s/#?(kafkastore.connection.url)=(.*)/\1=$SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS/g" $SCHEMA_REGISTRY_HOME/config/schema-registry.properties    
fi

$SCHEMA_REGISTRY_HOME/bin/schema-registry-start $SCHEMA_REGISTRY_HOME/config/schema-registry.properties    

