-- scripts/4.2.creInsertsTxnSingle.sql
-- Insert Statement with inline call to our generate_txn_embedding Python based UDF routine.
--  => c_paimon.finflow.transactions, sourced from c_cdcsource.demog.transactions

USE CATALOG c_cdcsource;
CREATE DATABASE IF NOT EXISTS demog;  
USE demog;

-- Recreate the CDC tables inside this session.

CREATE OR REPLACE TABLE transactions (
     _id                            BIGINT              NOT NULL
    ,eventid                        VARCHAR(36)
    ,transactionid                  VARCHAR(36)
    ,eventtime                      VARCHAR(30)
    ,direction                      VARCHAR(8)
    ,eventtype                      VARCHAR(10)
    ,creationdate                   VARCHAR(20)
    ,accountholdernationalid        VARCHAR(16)
    ,accountholderaccount           STRING
    ,counterpartynationalid         VARCHAR(16)
    ,counterpartyaccount            STRING
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
    ,amount                         STRING
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
    ,numberoftransactions           INT
    ,schemaversion                  INT
    ,usercode                       VARCHAR(4)
    ,created_at                     TIMESTAMP_LTZ(3)
    ,WATERMARK                      FOR created_at AS created_at - INTERVAL '15' SECOND
    ,PRIMARY KEY (_id) NOT ENFORCED
) WITH (
     'connector'                            = 'postgres-cdc'
    ,'hostname'                             = 'postgrescdc'
    ,'port'                                 = '5432'
    ,'username'                             = 'dbadmin'
    ,'password'                             = 'dbpassword'
    ,'database-name'                        = 'demog'
    ,'schema-name'                          = 'public'
    ,'table-name'                           = 'transactions'
    ,'slot.name'                            = 'transactions_pyflink' 
    ,'scan.incremental.snapshot.enabled'    = 'true'               
    ,'scan.startup.mode'                    = 'initial'            
    ,'decoding.plugin.name'                 = 'pgoutput'
    ,'scan.incremental.snapshot.chunk.size' = '4096' 
    ,'scan.snapshot.fetch.size'             = '512'
    ,'connect.timeout'                      = '30s'
);

DROP FUNCTION IF EXISTS generate_txn_embedding;

-- Register the UDF
-- Syntax: CREATE FUNCTION <function_name> AS '<module_name>.<function_name>' LANGUAGE PYTHON;
CREATE FUNCTION generate_txn_embedding 
    AS 'txn_embed_udf.generate_txn_embedding' 
    LANGUAGE PYTHON;


-- Set configurations
SET 'parallelism.default'               = '1';

-- Reduce Bundle Size: Making the bundles smaller allows the "checkpoint barrier" to pass through the UDF more frequently.
SET 'python.fn-execution.bundle.size'   = '50';
--   10 seconds
SET 'python.fn-execution.bundle.time'   = '10000';
-- 120seconds / 2min
SET 'execution.checkpointing.interval'  = '120s'; 

-- Disable Upsert Materializer: As seen in your previous error, this is mandatory for Paimon.
SET 'table.exec.sink.upsert-materialize' = 'NONE';


SET 'pipeline.name'                      = 'Emded & Persist into Fluss finflow.transactions';
INSERT INTO fluss_catalog.finflow.transactions
(
     _id                     
    ,eventid                 
    ,transactionid              
    ,eventtime                  
    ,direction                 
    ,eventtype                    
    ,creationdate                 
    ,accountholdernationalid        
    ,accountholderaccount            
    ,counterpartynationalid         
    ,counterpartyaccount             
    ,tenantid                 
    ,fromid                    
    ,accountagentid              
    ,fromfibranchid          
    ,accountnumber              
    ,toid                  
    ,accountidcode                 
    ,counterpartyagentid           
    ,tofibranchid                
    ,counterpartynumber         
    ,counterpartyidcode          
    ,amount                  
    ,msgtype                     
    ,settlementclearingsystemcode   
    ,paymentclearingsystemreference  
    ,requestexecutiondate            
    ,settlementdate                
    ,destinationcountry         
    ,localinstrument           
    ,msgstatus                
    ,paymentmethod                 
    ,settlementmethod           
    ,transactiontype             
    ,verificationresult         
    ,numberoftransactions     
    ,schemaversion                
    ,usercode                 
    ,embedding_dimensions
    ,embedding_timestamp
    ,partition_key
    ,created_at
    ,ptime
)
SELECT
     _id                     
    ,eventid                 
    ,transactionid              
    ,eventtime                  
    ,direction                 
    ,eventtype                    
    ,creationdate                 
    ,accountholdernationalid        
    ,accountholderaccount            
    ,counterpartynationalid         
    ,counterpartyaccount             
    ,tenantid                 
    ,fromid                    
    ,accountagentid              
    ,fromfibranchid          
    ,accountnumber              
    ,toid                  
    ,accountidcode                 
    ,counterpartyagentid           
    ,tofibranchid                
    ,counterpartynumber         
    ,counterpartyidcode          
    ,amount                  
    ,msgtype                     
    ,settlementclearingsystemcode   
    ,paymentclearingsystemreference  
    ,requestexecutiondate            
    ,settlementdate                
    ,destinationcountry         
    ,localinstrument           
    ,msgstatus                
    ,paymentmethod                 
    ,settlementmethod           
    ,transactiontype             
    ,verificationresult         
    ,numberoftransactions     
    ,schemaversion                
    ,usercode                 
    ,384                                    AS embedding_dimensions
    ,CURRENT_TIMESTAMP                      AS embedding_timestamp
    ,DATE_FORMAT(eventtime, 'yyyyMMdd')     AS partition_key
    ,created_at
    ,PROCTIME()                             AS ptime
FROM c_cdcsource.demog.transactions;