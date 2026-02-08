# Complete PyFlink UDF Setup for Flink 1.20.x

## Deploy

### Directory Structure

```
pyflink/
├── udfs/
│   ├── ah_embed_udf.py
│   ├── README.md
│   └── txn_embed_udf.py
└── README.md
```


### Notes for Flink 1.20.x

Python UDFs are fully supported in Flink 1.20.x

- ADD FILE is the correct way to add Python files to the session
- CREATE TEMPORARY FUNCTION with LANGUAGE PYTHON is the standard syntax
- UDFs registered with CREATE TEMPORARY FUNCTION only exist for the current session
- For permanent UDFs, use CREATE FUNCTION (without TEMPORARY)


### Quick Reference

Command Purpose 

- ADD FILE '/path/to/file.py'   Add Python file to session 
- CREATE TEMPORARY FUNCTION name AS 'module.func' 
- LANGUAGE PYTHON             Register Python UDF 
- SHOW FUNCTIONS              List all available functions 
- DROP FUNCTION name          Remove a function 
- SOURCE /path/to/script.sql  Execute SQL script file


## Summary

✅ UDF is defined in udfs/upper_udf.py
✅ Registration script is scripts/register_udfs.sql
✅ INSERT query is in scripts/queries_with_udfs.sql
✅ At SQL Client prompt: SOURCE register_udfs.sql then SOURCE queries_with_udfs.sql
✅ All files follow Flink 1.20.x syntax and conventions


## Alternative PyFlink Job submit options

### UDF as a Flink Sql-client submitted job

```bash
#!/bin/bash

export PYFLINK_CLIENT_EXECUTABLE=/usr/bin/python3

SQL_CLIENT="/opt/flink/bin/sql-client.sh"

# Set Python path for UDFs
export PYTHONPATH="/pyflink/udfs:$PYTHONPATH"

# Execute with Python configuration
$SQL_CLIENT \
  -pyexec /usr/bin/python3 \
  -pyfs file:///pyflink/udfs 
```

### UDF as a Flink Job

```bash
#!/bin/bash

export FLINK_CLIENT="/opt/flink/bin/flink"

$SQL_CLIENT run \
    -d \
    -m jobmanager:8081 \
    -py /pyflink/udfs/our_udf.py \
    -j /opt/flink/lib/flink-sql-connector-postgres-cdc-3.5.0.jar \
    -j /opt/flink/lib/flink-python-1.20.2.jar \
    -j /opt/flink/lib/postgresql-42.7.6.jar
```


## Flattening our json structured "string" column 

Lets side track a bit, if you're interested in flattening complex data inbound, that has been cast to a String... a side result of the CDC process see the below repo.

This is accomplished using an awesome package written and made available by [Hans-Peter Grahsl](https://www.linkedin.com/in/hpgrahsl/) ...

We will consume our inboundPostgreSQL source tables, take the the original jsonb columns, that are now represented as `string` columns in our Flink CDC table and convert this back into a complex structured row or array of rows or unwind'd into a new table.

Git Repo: [Flink-json-udf](https://github.com/hpgrahsl/flink-json-udfs)

