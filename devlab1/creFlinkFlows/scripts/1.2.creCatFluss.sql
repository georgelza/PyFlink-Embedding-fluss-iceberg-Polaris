
-- Apache Fluss
CREATE CATALOG fluss_catalog WITH (
    'type'              = 'fluss',
    'bootstrap.servers' = 'coordinator-server:9123'
);

USE CATALOG fluss_catalog;

CREATE DATABASE IF NOT EXISTS fluss_catalog.finflow; 

SHOW DATABASES;
