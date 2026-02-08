-- Generated S3/Polaris based Catalog deployment

USE CATALOG default_catalog;

CREATE CATALOG c_cdcsource WITH 
    ('type'='generic_in_memory');

USE CATALOG c_cdcsource;

-- Source for PyFlink
CREATE DATABASE IF NOT EXISTS demog;
-- Apache Fluss
CREATE CATALOG fluss_catalog WITH (
    'type'              = 'fluss',
    'bootstrap.servers' = 'coordinator-server:9123'
);

USE CATALOG fluss_catalog;

CREATE DATABASE IF NOT EXISTS fluss_catalog.finflow; 

SHOW DATABASES;

USE CATALOG fluss_catalog;

USE finflow;


-- Primary Key Table
--
-- The following SQL statement will create a Primary Key Table with a primary key consisting of nationalid
-- https://fluss.apache.org/docs/engine-flink/ddl/#primary-key-table
-- NOT, do not use => CREATE OR REPLACE TABLE 
CREATE TABLE accountholders ( 
     _id                      BIGINT NOT NULL 
     ,nationalid              STRING NOT NULL 
     ,firstname               STRING 
     ,lastname                STRING 
     ,dob                     STRING 
     ,gender                  STRING 
     ,children                INT 
     ,address                 STRING 
     ,accounts                STRING 
     ,emailaddress            STRING 
     ,mobilephonenumber       STRING 
     ,embedding_dimensions    INT 
     ,embedding_timestamp     TIMESTAMP 
     ,created_at              TIMESTAMP 
     ,ptime                   TIMESTAMP 
     ,PRIMARY KEY (nationalid) NOT ENFORCED 
) WITH ( 
      'table.datalake.enabled'   = 'true' 
     ,'table.datalake.freshness' = '60s' 
);
-- ALTER TABLE accountholders SET ('table.datalake.enabled' = 'false');
-- ALTER TABLE accountholders SET ('table.datalake.freshness' = '15');


-- Log Table
--
-- The following (see link) SQL statement creates a Log Table by not specifying primary key clause.
-- https://fluss.apache.org/docs/engine-flink/ddl/#log-table


-- Partitioned Primary Key Table
--
-- The following SQL statement creates a Partitioned Primary Key Table in Fluss.
-- For the Partitioned Primary Key Table, 
-- the partitioned field (partition_date in this case) 
-- must be a subset of the primary key (partition_date, eventid in this case)
-- https://fluss.apache.org/docs/engine-flink/ddl/#partitioned-primary-keylog-table
CREATE TABLE transactions (
     _id                                BIGINT      NOT NULL
    ,eventid                            STRING
    ,transactionid                      STRING
    ,eventtime                          STRING
    ,direction                          STRING
    ,eventtype                          STRING
    ,creationdate                       STRING
    ,accountholdernationalid            STRING
    ,accountholderaccount               STRING
    ,counterpartynationalid             STRING
    ,counterpartyaccount                STRING
    ,tenantid                           STRING
    ,fromid                             STRING
    ,accountagentid                     STRING
    ,fromfibranchid                     STRING
    ,accountnumber                      STRING
    ,toid                               STRING
    ,accountidcode                      STRING
    ,counterpartyagentid                STRING
    ,tofibranchid                       STRING
    ,counterpartynumber                 STRING
    ,counterpartyidcode                 STRING
    ,amount                             STRING
    ,msgtype                            STRING
    ,settlementclearingsystemcode       STRING
    ,paymentclearingsystemreference     STRING
    ,requestexecutiondate               STRING
    ,settlementdate                     STRING
    ,destinationcountry                 STRING
    ,localinstrument                    STRING
    ,msgstatus                          STRING
    ,paymentmethod                      STRING
    ,settlementmethod                   STRING
    ,transactiontype                    STRING
    ,verificationresult                 STRING
    ,numberoftransactions               INT
    ,schemaversion                      INT
    ,usercode                           STRING
    ,embedding_dimensions               INT
    ,embedding_timestamp                TIMESTAMP  
    ,partition_key                      STRING      NOT NULL
    ,created_at                         TIMESTAMP
    ,ptime                              TIMESTAMP
    ,PRIMARY KEY (partition_key, eventid) NOT ENFORCED
) PARTITIONED BY (partition_key) WITH (
      'table.datalake.enabled'     = 'true'
     ,'table.datalake.freshness'   = '60s'
);

show tables;

-- ALTER TABLE transactions SET ('table.datalake.enabled' = 'false');
-- ALTER TABLE transactions SET ('table.datalake.freshness' = '15');

-- For the above the admin needs to pre create the partitions.


-- For the above, auto partitioning can be enabled by using the below
-- https://fluss.apache.org/docs/engine-flink/ddl/#auto-partitioned-primary-keylog-table

-- ) PARTITIONED BY (partition_key) WITH (
--   'bucket.num' = '4'
--  ,'table.auto-partition.enabled'   = 'true'
--  ,'table.auto-partition.time-unit' = 'day'
-- );

-- As we have YYYYMMDD it implies day based partitioning.
-- 'table.auto-partition.time-unit' = 'day'

-- if we wanted  = 'month' then we need to provide the partition_key as 'YYYYMM'
-- 'table.auto-partition.time-unit' = 'month'

-- if we wanted  = 'year' then we need to provide the partition_key as 'YYYY'
-- 'table.auto-partition.time-unit' = 'year'
