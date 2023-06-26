
## Introduction

A container is a sandboxed process on your machine that is isolated from the host machine. When running a container, it uses an isolated filesystem. This custom filesystem is provided by a container image. Since the image contains the container’s filesystem, it must contain everything needed to run an application - all dependencies, configurations, scripts, binaries, etc. The image also contains other configuration for the container, such as environment variables, a default command to run, and other metadata.

Docker provides the ability to package and run an application in a loosely isolated environment called a container.

Docker provides tooling and a platform to manage the lifecycle of your containers:
Develop your application and its supporting components using containers.
The container becomes the unit for distributing and testing your application.
When you’re ready, deploy your application into your production environment, as a container or an orchestrated service. This works the same whether your production environment is a local data center, a cloud provider, or a hybrid of the two.

##### Advantages of using Docker 

- Light-weight - No OS to boot 
- Efficient - Less OS overhead
- Portable 
- Fast scaling
- Deployment flexibility
- Key Docker Terminology

Docker Image: The basis of a Docker container. Represents a full application
Docker Container: The standard unit in which the application service resides and executes
Docker Engine: Creates, ships and runs Docker containers deployable on a physical or virtual, host locally, in a datacenter or cloud service provider
Registry Service: Cloud or server based storage and distribution service for your images

First and foremost the first thing to do is to download Docker on our computer. Depending on the operating systems and types of chips we can download by following the installation guide at Docker https://docs.docker.com/desktop/ documentation.

In order to build the container image for the Fennica project we need to use Dockerfile. A Dockerfile is simply a text-based file with no file extension that contains a script of instructions. Docker uses this script to build a container image. 
Steps taken

1.In the Fennica directory we need to create a file named Dockerfile.We need to use the following commands.
To change directory to fennica project we use 
```	
$cd /fennica
```	
Then we create an empty file named Dockerfile
```
$touch Dockerfile
```
2.Using a text editor or code editor we write the following contents.

```
#Initialize new build stage and set base image(r version4.2.1 from rocker)
FROM rocker/r-ver:4.2.1 AS builder

#The command apt-get update is used to update the package index files on the system, which contain information about available packages and their versions. It downloads the most recent package information from the sources listed in the "/etc/apt/sources.list" file that contains your sources list and also installs different libraries listed
RUN apt-get update && apt-get install -y  git-core libcairo2-dev libxt-dev xvfb xauth xfonts-base libgtk2.0-dev libcurl4-openssl-dev libfribidi-dev libgit2-dev libharfbuzz-dev libicu-dev libpng-dev libssl-dev libtiff-dev libxml2-dev make pandoc pandoc-citeproc zlib1g-dev && rm -rf /var/lib/apt/lists/*

#create directories at the indicated path
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/

#Add a default CRAN mirror to the created directories 
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site

#Install remote package
RUN R -e 'install.packages("remotes")'

#Install “stringr” package version 1.4.1 with no upgrade (simple wrappers that make R's string functions more consistent, simpler and easier to use)
RUN Rscript -e 'remotes::install_version("stringr",upgrade="never", version = "1.4.1")'

#Install “knitr” package version 1.40 with no upgrade (an engine for dynamic report generation with R)
RUN Rscript -e 'remotes::install_version("knitr",upgrade="never", version = "1.40")'

#Install “rmarkdown” package version 2.16 with no upgrade (it creates dynamic analysis documents that combine code, rendered output (such as figures), and prose.)
RUN Rscript -e 'remotes::install_version("rmarkdown",upgrade="never", version = "2.16")'

#Install “bookdown” package version 0.29 with no upgrade ()
RUN Rscript -e 'remotes::install_version("bookdown",upgrade="never", version = "0.29")'

#Install “gridExtra” package version 2.3 with no upgrade
RUN Rscript -e 'remotes::install_version("gridExtra",upgrade="never", version = "2.3")'

#Install “testthat” package version 3.1.4 with no upgrade
RUN Rscript -e 'remotes::install_version("testthat",upgrade="never", version = "3.1.4")'

#Install “Cairo” package version 1.4.1 with no upgrade
RUN Rscript -e 'remotes::install_version("Cairo",upgrade="never", version = "1.6-0")'

#Install “R.utils” package version 2.12.0 with no upgrade
RUN Rscript -e 'remotes::install_version("R.utils",upgrade="never", version = "2.12.0")'

#Install “ggplot2” package version 3.3.6 with no upgrade
RUN Rscript -e 'remotes::install_version("ggplot2",upgrade="never", version = "3.3.6")'

#Install “remotes” package version 2.4.2 with no upgrade
RUN Rscript -e 'remotes::install_version("remotes",upgrade="never", version = "2.4.2")'

#Install “tm” package version 0.7-8 with no upgrade
RUN Rscript -e 'remotes::install_version("tm",upgrade="never", version = "0.7-8")'

#Install “XML” package version 3.99-0.10 with no upgrade
RUN Rscript -e 'remotes::install_version("XML",upgrade="never", version = "3.99-0.10")'

#Install “stringdist” package version 0.9.8 with no upgrade
RUN Rscript -e 'remotes::install_version("stringdist",upgrade="never", version = "0.9.8")'

#Install “dplyr” package version 1.0.10 with no upgrade
RUN Rscript -e 'remotes::install_version("dplyr",upgrade="never", version = "1.0.10")'

#Install “data.table” package version 1.4.1 with no upgrade
RUN Rscript -e 'remotes::install_version("data.table",upgrade="never", version = "1.14.2")'

#Install “comhis” package 
RUN Rscript -e 'remotes::install_github("comhis/comhis")'

#create directory (build_zone)
RUN mkdir /build_zone

#Copy all files to filesystem of image at path /build_zone
ADD . /build_zone

#set the working directory (to build_zone)
WORKDIR /build_zone

#remove directory (-rf option - without being prompted)
RUN rm -rf /build_zone

#copy all files to filesystem of the container at path /home/fennica
COPY . /home/fennica
 
#set working directory to /home/fennica
WORKDIR /home/fennica

#Execute the the R command to install 
RUN R -e 'remotes::install_local(upgrade="never")'

#Set working directory to the for all subsequent Dockerfile instructions
WORKDIR /home/fennica/inst/examples

#Change recursively to the group ID 0(root group) and recursively grant group permissions to be the same as the user’s.
RUN chgrp -R 0 /home/fennica && \
    chmod -R g=u /home/fennica

#Execute the R command to render the the bookdown file and move _book file to directory public
RUN R -e 'bookdown::render_book("index.Rmd", "bookdown::gitbook")' && \
    mv _book /public

#Starts new build stage with NGINX unprivileged base image
FROM nginxinc/nginx-unprivileged:latest

#Copy public folder from build stage to nginx public folder
COPY --from=builder /public /usr/share/nginx/html

#informs Docker that the container listens on the specified network ports at runtime
EXPOSE 8080

#Start NgInx service
CMD ["nginx", "-g", "daemon off;"]
```

3.Build the container image using the following commands:

```	
	$cd fennica
```
Build the container image:
```
	$ docker build -t <docker-image-name>
```
After building the docker image we can check if the image exists using the commands such as $docker ps     or  $ docker ps -a. 
Then we can share to a docker registry such as Dockerhub using the following commands.
```
docker tag <image id> your-dockerhub-user-name/image-name[:tag]
docker login
docker push your-dockerhub-user-name/image-name[:tag]
```
## Deployment on Rahti


After pushing to the Dockerhub we use the following Deployment,service and route configurations and run the following command on the terminal.
```
echo 'apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: fennica
spec:
  selector:
    matchLabels:
      app: fennica
  template:
    metadata:
      labels:
        app: fennica
    spec:
      containers:
      - name: fennica
        image: "docker.io/your-dockerhub-user-name/image-name[:tag]"
        resources: {}
        ports:
        - containerPort: 8080
          protocol: TCP

---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: fennica
  name: fennica-svc
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: fennica
  type: ClusterIP

---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: fennica
  name: fennica
spec:
  port:
    targetPort: 8080
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: edge
  to:
    kind: Service
    name: fennica-svc
    weight: 100
  wildcardPolicy: None' | oc create -f -
```
This created the pod on the Rahti and web address as follows on fennica2 project https://fennica-fennica2.rahtiapp.fi/




