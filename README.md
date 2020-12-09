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

Below steps are the overview for my quick demo exploring some of the ways to setup:

1. Demo use the default [Norconex Collector Download | Norconex HTTP Collector](https://opensource.norconex.com/collectors/http/download#v3) with Filesystem Committer.  (The other choices of Committers can be found here, [Committers (norconex.com)](https://opensource.norconex.com/committers/) )
    * Build container image using Dockerfile
    * Setup a Git Repository file structure for Container Image build
    * Guide to build and test run using the created Dockerfile
         * Demo setup locally using Docker Desktop to run Kubernetes
         * Tutorials for setting up local kubernetes

2. Determine where to push the Container Image, can be public or private Image Registry such as Docker Hub.
    * Demo will use Dockerhub public registry
    * Docker Hub at https://hub.docker.com/repository/docker/somphouang/norconex-devops-demo

3. Creating a Helm Chart template using the Helm Chart v3 
    * Demo will start with default template creation of Helm Chart
         * Get the Helm tool here Helm | Installing Helm https://helm.sh/docs/intro/install/ 
    * Demo to use the Kubernetes Node filesystem for persistent storage
         * Other storage options can be used, for instance, in AWS use EBS volume or EFS, etc..
    * Understanding Helm template and yaml configuration
         * `Cronjob.yaml` to deploy kubernetes Cronjob that would create new Kubernetes Job to run on schedule.
         * `pvc.yaml` to create kubernetes persistent volume and persistent volume claim that the Norconex Collector crawl job will use on the next recrawl job run.

4. Simple build using Jenkins
    * Overview the creation of Jenkins Build Server

## Test Locally

In my demo I have installed `Docker Desktop` to run local `docker`, and
`kubectl` using the local `Kubernetes cluster` that can be enabled with
Docker Desktop service.  Docker Desktop can be download from
[here](https://www.docker.com/products/docker-desktop).  Helm can also be
download from [here](https://github.com/helm/helm/releases) in order to follow
my steps below in using command `helm`.


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


Download and Install Helm from [here](https://github.com/helm/helm/releases)

Test locally deploying Helm Chart to Kubernetes using `--dry-run` flag without
actually deploying.

```
helm upgrade -name norconex-devops-demo -i --dry-run ./deploy/charts/norconex-devops-demo/
```

Output from the dry run command

```
Release "norconex-devops-demo" does not exist. Installing it now.
NAME: norconex-devops-demo
LAST DEPLOYED: Wed Dec  9 13:39:07 2020
NAMESPACE: default
STATUS: pending-install
REVISION: 1
HOOKS:
---
# Source: norconex-devops-demo/templates/tests/test-filesystem.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "norconex-devops-demo-test-filesystem"
  namespace:
  labels:
    helm.sh/chart: norconex-devops-demo-0.1.0
    app.kubernetes.io/name: norconex-devops-demo
    app.kubernetes.io/instance: norconex-devops-demo
    app.kubernetes.io/version: "0.1.0"
    app.kubernetes.io/managed-by: Helm
  annotations:
    "helm.sh/hook": test-success
spec:
  containers:
    - name: wget
      image: busybox
      command: ["sh", "-c", "sleep 2", "ls -alh ."]
  restartPolicy: Never
MANIFEST:
---
# Source: norconex-devops-demo/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: norconex-devops-demo
  labels:
    helm.sh/chart: norconex-devops-demo-0.1.0
    app.kubernetes.io/name: norconex-devops-demo
    app.kubernetes.io/instance: norconex-devops-demo
    app.kubernetes.io/version: "0.1.0"
    app.kubernetes.io/managed-by: Helm
---
# Source: norconex-devops-demo/templates/pvc.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "norconex-devops-demo"
  namespace: default
  annotations:
    pv.beta.kubernetes.io/gid: "2020"
    volume.alpha.kubernetes.io/storage-class: default
  labels:
    app: norconex-devops-demo
    release: "norconex-devops-demo"
spec:
  accessModes:
    - "ReadWriteOnce"
  storageClassName: "manual"
  # Local test passing `--set persistent.storageClass=manual` in the helm command
  hostPath:
    path: "/data"
  capacity:
    storage: "5Gi"
  persistentVolumeReclaimPolicy: "Delete"
---
# Source: norconex-devops-demo/templates/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "norconex-devops-demo"
  namespace: default
  annotations:
    pv.beta.kubernetes.io/gid: "2020"
    volume.alpha.kubernetes.io/storage-class: default
  labels:
    app: norconex-devops-demo
    release: "norconex-devops-demo"
spec:
  accessModes:
    - "ReadWriteOnce"
  storageClassName: "manual"
  resources:
    requests:
      storage: "5Gi"
---
# Source: norconex-devops-demo/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: norconex-devops-demo
  labels:
    helm.sh/chart: norconex-devops-demo-0.1.0
    app.kubernetes.io/name: norconex-devops-demo
    app.kubernetes.io/instance: norconex-devops-demo
    app.kubernetes.io/version: "0.1.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 2020
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: norconex-devops-demo
    app.kubernetes.io/instance: norconex-devops-demo
---
# Source: norconex-devops-demo/templates/cronjob.yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: "norconex-devops-demo"
  namespace:
  annotations:
    pv.beta.kubernetes.io/gid: "2020"
    volume.alpha.kubernetes.io/storage-class: default
  labels:
    heritage: "Helm"
    release: "norconex-devops-demo"
    chart: "norconex-devops-demo-0.1.0"
    app: norconex-devops-demo
spec:
  schedule: "0 6 * * 2"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            heritage: "Helm"
            release: "norconex-devops-demo"
            chart: "norconex-devops-demo-0.1.0"
            app: norconex-devops-demo
        spec:
          securityContext:
            fsGroup: 2020
            runAsGroup: 2020
            runAsUser: 2020
          imagePullSecrets:
          - name:
          containers:
          - name: init
            image: busybox:latest
            securityContext:
              runAsUser: 0
            command: ['/bin/sh']
            args: ['-c', 'chown -R 2020:2020 "/norconex/collector/examples-output/complex"']
            volumeMounts:
            - name: data
              mountPath: "/norconex/collector/examples-output/complex"
          - name: norconex-devops-demo
            securityContext:
              runAsUser: 2020
            image: "somphouang/norconex-devops-demo:latest"
            imagePullPolicy: IfNotPresent
            resources:
              requests:
                cpu: "100m"
                memory: "128Mi"
            volumeMounts:
            - name: data
              mountPath: "/norconex/collector/examples-output/complex"
          volumes:
          - name: data
            persistentVolumeClaim:
              claimName: "norconex-devops-demo"
          restartPolicy: OnFailure
```

Installing the Helm chart using `helm` command:

```
helm upgrade norconex-devops-demo -i ./deploy/charts/norconex-devops-demo/
```

Output result

```
Release "norconex-devops-demo" does not exist. Installing it now.
NAME: norconex-devops-demo
LAST DEPLOYED: Wed Dec  9 11:49:15 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

Check to see that the deployment has been successful in Kubernetes Cluster

```
kubectl get pv,pvc,cronjob,job,all
```

Output result showing the PVC is bound to the Persistent Volume correctly.
* Note: The volume mounted is local to the filesystem of the Kubernetes Node for our demo test purposes.

```
NAME                                    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                          STORAGECLASS   REASON   AGE
persistentvolume/norconex-devops-demo   5Gi        RWO            Delete           Bound    default/norconex-devops-demo   manual                  81s

NAME                                         STATUS   VOLUME                 CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/norconex-devops-demo   Bound    norconex-devops-demo   5Gi        RWO            manual         81s

NAME                                 SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/norconex-devops-demo   0 6 * * 2   False     0        <none>          81s

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/kubernetes             ClusterIP   10.96.0.1       <none>        443/TCP    22d
service/norconex-devops-demo   ClusterIP   10.108.76.188   <none>        2020/TCP   81s
```


Let's trigger a Manual Job run:

```
kubectl create job --from=cronjob/<cronjob-name> <job-name>
```

Type in command for our test:

```
kubectl create job --from=cronjob/norconex-devops-demo-demo manual-test-run1
```

Output result

```
job.batch/manual-test-run1 created
```

Check to see that the `Job` run and completed for `job.batch/manual-test-run1`

```
kubectl get pv,pvc,cronjob,job,pod
```

Output result shows it has been complted and ran took 19 seconds `19s`.

```
NAME                                    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                          STORAGECLASS   REASON   AGE
persistentvolume/norconex-devops-demo   5Gi        RWO            Delete           Bound    default/norconex-devops-demo   manual                  27s

NAME                                         STATUS   VOLUME                 CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/norconex-devops-demo   Bound    norconex-devops-demo   5Gi        RWO            manual         27s

NAME                                 SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/norconex-devops-demo   0 6 * * 2   False     0        <none>          27s

NAME                         COMPLETIONS   DURATION   AGE
job.batch/manual-test-run1   1/1           19s        21s

NAME                         READY   STATUS      RESTARTS   AGE
pod/manual-test-run1-mhgz5   0/2     Completed   0          21s
```

Now, let's look at the logs from the Job, run

Run `kubectl logs <pod-name> -c <container-name>` 

```
kubectl logs manual-test-run1-mhgz5 -c norconex-devops-demo
```



Note:  After the log entry `INFO  COLLECTOR_RUN_END...` the
`Dockerfile` CMD runs the second
command `cat ${WORKDIR}/M*/N*/c*/0/*.xml` to show the content
of the committer filesystem xml file from the crawl indexing.

The output result from Norconex Collector crawl job logs.

```
18:49:25.564 [Minimum Config HTTP Collector] INFO  Collector -
 _   _  ___  ____   ____ ___  _   _ _______  __
| \ | |/ _ \|  _ \ / ___/ _ \| \ | | ____\ \/ /
|  \| | | | | |_) | |  | | | |  \| |  _|  \  /
| |\  | |_| |  _ <| |__| |_| | |\  | |___ /  \
|_| \_|\___/|_| \_\\____\___/|_| \_|_____/_/\_\

============== C O L L E C T O R ==============

Collector and main components:

Collector:          Norconex HTTP Collector 3.0.0-SNAPSHOT (Norconex Inc.)
Collector Core:     Norconex Collector Core 2.0.0-SNAPSHOT (Norconex Inc.)
Importer:           Norconex Importer 3.0.0-SNAPSHOT (Norconex Inc.)
JEF:                Norconex JEF 5.0.0-SNAPSHOT (Norconex Inc.)
Lang:               Norconex Commons Lang 2.0.0-SNAPSHOT (Norconex Inc.)
Committer(s):
  Core:             Norconex Committer Core 3.0.0-SNAPSHOT (Norconex Inc.)
Runtime:
  Name:             OpenJDK Runtime Environment
  Version:          1.8.0_275-8u275-b01-0ubuntu1~20.04-b01
  Vendor:           Private Build

18:49:25.680 [Minimum Config HTTP Collector] INFO  JobSuite - Work directory is: /norconex/collector/examples-output/complex
18:49:25.686 [Minimum Config HTTP Collector] INFO  Collector - Collector with 1 crawler(s) created.
18:49:25.694 [Minimum Config HTTP Collector] INFO  COLLECTOR_RUN_BEGIN - Minimum Config HTTP Collector
18:49:25.866 [Minimum Config HTTP Collector] INFO  GenericHttpFetcher - User-Agent: <None specified>
18:49:25.867 [Minimum Config HTTP Collector] INFO  JobSuite - Initialization...
18:49:25.868 [Minimum Config HTTP Collector] INFO  JobSuite - No previous execution detected.
18:49:25.894 [Minimum Config HTTP Collector] INFO  JobSuite - Starting execution.
18:49:25.902 [Minimum Config HTTP Collector] INFO  JobSuite - Running Minimum Config HTTP Collector: START (2020-12-09T18:49:25.902Z)
18:49:25.910 [Norconex Minimum Test Page] INFO  JobSuite - Running Norconex Minimum Test Page: START (2020-12-09T18:49:25.910Z)
18:49:25.911 [Norconex Minimum Test Page] INFO  CRAWLER_INIT_BEGIN - Initializing crawler "Norconex Minimum Test Page"...
18:49:25.963 [Norconex Minimum Test Page] INFO  COMMITTER_INIT_BEGIN - CommitterEvent[name=COMMITTER_INIT_BEGIN]
18:49:26.009 [Norconex Minimum Test Page] INFO  COMMITTER_INIT_END - CommitterEvent[name=COMMITTER_INIT_END]
18:49:26.012 [Norconex Minimum Test Page] INFO  CrawlDocInfoService - STARTING a fresh crawl.
18:49:26.012 [Norconex Minimum Test Page] INFO  CRAWLER_INIT_END - Crawler "Norconex Minimum Test Page" initialized successfully.
18:49:26.022 [Norconex Minimum Test Page] INFO  CRAWLER_RUN_BEGIN - Norconex Minimum Test Page
18:49:26.024 [Norconex Minimum Test Page] INFO  HttpCrawler - RobotsTxt support: true
18:49:26.024 [Norconex Minimum Test Page] INFO  HttpCrawler - RobotsMeta support: true
18:49:26.024 [Norconex Minimum Test Page] INFO  HttpCrawler - Sitemap support: false
18:49:26.024 [Norconex Minimum Test Page] INFO  HttpCrawler - Canonical links support: true
18:49:26.443 [Norconex Minimum Test Page] INFO  StandardRobotsTxtProvider - No robots.txt found for https://opensource.norconex.com/robots.txt. (404 - Not Found)
18:49:26.448 [Norconex Minimum Test Page] INFO  HttpCrawler - 1 start URLs identified.
18:49:26.448 [Norconex Minimum Test Page] INFO  Crawler - Crawling references...
18:49:26.450 [Norconex Minimum Test Page/1] INFO  CRAWLER_RUN_THREAD_BEGIN - Thread[Norconex Minimum Test Page/1,5,main]
18:49:26.450 [Norconex Minimum Test Page/2] INFO  CRAWLER_RUN_THREAD_BEGIN - Thread[Norconex Minimum Test Page/2,5,main]
18:49:26.779 [Norconex Minimum Test Page/2] INFO  AbstractFSCommitter - Creating file: ./examples-output/complex/Minimum_32_Config_32_HTTP_32_Collector/Norconex_32_Minimum_32_Test_32_Page/committer/0/2020-12-09T06-49-25-963_1.xml
18:49:26.783 [Norconex Minimum Test Page/2] INFO  DOCUMENT_COMMITTED_UPSERT - https://opensource.norconex.com/collectors/http/test/minimum - Committers: XMLFileCommitter
18:49:26.785 [Norconex Minimum Test Page/1] INFO  CRAWLER_RUN_THREAD_END - Thread[Norconex Minimum Test Page/1,5,main]
18:49:26.851 [Norconex Minimum Test Page/2] INFO  CRAWLER_RUN_THREAD_END - Thread[Norconex Minimum Test Page/2,5,main]
18:49:26.851 [Norconex Minimum Test Page] INFO  Crawler - Reprocessing any cached/orphan references...
18:49:26.853 [Norconex Minimum Test Page] INFO  Crawler - Reprocessed 0 cached/orphan references.
18:49:26.853 [Norconex Minimum Test Page] INFO  Crawler - 1 reference(s) processed.
18:49:26.854 [Norconex Minimum Test Page] INFO  CRAWLER_RUN_END - Norconex Minimum Test Page
18:49:26.855 [Norconex Minimum Test Page] INFO  Crawler - Crawler completed.
18:49:26.857 [Norconex Minimum Test Page] INFO  Crawler - Crawler executed in 841 milliseconds.
18:49:26.858 [Norconex Minimum Test Page] INFO  MVStoreDataStoreEngine - Closing data store engine...
18:49:26.858 [Norconex Minimum Test Page] INFO  MVStoreDataStoreEngine - Compacting data store...
18:49:26.869 [Norconex Minimum Test Page] INFO  MVStoreDataStoreEngine - Data store engine closed.
18:49:26.869 [Norconex Minimum Test Page] INFO  MVStoreDataStoreEngine - Closing data store engine...
18:49:26.869 [Norconex Minimum Test Page] INFO  MVStoreDataStoreEngine - Data store engine closed.
18:49:26.871 [Norconex Minimum Test Page] INFO  COMMITTER_CLOSE_BEGIN - CommitterEvent[name=COMMITTER_CLOSE_BEGIN]
18:49:26.872 [Norconex Minimum Test Page] INFO  COMMITTER_CLOSE_END - CommitterEvent[name=COMMITTER_CLOSE_END]
18:49:26.873 [Norconex Minimum Test Page] INFO  JobSuite - Running Norconex Minimum Test Page: END (2020-12-09T18:49:25.910Z)
18:49:26.875 [Minimum Config HTTP Collector] INFO  JobSuite - Running Minimum Config HTTP Collector: END (2020-12-09T18:49:25.902Z)
18:49:26.877 [Minimum Config HTTP Collector] INFO  COLLECTOR_RUN_END - Minimum Config HTTP Collector
<?xml version='1.0' encoding='UTF-8'?>
<docs>
    <upsert>
        <reference>https://opensource.norconex.com/collectors/http/test/minimum</reference>
        <metadata>
            <meta name="title">Norconex HTTP Collector Minimum Test Page</meta>
            <meta name="document.reference">https://opensource.norconex.com/collectors/http/test/minimum</meta>
        </metadata>
        <content>
            Congratulations! If you read this text from your target repository (e.g. file system, search engine, ...)
                    it means that you successfully ran the Norconex HTTP Collector minimum example.





                    Norconex HTTP Collector

                        Minimum Test Page





                        We are excited that you are trying the Norconex HTTP Collector.

                        This standalone web page was created to help you test your installation is running properly.

                        Once you're done working with this document, make sure to familiarize yourself with the many configuration options available to you
                           on the Norconex HTTP Collector web site:



                          https://opensource.norconex.com/collectors/http/documentation







                    The Next Steps

                    The next logical step is probably to put in a different URL to crawl in the startURLs section of your configuration.
                       The process of changing the start URL is an easy 2 steps process.

                    First step: modify the URL between the following tags



              &lt;startURLs>
                &lt;url>https://www.YourOwnUrl.com/&lt;/url>
              &lt;/startURLs>



                    Second step: Add or update regular expression to let the crawler know which URL patterns you are now accepting.


              &lt;referenceFilters>
                &lt;filter class="com.norconex.collector.core.filter.impl.RegexReferenceFilter" onMatch="include">
                  https://www.YourOwnUrl.com/onlyThisSubset/.*
                &lt;/filter>
              &lt;/referenceFilters>






                    Now What?

                    There obviously are tons of options available to you now.  You probably want to crawl more than one page,
                    filter out some files such as CSS or Javascript, and much more.  You also want to install a "Committer" for your
                    search engine (or other target repository). Learn how to do all this and more magic using the Norconex HTTP Collector
                    site documentation (above URL).





                    Thank you for using Norconex HTTP Collector!





                    Copyright © 2009-2020 Norconex Inc.. All Rights Reserved.
        </content>
    </upsert>
</docs>

```



## Build DevOps 

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

Jenkin Job type `Multibranch pipeline`

With `Jenkinsfile` script using host system agent.
The build stage are 2 steps, shown below.

```
pipeline {
    agent none 
    
    options {
        // Only keep the number of most recent builds
        buildDiscarder(logRotator(numToKeepStr:'5'))
    }
    stages {
        stage('Build Docker Image') {
            agent any
            environment {
                registry = "somphouag/norconex-devops-demo"
                registryCredential = 'dockerLoginSecretCred'
              }
            // Build and push docker image only when in main branch
            when {
                branch "main"
            }
            steps {    
                script {
                    dockerImage = docker.build registry + ":$BUILD_NUMBER"
                    docker.withRegistry( 'https://dockerhub.com', registryCredential ) {                                                   
                        dockerImage.push()
                    }
                }
                sh "docker rmi $registry:$BUILD_NUMBER"      
            }                 
        }
        stage('Install Chart') {
            agent any
            }
            // Build and push docker image only when in master branch
            when {
                branch "main"
            }
            steps {
                script {
                  // Install the latest helm v3 chart using the default values.yaml with matching tag $BUILD_NUMBER
                  sh 'helm upgrade demo-collector-chart -i deploy/charts/norconex-devops-demo --set image.tag=$BUILD_NUMBER'
                }
            }
        }
 }
``` 


