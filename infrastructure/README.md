## Downloading and Building our base containers.

I tend to use the infrastructure directory always as my base starting point,

This is where we download all our containers required and the required JAR files to be pushed into our containers build using our Dockerfile definitions.


### Building

We currently only have one container that we'll be building, Apache Flink,

This can be done by executing the following 2 commands from the infrastructure directory.

- `make pull`
  
- `make build`


## NOTE 

As we're using a Makefile and a dockerfile I include a repo owner, change this to your personal choice in the `.env` file, you also need to change this in the `<Project root>/devlab/.env` additionally.