# Kafka and Zookeeper

FROM centos

ENV SCALA_VERSION 2.12
ENV KAFKA_VERSION 2.3.0
ENV SCHEMA_VERSION 5.3.2
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV SCHEMA_REGISTRY_HOME /opt/schema-registry-"$SCHEMA_VERSION"

# Install Kafka, Zookeeper and other needed things
RUN yum update -y && \
    yum install -y epel-release wget nc net-tools openssl krb5-workstation krb5-libs java maven which && \
    yum install -y python3-pip && \
    pip3 install supervisor && \
    wget -q \
        http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz \
        -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    wget -q https://github.com/confluentinc/common/archive/v"$SCHEMA_VERSION".tar.gz \
        -O /tmp/cp-common.tgz && \
    tar xfz /tmp/cp-common.tgz -C /opt && \
    wget -q https://github.com/confluentinc/rest-utils/archive/v"$SCHEMA_VERSION".tar.gz \
        -O /tmp/restutils.tgz && \
    tar xfz /tmp/restutils.tgz -C /opt && \
    wget -q https://github.com/confluentinc/schema-registry/archive/v"$SCHEMA_VERSION".tar.gz \
        -O /tmp/schema_registry.tgz && \
    tar xfz /tmp/schema_registry.tgz -C /opt
    
RUN cd /opt/common-"$SCHEMA_VERSION" && \
    mvn install && \
    cd /opt/rest-utils-"$SCHEMA_VERSION" && \
    mvn install && \
    cd /opt/schema-registry-"$SCHEMA_VERSION" && \
    mvn install -DskipTests=true && \
    yum clean all

ADD scripts/start-all.sh /usr/bin/start-all.sh
ADD scripts/start-kafka.sh /usr/bin/start-kafka.sh
ADD scripts/start-zookeeper.sh /usr/bin/start-zookeeper.sh
ADD scripts/start-schemaregistry.sh /usr/bin/start-schemaregistry.sh
ADD scripts/create-kafka-topics.sh /usr/bin/create-kafka-topics.sh

ADD config/log4j.properties config/zookeeper.jaas.tmpl config/kafka.jaas.tmpl "$KAFKA_HOME"/config/
ADD config/schema-registry.properties "$SCHEMA_REGISTRY_HOME"/config/

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
    chmod -R 777 "$KAFKA_HOME"/logs && \
    chmod -R 777 "$SCHEMA_REGISTRY_HOME"/config && \
    chmod -R 777 "$SCHEMA_REGISTRY_HOME"/ && \
    chmod -R 777  /tmp/zookeeper && \
    chmod -R 777  /tmp/kafka-logs && \
    chmod -R 777 /var/private/ssl

# Supervisor config
ADD supervisor/initialize.ini supervisor/kafka.ini supervisor/zookeeper.ini supervisor/schemaregistry.ini /etc/supervisord.d/

RUN echo_supervisord_conf | sed -e 's:;\[include\]:\[include\]:g' | sed -e 's:;files = relative/directory/\*.ini:files = /etc/supervisord.d/\*.ini:g' > /etc/supervisord.conf

# 2181 is zookeeper, 8081 is Schema Registry, 9092-9099 is kafka (for different listeners like SSL, INTERNAL, PLAINTEXT etc.)
EXPOSE 2181 8081 9092 9093 9094 9095 9096 9097 9098 9099

CMD ["supervisord", "-n"]
