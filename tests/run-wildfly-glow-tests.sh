#!/bin/bash

serverVersion=$1
if [ ! -z "$serverVersion" ]; then
  serverVersionOption="--server-version=$serverVersion";
fi
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
  spaces=$8
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
if [ ! -z "$spaces" ]; then
  spaces="--spaces=$spaces";
fi
if [ ! -z $GENERATE_CONFIG ]; then
 echo "java -jar -Dverbose=true $JAVA_OPTS $jar scan $warFile ${provisioningFile} $profile $addOns $preview $serverVersionOption $spaces"
 java -Dverbose=true $JAVA_OPTS -jar $jar scan $warFile ${provisioningFile} $profile $addOns $preview $serverVersionOption $spaces
else

  if [ "$DEBUG" = 1 ]; then
    echo "java $JAVA_OPTS $compact -jar $jar scan $warFile ${provisioningFile} $profile $addOns $context $preview $serverVersionOption $spaces"
  fi

  found_layers=$(java $JAVA_OPTS $compact  -jar $jar scan \
  $warFile \
  ${provisioningFile} \
  $profile \
  $addOns \
  $context \
  $preview \
  $serverVersionOption\
  $spaces)

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
  $preview --provision=SERVER --fails-on-error=false \
  $serverVersionOption \
  $spaces
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
  $preview --provision=BOOTABLE_JAR --fails-on-error=false \
  $serverVersionOption \
  $spaces
  if [ $? -ne 0 ]; then
    echo "ERROR BOOTABLE_JAR provisioning $warFile"
    test_failure=1
  fi
  fi
fi
}

echo "* Show configuration"

java $JAVA_OPTS -jar $jar show-configuration $serverVersionOption

if [ $? -ne 0 ]; then
    echo "Error, check log"
    exit 1
fi

echo "* Show configuration cloud"

java $JAVA_OPTS -jar $jar show-configuration --cloud $serverVersionOption

if [ $? -ne 0 ]; then
    echo "Error, check log"
    exit 1
fi

echo "* Show configuration incubating"

java $JAVA_OPTS -jar $jar show-configuration $serverVersionOption -sp=incubating

if [ $? -ne 0 ]; then
    echo "Error, check log"
    exit 1
fi

echo "* Show configuration cloud incubating"

java $JAVA_OPTS -jar $jar show-configuration --cloud $serverVersionOption -sp=incubating

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

echo kitchensink cloud preview
test \
"[bean-validation, cdi, ee-integration, ejb-lite, h2-driver, jaxrs, jpa, jsf]==>ee-core-profile-server,ejb-lite,h2-driver,jaxrs,jpa,jsf" \
"$WILDFLY_GLOW_DIR/examples/kitchensink.war" \
"" \
"" \
"" \
cloud \
"true"

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

echo kitchensink + grpc on preview
test \
"[bean-validation, cdi, ee-integration, ejb-lite, grpc, h2-driver, jaxrs, jpa, jsf]==>ee-core-profile-server,ejb-lite,grpc,h2-driver,jaxrs,jpa,jsf" \
"$WILDFLY_GLOW_DIR/examples/kitchensink.war" \
"" \
"" \
"grpc" \
"" \
"true"

echo kitchensink + hashicorp-vault
test \
"[bean-validation, cdi, ee-integration, ejb-lite, h2-driver, hashicorp-vault, jaxrs, jpa, jsf]==>ee-core-profile-server,ejb-lite,h2-driver,hashicorp-vault,jaxrs,jpa,jsf" \
"$WILDFLY_GLOW_DIR/examples/kitchensink.war" \
"" \
"" \
"hashicorp-vault" \
""

echo kitchensink + hashicorp-vault on preview
test \
"[bean-validation, cdi, ee-integration, ejb-lite, h2-driver, hashicorp-vault, jaxrs, jpa, jsf]==>ee-core-profile-server,ejb-lite,hashicorp-vault,h2-driver,jaxrs,jpa,jsf" \
"$WILDFLY_GLOW_DIR/examples/kitchensink.war" \
"" \
"" \
"hashicorp-vault" \
"" \
"true"

echo graphql
test \
"[cdi, microprofile-config, microprofile-graphql]==>ee-core-profile-server,microprofile-graphql" \
"tests/war/quickstart-graphql.war"

echo todo-backend
test \
"[cdi, datasources, ejb-lite, jaxrs, jpa, postgresql-datasource, postgresql-driver, transactions]==>ee-core-profile-server,ejb-lite,jaxrs,jpa,postgresql-datasource" \
"tests/war/todo-backend.war" \
"" \
"" \
"postgresql" \
""

echo todo-backend preview
test \
"[cdi, datasources, ejb-lite, jaxrs, jpa, postgresql-datasource, postgresql-driver, transactions]==>ee-core-profile-server,ejb-lite,jaxrs,jpa,postgresql-datasource" \
"tests/war/todo-backend.war" \
"" \
"" \
"postgresql" \
"" \
"true"

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


### Incubating space

echo Incubating ai feature-pack
test \
"[ai, cdi, chat-memory-provider, default-embedding-content-retriever, ee-integration, jaxrs, ollama-chat-model, ollama-streaming-chat-model, servlet]==>ee-core-profile-server,chat-memory-provider,default-embedding-content-retriever,jaxrs,ollama-chat-model,ollama-streaming-chat-model" \
"tests/war/webchat.war" \
"" \
"" \
"" \
"" \
"" \
incubating


echo Incubating ai feature-pack preview
test \
"[ai, cdi, chat-memory-provider, default-embedding-content-retriever, ee-integration, jaxrs, ollama-chat-model, ollama-streaming-chat-model, servlet]==>ee-core-profile-server,chat-memory-provider,default-embedding-content-retriever,jaxrs,ollama-chat-model,ollama-streaming-chat-model" \
"tests/war/webchat.war" \
"" \
"" \
"" \
"" \
"true" \
incubating

echo Incubating ai feature-pack with opentelemetry support.
test \
"[ai, cdi, chat-memory-provider, default-embedding-content-retriever, ee-integration, jaxrs, ollama-chat-model, ollama-streaming-chat-model, opentelemetry, servlet]==>ee-core-profile-server,chat-memory-provider,default-embedding-content-retriever,jaxrs,ollama-chat-model,ollama-streaming-chat-model,opentelemetry" \
"tests/war/webchat-opentelemetry.war" \
"" \
"" \
"" \
"" \
"" \
incubating

if [ "$test_failure" -eq 1 ]; then
  echo "There were test failures! See the above output for details."
  exit 1
else
  echo "All $test_count tests passed!"
fi
