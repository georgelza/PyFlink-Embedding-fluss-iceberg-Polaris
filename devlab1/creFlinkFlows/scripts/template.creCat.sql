

-- Apache Iceberg based REST Catalog stored inside PostgreSQL database using Polaris as catalog store
-------------------------------------------------------------------------------------------------------------------------
-- server:  postgrescat
-- db:      findept
-- schema:  polaris_schema
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
CREATE DATABASE IF NOT EXISTS c_iceberg.finflow;