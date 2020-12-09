# Overview

Building a very simple demo using the Norconex Collector v3 example configuration
included with the binary distribution download.  The minimum demo will crawl
few Norconex open-source web page and commit to xml file in the filesystem of
the container.  

There are many ways to expand from this simple demo.  For instance, Filesystem
at WORKDIR location, which can be an ENV variable if you wish to expand 
from this demo.  Custom Norconex Collector Config file xml can be copy into
container image for custom crawl with different committer.  

Norconex Committer can be download, unzip and merge lib with similar steps as 
Norconex Collector download in demo `Dockerfile`.

For instance, if using Elasticsearch Committer, download, extract, 
and add below to merge the lib jar within the container image build process:

```
# Copy the Committer lib to merge with Collector Lib using the JarCopier helper
RUN java -Dfile.encoding=UTF8 -cp "${NORCONEX_HOME}/norconex-committer-elasticsearch-${ELASTIC_COMMITTER_VERSION}/lib/*:${COLLECTOR_HOME}/lib/*" \
    com.norconex.commons.lang.jar.JarCopier \
    "${NORCONEX_HOME}/norconex-committer-elasticsearch-${ELASTIC_COMMITTER_VERSION}/lib" "${COLLECTOR_HOME}/lib" 3;
```

This quick demo workflow process will start with creating container image 
using Norconex Collector v3 snapshot distribution, then cover one of the possible
build job setup using Jenkins and deployment using helm chart.  

Also, I will cover the basic of the Helm Chart use case to deploy Norconex Collector 
as type Kubernetes Cronjob that will launch a Kubernetes Job on the 
Schedule provided in the Helm `values.yaml`

## Get Started

Below steps are the overview for my quick demo experiment setup:

1. Demoing will be set up using the default [Norconex Collector Download | Norconex HTTP Collector](https://opensource.norconex.com/collectors/http/download#v3) with Filesystem Committer.  (The other choices of Committers can be found here, [Committers (norconex.com)](https://opensource.norconex.com/committers/) )

2. Build container image using Dockerfile
    * Setup a Git Repository file structure for Container Image build
    * Demo will use Dockerfile

3. Determine where to push the Container Image, can be public or private Image Registry such as Docker Hub.
    * Demo will use Dockerhub public registry 

4. Creating a Helm Chart template using the Helm Chart v3 
    * Demo will start with default template creation of Helm Chart
        * Get the Helm tool here Helm | Installing Helm
    * Demo to use the Kubernetes Node filesystem for persistent storage
    * Other storage options can be used, for instance, in AWS use EBS volume or EFS, etc..

5. Simple build using Jenkins
    * Overview the creation of Jenkins Build Server

6. Demo setup locally using Docker Desktop to run Kubernetes
    * Tutorials for setting up local kubernetes


### Build Container Image

Build the local test using Docker tool.

In the root directory of this repository run:

```
docker build -t demo-collector .
```

When the build is done, run the docker container using:

```
docker run --name mydemo-collector demo-collector
```

By default, the volume will be mounted to match WORKDIR path setup in the 
`Dockerfile`

If you would like to specify the local docker volume `test-volume` run
command below:

```
docker run \
--name mydemo-collector \
-v ./test-volume:/norconex/collector/examples-output/complex \
demo-cllector
```

Viewing the docker volume using command:

```
docker volume inspect test-volume
```

If you would like to test run them without building it locally, run below:

```
docker pull somphouang/norconex-devops-demo
docker run --name mydemo-collector somphouang/norconex-devops-demo
```

It will pull the image from public Dockeerhub.com registry
`https://hub.docker.com/r/somphouang/norconex-devops-demo`


Note:  Instructions below has pre-requisites knowledge on `Jenkins`,
`Helm Chart`, and `Kubernetes - Cronjob, Job`

### Build Helm Chart

Helm chart template files are created in `deploy/charts`

There are 2 important files

* `cronjob.yaml` - will deploy Kubernetes Cronjob so that the crawl can happen
on schedule time, when the schedule time happen Kuberbernetes Job will run
the crawl job
* `pvc.yaml` - will provision Kubernetes Persistent Volume and Volume Claim
     *  There are options to use AWS EBS, AWS EFS, Kubernetes Node storage in the `values.yaml`
      
Helm chart deployment for this demo would create Kubernetes Cronjob with 
schedule `0 6 * * 2` to run every Tuesday, see `deploy/charts/norconex-devops`


### Build DevOps 

Building the continuous development and continuous deployment can be difficult
without some automation tools.  One of the tool chosen for this demo is Jenkins
Server.

Assuming the Kubernetes Cluster to use with this demo has been setup.
 
Putting the whole pipeline from code commit starting at buiding the container 
and push to image registry such as docker hub public then deploy
using Helm Chart template to create Kubernetes Cronjob so that it will
launch new Kubernetes Job which launch Pod to run the Crawl container
on schedule time.  When the crawl job completes the
Kubernetes Persistent Volume will stored the crawlstore data for next
incremental re-crawl as the next crawl job runs it will use the
same Persistent Volume Claim.



