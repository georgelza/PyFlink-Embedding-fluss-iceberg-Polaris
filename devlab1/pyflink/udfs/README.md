## Define our 2 Python routines, to calculate embedding vectors.


- `<Projecr root>/pyflink/udfs/ah_embed_udf.py`     -> Calculate embedding vectors for accountholders

- `<Projecr root>/pyflink/udfs/txn_embed_udf.py`    -> Calculate embedding vectors for transactions


## MODEL

We used the The `all-MiniLM-L6-v2` for both the accountHolder and tansaction embedding.

The `all-MiniLM-L6-v2` model is one of the most lightweight and efficient sentence-transformer models. Its memory footprint is very small, making it suitable for resource-constrained environments like Docker containers or small cloud instances.


### 1. Base Memory Requirements

For a standard Python environment (using `sentence-transformers` with `PyTorch`), the memory requirements are:

Model Disk Size: ~80 MB – 91 MB.

VRAM/RAM to load (Inference):

FP32 (Default): ~87 MB to 150 MB.

FP16: ~44 MB.

INT8 (Quantized): ~22 MB.

Peak Runtime Memory: Typically 200 MB to 500 MB total for the Python process, including the model, dependencies (PyTorch/Transformers), and input/output buffers.


### 2. Practical Docker/Container Limits

While the model itself is small, the `Python` runtime and `PyTorch library` add overhead.

Minimum: A container with 512 MB of RAM can often run this model for basic tasks.

Recommended: 1 GB – 2 GB of RAM is ideal to ensure stability during bulk encoding and to avoid OOM (Out of Memory) kills, especially if you are processing large batches of text at once.


### 3. Scaling Factors

Your memory usage will increase based on:

Batch Size: Larger batches in model.encode() require more memory to store temporary activation tensors.

Output Storage: If you encode a large dataset (e.g., millions of rows) and keep all embeddings in memory simultaneously, you will need approximately 1.5 KB per embedding (384 dimensions * 4 bytes/float32).

Example: 1 million embeddings ≈ 1.5 GB of additional RAM.

Why this matters for your Flink Job

In your current Flink setup, you are running this model inside a Python UDF.

Python Worker Overhead: Each Flink `TaskManager` starts a separate Python process. If your `TaskManager` has 4 slots, it may start 4 Python workers, each loading its own copy of this model (~400MB x 4 = 1.6GB overhead).

Managed Memory: Ensure your `config.yaml` leaves enough `Off-Heap Memory` for these `Python` processes, as they live outside the JVM heap. A setting of `taskmanager.memory.task.off-heap.size: 1gb` is usually the "sweet spot" for this specific model.


### Summary or is that Reality

Took some doing to get our deployment stable.

Take note of the above numbers and how they impact the settings in `devlab/conf/confi.yaml` for the `taskmanager` memory setup.


```yaml
taskmanager:
  bind-host: 0.0.0.0
  numberOfTaskSlots: 6
  memory:
    process:
      size: 12gb        # This must be LESS than the Docker limit to leave room for the Python process
    jvm-overhead:
      min: 512mb        # Increase the Overhead Max to allow for the driver buffers
      max: 2gb          # Fix the Overhead limit to allow Flink's math to succeed
    task:
      off-heap:         # Explicitly set Task Off-Heap (Crucial for your Python UDF weights)
        size: 4gb       # Specifically reserve memory for the UDF/Room for the ML model
    managed:
      fraction: 0.1     # Paimon doesn't need huge managed memory here
      size: 2gb         # DO NOT set taskmanager.memory.flink.size manually (let Flink derive it)
                        # Explicitly set Managed Memory (important for Paimon/RocksDB)
    network:            # Stabilize Networking
      min: 256mb
      max: 512mb

```

Also note the value for `taskmanager.memory.process.size` needs to match our docker-compose.yaml file, for the taskmanager service

```yaml
    deploy:
      replicas: 1
      resources:
          limits:
            memory: 12G
```