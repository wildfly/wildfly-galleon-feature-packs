#!/bin/bash

function createNewVersionDirectory() {
  echo "Creating directory $2"
  cp -r "${1}" "${2}"
  cd "${2}"
  array=(`find . -type f -name "*.xml"`)
  for i in "${array[@]}"
  do
   #echo "Updating file $i with release $2"
   sed -i "s|${1}|${2}|" "$i"
  done
  cd ..
}

newVersion=$1

# identify Beta vs Final
IFS='.' read -r -a versionArray <<< "$newVersion"
major=${versionArray[0]}
minor=${versionArray[1]}
micro=${versionArray[2]}
stability=${versionArray[3]}

if [ -z $newVersion ]; then
  echo "The new WildFly version must be passed as argument"
  exit 1
fi

if [ -d $newVersion ]; then
  echo "The new WildFly version already exists"
  exit 1
fi

# When adding a SNAPSHOT prior to have the next Final release released (due to some delay in releasing the Final).
if [[ "$stability" =~ "SNAPSHOT" ]]; then
    snapshotDir=$(find . -type d -iname "*-SNAPSHOT")
    previousVersion=$(basename -a $snapshotDir)
    nextVersion=$newVersion
    echo "Adding a new SNAPSHOT $newVersion from the previous $previousVersion"
    createNewVersionDirectory $previousVersion $newVersion
else
    if [ ! $micro = '0' ]; then
      previousMicro=$((micro - 1))
      previousVersion=$major.$minor.$previousMicro.$stability
    else
      previousVersion=$(basename -a $newVersion-SNAPSHOT)
      deletePrevious=${previousVersion}
    fi

    if [ ! -d $previousVersion ]; then
      echo "No $previousVersion WildFly version directory found for $newVersion"
      exit 1
    fi

    createNewVersionDirectory $previousVersion $newVersion

    if [ "$micro" = "0" ]; then
      if [ "$stability" = "Final" ]; then
        nextMajor=$((major + 1))
        nextVersion=$nextMajor.0.0.Beta1
      else
        if [[ "$stability" =~ "Beta" ]]; then
          nextVersion=$major.$minor.$micro.Final 
        else
          echo Unknown kind of version $newversion
          exit 1
        fi
      fi
      # Create the new SNAPSHOT if it doesn't already exist
      nextSnapshot=$(basename -a $nextVersion-SNAPSHOT)
      if [ ! -d $nextSnapshot ]; then
        nextVersion=$nextVersion-SNAPSHOT
        createNewVersionDirectory $newVersion $nextVersion
      else
        echo "New SNAPSHOT version $nextVersion-SNAPSHOT already exists."
        nextVersion=
      fi
    fi

    if [ ! -z $deletePrevious ]; then
      echo "Deleting $deletePrevious WildFly version directory"
      rm -rf $deletePrevious
    fi

    if [ "$stability" = "Final" ]; then
      # update latest
      echo "versions.yaml file: updating the latest version to ${newVersion} version"
      sed -i "/^latest: /clatest: ${newVersion}" "versions.yaml"
    fi

    # add the new version
    echo "versions.yaml file: adding ${newVersion} version"
    sed -i "/^versions=*/s/$/, ${newVersion}/" versions.yaml

    if [ "$stability" = "Final" ]; then
      echo "Generating documentation..."
      # generate doc
      cd docs
      mvn clean install
      cd ..
      echo "Documentation has been generated in docs/index.html"
    fi
fi

# Remove the current snapshot and add the new snapshot only if a new snapshot has been created
if [ ! -z ${nextVersion} ]; then
 echo "versions.yaml file: removing ${previousVersion} version"
 echo "versions.yaml file: adding ${nextVersion} version"
 sed -i "s|, ${previousVersion}||" versions.yaml
 sed -i "/^versions=*/s/$/, ${nextVersion}/" versions.yaml
fi

echo "DONE!"
echo "NOTE: Please check that this project Issues: https://github.com/wildfly/wildfly-galleon-feature-packs/issues 
don't contain issues that would imply to upgrade extra feature-packs for this new release. If that is the case, update them manually in all the updated *.xml files."
echo "At the end, make sure to review the changes, commit them and open PR against the release branch"
echo "Thank-you!"



