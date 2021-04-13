FROM openjdk:8-jdk

RUN apt-get update && apt-get install -y openssh-server
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys

RUN mkdir /home/hadoop
WORKDIR /opt
ENV HADOOP_VERSION=3.2.2
ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_CLASSPATH=$JAVA_HOME/lib/tools.jar
RUN curl -sL \
  "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
    | gunzip \
    | tar -x -C /opt/
RUN rm -rf $HADOOP_HOME/share/doc \
  && chown -R root:root $HADOOP_HOME \
  && mkdir -p $HADOOP_HOME/logs \
  && mkdir -p $HADOOP_CONF_DIR \
  && chmod 777 $HADOOP_CONF_DIR \
  && chmod 777 $HADOOP_HOME/logs
RUN echo "export JAVA_HOME=/usr/local/openjdk-8" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY hadoop/* $HADOOP_HOME/etc/hadoop/
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

# Install Spark
ENV SPARK_VERSION=3.1.1
ENV SPARK_HOME=/opt/spark-$SPARK_VERSION-bin-hadoop3.2
ENV SPARK_CONF_DIR=$SPARK_HOME/conf
ENV PATH $PATH:$SPARK_HOME/bin

RUN curl -sL \
  "https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.2.tgz" \
    | gunzip \
    | tar -x -C /opt/ \
  && chown -R root:root $SPARK_HOME \
  && mkdir -p /data/spark/ \
  && mkdir -p $SPARK_HOME/logs \
  && mkdir -p $SPARK_CONF_DIR \
  && chmod 777 $SPARK_HOME/logs
COPY spark/spark-defaults.conf $SPARK_HOME/conf/

#Install Hive
ENV HIVE_VERSION=3.1.2
ENV HIVE_HOME /opt/hive
ENV PATH $HIVE_HOME/bin:$PATH

RUN apt-get update && apt-get install -y wget procps && \
	wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
	tar -xzvf apache-hive-$HIVE_VERSION-bin.tar.gz && \
	mv apache-hive-$HIVE_VERSION-bin hive && \
	rm apache-hive-$HIVE_VERSION-bin.tar.gz && \
	apt-get --purge remove -y wget && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*
COPY hive/* $HIVE_HOME/conf/

#MYSQL for Hive Metastore
RUN apt-get update && apt-get -y install default-mysql-server
WORKDIR $HIVE_HOME/lib/
RUN apt-get update && apt-get install -y wget && \
wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.13/mysql-connector-java-8.0.13.jar
RUN cp $HIVE_HOME/conf/hive-site.xml $SPARK_HOME/conf/
RUN cp $HIVE_HOME/lib/mysql-connector-java-8.0.13.jar $SPARK_HOME/jars/

#Hudi
ENV HUDI_VERSION=0.8.0
WORKDIR $SPARK_HOME/jars/
RUN apt-get update && apt-get install -y wget && \
wget https://repository.apache.org/service/local/repositories/releases/content/org/apache/hudi/hudi-spark3-bundle_2.12/$HUDI_VERSION/hudi-spark3-bundle_2.12-$HUDI_VERSION.jar
WORKDIR $HIVE_HOME/lib/
RUN apt-get update && apt-get install -y wget && \
wget https://repository.apache.org/service/local/repositories/releases/content/org/apache/hudi/hudi-hadoop-mr-bundle/$HUDI_VERSION/hudi-hadoop-mr-bundle-$HUDI_VERSION.jar

RUN rm $HIVE_HOME/lib/guava-*.jar
RUN cp $HADOOP_HOME/share/hadoop/common/lib/guava-*.jar $HIVE_HOME/lib/

#Hue
WORKDIR /home/hadoop
ENV PYTHON_VER=python3.7
RUN apt-get -y install npm git ant gcc g++ libffi-dev libkrb5-dev default-libmysqlclient-dev libsasl2-dev libsasl2-modules-gssapi-mit libsqlite3-dev libssl-dev libxml2-dev libxslt-dev make maven libldap2-dev python-dev python-setuptools libgmp3-dev
RUN apt -y install python3.7-dev python3-distutils
RUN npm install -g npm@latest
RUN git clone --depth 1 --branch release-4.9.0 https://github.com/cloudera/hue.git
WORKDIR /home/hadoop/hue
RUN make apps
COPY hue/hue.ini desktop/conf/pseudo-distributed.ini
COPY hue/hue.ini desktop/conf.dist/hue.ini
RUN adduser --disabled-password --gecos "" hue

WORKDIR /home/hadoop
COPY start-up.sh ./
COPY mysql/init.sql ./
RUN chmod 777 start-up.sh

EXPOSE 10000 10002 8020 9864 9870 19888 8088 22 8042 8888
CMD ["/home/hadoop/start-up.sh"]
