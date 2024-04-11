#!/bin/bash

script_dir=$(dirname "$0")
jar="$WILDFLY_GLOW_DIR/wildfly-glow.jar"
compact=-Dcompact=true
JAVA_OPTS=-Dwildfly-glow-galleon-feature-packs-url=file://$PWD

test_failure=0
test_count=0

function test {
  expected=$1
  warFile=$2
  profile=$3
  provisioningFile=$4
  addOns=$5
  context=$6
  preview=$7
  test_count=$((test_count+1))

if [ ! -z "$provisioningFile" ]; then
  if [ ! "default" == "$provisioningFile" ]; then
    provisioningFile="--input-feature-packs-file=$provisioningFile";
  else
    unset provisioningFile
  fi
fi
if [ ! -z "$profile" ]; then
  profile="--$profile";
fi
if [ ! -z "$addOns" ]; then
  addOns="--add-ons=$addOns";
fi
if [ ! -z "$context" ]; then
  context="--$context";
fi
if [ ! -z "$preview" ]; then
  preview="--wildfly-preview";
fi
if [ ! -z $GENERATE_CONFIG ]; then
 echo "java -jar -Dverbose=true $JAVA_OPTS $jar scan $warFile ${provisioningFile} $profile $addOns $preview"
 java -Dverbose=true $JAVA_OPTS -jar $jar scan $warFile ${provisioningFile} $profile $addOns $preview
else

  if [ "$DEBUG" = 1 ]; then
    echo "java $JAVA_OPTS $compact -jar $jar scan $warFile ${provisioningFile} $profile $addOns $context $preview"
  fi

  found_layers=$(java $JAVA_OPTS $compact  -jar $jar scan \
  $warFile \
  ${provisioningFile} \
  $profile \
  $addOns \
  $context \
  $preview)

  if [ "$found_layers" != "$expected" ]; then
    echo "ERROR $warFile, found layers $found_layers; expected $expected"
    test_failure=1
  fi
  # Check provisioning
  echo "Testing SERVER provisioning"
  java $JAVA_OPTS $compact  -jar $jar scan \
  $warFile \
  ${provisioningFile} \
  $profile \
  $addOns \
  $context \
  $preview --provision=SERVER --fails-on-error=false
  if [ $? -ne 0 ]; then
    echo "ERROR SERVER provisioning $warFile"
    test_failure=1
  fi

  if [ -z "$context" ]; then
  echo "\nTesting BOOTABLE_JAR provisioning"
  java $JAVA_OPTS $compact  -jar $jar scan \
  $warFile \
  ${provisioningFile} \
  $profile \
  $addOns \
  $context \
  $preview --provision=BOOTABLE_JAR --fails-on-error=false
  if [ $? -ne 0 ]; then
    echo "ERROR BOOTABLE_JAR provisioning $warFile"
    test_failure=1
  fi
  fi
fi
}

echo "* Show configuration"

java $JAVA_OPTS -jar $jar show-configuration

if [ $? -ne 0 ]; then
    echo "Error, check log"
    exit 1
fi

echo "* Show configuration cloud"

java $JAVA_OPTS -jar $jar show-configuration --cloud

if [ $? -ne 0 ]; then
    echo "Error, check log"
    exit 1
fi

echo kitchensink
test \
"[bean-validation, cdi, ee-integration, ejb-lite, h2-driver, jaxrs, jpa, jsf]==>ee-core-profile-server,ejb-lite,h2-driver,jaxrs,jpa,jsf" \
"$WILDFLY_GLOW_DIR/examples/kitchensink.war"

echo kitchensink cloud
test \
"[bean-validation, cdi, ee-integration, ejb-lite, h2-driver, jaxrs, jpa, jsf]==>ee-core-profile-server,ejb-lite,h2-driver,jaxrs,jpa,jsf" \
"$WILDFLY_GLOW_DIR/examples/kitchensink.war" \
"" \
"" \
"" \
cloud

echo kitchensink cloud HA
test \
"[ha][bean-validation, cdi, ee-integration, ejb-lite, h2-driver, jaxrs, jpa, jsf]==>ee-core-profile-server,ejb-dist-cache,ejb-lite,h2-driver,jaxrs,jpa-distributed,jsf,-ejb-local-cache" \
"$WILDFLY_GLOW_DIR/examples/kitchensink.war" \
"ha" \
"" \
"" \
cloud

### Extra feature-packs testing


echo kitchensink + grpc + myFaces
test \
"[bean-validation, cdi, ee-integration, ejb-lite, grpc, h2-driver, jaxrs, jpa, jsf, myfaces]==>ee-core-profile-server,ejb-lite,grpc,h2-driver,jaxrs,jpa,myfaces" \
"$WILDFLY_GLOW_DIR/examples/kitchensink.war" \
"" \
"" \
"grpc,myfaces" \
""

echo graphql
test \
"[cdi, microprofile-config, microprofile-graphql]==>ee-core-profile-server,microprofile-graphql" \
"tests/war/quickstart-graphql.war"

echo spring-resteasy
test \
"[bean-validation, ee-concurrency, ee-integration, ejb-lite, jaxrs, jsf, jsonb, naming, resteasy-spring, resteasy-spring-web, servlet]==>ee-core-profile-server,ejb-lite,jaxrs,jsf,resteasy-spring,resteasy-spring-web" \
"tests/war/spring-resteasy.war"

echo todo-backend
test \
"[cdi, datasources, ejb-lite, jaxrs, jpa, postgresql-datasource, postgresql-driver, transactions]==>ee-core-profile-server,ejb-lite,jaxrs,jpa,postgresql-datasource" \
"tests/war/todo-backend.war" \
"" \
"" \
"postgresql" \
""

echo saml auto-registration
test \
"[keycloak-saml, servlet]==>ee-core-profile-server,keycloak-saml" \
"tests/war/saml-app-auto-reg.war" \
"" \
"" \
"" \
cloud

echo saml
test \
"[datasources, keycloak-client-saml, keycloak-saml, servlet]==>ee-core-profile-server,datasources,keycloak-client-saml" \
"tests/war/servlet-saml-service-provider.war"

### END Extra feature-packs testing


if [ "$test_failure" -eq 1 ]; then
  echo "There were test failures! See the above output for details."
  exit 1
else
  echo "All $test_count tests passed!"
fi