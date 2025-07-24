#!/bin/bash

echo "Deleting the metadata version upgrade commit and the maven metadata artifact from nexus repository manager staging repository."
cd maven/maven-metadata
metadataVersion=$(mvn -B help:evaluate -Dexpression=project.version -DforceStdout -q)
mvn -Pjboss-staging-delete nxrm3:staging-delete
git reset --hard HEAD^
git tag -d $metadataVersion
echo "Maven metadata $metadataVersion has been deleted from the wildfly-staging repository."
