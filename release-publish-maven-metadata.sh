#!/bin/bash

# Strict mode: fail on error, fail on unset vars, fail on pipe failure
set -o errexit
set -o nounset
set -o pipefail

echo "Deploying the maven metadata to central repository."

cd maven/maven-metadata
rm -rf target
git pull --rebase upstream release

current=$(mvn -B help:evaluate -Dexpression=project.version -DforceStdout -q)
releasedVersion=(${current//./ })
next=$((releasedVersion+1)).0-SNAPSHOT
releasedVersion=$releasedVersion.0
echo Releasing $releasedVersion next is $next
bash release.sh  -d $next -r $releasedVersion

echo "Maven metadata $metadataVersion has been pushed to the central repository."