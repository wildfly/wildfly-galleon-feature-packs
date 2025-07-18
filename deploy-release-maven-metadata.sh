#!/bin/bash

echo "Deploying the maven metadata to nexus repository manager release repository."
cd maven/maven-metadata
metadataVersion=$(mvn -B help:evaluate -Dexpression=project.version -DforceStdout -q)
mvn -Pjboss-staging-move nxrm3:staging-move

git push upstream release
git push upstream $metadataVersion
echo "Maven metadata $metadataVersion has been deployed. Changes have been pushed to the upstream release branch. $metadataVersion tag has been pushed."
