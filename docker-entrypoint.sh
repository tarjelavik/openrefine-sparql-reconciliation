#!/bin/bash

#Varibales are defined from .env file
TDB_PATH=/data/tdb
FUSEKI_DATABASES=/fuseki/databases
DATABASE=$FUSEKI_DATABASES/knav
TDB=$TDB_PATH/knav
ADMIN_PASSWORD=pwd123
LOAD_FUSEKI_DATA_ON_START=yes

#Leave this variable empty if you do not want to load Fuseki data on start 
echo "Using variable LOAD_FUSEKI_DATA_ON_START: ${LOAD_FUSEKI_DATA_ON_START}"

if  [[ -n "${LOAD_FUSEKI_DATA_ON_START}" ]]; then
     rm -r $DATABASE
     mkdir -p $DATABASE
     
    /jena-fuseki/tdbloader --loc $DATABASE /staging/data/*.rdf

    rm -r $TDB
    echo "Copying Fuseki TDBs to ${TDB} ..."
    mkdir -p $TDB_PATH
    cp -r $DATABASE $TDB
fi
source /fuseki-docker-entrypoint.sh


