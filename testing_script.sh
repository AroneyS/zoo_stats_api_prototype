#!/bin/bash

# file_array=(input01 input02 input03 input04 input05 input06 input07 input08 input09 input10 input11 input12 input13 input14 input15)
# sizes=(100K 200K 300K 400K 500K 750K 1M 2M 5M 10M 20M 50M 100M 500M 1B)
file_array=(input01 input02)
sizes=(100K 200K)
path="./scripts/generate_testing_database/files/"
script_path="./scripts/generate_testing_database/"
> testing_output.csv

echo "***Script starting***"

for i in {0..1}; do
    echo "|||Database size ${sizes[$i]}|||"
    echo "***Setup database***"
    docker-compose run --rm --entrypoint="bundle exec rake db:reset" zoo_stats
    echo "***Importing data***"
    docker cp $path${file_array[$i]}.csv zoo_stats_api_prototype_timescale_1:/input.csv
    docker cp ${script_path}add_csv.sql zoo_stats_api_prototype_timescale_1:/input.sql
    docker exec zoo_stats_api_prototype_timescale_1 psql -U zoo_stats zoo_stats_development -f input.sql

    echo "***Test setup***"
    docker stop zoo_stats_api_prototype_timescale_1
    docker start zoo_stats_api_prototype_timescale_1

    echo "***Running database tests***"
    docker-compose run --rm --entrypoint="bin/rails runner scripts/generate_testing_database/run_database_tests.rb" zoo_stats >> testing_output.csv
done