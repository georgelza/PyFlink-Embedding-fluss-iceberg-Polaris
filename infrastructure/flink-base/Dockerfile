FROM arm64v8/flink:1.20.2-scala_2.12-java17
SHELL ["/bin/bash", "-c"]

# 1. Install necessary system tools 
RUN echo "--> Installing system dependencies" \
    && build_deps="neovim tree lnav unzip gradle python3-pip python3.10-venv openjdk-17-jdk-headless postgresql-client" \
    && apt-get update \
    && apt-get install -y $build_deps

# 2. Environment Variables 
ENV FLINK_HOME=/opt/flink
ENV PYTHON_HOME=/usr/bin/python3.10
ENV PATH=$PATH:$PYTHON_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
ENV FLINK_VERSION_FULL=1.20.2

# FIX: Classpath must include all directories containing your JARs
ENV HADOOP_CLASSPATH=${FLINK_HOME}/lib/*

WORKDIR ${FLINK_HOME}

# 3. Python Setup, required by our Python UDF
RUN echo "--> Setup Python Environment" \
    && python3 -m pip install --upgrade pip setuptools wheel \
    && /usr/bin/pip3 install apache-flink==${FLINK_VERSION_FULL} \
    && /usr/bin/pip3 install pyflink sentence_transformers \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && ldconfig /usr/lib

# 4. Cleanup and Permissions 
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    chown -R flink:flink $FLINK_HOME 