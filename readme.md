# Alma Cantaloupe Image Server

A docker build of the [Canteloupe Image Server](https://medusa-project.github.io/cantaloupe/) with a custom script resolver for digital resources managed in [Ex Libris Alma](http://www.exlibrisgroup.com/category/AlmaOverview).

Docker hub repository available at https://hub.docker.com/r/exlibrisgroup/alma-cantaloupe/.

The docker image was based on input from the example in this [fork](https://github.com/kaij/cantaloupe/tree/docker-deploy/docker) and the [Loris docker repository](https://github.com/loris-imageserver/loris-docker) (for the OpenJPEG installation). 

## Docker Image

The docker image is based on the following components:
* OpenJDK 8 on Debian
* [OpenJPEG](https://github.com/uclouvain/openjpeg.git) (Version 2.1.2)
* [Cantaloupe Image Server](https://github.com/medusa-project/cantaloupe/) (Version 3.3)

## Alma Resolver

This repository includes a custom delegate script for the `FilesystemResolver`. It implementsthe following logic:
* Receives a [JWT token](http://jwt.io/) as the identifier 
  * The token is `RS256` signed with an Alma private key and validated with with the public key in `keyfile-pub.pem`.
  * The payload includes the following properties:
```
    {
        "region": region,
        "bucket": bucket,
        "key": filename
    }
```
* If the file is not in cache it is downloaded from the Alma S3 storage

## AWS Deployment

The docker image is deployed to an AWS Elastic Beanstalk application using the 
configuration in `Dockerrun.aws.json`.

## Usage

### Pull the image from docker

    $ docker pull exlibrisgroup/alma-cantaloupe

### Run the image in development

Because the resolver requires AWS credentials, we mount the current user's home directory as the cantaloupe user's home in the container:

    $ docker run -d --rm -p 8182:8182 -v ~/.aws:/home/.aws --name cantaloupe exlibrisgroup/alma-cantaloupe

The credentials file must be readable by the cantaloupe user. So the file permissions must be changed on the host:

    $ chmod o+r ~/.aws/*

### Connect to a running container
    $ docker exec -i -t --user root exlibrisgroup/alma-cantaloupe /bin/bash

Use `Cntrl-P`, `Cntrl-Q` to leave running.

### Build the container

    $ docker build -t exlibrisgroup/alma-cantaloupe .

