#!/bin/bash

echo "Deploying the maven metadata to nexus repository manager, tagging the repository and pushing to upstream..."

cd maven/maven-metadata
git pull --rebase upstream release

mvn build-helper:parse-version versions:set -DnewVersion='${parsedVersion.nextMajorVersion}.0' versions:commit
metadataVersion=$(mvn -B help:evaluate -Dexpression=project.version -DforceStdout -q)

git add pom.xml
git commit -m "Maven metadata $metadataVersion"
git tag $metadataVersion

mvn clean deploy
echo "Maven metadata $metadataVersion has been deployed to the maven repo manager, make sure to log to the repo manager, close and release the repo."

git push upstream release
git push upstream $metadataVersion
echo "Maven metadata $metadataVersion has been deployed, repository has been tagged"
