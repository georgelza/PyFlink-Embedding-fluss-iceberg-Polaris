
.DEFAULT_GOAL := help
include .env

define HELP

Available commands:

- build: 		Build required Docker images (Flink with CDC)

- run:  		Start All services (Flink, Fluss, PostgreSQL), output onto S3/MinIO, with Polaris Catalog
- deploy:    	Deploy all structures required.

- ahs			Deploy insert statement for accountHolder data feed into Fluss datastore
- txns			Deploy insert statement for transaction data feed into Fluss datastore
- tier			Kick off Fluss Tiering Job - Iceberg on S3/MinIO with Polaris Catalog

- stop:  		Stop the project
- start: 		Restart a stopped project
- down:  		Tear down the project, clean directories

- ps:    		how all running containers
- logs:  		Show/tail logs
- logsf: 		Stream logs
- watch: 		Watch logs
- fsql			Open Flink-Sql console
- jm			Open Flink Jobmanager console
- cs			Open Fluss Coordinator-server console


endef

export HELP
help:
	@echo "$$HELP"
.PHONY: help


#	docker rmi $(docker images -q --filter "dangling=true")

build:
#	@cd ../infrastructure && make pull && make build
	@cd ../infrastructure && make build
.PHONY: build


# Polaris Based Catalog, Iceberg on S3/Minio
run:
	@echo "🚀 Precreating Required volumes..."
	mkdir -p ./data/flink/logs ./data/flink/checkpoints ./data/flink/rocksdb ./data/flink/catalogs
	mkdir -p ./data/postgrescdc ./data/postgrescat
	mkdir -p ./data/fluss
	mkdir -p ./data/zk/data ./data/zk/datalogs
	mkdir -p ./data/minio

	@echo "🚀 Starting Flink & Fluss stack, supporting services (PostgreSQL)... for Iceberg Polaris Catalog"
	docker compose -f docker-compose.yml -p pol up -d \
		jobmanager taskmanager \
 		postgrescdc postgrescat \
		zookeeper \
		minio minio-client\
		coordinator-server tablet-server-1 tablet-server-2 tablet-server-3 \
		polaris polaris-bootstrap polaris-setup \
		--remove-orphans
	@echo "✅ Flink & Fluss stack with supporting services started successfully"
.PHONY: run

#		polaris polaris-bootstrap polaris-setup polaris-console \


stop:
	docker compose stop

start:
	docker compose start

down:	
	docker compose down
	cd data/; rm -rf flink
	cd data/; rm -rf postgrescdc
	cd data/; rm -rf postgrescat
	cd data/; rm -rf fluss
	cd data/; rm -rf zk
	cd data/; rm -rf minio
	cd data/; rm -rf polaris

ps:
	docker compose ps

logs:
	docker compose logs

logsf:
	docker compose logs -f

watch:
	watch docker compose ps

fsql:
	docker compose exec --interactive --tty jobmanager /opt/flink/bin/sql-client.sh

jm:
	docker compose exec --interactive --tty jobmanager /bin/bash

cs:
	docker compose exec --interactive --tty coordinator-server /bin/bash

# Polaris Catalog, MinIO/S3 Storage
master:
	@echo "-- Generated S3/Polaris based Catalog deployment" > ./creFlinkFlows/master.sql
	@cat ./creFlinkFlows/scripts/1.0.creCatGen.sql >> ./creFlinkFlows/master.sql
	@cat ./creFlinkFlows/scripts/1.2.creCatFluss.sql >> ./creFlinkFlows/master.sql
	@cat ./creFlinkFlows/scripts/3.1.creTargetFinflow.sql >> ./creFlinkFlows/master.sql
	@echo "✅ master.sql for MinIO/S3 Storage with Polaris Catalog deployment"

deploy: master
	@echo "-- Deploying Fluss & Iceberg + Polaris Catalog & MinIO/S3 Storage..."
	docker compose exec --interactive --tty jobmanager /opt/flink/bin/sql-client.sh -f /creFlinkFlows/master.sql

# Single worker/sing thread, outputting from Flink to Fluss and down into Lakehouse tier
ahs:
	@echo "-- Submitting Account Holders Embedding Job, output to Fluss..."
	docker compose exec --interactive --tty jobmanager /opt/flink/bin/sql-client.sh -f /creFlinkFlows/scripts/4.1.creInsertsAhSingle.sql

txns:
	@echo "-- Submitting Transaction Embedding Job, output to Fluss..."
	docker compose exec --interactive --tty jobmanager /opt/flink/bin/sql-client.sh -f /creFlinkFlows/scripts/4.2.creInsertsTxnSingle.sql


# https://fluss.apache.org/docs/maintenance/tiered-storage/lakehouse-storage/#enable-lakehouse-storage	
tier:
	@echo "-- Submitting Iceberg Tiering Job... Polaris Catalog"
	docker compose exec --interactive --tty jobmanager \
		/opt/flink/bin/flink run \
			-Dpipeline.name="My Fluss Tiering Service, output to Iceberg, Polaris Catalog" \
			-Dparallelism.default=2 \
			/opt/flink/lib/fluss-flink-tiering-0.8.0-incubating.jar \
			--fluss.bootstrap.servers coordinator-server:9123 \
			--datalake.format iceberg \
			--datalake.iceberg.warehouse icebergcat \
			--datalake.iceberg.catalog.name icebergcat \
			--datalake.iceberg.type rest \
			--datalake.iceberg.uri http://polaris:8181/api/catalog  \
			--datalake.iceberg.oauth2-server-uri http://polaris:8181/api/catalog/v1/oauth/tokens \
			--datalake.iceberg.credential ${ROOT_CLIENT_ID}:${ROOT_CLIENT_SECRET} \
			--datalake.iceberg.scope PRINCIPAL_ROLE:ALL

