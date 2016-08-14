#!/usr/bin/env bash
set -e

[ -f './project.bash' ] && source './project.bash'

PROJECT_NAME=${PROJECT_NAME:-'project'}

JAVA_MINOR_VERSION=${JAVA_MINOR_VERSION:-8}
JAVA_VERSION=${JAVA_VERSION:-"1.${JAVA_MINOR_VERSION}"}

LEININGEN_VERSION='2.6.1'

WILDFLY_RELEASE='Final'
WILDFLY_VERSION='10.0.0'
WILDFLY_FULL_VERSION="${WILDFLY_VERSION}.${WILDFLY_RELEASE}"

# GLASSHFISH_MAJOR_VERSION=${GLASSHFISH_MAJOR_VERSION:-4}
# GLASSHFISH_VERSION=${GLASSHFISH_VERSION:-"${GLASSHFISH_MAJOR_VERSION}.1"}

NODE_VERSION=${NODE_VERSION:-'6.2.0'}

DATABASE_USER=${DATABASE_USER:-'app'}
DATABASE_PASS=${DATABASE_PASS:-'password'}

docker_err() {
		exit=$?

		echo '/nStoping containers'
		docker stop mysql-dbms java-dev node-assets glassfish-web

		exit $exit;
}

trap docker_err ERR

docker run \
			 --detach=true \
			 --name='mysql-dbms' \
			 --env="DATABASE_USER=${DATABASE_USER}" \
			 --env="DATABASE_PASS=${DATABASE_PASS}" \
			 "${PROJECT_NAME}/mysql-dbms:latest"

docker run \
			 --detach=true \
			 --name='clojure-dev' \
			 --volume="$(dirname $(pwd))/src:/var/www/projects" \
			 --publish='3000:3000' \
			 "${PROJECT_NAME}/clojure-leiningen-${LEININGEN_VERSION}:latest"

docker run \
			 --detach=true \
			 --name='node-assets' \
			 --volume="$(dirname $(pwd))/src:/var/www/projects" \
			 "${PROJECT_NAME}/node-${NODE_VERSION}:latest"

# 4848 (administration), 8080 (HTTP listener), 8181 (HTTPS listener), 9009 (JPDA debug port)
# docker run \
# 			 --detach=true \
# 			 --name='glassfish-web' \
# 			 --publish='8080:8080' \
# 			 --publish='8181:8181' \
# 			 --publish='9009:9009' \
# 			 --publish='4848:4848' \
# 			 "${PROJECT_NAME}/glassfish-${JAVA_VERSION}-${GLASSHFISH_VERSION}:latest"

# 9990 (administration), 8080 (HTTP listener), 8181 (HTTPS listener), 9009 (JPDA debug port)
docker run \
			 --detach=true \
			 --name='wildfly-web' \
			 --publish='8080:8080' \
			 --publish='8443:8443' \
			 --publish='9009:9009' \
			 --publish='9990:9990' \
			 "${PROJECT_NAME}/wildfly-${JAVA_VERSION}-${WILDFLY_VERSION}:latest"
