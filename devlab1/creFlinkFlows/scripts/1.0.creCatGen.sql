
USE CATALOG default_catalog;

CREATE CATALOG c_cdcsource WITH 
    ('type'='generic_in_memory');

USE CATALOG c_cdcsource;

-- Source for PyFlink
CREATE DATABASE IF NOT EXISTS demog;