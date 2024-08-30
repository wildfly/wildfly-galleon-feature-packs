# Steps to follow when a new WildFly version has been released

When a new WildFly version is released, we need to add content for the version to be discovered by WildFly Glow. 
We are also preparing a new SNAPSHOT version (if needed). It all depends on the nature of the release (Beta, Final and Micro).

The steps detailed here are fully automated in the script `add-wildfly-release.sh <new release version>` that you should execute to create a new release. 

## Steps for Beta releases: 

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

## Steps for Final releases: 

* Add a new directory for the new WildFly version by copying the latest *.Final-SNAPSHOT directory and replacing the versions with the new released Final version.
* Create the next Major+1.0.0.Beta1-SNAPSHOT directory by copying the newly created directory and replacing the versions with the next Major+1.0.0.Beta1-SNAPSHOT version.
* Remove the previous *.Final-SNAPSHOT directory
* Remove the previous *.Final-SNAPSHOT from the list of releases in the `versions.yaml` file, field `versions`.
* Add the new *.Final release to the list of releases in the `versions.yaml` file, field `versions`.
* Add the new Major+1.0.0.Beta1-SNAPSHOT release to the list of releases in the `versions.yaml` file, field `versions`.
* Replace the current latest with the new *.Final release in the `versions.yaml` file, field latest.
* Generate documentation: `cd docs; mvn clean install`
* Review your changes, commit and open PR against the release branch

## Steps for Micro releases: 

* Add a new directory for the new WildFly version by copying the latest Major.Minor.Micro.Final-SNAPSHOT directory and replacing the versions with the new released Micro version.
* Add the new *.Final release to the list of releases in the `versions.yaml` file, field `versions`.
* Remove the previous Major.Minor.Micro.Final-SNAPSHOT directory
* Remove the previous Major.Minor.Micro.Final-SNAPSHOT from the list of releases in the `versions.yaml` file, field `versions`.
* Replace the current latest with the new *.Final release in the `versions.yaml` file, field latest.
* Generate documentation: `cd docs; mvn clean install`
* Review your changes, commit and open PR against the release branch

## Steps for adding a SNAPSHOT. 

Can occur if the main wildfly branch is updated to the new SNAPSHOT although the release is not yet ready (delay). This is required
to have the nightly SNAPSHOT CI to succeed.

* Add a new directory for the new SNAPSHOT WildFly version by copying the latest *.*-SNAPSHOT directory and replacing the versions with the X.X.X.[Beta1 | Final]-SNAPSHOT version.

