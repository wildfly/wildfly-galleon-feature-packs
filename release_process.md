# Steps to follow when a new WildFly version has been released

* Checkout the release branch

## Reference the new version, and add the new SNAPSHOT version. It applies to Major, Micro and Beta

* Delete the latest WildFly SNAPSHOT directory (eg: 33.0.0.Beta1-SNAPSHOT). We just keep a single SNAPSHOT that we are going to create.
* Copy the latest WildFly version directory (e.g.: `32.0.0.Final`) and rename it to the new released version (e.g.: 33.0.0.Beta1)
* In all the xml files located in the copied directory: `provisioning-bare-metal.xml`, `provisioning-cloud.xml`, 
`tech-preview/provisioning-bare-metal.xml`, `tech-preview/provisioning-cloud.xml`:
  - Replace the WildFly feature-packs (org.wildfly:wildfly-galleon-pack and org.wildfly:wildfly-preview-feature-pack) versions with the new version.
  - If [Issues](https://github.com/wildfly/wildfly-galleon-feature-packs/issues) exist in the project that require upgrades for the other referenced feature-packs, update them. The list of extra feature-packs repositories is [there](extra-feature-packs.md).
* Copy the new release directory and rename it to the new SNAPSHOT version. For example: `cp -r 33.0.0.Beta1 33.0.0.Final-SNAPSHOT`
* In all the xml files located in the copied directory: `provisioning-bare-metal.xml`, `provisioning-cloud.xml`, 
`tech-preview/provisioning-bare-metal.xml`, `tech-preview/provisioning-cloud.xml`:
  - Replace the WildFly feature-packs (org.wildfly:wildfly-galleon-pack and org.wildfly:wildfly-preview-feature-pack) versions with the new SNAPSHOT version.

## Update the latest version, applies to Major and Micro ONLY

* Edit the file `versions.yaml`
* `latest` field value must be replaced with the new WildFly release (e.g.: 33.0.0.Final).

### Add the version to the list of known versions, applies to Major, Micro and Beta

* Edit the file `versions.yaml`
* Remove the latest WildFly SNAPSHOT version (eg: 33.0.0.Beta1-SNAPSHOT) from the `versions` field.
* Add the new released version and the new SNAPSHOT version at the end of the list of versions, field `versions`. 
The newly added versions must be separated with a comma. For example: `33.0.0.Beta1, 33.0.0.Final-SNAPSHOT`.

### Update the documentation, applies to Major and Micro ONLY

* cd docs.
* mvn clean install
* The `index.html` file is updated with the latest WildFly version.

### Publish the changes

* Add updated files, commit the changes, open a new PR, CI will run, merge
