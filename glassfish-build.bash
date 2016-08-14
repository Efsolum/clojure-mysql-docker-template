#!/usr/bin/env bash
set -e

[ -f './project.bash' ] && source './project.bash'

PROJECT_NAME=${PROJECT_NAME:-'project'}

ALPINE_VERSION=${ALPINE_VERSION:-'3.4'}

JAVA_MINOR_VERSION=${JAVA_MINOR_VERSION:-'8'}
JAVA_VERSION=${JAVA_VERSION:-"1.${JAVA_MINOR_VERSION}"}

GLASSHFISH_MAJOR_VERSION=${GLASSHFISH_MAJOR_VERSION:-'4'}
GLASSHFISH_VERSION=${GLASSHFISH_VERSION:-"${GLASSHFISH_MAJOR_VERSION}.1"}
GLASSFISH_SHA256=${GLASSFISH_SHA256:-"3edc5fc72b8be241a53eae83c22f274479d70e15bdfba7ba2302da5260f23e9d"}

CONTAINER_USER=${CONTAINER_USER:-developer}
TEMP_DIR=$(mktemp --directory glassfish-build-XXXXXXXX)

docker_end() {
		exit=$?

		echo 'Cleaning up'
		rm -r $TEMP_DIR

		exit $exit;
}

trap docker_end EXIT SIGINT SIGTERM

cat <<EOF > $TEMP_DIR/Dockerfile
FROM alpine:${ALPINE_VERSION}
MAINTAINER 'Matthew Jordan <matthewjordandevops@yandex.com>'

ENV LANG en_US.UTF-8
ENV SSL_CERT_DIR /etc/ssl/certs
ENV JAVA_HOME /usr/lib/jvm/java-1.${JAVA_MINOR_VERSION}-openjdk
ENV GLASSFISH_HOME /usr/local/glassfish-${GLASSHFISH_VERSION}
ENV PATH "\${GLASSFISH_HOME}/bin:\${JAVA_HOME}/bin:\$PATH"

RUN adduser -u $(id -u $USER) -Ds /bin/bash $CONTAINER_USER

COPY apk-install.sh /usr/local/bin/apk-install.sh
RUN chmod u+x /usr/local/bin/apk-install.sh
RUN apk-install.sh

RUN which java && java -version
RUN which javac && javac -version

COPY glassfish-build.bash /usr/local/bin/glassfish-build.bash
RUN chmod u+x /usr/local/bin/glassfish-build.bash
RUN glassfish-build.bash
RUN chown -R ${CONTAINER_USER}:${CONTAINER_USER} \${GLASSFISH_HOME}

COPY change-admin-password.sh /usr/local/bin/change-admin-password.sh
RUN chmod ugo+x /usr/local/bin/change-admin-password.sh

USER $CONTAINER_USER
WORKDIR /home/$CONTAINER_USER

# 4848 (administration), 8080 (HTTP listener), 8181 (HTTPS listener), 9009 (JPDA debug port)
EXPOSE 4848 8080 8181 9009
CMD sh -c 'kill -STOP \$$'
EOF

cat <<EOF >> $TEMP_DIR/change-admin-password.sh
#!/usr/bin/expect

set password [lindex $argv 0]

spawn asadmin --user admin change-admin-password
expect "password"
send "\n"
expect "password"
send "$password\n"
expect "password"
send "$password\n"
expect eof
exit
EOF

cat <<EOF >> ${TEMP_DIR}/apk-install.sh
#!/usr/bin/env sh
set -eo pipefail

apk update
apk add \
			bash \
			ca-certificates \
			expect \
			git \
			openjdk${JAVA_MINOR_VERSION} \
			openjdk${JAVA_MINOR_VERSION}-jre \
			openssl \
			python \
			sudo \
			wget \
		&& echo 'End of package(s) installation.'

echo 'Cleaning up apks'
rm -rf '/var/cache/apk/*'
EOF

cat <<EOF >> $TEMP_DIR/glassfish-build.bash
#!/usr/bin/env bash
set -eo pipefail

mkdir -v /tmp/glassfish-build
cd /tmp/glassfish-build

wget "http://download.java.net/glassfish/${GLASSHFISH_VERSION}/release/glassfish-${GLASSHFISH_VERSION}.zip"
sha256sum "glassfish-${GLASSHFISH_VERSION}.zip" | grep "${GLASSFISH_SHA256}"

unzip glassfish-4.1.zip
mv glassfish${GLASSHFISH_MAJOR_VERSION} \${GLASSFISH_HOME}
cd /
rm -vr /tmp/glassfish-build

chmod +x \${GLASSFISH_HOME}/bin/*
EOF

docker build \
			 --no-cache=false \
			 --tag "${PROJECT_NAME}/glassfish-${JAVA_VERSION}-${GLASSHFISH_VERSION}:latest" \
			 $TEMP_DIR
docker tag \
			 "${PROJECT_NAME}/glassfish-${JAVA_VERSION}-${GLASSHFISH_VERSION}:latest" \
			 "${PROJECT_NAME}/glassfish-${JAVA_VERSION}-${GLASSHFISH_VERSION}:$(date +%s)"
