
-- psql -h localhost -p 5432 -U dbadmin -d sales

CREATE TABLE public.accountholders (
     _id                      SERIAL        NOT NULL
    ,nationalid               VARCHAR(16)   NOT NULL
    ,firstname                VARCHAR(100)     
    ,lastname                 VARCHAR(100)      
    ,dob                      VARCHAR(10)              
    ,gender                   VARCHAR(10)       
    ,children                 INTEGER
    ,address                  JSONB            
    ,accounts                 JSONB     
    ,emailaddress             VARCHAR(100)
    ,mobilephonenumber        VARCHAR(20)
    ,created_at               TIMESTAMPTZ       DEFAULT NOW() NOT NULL
    ,PRIMARY KEY              (_id)
) TABLESPACE pg_default;

CREATE TABLE public.transactions (
     _id                            SERIAL          NOT NULL
    ,eventid                        VARCHAR(36)     NOT NULL
    ,transactionid                  VARCHAR(36)     NOT NULL
    ,eventtime                      VARCHAR(30)
    ,direction                      VARCHAR(8)
    ,eventtype                      VARCHAR(10)
    ,creationdate                   VARCHAR(20)
    ,accountholdernationalId        VARCHAR(16)
    ,accountholderaccount           JSONB
    ,counterpartynationalId         VARCHAR(16)
    ,counterpartyaccount            JSONB
    ,tenantid                       VARCHAR(8)
    ,fromid                         VARCHAR(8)
    ,accountagentid                 VARCHAR(8)
    ,fromfibranchid                 VARCHAR(6)
    ,accountnumber                  VARCHAR(16)
    ,toid                           VARCHAR(8)
    ,accountidcode                  VARCHAR(5)
    ,counterpartyagentid            VARCHAR(8)
    ,tofibranchid                   VARCHAR(6)
    ,counterpartynumber             VARCHAR(16)
    ,counterpartyidcode             VARCHAR(5)
    ,amount                         JSONB
    ,msgtype                        VARCHAR(6)
    ,settlementclearingsystemcode   VARCHAR(5)
    ,paymentclearingsystemreference VARCHAR(12)
    ,requestexecutiondate           VARCHAR(10)
    ,settlementdate                 VARCHAR(10)
    ,destinationcountry             VARCHAR(30)
    ,localinstrument                VARCHAR(2)
    ,msgstatus                      VARCHAR(12)
    ,paymentmethod                  VARCHAR(4)
    ,settlementmethod               VARCHAR(4)
    ,transactiontype                VARCHAR(2)
    ,verificationresult             VARCHAR(4)
    ,numberoftransactions           INTEGER
    ,schemaversion                  INTEGER
    ,usercode                       VARCHAR(4)
    ,created_at                     TIMESTAMPTZ      DEFAULT NOW() NOT NULL
    ,PRIMARY KEY                    (_id)
) TABLESPACE pg_default;

CREATE INDEX accountholders_nationalid_idx ON public.accountholders(nationalid);
CREATE INDEX transactions_eventid_idx ON public.transactions(eventid);
CREATE INDEX transactions_txnid_idx ON public.transactions(transactionid);

ALTER TABLE public.accountholders REPLICA IDENTITY FULL;
ALTER TABLE public.accountholders OWNER TO dbadmin;

ALTER TABLE public.transactions REPLICA IDENTITY FULL;
ALTER TABLE public.transactions OWNER TO dbadmin;


-- Replication role and user
CREATE ROLE replicator WITH
  LOGIN
  INHERIT
  SUPERUSER
  REPLICATION;

GRANT pg_monitor TO replicator;
GRANT ALL PRIVILEGES ON DATABASE demog TO replicator;

-- CREATE ROLE flinkcdc WITH
--   LOGIN
--   INHERIT
--   SUPERUSER
--   REPLICATION
--   ENCRYPTED PASSWORD 'dbpassword';

--GRANT replicator TO flinkcdc;
GRANT replicator TO dbadmin;

-- replica is the default value for wal_level

-- https://dba.stackexchange.com/questions/270365/wal-level-set-to-replica-at-database-level-but-i-dont-see-that-in-configuration

-- select name, setting, sourcefile, sourceline from pg_settings where name = 'wal_level';

-- select pg_drop_replication_slot('the_name_of_subscriber');

-- https://www.dbi-services.com/blog/postgresql-when-wal_level-to-logical/
-- SELECT * FROM pg_logical_slot_get_changes('flinkcdc', NULL, NULL);

-- show config_file
-- show hba_file


-- See: 
-- https://www.alibabacloud.com/help/en/flink/developer-reference/configure-a-postgresql-database#concept-2116236
-- https://www.percona.com/blog/setting-up-streaming-replication-postgresql/#:~:text=PostgreSQL%20streaming%20replication%20is%20a,mirror%20the%20primary%20database%20accurately.
-- https://knowledge.informatica.com/s/article/ERROR-Must-be-wal-level-logical-for-logical-decoding-SQL-state-55000-while-performing-row-test-in-PowerExchange-PostgreSQL?language=en_US
-- https://www.dbi-services.com/blog/postgresql-when-wal_level-to-logical/



-------------------------------------------------------------------------------------------
-- Catalogs Database
-------------------------------------------------------------------------------------------

CREATE DATABASE catalogs;

GRANT ALL PRIVILEGES ON DATABASE catalogs TO dbadmin;

-- Connect to the newly created database
\connect catalogs;


-------------------------------------------------------------------------------------------
-- Apache Paimon JDBC Catalog Datastore

-- Schema that will house our Flink / Paimon JDBC catalogs
CREATE SCHEMA IF NOT EXISTS paimon_jdbc AUTHORIZATION dbadmin;

-- Grant permissions to the catalog user
GRANT ALL PRIVILEGES ON SCHEMA paimon_jdbc TO dbadmin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA paimon_jdbc TO dbadmin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA paimon_jdbc TO dbadmin;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA paimon_jdbc GRANT ALL ON TABLES TO dbadmin;
ALTER DEFAULT PRIVILEGES IN SCHEMA paimon_jdbc GRANT ALL ON SEQUENCES TO dbadmin;

COMMENT ON SCHEMA paimon_jdbc IS 'Paimon JDBC Catalog Storage';

-------------------------------------------------------------------------------------------
-- Apache Fluss JDBC Catalog Datastore

-- Schema that will house our Fluss JDBC catalogs
CREATE SCHEMA IF NOT EXISTS iceberg_jdbc AUTHORIZATION dbadmin;

-- Grant permissions to the catalog user
GRANT ALL PRIVILEGES ON SCHEMA iceberg_jdbc TO dbadmin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA iceberg_jdbc TO dbadmin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA iceberg_jdbc TO dbadmin;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA iceberg_jdbc GRANT ALL ON TABLES TO dbadmin;
ALTER DEFAULT PRIVILEGES IN SCHEMA iceberg_jdbc GRANT ALL ON SEQUENCES TO dbadmin;

COMMENT ON SCHEMA iceberg_jdbc IS 'Iceberg JDBC Catalog Storage';
