#!/bin/bash

echo "Deploying the maven metadata to nexus staging repository."

cd maven/maven-metadata
git pull --rebase upstream release

mvn build-helper:parse-version versions:set -DnewVersion='${parsedVersion.nextMajorVersion}.0' versions:commit
metadataVersion=$(mvn -B help:evaluate -Dexpression=project.version -DforceStdout -q)

git add pom.xml
git commit -m "Maven metadata $metadataVersion"
git tag $metadataVersion

mvn -Pjboss-release -Pjboss-staging-deploy deploy
echo "Maven metadata $metadataVersion has been deployed to the staging repository, 
once content validated in https://repository.jboss.org/nexus/#browse/browse:wildfly-staging
call sh deploy-release-maven-metadata.sh."
