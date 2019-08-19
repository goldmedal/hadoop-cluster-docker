FROM centos:centos7

MAINTAINER KiwenLau <kiwenlau@gmail.com>

WORKDIR /root

# install openssh-server, openjdk wget
RUN yum -y update && yum -y install openssh-server java-1.8.0-openjdk java-1.8.0-openjdk-devel wget

# install gcc, make, git, autoconf, automake and libtool for Intel ISA-L
RUN yum -y install gcc make git autoconf automake libtool

# install openssl, openssl-devel, cyrus-sasl, cyrus-sasl-lib, cyrus-sasl-devel, libgsasl and libgsasl-devel
RUN yum -y install openssl openssl-devel cyrus-sasl cyrus-sasl-lib cyrus-sasl-devel libgsasl libsasl-devel

# install hadoop 3.2.0
RUN wget https://github.com/goldmedal/compile-hadoop/releases/download/v3.2.0/hadoop-3.2.0-native-isal.tar.gz && \
    tar -xzvf hadoop-3.2.0-native-isal.tar.gz && \
    mv hadoop-3.3.0-SNAPSHOT /usr/local/hadoop && \
    rm hadoop-3.2.0-native-isal.tar.gz

# set environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

# ssh without key
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# build yasm
RUN wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
    tar -xzvf yasm-1.3.0.tar.gz

WORKDIR /root/yasm-1.3.0
RUN ./configure && \
    make && make install

WORKDIR /root
RUN rm yasm-1.3.0.tar.gz

# build intel isa-l
RUN git clone https://github.com/intel/isa-l.git
WORKDIR /root/isa-l
RUN ./autogen.sh && ./configure --prefix=/usr --libdir=/usr/lib64 && make && make install

WORKDIR /root

RUN mkdir -p ~/hdfs/namenode && \
    mkdir -p ~/hdfs/datanode && \
    mkdir $HADOOP_HOME/logs

COPY config/* /tmp/

RUN mv /tmp/ssh_config ~/.ssh/config && \
    mv /tmp/hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh && \
    mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml && \
    mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml && \
    mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml && \
    mv /tmp/slaves $HADOOP_HOME/etc/hadoop/slaves && \
    mv /tmp/workers $HADOOP_HOME/etc/hadoop/workers && \
    mv /tmp/start-hadoop.sh ~/start-hadoop.sh && \
    mv /tmp/run-wordcount.sh ~/run-wordcount.sh

RUN chmod +x ~/start-hadoop.sh && \
    chmod +x ~/run-wordcount.sh && \
    chmod +x $HADOOP_HOME/sbin/start-dfs.sh && \
    chmod +x $HADOOP_HOME/sbin/start-yarn.sh
# enable openssh server
RUN chmod 600 ~/.ssh/config
RUN chown root ~/.ssh/config
RUN /usr/sbin/sshd-keygen -A

# format namenode
RUN /usr/local/hadoop/bin/hdfs namenode -format

CMD [ "sh", "-c", "/usr/sbin/sshd; bash"]
