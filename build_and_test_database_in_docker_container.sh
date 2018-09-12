#!/usr/bin/env bash

echo Stop current oracletest Docker container
sudo -S <<< "password" docker stop oracletest

echo Remove current oracletest Docker container
sudo -S <<< "password" docker rm oracletest

echo Create a fresh Docker oracletest container
echo Starting alexeiled/docker-oracle-xe-11g:latest in Docker container
sudo -S <<< "password" docker run \
    -d -p 1521:1521 -p 8080:8080 \
    --name oracletest \
    alexeiled/docker-oracle-xe-11g

echo Pause a minute to allow Oracle to start up
sleep 60

echo Install utPLSQL
cd utPLSQL/source
sqlplus sys/oracle@localhost:1521/xe as sysdba @install_headless.sql
cd ../..

echo Install Schema, Test Data, PLSQL Code and utPLSQL to test with
liquibase --changeLogFile=src/test/db/changelog-with-unit-tests.xml update

echo Run the PLSQL unit tests
mkdir -p test_results
utplsql run system/oracle@localhost:1521:xe \
-source_path=src/main/db -test_path=src/test/db \
-f=ut_documentation_reporter  -c \
-f=ut_coverage_html_reporter  -o=test_results/coverage.html \
-f=ut_coverage_sonar_reporter -o=test_results/sonar_coverage.xml \
-f=ut_sonar_test_reporter     -o=test_results/sonar_test.xml \
-f=ut_xunit_reporter          -o=test_results/xunit_results.xml \
--failure-exit-code=0

echo Commit the Docker Oracle container as a Docker image
sudo docker commit -a howarddeiner -m "finsihed provisioning" oracletest howarddeiner/oracletest:releasecopy

echo Authenticate to Docker Hub
sudo docker login

echo Push the Docker Oracle release image to the Docker Hub registry
sudo docker push howarddeiner/oracletest:releasecopy