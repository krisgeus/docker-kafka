#!/bin/sh

# Configure kerberos for zookeeper
if [ ! -z "$ENABLE_KERBEROS" ]; then
    echo "set authProvider.1 to SASLAuthenticationProvider"
    if grep -r -q "^#\?authProvider\.1" $KAFKA_HOME/config/zookeeper.properties; then
        sed -r -i "s/#?(authProvider\.1)=(.*)/\1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider/g" $KAFKA_HOME/config/zookeeper.properties
    else
        echo "authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider" >> $KAFKA_HOME/config/zookeeper.properties
    fi

    echo "set requireClientAuthScheme to sasl"
    if grep -r -q "^#\?requireClientAuthScheme" $KAFKA_HOME/config/zookeeper.properties; then
        sed -r -i "s/#?(requireClientAuthScheme)=(.*)/\1=sasl/g" $KAFKA_HOME/config/zookeeper.properties
    else
        echo "requireClientAuthScheme=sasl" >> $KAFKA_HOME/config/zookeeper.properties
    fi

    echo "set jaasLoginRenew period"
    if grep -r -q "^#\?jaasLoginRenew" $KAFKA_HOME/config/zookeeper.properties; then
        sed -r -i "s/#?(jaasLoginRenew)=(.*)/\1=3600000/g" $KAFKA_HOME/config/zookeeper.properties
    else
        echo "jaasLoginRenew=3600000" >> $KAFKA_HOME/config/zookeeper.properties
    fi

    echo "create jaas config based on template"
    sed "s/HOSTNAME/$(hostname -f)/g" $KAFKA_HOME/config/zookeeper.jaas.tmpl > $KAFKA_HOME/config/zookeeper.jaas

    export KAFKA_OPTS="-Djava.security.auth.login.config=${KAFKA_HOME}/config/zookeeper.jaas -Djava.security.krb5.conf=/etc/krb5.conf -Dsun.security.krb5.debug=true"
fi

# Run Zookeeper
export EXTRA_ARGS="-name zookeeper" # no -loggc to minimize logging
$KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties