
# Boot strapping our environment.

From within `<Project root>/devlab1/`
  
## Running a stack


We start with building the containers, for this we have one set, will try and add enough comments into the Apache Flink and Apache Fluss (Incubating) Dockerfiles to make it as clear as possible what JAR's are included for what purpose/scenario.

The build is executed by executing make build inside the `<Project root>/infrastructure` directory.

After building the containers we will come to either `devlab1`  and execute the below commands. 

- make run

- make deploy, 
  
    This creates our various catalogs and tables.

- Execute the load generator via the `shadowtraffic/run_pg#.sh` script

    This will start pushing data into our PostgreSQL tables and onwards via the Apache Flink CDC into our Apache Flink Tables.

- make ahs or make txns 

    This defines the Apache Fluss (Incubating) job that select data from our Apache Flink tables and insert it into our Apache Fluss (Incubating) tables.

- make tier.

    Here we tell Apache Fluss (Incubating) to lakehouse tier/move the Apache Fluss (Incubating) data into our specified lakehouse table format (Apache Iceberg) onto the storage option (S3/MinIO in our case) configured.
