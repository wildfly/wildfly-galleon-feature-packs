#!/bin/bash

set -e

function configureSed() {
    SED="sed -i.bak"
    osType="$(uname -s)"
    if [ "${osType}" == "Darwin" ]; then
      SED='sed -i .bak';
    fi
    echo "sed options for this platform are ${SED}"
}

function createNewVersionDirectory() {
  targetDir=$3
  echo "Creating directory $targetDir/$2"
  cp -r "$targetDir/${1}" "$targetDir/${2}"
  # Only change versions in the default space
  if [ "$targetDir" == "." ]; then
      cd "${2}"
      array=(`find . -type f -name "*.xml"`)
      for i in "${array[@]}"
      do
       echo "Updating file $i with release $2"
       ${SED} "s|${1}|${2}|" "$i"
       rm "$i".bak
      done
      cd ..
  fi
}

newVersion=$1

# identify Beta vs Final
IFS='.' read -r -a versionArray <<< "$newVersion"
major=${versionArray[0]}
minor=${versionArray[1]}
micro=${versionArray[2]}
stability=${versionArray[3]}

if [ -z "$newVersion" ]; then
  echo "The new WildFly version must be passed as argument"
  exit 1
fi

if [ -d "$newVersion" ]; then
  echo "The new WildFly version already exists"
  exit 1
fi

function addVersions() {
    dir=$1
    echo "Making changes to the directory $dir"
    # When adding a SNAPSHOT prior to have the next Final release released (due to some delay in releasing the Final).
    if [[ "$stability" =~ "SNAPSHOT" ]]; then
        snapshotDir=$(find "$dir" -maxdepth 1 -type d -iname "*-SNAPSHOT")
        previousVersion=$(basename -a $dir/$snapshotDir)
        nextVersion=$newVersion
        echo "Adding a new SNAPSHOT $newVersion from the previous $previousVersion"
        createNewVersionDirectory $previousVersion $newVersion $dir
    else
        previousVersion=$(basename -a "$dir/$newVersion-SNAPSHOT")
        echo "PREVIOUS " $previousVersion
        deletePrevious=${previousVersion}
        
        if [ ! -d "$dir/$previousVersion" ]; then
          echo "No $previousVersion WildFly version directory found for $newVersion"
          if [ $dir == "." ]; then
            exit 1
          else
            return
          fi
        fi

        createNewVersionDirectory $previousVersion $newVersion $dir
        echo "OK1"
        if [ "$micro" = "0" ]; then
          if [ "$stability" = "Final" ]; then
            nextMajor=$((major + 1))
            nextVersion=$nextMajor.0.0.Beta1
            # Must delete the latest previous Major micro SNAPSHOT
            previousMajor=$((major - 1))
            microSnapshotDir=$(find "$dir" -maxdepth 1 -type d -iname "$previousMajor.0.*-SNAPSHOT")
            echo "XXX $microSnapshotDir"
            if [ -n "$microSnapshotDir" ]; then
              previousMicroSnapshotVersion=$(basename -a $microSnapshotDir)
            fi
            echo "previousMicroSnapshotVersion=$previousMicroSnapshotVersion"
            nextMicroSnapshot=$major.$minor.1.$stability-SNAPSHOT
            echo Creating the next micro SNAPSHOT release $dir/$nextMicroSnapshot
            createNewVersionDirectory $newVersion $nextMicroSnapshot $dir
            echo "$dir/versions.yaml file: adding ${newVersion} version"
            ${SED} "/^versions=*/s/$/, ${nextMicroSnapshot}/" $dir/versions.yaml
            rm "$dir/versions.yaml".bak
          else
            if [[ "$stability" =~ "Beta" ]]; then
              nextVersion=$major.$minor.$micro.Final 
            else
              echo Unknown kind of version $newversion
              exit 1
            fi
          fi
          # Create the new SNAPSHOT if it doesn't already exist
          nextSnapshot=$(basename -a $dir/$nextVersion-SNAPSHOT)
          if [ ! -d "$dir/$nextSnapshot" ]; then
            nextVersion=$nextVersion-SNAPSHOT
            createNewVersionDirectory $newVersion $nextVersion $dir
          else
            echo "New SNAPSHOT version $nextVersion-SNAPSHOT already exists."
            nextVersion=
          fi
        else
          nextMicro=$((micro + 1))
          nextVersion=$major.$minor.$nextMicro.$stability
          nextSnapshot=$(basename -a $nextVersion-SNAPSHOT)
          # Create the new SNAPSHOT if it doesn't already exist
          if [ ! -d "$dir/$nextSnapshot" ]; then
            nextVersion=$nextVersion-SNAPSHOT
            createNewVersionDirectory $newVersion $nextVersion $dir
          else
            echo "New SNAPSHOT version $nextVersion-SNAPSHOT already exists."
            nextVersion=
          fi
        fi

        if [ ! -z "$deletePrevious" ]; then
          echo "Deleting $deletePrevious WildFly version directory"
          rm -rf $dir/$deletePrevious
        fi
        if [ ! -z "$previousMicroSnapshotVersion" ]; then
          echo "Deleting $previousMicroSnapshotVersion WildFly version directory"
          rm -rf $dir/$previousMicroSnapshotVersion
        fi

        if [ "$stability" = "Final" ]; then
          # update latest
          echo "$dir/versions.yaml file: updating the latest version to ${newVersion} version"
          ${SED} "s/latest:.*/latest: ${newVersion}/g" "$dir/versions.yaml"
          rm "$dir/versions.yaml.bak"
        fi

        # add the new version
        echo "$dir/versions.yaml file: adding ${newVersion} version"
        ${SED} "/^versions=*/s/$/, ${newVersion}/" "$dir/versions.yaml"
        rm "$dir/versions.yaml.bak"

        if [ -d "$dir/maven/docs" ]; then
            if [ "$stability" = "Final" ]; then
              echo "Generating documentation..."
              cd $dir/maven/docs
              # generate doc
              mvn clean install
              cd $dir/../..
              echo "Documentation has been generated in maven/docs/index.html"
            fi
        fi
    fi

    # Remove the current snapshot and add the new snapshot only if a new snapshot has been created
    if [ ! -z "${nextVersion}" ]; then
     echo "$dir/versions.yaml file: removing ${previousVersion} version"
     echo "$dir/versions.yaml file: adding ${nextVersion} version"
     ${SED} "s|, ${previousVersion}||" "$dir/versions.yaml"
     ${SED} "s| ${previousVersion},||" "$dir/versions.yaml"
     ${SED} "/^versions=*/s/$/, ${nextVersion}/" "$dir/versions.yaml"
     rm "$dir/versions.yaml.bak"
    fi

    # Remove the latest micro snapshot
    if [ ! -z "${previousMicroSnapshotVersion}" ]; then
     echo "$dir/versions.yaml file: removing ${previousMicroSnapshotVersion} version"
     ${SED} "s|, ${previousMicroSnapshotVersion}||" "$dir/versions.yaml"
     ${SED} "s| ${previousMicroSnapshotVersion},||" "$dir/versions.yaml"
     rm "$dir/versions.yaml.bak"
    fi
}

configureSed

addVersions "."

addVersions "spaces/incubating"

echo "DONE!"
echo "NOTE: Please check that this project Issues: https://github.com/wildfly/wildfly-galleon-feature-packs/issues 
don't contain issues that would imply to upgrade extra feature-packs for this new release. If that is the case, update them manually in all the updated *.xml files."
echo "At the end, make sure to review the changes, commit them and open PR against the release branch"
echo "Thank-you!"



