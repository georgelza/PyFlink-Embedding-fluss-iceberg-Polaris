.DEFAULT_GOAL := help
include ../.env

FLINK_VERSION_FULL=1.20.2

IMAGE_NAME=apacheflink-base-${FLINK_VERSION_FULL}-scala_2.12-java17
VERSION=1.0.0

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
