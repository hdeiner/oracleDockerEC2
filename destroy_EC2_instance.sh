#!/usr/bin/env bash

# create the test infrasctucture
cd terraform
terraform destroy -auto-approve
cd ..