# Kafka and Zookeeper

FROM centos

ENV SCALA_VERSION 2.12
ENV KAFKA_VERSION 0.10.2.1
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV JAVA_HOME /opt/jdk1.8.0_131

# Install Kafka, Zookeeper and other needed things
RUN yum update -y && \
	yum install -y epel-release && \
    yum install -y wget supervisor nc openssl && \
    wget -q http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    wget -q --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz" -O /tmp/jdk-8u131-linux-x64.tar.gz && \
    tar xfz /tmp/jdk-8u131-linux-x64.tar.gz -C /opt && \
    rm /tmp/jdk-8u131-linux-x64.tar.gz && \
    yum clean all

ADD scripts/start-kafka.sh /usr/bin/start-kafka.sh
ADD scripts/start-zookeeper.sh /usr/bin/start-zookeeper.sh
ADD scripts/create-kafka-topics.sh /usr/bin/create-kafka-topics.sh

ADD config/log4j.properties "$KAFKA_HOME"/config/

RUN mkdir -p /tmp/zookeeper && \
    mkdir -p /tmp/kafka-logs && \
    mkdir -p /var/log/supervisor && \
    mkdir "$KAFKA_HOME"/logs && \
    mkdir -p /var/private/ssl/ && \
    chmod -R 777 /var/log/supervisor/ && \
    chmod -R 777 /var/run/ && \
    chmod -R 777 "$KAFKA_HOME"/logs && \
    chmod -R 777 "$KAFKA_HOME"/config && \
    chmod -R 777  /tmp/zookeeper && \
    chmod -R 777  /tmp/kafka-logs && \
    chmod -R 777 /var/private/ssl

# Supervisor config
ADD supervisor/kafka.ini supervisor/zookeeper.ini supervisor/create-topics.ini /etc/supervisord.d/

# 2181 is zookeeper, 9092-9099 is kafka (for different listeners like SSL, INTERNAL, PLAINTEXT etc.)
EXPOSE 2181 9092 9093 9094 9095 9096 9097 9098 9099

CMD ["supervisord", "-n"]
