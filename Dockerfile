FROM ubuntu:20.04

# Demo will be using default "minimum-config.xml" to run collector and
# commit to the local filsystem as xml file
# Default path from zip extract is at 
# .\norconex-collector-http-3.0.0-M2\examples\minimum

# Download the latest snapshot binary for Norconex Collector here
# https://opensource.norconex.com/collectors/http/download#v3

# At the time of writing this demo
# Download snapshot build for Norconex Collector V3 from below
# https://oss.sonatype.org/content/repositories/snapshots/com/norconex/collectors/norconex-collector-http/3.0.0-SNAPSHOT/norconex-collector-http-3.0.0-20201124.061504-27.zip
# https://oss.sonatype.org/content/repositories/releases/com/norconex/collectors/norconex-collector-http/3.0.0-M2/norconex-collector-http-3.0.0-M2.zip


ENV COLLECTOR_USERID=2021 \
    COLLECTOR_USER=collector \
    COLLECTOR_GROUP=norconex \
    COLLECTOR_GROUPID=2021 \
    COLLECTOR_VERSION=3.0.0-M2 \
    COLLECTOR_DOWNLOAD_URL=https://oss.sonatype.org/content/repositories/releases/com/norconex/collectors/norconex-collector-http \
    COLLECTOR_DOWNLOAD_FILENAME=norconex-collector-http-3.0.0-M2 \
    COLLECTOR_HOME=/norconex/collector \
    WORKDIR=/norconex/collector/examples-output/complex \
    COLLECTOR_CONFIG_FILE=examples/minimum/minimum-config.xml \
    COLLECTOR_LOG_DIR=/norconex/collector/logs \
    COLLECTOR_PARAMS="" \
    NORCONEX_HOME=/norconex \
    ENVIRONMENT="test" \
    PATH="/norconex/collector:$PATH"
    
# Add the collector user to run the java crawl job in the entrypoint
RUN set -x; \
  groupadd -r --gid "$COLLECTOR_GROUPID" "$COLLECTOR_GROUP"; \
  useradd -r --uid "$COLLECTOR_USERID" --gid "$COLLECTOR_GROUPID" "$COLLECTOR_USER"; \
  mkdir -p "$NORCONEX_HOME"; \
  chown -R "${COLLECTOR_USER}:${COLLECTOR_GROUP}" "$NORCONEX_HOME"; 

# Install all the tools needed in this linux to start others
RUN apt-get update; \
    apt-get install -y openjdk-8-jre-headless; \
    apt-get install -y wget; \
    apt-get install unzip -y;

# Download Norconex Collector installation package
RUN set -x; \
    wget -nv "${COLLECTOR_DOWNLOAD_URL}/${COLLECTOR_VERSION}/${COLLECTOR_DOWNLOAD_FILENAME}.zip"; 

# Rename the norconex artifacts downloaded zip so that it removed the snapshot timestamps filename
RUN set -x; \
    ls -alh *.zip; \ 
    mv norconex-collector-http-*.zip norconex-collector.zip; 

# Extract and setup the folders for data
RUN set -x; \
    unzip norconex-collector.zip -d "$NORCONEX_HOME"; 

# Remove the downloaded file to save some space in the docker image
RUN rm norconex-collector.zip; \
    mv "${NORCONEX_HOME}/norconex-collector-http-${COLLECTOR_VERSION}" "${COLLECTOR_HOME}"; 
    
# Create Crawl Configs folder from repository to copy to variables from ENV to use locally docker run
RUN set -x; \
    mkdir -p "${WORKDIR}"; \
    chown -R "${COLLECTOR_USER}:${COLLECTOR_GROUP}" "${WORKDIR}"; 

# Update user permissions for folders
RUN chown -R "${COLLECTOR_USER}:${COLLECTOR_GROUP}" "${NORCONEX_HOME}";

# Allow execute for `collector-http.sh` in the collector
RUN chmod +x "${COLLECTOR_HOME}/collector-http.sh";

USER "$COLLECTOR_USER"
VOLUME "$WORKDIR"

# Run demo crawl and print out committed xml file result
CMD ["sh", "-c", "collector-http.sh start -c ${COLLECTOR_HOME}/${COLLECTOR_CONFIG_FILE} ${COLLECTOR_PARAMS}; cat ${WORKDIR}/M*/N*/c*/0/*.xml"]
