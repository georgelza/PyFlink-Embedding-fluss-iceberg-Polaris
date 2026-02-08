## Polaris based Catalog, configured with PostgreSQL persistent store

For our [Apache Iceberg](https://iceberg.apache.org) based tables we'll be using a [Apache Polaris (incubating)](https://polaris.apache.org) as our Catalog store.

The basic verification/qualification of our build can be found in `docker-compose-basic.yaml`, this can be started up on it's own using `make run_basic`. The catlaog has been configured to use PostgreSQL as persistant store.

This is provided via the `postgrecat` service that spins up a PostgreSQL server and creates a `catalog_store` database. Polaris as part of the bootstrap them creates a schema: `polaris_schema` which is utilised for the required tables.

See the `.env` and the below specific variables.

```bash

# PostgreSQL Catalog Store
COMPOSE_PROJECT_NAME=fi
REPO_NAME=sgeorgelza

# PostgreSQL CDC Source
POSTGRES_CDC_HOST=postgrescdc
POSTGRES_CDC_PORT=5432
POSTGRES_CDC_USER=dbadmin
POSTGRES_CDC_PASSWORD=dbpassword
POSTGRES_CDC_DB=demog

# PostgreSQL Catalog Store used for out Polaris REST catalog for our Iceber tables & Flink JDBC catalog used for Paimon tables
#
# If you decide to change the CAT_DB name then also update <Project Root>/devlab/sql/postgrescat/postgresql-init.sql script, 
# making sure to assign dbadmin user access to the new DB name chosen.
#
# Following strict Polaris conventions the POSTGRES_CAT_DB name should match the value for POLARIS_REALM variable
# We create flink_catalog as the default database, then create findept using the postgresql-init.sql script.
POSTGRES_CAT_HOST=postgrescat
POSTGRES_CAT_PORT=5433
POSTGRES_CAT_USER=dbadmin
POSTGRES_CAT_PASSWORD=dbpassword
POSTGRES_CAT_DB=catalog


# Polaris Catalog
ROOT_CLIENT_ID=root
ROOT_CLIENT_SECRET=s3cr3t
CATALOG_NAME=icebergcat
POLARIS_REALM=findept

# Minio
MINIO_ROOT_USER=mnadmin
MINIO_ROOT_PASSWORD=mnpassword
MINIO_ALIAS=minio
MINIO_ENDPOINT=http://minio:9000
MINIO_BUCKET=warehouse
AWS_ACCESS_KEY_ID=mnadmin
AWS_SECRET_ACCESS_KEY=mnpassword
AWS_REGION=za-south-1
AWS_DEFAULT_REGION=za-south-1

```



#
# NOTE:
# Polaris Namespace = Flink/Fluss DB
# Re: [Polaris Namespace](https://polaris.apache.org/in-dev/unreleased/entities/#namespace)
#
# By: [Alex Merced](https://dev.to/alexmercedcoder)
# Re: [Understanding the Polaris Iceberg Catalog and Its Architecture](https://dev.to/alexmercedcoder/understanding-the-polaris-iceberg-catalog-and-its-architecture-7ka)
#


## Verification

### Get Token

```bash
TOKEN=$(curl -s http://localhost:8181/api/catalog/v1/oauth/tokens \
  --user root:s3cr3t \
  -H "Polaris-Realm: finflow" \
  -d grant_type=client_credentials \
  -d scope=PRINCIPAL_ROLE:ALL | jq -r .access_token)
```

### Verify Catalog has been created

```bash
curl -X GET http://localhost:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $TOKEN" | jq
```

## Additional setup steps.

### Create a catalog admin role

```bash
curl -X PUT http://localhost:8181/api/management/v1/catalogs/icebergcat/catalog-roles/catalog_admin/grants \
  -H "Authorization: Bearer $TOKEN" \
  --json '{"grant":{"type":"catalog", "privilege":"CATALOG_MANAGE_CONTENT"}}'
```

### Create a DataEngineer role

```bash
curl -X POST http://localhost:8181/api/management/v1/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  --json '{"principalRole":{"name":"DataEngineer"}}'
```

### Connect the roles

```bash
curl -X PUT http://localhost:8181/api/management/v1/principal-roles/DataEngineer/catalog-roles/icebergcat \
  -H "Authorization: Bearer $TOKEN" \
  --json '{"catalogRole":{"name":"catalog_admin"}}'
```

### Assign root the DataEngineer role

```bash
curl -X PUT http://localhost:8181/api/management/v1/principals/root/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  --json '{"principalRole": {"name":"DataEngineer"}}'
```

## Verify roles assigned to root user

```bash
curl -X GET http://localhost:8181/api/management/v1/principals/root/principal-roles -H "Authorization: Bearer $TOKEN" | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   300  100   300    0     0   3529      0 --:--:-- --:--:-- --:--:--  3571

{
  "roles": [
    {
      "name": "service_admin",
      "federated": false,
      "properties": {},
      "createTimestamp": 1769870596578,
      "lastUpdateTimestamp": 1769870596578,
      "entityVersion": 1
    },
    {
      "name": "DataEngineer",
      "federated": false,
      "properties": {},
      "createTimestamp": 1769870604579,
      "lastUpdateTimestamp": 1769870604579,
      "entityVersion": 1
    }
  ]
}
```



## Apache Polaris Resources

For more "insight" or is that exploring this rabbit hole.

- [Polaris](https://polaris.apache.org)

- [Quick Start with Apache Iceberg and Apache Polaris on your Laptop (quick setup notebook environment)](https://www.dremio.com/blog/quick-start-with-apache-iceberg-and-apache-polaris-on-your-laptop-quick-setup-notebook-environment/)

- Also various examples at the Project GIT Repo: [Polaris](https://github.com/apache/polaris.git) in the `getting-started` sub directory.


## Deployment Steps

### 1. Start the Services

```bash

# Start all services
make run_basic

# Check service status
make ps
# or
docker-compose ps

# View logs
docker-compose logs -f polaris
docker-compose logs -f postgrescat
docker-compose logs -f minio

# or

make logsf |grep polaris
make logsf |grep postgrescat
make logsf |grep minio

```


### 2. Verify PostgreSQL Setup

```bash

# Connect to PostgreSQL  => Polaris Data
docker exec -it postgrescat psql -U dbadmin -d findept

# List all schemas
\dn

# Expected output:
#          Name          |  Owner  
# -----------------------+---------
#  polaris_schema        | dbadmin
#  public                | dbadmin

# Exit
\q

```


### 3. Check Polaris health

```bash

curl http://localhost:8182/q/health

# The important bit for the below one is the http Status 200 at the end of the response
curl -w "\nHTTP Status: %{http_code}\n" http://localhost:8182/healthcheck

# metrics that can be scraped using Prometheus server
curl -f http://localhost:8182/q/metrics

# want to see healthy
docker inspect polaris --format='{{.State.Health.Status}}'

```


### 4. Extract Polaris Credentials

```bash
# Extract credentials from .env

ROOT_CLIENT_ID=$(grep ROOT_CLIENT_ID .env | cut -d '=' -f2)
ROOT_CLIENT_SECRET=$(grep ROOT_CLIENT_SECRET .env | cut -d '=' -f2)

echo "Client ID: ${ROOT_CLIENT_ID}"
echo "Client Secret: ${ROOT_CLIENT_SECRET}"
```

**Your Credentials:**
- Client ID: `root`
- Client Secret: `s3cr3t`


### 5. Get OAuth Token from Polaris

```bash

# Get access token
#
# Retrieve access token - This needs to be done before any other commands are executed as the TOKEN forms part of the API call variables.
# Note the client_id and client_secret need to match .env/ROOT_CLIENT_* values

export TOKEN=$(curl -s -X POST http://localhost:8181/api/catalog/v1/oauth/tokens \
    -d 'grant_type=client_credentials' \
    -d 'client_id=root' \
    -d 'client_secret=s3cr3t' \
    -d 'scope=PRINCIPAL_ROLE:ALL' \
    | jq -r '.access_token')

```


### 6. Create our Polaris Catalogs (Optional via REST API)

```bash

# The below was executed/completed via our bootstrap service defined in our `docker-compose.yaml` file.
# The command is shared for example purposes only.

# Take note of our helper scripts located in `<Project Root>/conf/polaris`.

# The below catalog is deployed as part of our `polaris-setup` docker-compose service
#
# Create (iceberg based) catalog via REST API (optional - Flink will create via REST)
# We specify a "specified" folder location under our MinIO warehouse root

# 1. Create the "icebergcat" catalog pointing to MinIO
curl -i -X POST http://localhost:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
  --json '{
    "name": "icebergcat",
    "type": "INTERNAL",
    "properties": {
      "default-base-location": "s3://warehouse/iceberg",
      "s3.endpoint": "http://minio:9000",
      "s3.access-key-id": "mnadmin",
      "s3.secret-access-key": "mnpassword",
      "s3.region": "af-south-1",
      "s3.path-style-access": true
    },
    "storageConfigInfo": {
      "storageType": "S3",
      "allowedLocations": [
        "s3://warehouse/iceberg/*"
      ]
    }
}' -v | jq


# 2. List all catalogs to verify creation
curl -X GET http://localhost:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
    | jq
```


### 7. Create Catalog Namespace 

```bash

# 1. List namespaces in the catalog
curl -X GET http://localhost:8181/api/catalog/v1/icebergcat/namespaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
    | jq


# 2. Create 'fraud' Namespace inside icebergcat catalog
curl -X POST http://localhost:8181/api/catalog/v1/icebergcat/namespaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
    -d '{
      "namespace": ["fraud"], 
      "properties": {
        "description": "Icebergcat catalog, database: fraud"
      }
}' | jq
```


### 8. Setting Up Role-Based Access Control (RBAC)

If you want to set up role-based access control:

[Build a Data Lakehouse with Apache Iceberg, Polaris, Trino & MinIO](https://medium.com/@gilles.philippart/build-a-data-lakehouse-with-apache-iceberg-polaris-trino-minio-349c534ecd98) by [Gilles Philippart](https://medium.com/@gilles.philippart)

```bash

# 1. Create a catalog admin role
curl -X PUT http://localhost:8181/api/management/v1/catalogs/icebergcat/catalog-roles/catalog_admin/grants \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
  --json '{
    "grant":{
      "type":"catalog", 
      "privilege":"CATALOG_MANAGE_CONTENT"
    }
}' | jq

# 2. Create a data engineer role
curl -X POST http://localhost:8181/api/management/v1/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
  --json '{
    "principalRole":{
      "name":"DataEngineer"
    }
}' | jq


# 3. Connect the roles
curl -X PUT http://localhost:8181/api/management/v1/principal-roles/DataEngineer/catalog-roles/icebergcat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
  --json '{
    "catalogRole":{
      "name":"catalog_admin"
    }
}' | jq


# 4.Give root the data engineer role
curl -X PUT http://localhost:8181/api/management/v1/principals/root/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
  --json '{
      "principalRole": {
        "name":"DataEngineer"
      }
}' | jq


# 5. Inspect
curl -X GET http://localhost:8181/api/management/v1/principals/root/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Polaris-Realm: findept" \
  | jq
```

```json
{
  "roles": [
    {
      "name": "service_admin",
      "federated": false,
      "properties": {},
      "createTimestamp": 1751733238263,
      "lastUpdateTimestamp": 1751733238263,
      "entityVersion": 1
    },
    {
      "name": "DataEngineer",
      "federated": false,
      "properties": {},
      "createTimestamp": 1751733315678,
      "lastUpdateTimestamp": 1751733315678,
      "entityVersion": 1
    }
  ]
}
```


```bash
# OR

# NOT VERIFIED AS WORKING

# Step 1. Create a principal role
curl -X POST http://localhost:8181/management/v1/principal-roles \
  -H "Authorization: Bearer {$TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "principalRole": {
      "name": "DataEngineer"
    }
}' | jq


# Step 2. Create a catalog role
curl -X POST http://localhost:8181/management/v1/catalogs/icebergcat/catalog-roles \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "catalogRole": {
      "name": "TableManager"
    }
}' | jq


# Step 3. Create a catalog admin role
curl -X PUT http://localhost:8181/api/management/v1/catalogs/icebergcat/catalog-roles/catalog_admin/grants \
  -H "Authorization: Bearer ${TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "grant":{
      "type":"catalog", 
      "privilege": "CATALOG_MANAGE_CONTENT"
    }
}' | jq


# 4. Create a data engineer role
# Create a data engineer role
curl -X POST http://localhost:8181/api/management/v1/principal-roles \
  -H "Authorization: Bearer ${TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
      "principalRole": {
        "name": "DataEngineer"
    }
}' | jq


# 5. Connect the roles
curl -X PUT http://localhost:8181/api/management/v1/principal-roles/DataEngineer/catalog-roles/icebergcat \
  -H "Authorization: Bearer ${TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "catalogRole":{
      "name": "TableManager"
    }
}' | jq


# 6. Give root the data engineer role
curl -X PUT http://localhost:8181/api/management/v1/principals/root/principal-roles \
  -H "Authorization: Bearer v \
  -H 'Content-Type: application/json' \
  -d '{
    "principalRole": {
      "name": "DataEngineer"
    }
}' | jq


# 7. Get principal roles 
curl -X GET http://localhost:8181/api/management/v1/principals/root/principal-roles \
  -H "Authorization: Bearer $TOKEN" | jq


# 8. Grant table privileges to the catalog role (TableManager)
curl -X PUT http://localhost:8181/api/management/v1/catalogs/icebergcat/catalog-roles/TableManager/grants \
  -H "Authorization: Bearer ${TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "grants": [
      {
        "type": "catalog",
        "privilege": "TABLE_CREATE"
      },
      {
        "type": "catalog", 
        "privilege": "TABLE_READ_DATA"
      },
      {
        "type": "catalog",
        "privilege": "TABLE_WRITE_DATA"
      }
    ]
}' | jq

# Catalog Roles
# 
#   Table specific
#     TABLE_CREATE
#     TABLE_DROP
#     TABLE_LIST
#     TABLE_READ_PROPERTIES
#     TABLE_WRITE_PROPERTIES
#     TABLE_READ_DATA
#     TABLE_WRITE_DATA
#     TABLE_FULL_METADATA
#
#   View Privileges
#     ...
#
#   Namespace Privileges
#     ...
# 
#   Catalog wide
#     CATALOG_MANAGE_METADATA
#     TABLE_FULL_METADATA
#     NAMESPACE_FULL_METADATA
#     VIEW_FULL_METADATA
#     TABLE_WRITE_DATA
#     TABLE_READ_DATA
#     CATALOG_READ_PROPERTIES
#     CATALOG_WRITE_PROPERTIES
#
# See https://polaris.apache.org/in-dev/unreleased/managing-security/access-control/

# or

curl -X PUT http://localhost:8181/api/management/v1/catalogs/icebergcatx/catalog-roles/TableManager/grants \
  -H "Authorization: Bearer ${TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "grants": [
      {
        "type": "catalog",
        "privilege": "CATALOG_MANAGE_CONTENT"
      }
    ]
  }' 
```

### 9. List tables in the finflow namespace from icebergcat catalog

```bash

curl -X GET http://localhost:8181/api/catalog/v1/icebergcat/namespaces/finflow/tables \
  -H "Authorization: Bearer ${TOKEN}" | jq

```


## Create Flink Catalog using Flink-sql, referencing our Polaris API created catalog: 'icebergcat'

### 1. Create c_iceberg catalog using Polaris REST interface

```sql

-- 1. Catalog
CREATE CATALOG c_iceberg WITH (
   'type'                       = 'iceberg'
  ,'catalog-type'               = 'rest'
  ,'uri'                        = 'http://polaris:8181/api/catalog'
  ,'warehouse'                  = 'icebergcat'
  ,'oauth2-server-uri'          = 'http://polaris:8181/api/catalog/v1/oauth/tokens'
  ,'credential'                 = 'root:s3cr3t'
  ,'scope'                      = 'PRINCIPAL_ROLE:ALL'
  ,'s3a.endpoint'               = 'http://minio:9000'
  ,'s3a.access-key-id'          = 'mnadmin'
  ,'s3a.secret-access-key'      = 'mnpassword'
  ,'s3a.path-style-access'      = 'true'
  ,'table-default.file.format'  = 'parquet'
);

USE CATALOG c_iceberg;
CREATE DATABASE IF NOT EXISTS finflow;


-- 2. Create CDC source tables in default_catalog
-- Note: These are NOT a catalog, just table definitions with postgres-cdc connector
USE CATALOG default_catalog;
CREATE DATABASE IF NOT EXISTS demog;
USE demog;


-- 3. Create CDC tables
-- See full script for details, <Project Toor>/devlab/creFlinkFlows/2.1.creCdc.sql

```

## Database, Schema, Catalog Structure

PostgreSQL Server: `postgrescat`

**Note**: also shown is the presence of the Flink based JDBC catalog database: `flink_catalog` hosted on the same PostgreSQL server.


### 1. DB: findept REALM

| Schema | Purpose | Used By |
|--------|---------|---------|
| `polaris_schema` | Polaris metadata storage | Apache Polaris (Iceberg) |
| `public`  | Default PostgreSQL schema | General use |


### 2. Catalog Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flink SQL Engine                    │
└───────────────┬───────────────────────────┬─────────────┘
                │                           │
                │                           │
           ┌────▼────┐                ┌─────▼──────────┐
           │c_iceberg│                │ default_catalog│
           │ (REST)  │                │ (in-memory)    │
           └────┬────┘                └──────┬─────────┘
                │                            │
                │                            │
                │                            │
                │                            │
           ┌────▼────┐                 ┌─────▼──────┐
           │ Polaris │                 │demog DB:   │
           │  REST   │                 │CDC table   │
           │  API    │                 │definitions │
           └────┬────┘                 │(reference  │
                └─────────────┐        │PostgresCDC)│
                              │        └────────────┘
           ┌──────────────────▼─────────────────┐
           │       PostgresCAT Pg Server        │
           │                                    │
           │          DB:findept                │
           │        polaris_schema              │
           │     (polaris REST based catalog)   │
           └────┬───────────────────┬───────────┘
                │                   │
                │                   │
           ┌────▼───────────────────▼─────┐
           │      MinIO S3 Storage        │
           │                              │
           │     warehouse/iceberg/       │
           └────┬───────────────────┬─────┘
                │                   │
                │                   │
           ┌────▼───────────────────▼───────┐
           │        -> c_iceberg            │
           │                                │
           │     warehouse/iceberg/finflow  │
           │                                │
           │     warehouse/iceberg/fraud    │
           │                                │
           └────────────────────────────────┘

```

### 3. MinIO Storage Structure

```
warehouse/
│
└── iceberg/          # c_iceberg Iceberg based catalog housing Iceberg table data and metadata
    └── finflow/      # finflow database/namespace
    └── fraud/        # fraud database/namespace

```