# Wildfly Galleon feature-packs

This repository contains, per WildFly server version, the set of [Galleon](https://github.com/wildfly/galleon) feature-packs that can be provisioned with WildFly.

Each directory named `<WildFly version>` (e.g.: `29.0.0.1`) contains:

* `provisioning-bare-metal.xml` file: Contains the set of possible Galleon feature-packs to be used in bare-metal execution context.

* `provisioning-cloud.xml` file: Contains the set of possible Galleon feature-packs to be used in cloud execution context.

* `tech-preview` directory: Contains bare-metal and cloud provisioning files usable with WildFly preview Galleon feature-packs.

The file `versions.yaml` contains some metadata allowing to discover the content of this repository:

* `latest`: Identifies the directory of the latest WildFly version.

* `versions`: Comma separated list of WildFly versions that this repository contains.


# Repository branchs

This repository contains the following branchs:

* `main`: This branch can contain SNAPSHOT Galleon feature-packs. The latest version in this branch is the current WildFly SNAPSHOT. Using this branch implies having a local build of WildFly `main` branch.

* `release`: This branch contains only released versions of Galleon feature-packs.


# Relationship with WildFly Glow

The [WildFly Glow](https://github.com/wildfly/wildfly-glow) tooling relies on this repository to discover the set of Galleon 
feature-packs to use according to the chosen execution context.


# Using WildFly Glow with your own fork of this repository

In order to integrate your own Galleon feature-packs in the WildFly Glow discovery (before 
your Galleon feature-packs have been officialy added to this repository), follow the following steps:

* Follow the steps detailed in the [CONTRIBUTING](CONTRIBUTING.md) file.
* Add your Galleon feature-pack(s) to the various provisioning files located inside the latest WildFly version directory.
* Reference your own fork and branch when building WildFly Glow by setting the system property `wildfly.glow.galleon.feature-packs.url`. 
To do so, from inside the [WildFly Glow](https://github.com/wildfly/wildfly-glow) repository, call `mvn clean install -Dwildfly.glow.galleon.feature-packs.url=https://raw.githubusercontent.com/myfork/wildfly-galleon-feature-packs/mybranch/`


# Adding new feature-packs to the repository

New Galleon feature-packs can be added to this repository. Such Galleon feature-packs must meet the following expectations: 

* Must be compatible with WildFly.
* Must have been tested with the WildFly server version they are targetting.
* Must be stable (Maven coordinates, layer names, content).
* Must have proven to offer added-value to WildFly server. 
* Must contain Galleon layers well designed for WildFly Glow automatic discovery (Galleon layers containing the metadata required by [WildFly Glow](https://github.com/wildfly/wildfly-glow)).

If you think that your Galleon feature-packs meet these expectations, open a Pull Request against the `main` branch 
of this repository with references to your Galleon feature-packs and information required to build them.


