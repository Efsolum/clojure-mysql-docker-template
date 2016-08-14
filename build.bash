#!/usr/bin/env bash
set -e

PROJECT_NAME='project'

ALPINE_VERSION='3.4'

NODE_VERSION='6.2.0'

JAVA_MINOR_VERSION='8'
JAVA_VERSION="1.${JAVA_MINOR_VERSION}"

MAVEN_MAJOR_VERSION='3'
MAVEN_VERSION="${MAVEN_MAJOR_VERSION}.3.9"

GLASSHFISH_MAJOR_VERSION='4'
GLASSHFISH_VERSION="${GLASSHFISH_MAJOR_VERSION}.1"

MYSQL_MAJOR_VERSION=5.7

echo "==========> Building MySQL Image"
./mysql-build.bash

echo "==========> Building Wildfly Image"
./wildfly-build.bash

echo "==========> Building Clojure Image"
./clojure-build.bash

echo "==========> Building NodeJS Image"
./nodejs-build.bash
