.DEFAULT_GOAL := help
include ../.env

FLINK_VERSION_FULL=1.20.2
FLINK_VERSION_SHORT=1.20
HADOOP_VERSION=3.3.4
POSTGRESQL_CONNECTOR=42.7.6
FLINK_CDC=3.5.0
JDBC_VERSION=3.3.0

IMAGE_NAME=apacheflink-${FLINK_VERSION_FULL}-scala_2.12-java17
VERSION=1.0.6

define HELP

Available commands:

- pull:  Pull/wget all jar's

- build: Build this project

endef

export HELP
help:
	@echo "$$HELP"
.PHONY: help

build: 
	@echo "🔨 Building Apache Flink 1.20.2 Docker images..."
	docker build --build-arg REPO_NAME=${REPO_NAME} -t ${REPO_NAME}/${IMAGE_NAME}:${VERSION} --file Dockerfile . --no-cache
	@echo "✅ Apache Flink Docker image built ${IMAGE_NAME}:${VERSION} successfully"


pull: flink misc fluss fluss_iceberg

flink:
	cd stage; wget https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-postgres-cdc/3.5.0/flink-sql-connector-postgres-cdc-3.5.0.jar \
    cd stage; wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.6/postgresql-42.7.6.jar 
	cd stage; wget https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-parquet/1.20.2/flink-sql-parquet-1.20.2.jar \
	cd stage; wget https://repo1.maven.org/maven2/org/apache/flink/flink-python/1.20.2/flink-python-1.20.2.jar 


misc:
	cd stage; wget https://repo1.maven.org/maven2/org/apache/commons/commons-configuration2/2.1.1/commons-configuration2-2.1.1.jar \
	cd stage; wget https://repo1.maven.org/maven2/commons-logging/commons-logging/1.1.3/commons-logging-1.1.3.jar \
	cd stage; wget https://repo1.maven.org/maven2/org/apache/hadoop/thirdparty/hadoop-shaded-guava/1.1.1/hadoop-shaded-guava-1.1.1.jar \

	cd stage; wget https://repo1.maven.org/maven2/org/codehaus/woodstox/stax2-api/4.2.1/stax2-api-4.2.1.jar \
	cd stage; wget https://repo1.maven.org/maven2/com/fasterxml/woodstox/woodstox-core/5.3.0/woodstox-core-5.3.0.jar \
	cd stage; wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar \
	cd stage; wget https://repo1.maven.org/maven2/io/trino/hadoop/hadoop-apache/3.3.5-2/hadoop-apache-3.3.5-2.jar


fluss:
	cd stage; wget https://repo1.maven.org/maven2/org/apache/fluss/fluss-flink-1.20/0.8.0-incubating/fluss-flink-1.20-0.8.0-incubating.jar \
	cd stage; wget https://repo1.maven.org/maven2/org/apache/fluss/fluss-flink-tiering/0.8.0-incubating/fluss-flink-tiering-0.8.0-incubating.jar \
	cd stage; wget https://repo1.maven.org/maven2/org/apache/fluss/fluss-fs-s3/0.8.0-incubating/fluss-fs-s3-0.8.0-incubating.jar \
	cd stage; wget https://repo1.maven.org/maven2/org/apache/fluss/fluss-lake-iceberg/0.8.0-incubating/fluss-lake-iceberg-0.8.0-incubating.jar


# Lakehouse 
# https://fluss.apache.org/docs/streaming-lakehouse/integrate-data-lakes/iceberg/
fluss_iceberg:
	cd stage; wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws/1.9.1/iceberg-aws-1.9.1.jar \
	cd stage; wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.9.1/iceberg-aws-bundle-1.9.1.jar \
	cd stage; wget https://repo1.maven.org/maven2/dev/failsafe/failsafe/3.3.2/failsafe-3.3.2.jar \
