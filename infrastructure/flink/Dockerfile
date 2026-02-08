FROM georgelza/apacheflink-base-1.20.2-scala_2.12-java17:1.0.0
SHELL ["/bin/bash", "-c"]

# 2. Environment Variables 
ENV PYTHON_HOME=/usr/bin/python3.10
ENV PATH=$PATH:$PYTHON_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
ENV FLINK_HOME=/opt/flink
ENV HIVE_HOME=${FLINK_HOME}/conf/
ENV HADOOP_CONF_DIR=${FLINK_HOME}/conf/
ENV FLINK_VERSION_SHORT=1.20
ENV FLINK_VERSION_FULL=1.20.2
ENV ICEBERG_VERSION=1.9.1
ENV POSTGRESQL_CONNECTOR=42.7.6
ENV FLINK_CDC=3.5.0
ENV FLUSS=0.8.0
ENV HADOOP_VERSION=3.3.4

# 5. Directory Structure 
RUN mkdir -p /opt/flink/conf/ && \
    mkdir -p /opt/flink/checkpoints && \
    mkdir -p /opt/flink/rocksdb && \
    mkdir -p /opt/flink/lib

# 6.  
RUN echo "-> Install JARs: S3 Plugin (Internal Flink System)" && \
    mkdir -p ./plugins/s3-fs-hadoop && \
    mv /opt/flink/opt/flink-s3-fs-hadoop-${FLINK_VERSION_FULL}.jar ./plugins/s3-fs-hadoop/

# 7. Install JARs: Connectors & Hadoop 
RUN echo "-> Install JARs: Postgres Driver and Flink CDC Postgres connector" 
COPY stage/flink-sql-connector-postgres-cdc-${FLINK_CDC}.jar            ${FLINK_HOME}/lib/
COPY stage/postgresql-${POSTGRESQL_CONNECTOR}.jar                       ${FLINK_HOME}/lib/

# 8.
RUN echo "-> Install JARs: Generic Flink" 
COPY stage/flink-sql-parquet-${FLINK_VERSION_FULL}.jar                  ${FLINK_HOME}/lib/
COPY stage/flink-python-${FLINK_VERSION_FULL}.jar                       ${FLINK_HOME}/lib/

# Jars that make the world go round, if you exclude them then most things Flink, Flink CDC, PyFlink etc simply does not work.
# 9.
RUN echo "-> Install JARs: Generic Hadoop" 
COPY stage/commons-configuration2-2.1.1.jar                             ${FLINK_HOME}/lib/
COPY stage/commons-logging-1.1.3.jar                                    ${FLINK_HOME}/lib/
COPY stage/hadoop-shaded-guava-1.1.1.jar                                ${FLINK_HOME}/lib/
COPY stage/stax2-api-4.2.1.jar                                          ${FLINK_HOME}/lib/
COPY stage/woodstox-core-5.3.0.jar                                      ${FLINK_HOME}/lib/
COPY stage/aws-java-sdk-bundle-1.12.262.jar                             ${FLINK_HOME}/lib/
COPY stage/hadoop-apache-3.3.5.jar                                      ${FLINK_HOME}/lib/

# 10.
RUN echo "-> Install JARs: Dependencies for Fluss" 
COPY stage/fluss-flink-${FLINK_VERSION_SHORT}-${FLUSS}-incubating.jar   ${FLINK_HOME}/lib/
COPY stage/fluss-flink-tiering-${FLUSS}-incubating.jar                  ${FLINK_HOME}/lib/
COPY stage/fluss-fs-s3-${FLUSS}-incubating.jar                          ${FLINK_HOME}/lib/
# Lakehouse options Libraries
COPY stage/fluss-lake-iceberg-${FLUSS}-incubating.jar                   ${FLINK_HOME}/lib/


# 11. S3 FileIO
# https://fluss.apache.org/docs/streaming-lakehouse/integrate-data-lakes/iceberg/#5-iceberg-fileio-dependencies
RUN echo "-> Install JARs: Dependencies for Iceberg FileIO" 
COPY stage/iceberg-aws-1.9.1.jar                                        ${FLINK_HOME}/lib/
COPY stage/iceberg-aws-bundle-1.9.1.jar                                 ${FLINK_HOME}/lib/
COPY stage/failsafe-3.3.2.jar                                           ${FLINK_HOME}/lib/


RUN echo "--> Set Ownerships of /opt/flink" && \
    chown -R flink:flink $FLINK_HOME 

USER flink:flink
CMD ./bin/start-cluster.sh && sleep infinity