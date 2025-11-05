#!/bin/bash

set -e

newVersion=$1

if [ -z "$newVersion" ]; then
  echo "The new WildFly version must be passed as argument"
  exit 1
fi

if [ -d "$newVersion" ]; then
  echo "The new WildFly version already exists"
  exit 1
fi

dir=$(pwd)
echo "Current directory $dir"
# identify Beta vs Final for doc generation
IFS='.' read -r -a versionArray <<< "$newVersion"
major=${versionArray[0]}
minor=${versionArray[1]}
micro=${versionArray[2]}
stability=${versionArray[3]}

pushd maven/add-wildfly-release
mvn clean install
mvn exec:java -Dwildfly-version=$newVersion -Dbase-dir=$dir
popd

if [ "$stability" = "Final" ]; then
  echo "Generating documentation..."
  pushd maven/docs
  # generate doc
  mvn clean install
  popd
  echo "Documentation has been generated in maven/docs/index.html"
fi

echo "DONE!"
echo "Thank-you!"



