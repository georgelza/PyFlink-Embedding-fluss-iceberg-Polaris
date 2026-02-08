.DEFAULT_GOAL := help
include ../.env

FLUSS_VERSION_FULL=0.8.0

IMAGE_NAME=fluss_0.8.0-incubating
VERSION=1.0.2

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
	@echo "🔨 Building Apache Fluss 0.8.0 Docker images..."
	docker build --build-arg REPO_NAME=${REPO_NAME} -t ${REPO_NAME}/${IMAGE_NAME}:${VERSION} --file Dockerfile . --no-cache
	@echo "✅ Apache Fluss Docker image built ${IMAGE_NAME}:${VERSION} successfully"


# Required for Iceberg and JDBC catalog.
pull: iceberg

iceberg:
	cd stage; wget https://repo1.maven.org/maven2/io/trino/hadoop/hadoop-apache/3.3.5-2/hadoop-apache-3.3.5-2.jar\
	cd stage; wget https://repo1.maven.org/maven2/org/apache/hadoop/thirdparty/hadoop-shaded-guava/1.1.1/hadoop-shaded-guava-1.1.1.jar \
	cd stage; wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.770/aws-java-sdk-bundle-1.12.770.jar

#	cd stage; wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar \
#	cd stage; wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-core/1.9.1/iceberg-core-1.9.1.jar \

