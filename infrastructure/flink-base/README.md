## Building our Primary Flink Contaier

We have various version options that can be build, see the flink/Dockerfile for the possible variables to set. Keep in mind they need to match the Apache Flink stack.

### 1. Build combinations

You will notice in the `Dockerfile`, I don't like to hard code versions. Once we get the stack working using variables make it easy to just change what needs to be changed and everything else will fit/fall together.

- Apache Flink 1.20.2
- Apache Paimon 1.3.1
- Apache Flink CDC 3.5.0
- PostgreSQL Connetor 42.7.6
- Hadoop S3 Libraries 2.8.3 
  

### 2. Building New Apache Flink Container

You can do allot of this from the `./infrastructure/Makefile` or do the pull from the `Makefile` and then the build locally in the `./flink` directory.

- `make pull`

- `make build`


## NOTE 

As we're using a Makefile and a dockerfile I include a repo owner, change this to your personal choice in the `.env` file, you also need to change this in the `<Project root>/devlab/.env` additionally.