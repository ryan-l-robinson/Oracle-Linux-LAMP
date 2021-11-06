#!/bin/bash

##############################################################
#
# file: importdb.sh
# This script will import .sql files from the specified path.
#
# The script expects two argument when being called:
# the import_path
# the name of the database to import into
#
# Example: /vagrant/conf/scripts/importdb.sh /vagrant/conf/mysql drupal
#
##############################################################

# make sure exactly 1 argument is provided
if (( $# != 2 ))
then
  echo "ERROR: Need to supply 2 arguments, the path to the folder where the .sql files are and the name of the database to import into:"
  echo "Usage: /vagrant/conf/scripts/importdb.sh /path/to/folder/withsqlfiles drupal"
  exit 1
fi

# let the first argument be the path we import .sql files from.
import_path=$1

# if the import path actually exists, continue
if [ -d "$import_path" ]
then

  # move into the import path and count the number of .sql files avilable.
  cd $import_path
  count_sql_files="$(ls -1q *.sql | wc -l)"

  echo ""
  echo "Found $count_sql_files .sql files in $import_path"
  echo ""

  # if found 1 or more .sql files in import path, continue
  if [ $count_sql_files -gt 0 ]; then
    echo ""
    #for the drupal site we can make this specific to just Drupal. In that case, we'll want to import the newest backup and only the newest backup sql file.
    sql_file="$(ls -t *.sql | head -n1)"
    echo "Newest database to import into Drupal is: $sql_file"
    echo "CREATE DATABASE IF NOT EXISTS $2" | mysql -u root --password=root
    echo "Importing $sql_file into database $2"
    time mysql -u root --password=root $2 < $sql_file
    echo "FINISHED importing $sql_file"
    echo ""
  # no .sql files in import path  
  else
     echo "NOTICE: Could not find any .sql files in $import_path. No databases were created/imported."
  fi
# could not find import path
else
  "WARNING: could not find the folder $import_path. No DBs were imported."
fi
