## An Pratical Example "How to" Source data from a Postgres, Push it into Apache Fluss with Iceberg based Lakehouse tier'd onto S3 with a Apache Polaris (Incubating) REST based Catalog.

### Blog Overview

So this blog is a continuation from the previous. As such, it's going to be shorter..., well we will continue trying to get them shorter.

We previously we used Apache Paimon as our Open Table Format, for which we then used local file system or MinIO/S3 Object store for storage. For both the above storage options we had catalog options of either local file system or JDBC (with a PostgreSQL datastore for persistance).


This time round, we're deploying a similar stack, but based on Apache Polaris (Incubating) as our metadata catalog store (with a PostgreSQL datastore for persistance), again.


Accompanying BLOG: [An Practical “How to” build a PostgresSQL -> Apache Fluss with Apache Iceberg based Lakehouse streaming solution, using Apache Polaris (Incubating) Catalog](https://medium.com/@georgelza/an-practical-how-to-build-a-postgressql-apache-fluss-with-apache-iceberg-based-lakehouse-polaris)

**NOTES:** As per previous, for using local File System during testing as lakehouse storage, Dual mount your ./tmp/paimon in container to say ./data/paimon: locally, This needs to be done in BOTH the Flink containers (Jobmanager, TaskManager) and the Fluss Incubating containers (coordinator-server and tablet-servers).

**Building**

Below is the Dockerfile's for our main 2 container images, namely the Apache Flink and Apache Fluss (incubating).

These two containers can be built by changing into <Project root>/infrastructure and executing `make build` or by

- cd infrastructure/flink_base
  - make pull
  - make build

- cd infrastructure/flink
  - make pull
  - make build

- cd infrastructure/fluss
  - make pull
  - make build


### Apache Fluss (Incubating) Dockerfile - JAR's

If you read the previous blog you will see as a start the Apache Fluss one has grown, sigificantly as we now need to include MinIO/S3 endpoint and credentials for Apache Iceberg.


```bash
FROM apache/fluss:0.8.0-incubating
SHELL ["/bin/bash", "-c"]

ENV FLUSS_HOME=/opt/fluss
ENV HADOOP_CONF_DIR=/opt/fluss/conf

# Required for Iceberg / JDBC catalog
# See Option 2, https://fluss.apache.org/docs/next/streaming-lakehouse/integrate-data-lakes/iceberg/#2-custom-catalog-implementations
# Required for Iceberg: https://fluss.apache.org/docs/next/streaming-lakehouse/integrate-data-lakes/iceberg/#configure-iceberg-in-cluster-configurations

# 1. Iceberg / JDBC catalog
RUN mkdir -p /opt/fluss/plugins/iceberg
COPY stage/postgresql-42.7.6.jar            ${FLUSS_HOME}/plugins/iceberg

COPY stage/hadoop-apache-3.3.5-2.jar        ${FLUSS_HOME}/plugins/iceberg
COPY stage/iceberg-core-1.9.1.jar           ${FLUSS_HOME}/plugins/iceberg

# 1a. Add Iceberg AWS S3 FileIO support - CRITICAL FOR S3FileIO
COPY stage/aws-java-sdk-bundle-1.12.262.jar ${FLUSS_HOME}/plugins/iceberg
COPY stage/hadoop-shaded-guava-1.1.1.jar    ${FLUSS_HOME}/plugins/iceberg


# 2. Fluss -> S3 Lakehouse tiering
RUN mv ${FLUSS_HOME}/plugins/s3/fluss-fs-s3-0.8.0-incubating.jar  ${FLUSS_HOME}/lib
RUN rm -rf ${FLUSS_HOME}/plugins/s3

# 3. Lets make sure with our copying of JARs that all is owned by the right user/group.
RUN chown -R fluss:fluss ${FLUSS_HOME}
```

### Apache Flink Dockerfile - JAR's

Something to notice, I build my Flink container in 2 steps, first we have `flink_base` where I add generic OS settings and add the Python library stack as required for the PyFlink UDF. 

The second phase is then adding the libraries for the Open Table Format and the desired storage layer and catalog configurations.
The below is the second phase:

I'm well aware that I can probably change this to rather use Docker's own multistage build pattern ;)


```bash
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
ENV PAIMON_VERSION=1.3.1
ENV ICEBERG_VERSION=1.9.1
ENV LANCE_VERSION=0.0.1
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
```

## Running Lab

Once we have these 2 containers build we can run the lab, as contained in `devlab1`.

The biggest difference now being the `coordinator-server` and `tablet-server` configurations as per the `docker-compose.yaml` and the configuration of our Apache Flink tiering job. see `devlab1/Makefile` for these, at the end of the file... ;)

The lab can be found in `<Project root>/devlab1`

- `make run`

- `make deploy`

- `make ahs` or `make txns`

- Run the ShadowTraffic load generator, `<Project root>/shadowtraffic/run_pg#.sh`

- `make tier`

Note: you can also run the ShadowTraffic after the deploy command.


## Key Findings:

The biggest part of this how to blog can be found in the Apache Polaris (Incubating) and Apache Fluss (Incubating) Docker-Compose service definition. Peeking behind the curtain… well the surprise was values required, was not as expected, and the “sharing” of values between the Apache Polaris (Incubating) and Apache Fluss (Incubating) docker-compose services.

- Pay careful attention to each service “depends_on” block. It’s surprising how important the correct order is.

- For both the Apache Flink and Apache Fluss (Incubating) service we use a configs import to “import” the Hadoop configuration file into /opt/<Software>/conf/core-site.xml

The source file can be found in <Project root>/devlab1/conf.
This file contains the following S3 settings.

```shell
fs.s3a.endpoint
fs.s3a.access.key
fs.s3a.secret.key
fs.s3a.path.style.access
fs.s3a.connection.ssl.enabled
fs.s3a.impl
fs.s3a.aws.credentials.provider
```


### Apache Fluss (Incubating) 

(`<Project root>/devlab1/docker-compose.yaml`)

-> `coordinator-server` & `tablet-server-#` services

For the below code snippet, see the values for:

- datalake.iceberg.warehouse and 

- datalake.iceberg.catlog.name. 


Both configured as `icebergcat`. Make note of this… ;)

```shell
environment:
    - |
    FLUSS_PROPERTIES=
        bind.listeners                                : INTERNAL://coordinator-server:9124, CLIENT://coordinator-server:9123
        advertised.listeners                          : INTERNAL://coordinator-server:9124, CLIENT://coordinator-server:9123
        zookeeper.address                             : zookeeper:2181
        internal.listener.name                        : INTERNAL

        data.dir                                      : /tmp/local-data
        remote.data.dir                               : /tmp/remote-data

        # Lakehouse store on S3 and catalog in Polaris
        datalake.enabled                                : true
        datalake.format                                 : iceberg
        datalake.iceberg.warehouse                      : icebergcat    # NOTE: this aligns with our polaris catalog, also matches below catalog.name value.
        datalake.iceberg.table-default.file.format      : parquet

        # Polaris Catalog
        datalake.iceberg.catalog.name                   : icebergcat
        datalake.iceberg.type                           : rest
        datalake.iceberg.uri                            : http://polaris:8181/api/catalog  # Correct - client adds /v1/icebergcat automatically
        datalake.iceberg.oauth2-server-uri              : http://polaris:8181/api/catalog/v1/oauth/tokens
        datalake.iceberg.credential: ${ROOT_CLIENT_ID}  :${ROOT_CLIENT_SECRET}
        datalake.iceberg.scope                          : PRINCIPAL_ROLE:ALL
```

### Apache Polaris Configuration

(`<Project root>/devlab1/docker-compose.yaml`)
-> `polaris-setup` service

And we’re back, now the next bit, and this is where things get tied together, note the very last line, where we tell polaris-setup to create our catalog using our helper script (create-catalog.sh, which can be found in conf/polaris), well the last parameter, catalog-name. 

Well, this comes from our .env file, and without “copying” the contents here, the value specified is “icebergcat”, as also used/specified above in our coordinator-server (and the not shown tablet-server-# service configurations). 

What we also define for the catalog create is where the data will go, as in our S3 location, which now maps to s3a://warehouse/iceberg which is again a value specified in .env as S3_BUCKET and well iceberg is iceberg ;).

If you read the previous blogs, note the $$<Params> parameters are now wrapped in ‘ ” & “’ quotes, just something that’s required as the values are passed around from the docker-compose into the helper scripts.

```shell
command:
    - "-c"
    - >-
    chmod +x /polaris/create-catalog.sh;
    chmod +x /polaris/obtain-token.sh;
    source /polaris/obtain-token.sh "$$POLARIS_HOST" "$$POLARIS_REALM" "$$CLIENT_ID" "$$CLIENT_SECRET";
    export PROPERTIES='{
        "default-base-location": "s3a://'$$S3_BUCKET'/iceberg",
        "s3a.endpoint": "'$$S3_ENDPOINT'",
        "s3a.path-style-access": true,
        "s3a.access-key-id": "'$$AWS_ACCESS_KEY_ID'",
        "s3a.secret-access-key": "'$$AWS_SECRET_ACCESS_KEY'",
        "s3a.region": "'$$AWS_REGION'"
    }';
    export STORAGE_CONFIG_INFO='{
        "storageType": "S3",
        "endpoint": "'$$S3_ENDPOINT'",
        "endpointInternal": "'$$S3_ENDPOINT'",
        "region": "'$$AWS_REGION'",
        "pathStyleAccess": true,
        "allowedLocations": ["s3a://'$$S3_BUCKET'/iceberg/*"],
        "accessKeyId": "'$$AWS_ACCESS_KEY_ID'",
        "secretAccessKey": "'$$AWS_SECRET_ACCESS_KEY'"
    }';
    export STORAGE_LOCATION="s3a://$$S3_BUCKET/iceberg";
    source /polaris/create-catalog.sh "$$POLARIS_HOST" "$$POLARIS_REALM" "$$CATALOG_NAME";
```


### Tiering Job
  
```yaml
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
```


## Summary

So, we now have a working example whereby we insert two data products into PostgreSQL tables. We then utilise Apache Flink CDC to source those records into transient Apache Flink Tables. From there we push the data steam into Apache Fluss (Incubating) configured with Apache Iceberg as lakehouse tier, hosted on a S3/MinIO Object store, all with Apache Polaris (Incubating) as metadata store for our Iceberg table. 

Nifty, I think.

As previous, these are not complete solutions, but rather blocks that can be used to build a larger stack. I have one 

Last blog in this series, but that’s waiting for Apache Fluss (Incubating) 0.9.0, which is imminent.


**THE END**


Thanks for following. Till next time.


### The Rabbit Hole

<img src="blog-doc/diagrams/rabbithole.jpg" alt="Our Build" width="600">

And like that we’re done with our little trip down another Rabbit Hole.


## ABOUT ME

I’m a techie, a technologist, always curious, love data, have for as long as I can remember always worked with data in one form or the other, Database admin, Database product lead, data platforms architect, infrastructure architect hosting databases, backing it up, optimizing performance, accessing it. Data data data… it makes the world go round.
In recent years, pivoted into a more generic Technology Architect role, capable of full stack architecture.

### By: George Leonard

- georgelza@gmail.com
- https://www.linkedin.com/in/george-leonard-945b502/
- https://medium.com/@georgelza



<img src="blog-doc/diagrams/TechCentralFeb2020-george-leonard.jpg" alt="Our Build" width="600">



## Regarding our Stack

The following stack is deployed using one of the provided  `<Project Root>/devlab/docker-compose-*.yaml` files as per above.

- [Apache Flink 1.20.2](https://nightlies.apache.org/flink/flink-docs-release-1.20/)                   

- [Apache Flink CDC 3.5.0](https://nightlies.apache.org/flink/flink-cdc-docs-release-3.5/)

- [Apache Iceberg 1.9.1.](https://iceberg.apache.org)

- [Apache Polaris (Incubating)](https://polaris.apache.org) – we used latest

- [PostgreSQL 15](https://www.postgresql.org)

- [MinIO](https://www.min.io) - Project has gone into Maintenance mode... 

- [ShadowTraffic](https://shadowtraffic.io)

