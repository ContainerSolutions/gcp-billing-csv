#!/bin/bash
psql cost < schema.sql && ./process_csv.sh
