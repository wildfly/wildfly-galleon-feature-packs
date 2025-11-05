# Add a new WildFly release

## Build the project

`mvn clean install`

## Add a new release

* `mvn exec:java -Dwildfly-version=<WildFly Version> -Dbase-dir=<root dir of the repo>`

