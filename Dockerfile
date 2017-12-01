# Kafka and Zookeeper

FROM centos

ENV SCALA_VERSION 2.12
ENV KAFKA_VERSION 0.10.2.1
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV JAVA_HOME /opt/jdk1.8.0_151


# Install Kafka, Zookeeper and other needed things
RUN yum update -y && \
    yum install -y epel-release zip unzip && \
    yum install -y wget supervisor nc openssl krb5-workstation krb5-libs && \
    wget -q \
        http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz \
        -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    wget -q --no-cookies --no-check-certificate \
        --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
        "http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.tar.gz" \
        -O /tmp/jdk-linux-x64.tar.gz && \
    tar xfz /tmp/jdk-linux-x64.tar.gz -C /opt && \
    rm /tmp/jdk-linux-x64.tar.gz && \
    wget -q --no-cookies --no-check-certificate \
        --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
        "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip" \
        -O /tmp/jce_policy-8.zip && \
    unzip -j -o /tmp/jce_policy-8.zip -d $JAVA_HOME/jre/lib/security/ && \
    rm -rf /tmp/jce_policy-8.zip && \
    yum clean all


ADD scripts/start-all.sh /usr/bin/start-all.sh
ADD scripts/start-kafka.sh /usr/bin/start-kafka.sh
ADD scripts/start-zookeeper.sh /usr/bin/start-zookeeper.sh
ADD scripts/create-kafka-topics.sh /usr/bin/create-kafka-topics.sh
ADD scripts/configureKerberosClient.sh /usr/bin/configureKerberosClient.sh

ADD config/log4j.properties config/zookeeper.jaas.tmpl config/kafka.jaas.tmpl "$KAFKA_HOME"/config/

RUN mkdir -p /tmp/zookeeper && \
    mkdir -p /tmp/kafka-logs && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /var/log/zookeeper && \
    mkdir "$KAFKA_HOME"/logs && \
    mkdir -p /var/private/ssl/ && \
    chmod -R 777 /var/log/supervisor/ && \
    chmod -R 777 /var/log/zookeeper/ && \
    chmod -R 777 /var/run/ && \
    chmod -R 777 "$KAFKA_HOME"/logs && \
    chmod -R 777 "$KAFKA_HOME"/config && \
    chmod -R 777  /tmp/zookeeper && \
    chmod -R 777  /tmp/kafka-logs && \
    chmod -R 777 /var/private/ssl

# Supervisor config
ADD supervisor/initialize.ini supervisor/kafka.ini supervisor/zookeeper.ini /etc/supervisord.d/



# 2181 is zookeeper, 9092-9099 is kafka (for different listeners like SSL, INTERNAL, PLAINTEXT etc.)
EXPOSE 2181 9092 9093 9094 9095 9096 9097 9098 9099

CMD ["supervisord", "-n"]
