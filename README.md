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

# Steps to follow when a new WildFly version has been released

The steps to follow are documented in [this](release_process.md) document.

# Relationship with WildFly Glow

The [WildFly Glow](https://github.com/wildfly/wildfly-glow) tooling relies on this repository to discover the set of Galleon 
feature-packs to use according to the chosen execution context. The `release` branch is used by WildFly Glow to resolve feature-packs.

WildFly Glow CLI and WildFly Glow integration in WildFly Maven Plugin use the `https://raw.githubusercontent.com/wildfly/wildfly-galleon-feature-packs/release/` branch to resolve feature-packs

# Relationship with WildFly Quickstarts when testing with Wildfly SNAPSHOT builds

The WildFly quickstarts github actions run tests with WildFly SNAPSHOT. In such a case, the system property 
`-Dwildfly-glow-galleon-feature-packs-url=https://raw.githubusercontent.com/wildfly/wildfly-galleon-feature-packs/main/` has to be provided to resolve SNAPSHOT WildFly feature-packs


# Adding extra feature-packs to the repository

New Galleon feature-packs can be added to this repository. Such Galleon feature-packs must meet the following expectations: 

* Must be compatible with WildFly.
* Must have been tested with the WildFly server version they are targetting.
* Must be stable (Maven coordinates, layer names, content).
* Must have proven to offer added-value to WildFly server. 
* Must contain Galleon layers well designed for WildFly Glow automatic discovery (Galleon layers containing the metadata required by [WildFly Glow](https://github.com/wildfly/wildfly-glow)).

If you think that your Galleon feature-packs meet these expectations, open a Pull Request against the `release` branch 
of this repository with the following requirements:


## Update the provisioning xml files located in the directory of the latest WildFly release (eg: 30.0.0.Final)

Add your feature-pack maven coordinates (`groupId:artifactId:version`) to the following provisioning files:

* `<latest WildFly version>/provisioning-bare-metal.xml` if your feature-pack targets WildFly execution on bare-metal.
* `<latest WildFly version>/provisioning-cloud.xml` if your feature-pack targets WildFly execution on cloud platforms.

If you have defined a feature-pack compatible with WildFly Preview feature-pack, 
add this feature-pack maven coordinates (`groupId:artifactId:version`) to the following provisioning files:

* `<latest WildFly version>/tech-preview/provisioning-bare-metal.xml` if you have defined a feature-pack targets WildFly Preview execution on bare-metal and is compatible with .
* `<latest WildFly version>/tech-preview/provisioning-cloud.xml` if your feature-pack targets WildFly Preview execution on cloud platforms.

## Add a test

* Add a war file that will be scanned by the tests inside the `tests/war` directory.
* Update the `tests/war/README` file with the github project used to build this war (to keep track, not actually used by tests).
* Add a test to the file `tests/run-wildfly-glow-tests.sh`. Add it before the marker `### END Extra feature-packs testing`.
* The test syntax is: 
```
echo <your description>
test \
"[expected discovered layers]" \
"tests/war/<name of your war>"
```

To retrieve the `[expected discovered layers]`:

* Download and unzip the latest release zip file from [WildFly Glow releases](https://github.com/wildfly/wildfly-glow/releases). 
* Run `JAVA_OPTS=-Dcompact=true <wildfly-glow-unzipped-directory>/wildfly-glow scan <path to your war file>`.
* If what WildFly Glow has discovered is what you are expecting, replace `[expected discovered layers]` with the printed output.

## Update documentation

* `cd docs; mvn clean package`
* The file `docs/index.html` should have been updated with your feature-pack.
* Commit the `docs/index.html` file.

* Update the tables located in the file `extra-feature-packs.md` with your feature-pack and URL to its github project.

## Open a PR against the `release` branch

In the description section, please add some information to help reviewers understand what this Galleon feature-pack is about.

# Using WildFly Glow with your own fork of this repository

In order to integrate your own Galleon feature-packs in the WildFly Glow discovery (before 
your Galleon feature-packs have been officialy added to this repository), follow the following steps:

* Follow the steps detailed in the [CONTRIBUTING](CONTRIBUTING.md) file.
* Add your Galleon feature-pack(s) to the various provisioning files located inside the latest WildFly version directory.
* Reference your own fork and branch when building WildFly Glow by setting the system property `wildfly.glow.galleon.feature-packs.url`. 
To do so, from inside the [WildFly Glow](https://github.com/wildfly/wildfly-glow) repository, call `mvn clean install -Dwildfly.glow.galleon.feature-packs.url=https://raw.githubusercontent.com/myfork/wildfly-galleon-feature-packs/mybranch/`
