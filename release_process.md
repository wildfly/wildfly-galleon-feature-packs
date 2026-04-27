# Steps to follow when a new WildFly version has been released

When a new WildFly version is released, we need to add content for the version to be discovered by WildFly Glow. 
We are also preparing a new SNAPSHOT version (if needed). It all depends on the nature of the release (Beta, Final and Micro).

## Steps to add a new WildFly release

* Make sure you are in the release branch, then do `git pull --rebase upstream release`
* Call `sh add-wildfly-release.sh <new release version>`, for example `sh add-wildfly-release.sh 40.0.0.Beta1`
* Review the changes, commit, open PR against the `release` branch, merge when green (ignore the SNAPSHOT CI that can be red due to new SNAPSHOT version not yet updated in WildFly repo).
* Pull the changes: `git pull --rebase upstream release`
* Call `sh deploy-staging-maven-metadata.sh` WARNING: This script deploy the maven metadata to nexus staging repo, 
* Check deployment content in https://repository.jboss.org/nexus/#browse/browse:wildfly-staging Coordinates are `org.wildfly.galleon.feature-packs:wildfly-galleon-feature-packs-metadata`
* Access the wildfly-staging validation task (https://repository.jboss.org/nexus/#admin/system/tasks:cb5eaab4-655c-4863-90b0-eba8f8ccae2c) 
* Update the settings `Filter` with `tag=wildfly-galleon-feature-packs-<released version>`
* Save the settings, run the task, clear the `Filter`, save again the settings.
* If something is wrong, call `sh deploy-delete-staging-maven-metadata.sh` it will delete the artifact from the wildfly-staging 
and the last commit (version upgrade).
* Once validated, call `sh deploy-release-maven-metadata.sh`. WARNING: This script deploy the maven metadata to nexus release repo, 
update, commit and push to the upstream release branch.
* DONE, you can advertise that the WildFly Glow metadata has been released.

## Details

### Steps for Beta releases: 

* Add a new directory for the new WildFly version by copying the latest *.Beta1-SNAPSHOT directory and replacing the versions with the new released Beta version.
* Create the next *.Final-SNAPSHOT directory by copying the newly created directory and replacing the versions with the next *.Final-SNAPSHOT version.
* Remove the previous *.Beta1-SNAPSHOT directory
* Remove the  previous *.Beta1-SNAPSHOT from the list of releases in the `versions.yaml` file, field `versions`.
* Add the new Beta release to the list of releases in the `versions.yaml` file, field `versions`.
* Add the new Final-SNAPSHOT release to the list of releases in the `versions.yaml` file, field `versions`.
* Check that this project [Issues](https://github.com/wildfly/wildfly-galleon-feature-packs/issues) 
don't contain issues that would imply to upgrade extra feature-packs for this new release. If that is the case, update them manually in both the new
Beta and Final-SNAPSHOT files.
* Review your changes, commit and open PR against the release branch

### Steps for Final releases: 

* Add a new directory for the new WildFly version by copying the latest *.Final-SNAPSHOT directory and replacing the versions with the new released Final version.
* Create the next Major+1.0.0.Beta1-SNAPSHOT directory by copying the newly created directory and replacing the versions with the next Major+1.0.0.Beta1-SNAPSHOT version.
* Remove the previous *.Final-SNAPSHOT directory
* Remove the previous *.Final-SNAPSHOT from the list of releases in the `versions.yaml` file, field `versions`.
* Add the new *.Final release to the list of releases in the `versions.yaml` file, field `versions`.
* Add the new Major+1.0.0.Beta1-SNAPSHOT release to the list of releases in the `versions.yaml` file, field `versions`.
* Replace the current latest with the new *.Final release in the `versions.yaml` file, field latest.
* Generate documentation: `cd docs; mvn clean install`
* Review your changes, commit and open PR against the release branch

### Steps for Micro releases: 

* Add a new directory for the new WildFly version by copying the latest Major.Minor.Micro.Final-SNAPSHOT directory and replacing the versions with the new released Micro version.
* Add the new *.Final release to the list of releases in the `versions.yaml` file, field `versions`.
* Remove the previous Major.Minor.Micro.Final-SNAPSHOT directory
* Remove the previous Major.Minor.Micro.Final-SNAPSHOT from the list of releases in the `versions.yaml` file, field `versions`.
* Replace the current latest with the new *.Final release in the `versions.yaml` file, field latest.
* Generate documentation: `cd docs; mvn clean install`
* Review your changes, commit and open PR against the release branch

### Steps for adding a SNAPSHOT. 

Can occur if the main wildfly branch is updated to the new SNAPSHOT although the release is not yet ready (delay). This is required
to have the nightly SNAPSHOT CI to succeed.

* Add a new directory for the new SNAPSHOT WildFly version by copying the latest *.*-SNAPSHOT directory and replacing the versions with the X.X.X.[Beta1 | Final]-SNAPSHOT version.