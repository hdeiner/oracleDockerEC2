#!/usr/bin/env bash

# First, add the GPG key for the official Docker repository to the system:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repository to APT sources:
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Next, update the package database with the Docker packages from the newly added repo:
sudo apt-get update

# Finally, install Docker:
sudo apt-get install -y docker-ce

# AUTHENTICATE - FIX  THIS!!!
sudo docker login -u howarddeiner -p hjd001

# Start up private Docker registry image for MSSQLSVR
sudo docker run -d -p 1521:1521 -p 8080:8080 howarddeiner/oracletest:releasecopy