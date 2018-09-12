This project demomstrates a way to

* Create a local Oracle 11g database inside a Docker container
* Build the database from scratch using Liquibase
* Unit test the stored procedures in the database using utPLSQL
* Push the verified Docker container to a private Docker registry
* Terraform create an AWS EC2 instance that pulls the private Docker image
* Smoke test the Oracle Docker instance running in the AWS EC2 instance

