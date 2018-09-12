#!/usr/bin/env bash

# create the test infrasctucture
cd terraform
terraform init
terraform apply -auto-approve
export ORACLE=$(echo `terraform output oracle_dns`)
cd ..

echo Created Oracle on $ORACLE
echo Give Oracle a minute to get online
sleep 60

echo Run our unit tests in lieu of some real smoke tests
echo Run the PLSQL unit tests
mkdir -p test_results
utplsql run system/oracle@$ORACLE:1521:xe \
-source_path=src/main/db -test_path=src/test/db \
-f=ut_documentation_reporter  -c \
-f=ut_coverage_html_reporter  -o=test_results/coverage.html \
-f=ut_coverage_sonar_reporter -o=test_results/sonar_coverage.xml \
-f=ut_sonar_test_reporter     -o=test_results/sonar_test.xml \
-f=ut_xunit_reporter          -o=test_results/xunit_results.xml \
--failure-exit-code=0
