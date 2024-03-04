#!/bin/bash

set -euo pipefail

# Function to extract lines from a given matching line
function extract_lines {
    local input_file="$1"
    awk "/^Billing account name/ {found=1} found" "$input_file"
}

for f in $(ls raw_billing_csvs)
do
    echo doing $f
    CSV_FILENAME='current.csv'
    cp raw_billing_csvs/${f} "${CSV_FILENAME}"

    tmpfile1=$(mktemp)
    tmpfile2=$(mktemp)
    tmpfile3=$(mktemp)
    tmpfile_header=$(mktemp)

    # process file
    head -8 "${CSV_FILENAME}" > "${tmpfile_header}"
    invoice_date="$(grep Invoice.date ${tmpfile_header} | cut -d, -f2)"

    # remove commas from file
    # remove commas from numbers in file
    while grep '.*,"[0-9.]*,[0-9,.]*"' "${CSV_FILENAME}"
    do
        sed -i 's/\(.*,\)"\([0-9.]*\),\([0-9,.]*\)"\(.*\)/\1"\2\3"\4/' "${CSV_FILENAME}"
    done

    extract_lines "${CSV_FILENAME}" | grep -v 'Charges not specific to a project' | grep -v '^,,,' > "${tmpfile1}"
    echo 'project_name,project_id,project_hierarchy' > project.csv
    tail -n +2 "$tmpfile2" | cut -d, -f3,4,5 | sort -u >> project.csv
    echo 'service_name,service_id' > service.csv
    tail -n +2 "$tmpfile2" | cut -d, -f6,7 | sort -u >> service.csv
    echo 'sku_name,sku_id' > sku.csv
    tail -n +2 "$tmpfile2" | cut -d, -f8,9 | sort -u >> sku.csv
    echo 'project_id,service_id,sku_id,credit_type,cost_type,usage_start_date,usage_end_date,usage_amount,usage_unit,unrounded_cost,cost' > cost.csv
    tail -n +2 "$tmpfile2" | cut -d, -f4,7,9,10,11,12,13,14,15,16,17 >> "${tmpfile3}"
    sed "s/\$/,"${invoice_date}"/" "${tmpfile3}" > cost.csv

    # Upload project
    echo 'drop table if exists tmp_project' | psql -t cost
    echo 'create table tmp_project as select * from project with no data' | psql -t cost
    echo "\\COPY tmp_project (project_name,project_id,project_hierarchy) FROM 'project.csv' DELIMITER ',' CSV HEADER" | psql cost
    echo 'insert into project select * from tmp_project on conflict do nothing' | psql cost

    echo 'drop table if exists tmp_service' | psql -t cost
    echo 'create table tmp_service as select * from service with no data' | psql -t cost
    echo "\\COPY tmp_service (service_name,service_id) FROM 'service.csv' DELIMITER ',' CSV HEADER" | psql cost
    echo 'insert into service select * from tmp_service on conflict do nothing' | psql cost

    echo 'drop table if exists tmp_sku' | psql -t cost
    echo 'create table tmp_sku as select * from sku with no data' | psql -t cost
    echo "\\COPY tmp_sku (sku_name,sku_id) FROM 'sku.csv' DELIMITER ',' CSV HEADER" | psql cost
    echo 'insert into sku select * from tmp_sku on conflict do nothing' | psql cost

    echo 'drop table if exists tmp_cost' | psql -t cost
    echo 'create table tmp_cost as select * from cost with no data' | psql -t cost
    echo "\\COPY tmp_cost (project_id,service_id,sku_id,credit_type,cost_type,usage_start_date,usage_end_date,usage_amount,usage_unit,unrounded_cost,cost,invoice_date) FROM 'cost.csv' DELIMITER ',' CSV HEADER" | psql cost
    echo 'insert into cost (credit_type, cost_type, usage_start_date, usage_end_date, usage_amount, usage_unit, project_id, service_id, sku_id, unrounded_cost, cost, invoice_date) select credit_type, cost_type, usage_start_date, usage_end_date, usage_amount, usage_unit, project_id, service_id, sku_id, unrounded_cost, cost, invoice_date from tmp_cost on conflict do nothing' | psql cost

    echo 'drop table if exists tmp_cost' | psql -t cost
    echo 'drop table if exists tmp_sku' | psql -t cost
    echo 'drop table if exists tmp_service' | psql -t cost
    echo 'drop table if exists tmp_project' | psql -t cost
    # Clean up
    rm -f "${CSV_FILENAME}" "$tmpfile1" "$tmpfile2" cost.csv project.csv service.csv sku.csv "${tmpfile_header}"
done
