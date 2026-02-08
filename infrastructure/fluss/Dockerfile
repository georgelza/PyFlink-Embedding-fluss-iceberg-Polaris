FROM apache/fluss:0.8.0-incubating
SHELL ["/bin/bash", "-c"]

ENV FLUSS_HOME=/opt/fluss
ENV HADOOP_CONF_DIR=/opt/fluss/conf

# Required for Iceberg / JDBC catalog
# See Option 2, https://fluss.apache.org/docs/next/streaming-lakehouse/integrate-data-lakes/iceberg/#2-custom-catalog-implementations
# Required for Iceberg: https://fluss.apache.org/docs/next/streaming-lakehouse/integrate-data-lakes/iceberg/#configure-iceberg-in-cluster-configurations

# 1. Iceberg / JDBC catalog
RUN mkdir -p /opt/fluss/plugins/iceberg

COPY stage/hadoop-apache-3.3.5-2.jar        ${FLUSS_HOME}/plugins/iceberg
COPY stage/iceberg-core-1.9.1.jar           ${FLUSS_HOME}/plugins/iceberg

#     Added during DEBUG!
COPY stage/iceberg-aws-bundle-1.9.1.jar     ${FLUSS_HOME}/plugins/iceberg
COPY stage/iceberg-aws-1.9.1.jar            ${FLUSS_HOME}/plugins/iceberg

# 1a. Add Iceberg AWS S3 FileIO support - CRITICAL FOR S3FileIO
#     Updated aws-java-sdk-bundle-1.12.770.jar to later version
COPY stage/aws-java-sdk-bundle-1.12.770.jar ${FLUSS_HOME}/plugins/iceberg
COPY stage/hadoop-shaded-guava-1.1.1.jar    ${FLUSS_HOME}/plugins/iceberg


# 2. Fluss -> S3 Lakehouse tiering
RUN mv ${FLUSS_HOME}/plugins/s3/fluss-fs-s3-0.8.0-incubating.jar  ${FLUSS_HOME}/lib
RUN rm -rf ${FLUSS_HOME}/plugins/s3


# 4. Lets make sure with our copying of JARs that all is owned by the right user/group.
RUN chown -R fluss:fluss ${FLUSS_HOME}