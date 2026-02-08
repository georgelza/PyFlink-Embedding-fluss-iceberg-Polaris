
## Catalogs, Databases and Table/Objects Structures


### 1.1.creCatGen.sql

Will create the various Generic In Memory Catalog.

- `c_cdcsource` - Generic In Memory based catalog
  
  - `demog`

### 1.1.creCatPaimon-fs.sql

Will create the various Paimon Catalog.

- `c_paimon`
  
  - `finflow`

### 1.1.creCatPaimon-s3.sql

Will create the various Paimon Catalog.

- `c_paimon`
  
  - `finflow`

### 1.1.creFluss.sql

Will create the various Fluss Catalog.

- `fluss_catalog`
  
  - `finflow`


### 2.1.creCdcDemog.sql

This will create our transciant CDC based tables which will connect to our PostgreSQL datastore and expose data using the Flink CDC capabilities
This script will be used/called by other scripts, this is required as the catalog/database is only visible in the current session.

Catalog: `c_cdcsource`.`demog`

- `accountholders`

- `transactions` 


### 3.1.creTargetFinflow-Fluss.sql

Create our output tables that will recieve the "vectorized/embedding" records, sourced from 4.1 & 4.2

Catalog: `fluss_catalog`.`finflow`

- `accountholders`

- `transactions` 


### 3.1.creTargetFinflow-Paimon.sql

Create our output tables that will recieve the "vectorized/embedding" records, sourced from 4.1 & 4.2

Catalog: `fluss_catalog`.`finflow`

- `accountholders`

- `transactions` 


### 4.1.creInsertsAhSingle_fluss.sql

Run the Insert statement with the inline UDF call (`generate_ah_embedding`) to calculate the embedding values

Catalog: `fluss_catalog`.`finflow`

- Output to `accountholders`


### 4.1.creInsertsAhSingle_paimon.sql

Run the Insert statement with the inline UDF call (`generate_ah_embedding`) to calculate the embedding values

Catalog: `fluss_catalog`.`finflow`

- Output to `accountholders`


### 4.2.creInsertsTxnSingle_fluss.sql

Run the Insert statement with the inline UDF call (`generate_txn_embedding`) to calculate the embedding values

Catalog: `fluss_catalog`.`finflow`

- Outoput to `transactions` 


### 4.2.creInsertsTxnSingle_paimon.sql

Run the Insert statement with the inline UDF call (`generate_txn_embedding`) to calculate the embedding values

Catalog: `fluss_catalog`.`finflow`

- Outoput to `transactions` 


