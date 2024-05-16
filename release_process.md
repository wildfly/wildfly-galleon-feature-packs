# Steps to follow when a new WildFly version has been released

## 1) In the release branch

This branch is consumed by WildFly Glow tooling.

* Checkout the release branch

### Reference the new version, applies to Major, Micro and Beta

* Copy the latest WildFly version directory (e.g.: `32.0.0.Final`) and rename it to the new released version (e.g.: 33.0.0.Beta1)
* In all the xml files located in the copied directory: `provisioning-bare-metal.xml`, `provisioning-cloud.xml`, 
`tech-preview/provisioning-bare-metal.xml`, `tech-preview/provisioning-cloud.xml`:
  - Replace the WildFly feature-packs (org.wildfly:wildfly-galleon-pack and org.wildfly:wildfly-preview-feature-pack) versions with the new version.
  - If [Issues](https://github.com/wildfly/wildfly-galleon-feature-packs/issues) exist in the project that require upgrades for the other referenced feature-packs, update them. The list of extra feature-packs repositories is [there](extra-feature-packs.md).
* Add all new files, commit the changes. Keep the commit hash, it will be cherry-picked in the main branch in a following step

### Update the latest version, applies to Major and Micro ONLY

* Edit the file `versions.yaml`
* `latest` field value must be replaced with the new WildFly release.

### Add the version to the list of known versions, applies to Major, Micro and Beta

* Edit the file `versions.yaml`
* Add the new released version at the end of the list of versions, field `versions`. The newly added version must be separated with a comma.

### Update the documentation, applies to Major and Micro ONLY

* cd docs.
* mvn clean install
* The `index.html` file is updated with the latest WildFly version.

### Publish the changes

* Add updated files, commit the changes, open a new PR, CI will run, merge

At this point, the doc will be published and WildFly Glow users will have access to the new WildFly release.

## 2) In the main branch

This branch is consumed by the WildFly Quickstart CI job main branch when testing with WildFly SNAPSHOT

### Reference the new version and new SNAPSHOT version, applies to Major, Micro and Beta

* Checkout the main branch
* Delete the latest WildFly SNAPSHOT directory (eg: 33.0.0.Beta1-SNAPSHOT). We just keep a single SNAPSHOT that we are going to create.
* Cherry-pick the commit that you previously stored. It will create the new WildFly version directory (eg: 33.0.0.Beta1)
* Copy this directory and rename it to the new WildFly SNAPSHOT version (eg: 33.0.0.Final-SNAPSHOT)
* In all the xml files located in the copied directory: `provisioning-bare-metal.xml`, `provisioning-cloud.xml`, 
`tech-preview/provisioning-bare-metal.xml`, `tech-preview/provisioning-cloud.xml`:
  - Replace the WildFly feature-packs (org.wildfly:wildfly-galleon-pack and org.wildfly:wildfly-preview-feature-pack) versions with the new SNAPSHOT version.

### Update the latest version, applies to Major, Micro and Beta

* Edit the file `versions.yaml`
* `latest` field value must be replaced with the new SNAPSHOT WildFly release.

### Add the version to the list of known versions, applies to Major, Micro and Beta

* Edit the file `versions.yaml`
* Remove the latest WildFly SNAPSHOT version (eg: 33.0.0.Beta1-SNAPSHOT) from the `versions` field.
* Add the new released version and the new SNAPSHOT version at the end of the list of versions, field `versions`. 
The newly added versions must be separated with a comma. For example: `33.0.0.Beta1, 33.0.0.Final-SNAPSHOT`.

### Publish the changes

* Add updated files, commit the changes, open a new PR, merge

At this point, the Quickstart CI will be able to run with the new SNAPSHOT build of WildFly.

