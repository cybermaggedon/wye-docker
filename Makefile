
PACKAGE=wye
VERSION=0.04
GIT_VERSION=v0.04

FEDORA_FILES =  RPM/RPMS/x86_64/${PACKAGE}-${VERSION}-1.fc24.x86_64.rpm
FEDORA_FILES += RPM/RPMS/x86_64/${PACKAGE}-debuginfo-${VERSION}-1.fc24.x86_64.rpm
FEDORA_FILES += ${PACKAGE}-${VERSION}.tar.gz
FEDORA_FILES += RPM/SRPMS/${PACKAGE}-${VERSION}-1.fc24.src.rpm

DEBIAN_FILES = ${PACKAGE}_${VERSION}-1_amd64.deb

UBUNTU_FILES = ${PACKAGE}_${VERSION}-1_amd64.deb

# sudo not needed if I'm in the docker group
SUDO=

all: product debian fedora ubuntu container

product:
	mkdir product

debian:
	${SUDO} docker build ${BUILD_ARGS} -t ${PACKAGE}-debian-dev \
		-f Dockerfile.debian.dev .
	${SUDO} docker build ${BUILD_ARGS} -t ${PACKAGE}-debian-build \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		-f Dockerfile.debian.build .
	id=$$(${SUDO} docker run -d ${PACKAGE}-debian-build sleep 180); \
	dir=/usr/local/src/${PACKAGE}; \
	for file in ${DEBIAN_FILES}; do \
		bn=$$(basename $$file); \
		${SUDO} docker cp $${id}:$${dir}/$${file} product/debian-$${bn}; \
	done; \
	${SUDO} docker rm -f $${id}

fedora:
	${SUDO} docker build ${BUILD_ARGS} -t ${PACKAGE}-fedora-dev \
		-f Dockerfile.fedora.dev .
	${SUDO} docker build ${BUILD_ARGS} -t ${PACKAGE}-fedora-build \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		-f Dockerfile.fedora.build .
	id=$$(${SUDO} docker run -d ${PACKAGE}-fedora-build sleep 180); \
	dir=/usr/local/src/${PACKAGE}; \
	for file in ${FEDORA_FILES}; do \
		bn=$$(basename $$file); \
		${SUDO} docker cp $${id}:$${dir}/$${file} product/fedora-$${bn}; \
	done; \
	${SUDO} docker rm -f $${id}
	mv -f product/fedora-${PACKAGE}-${VERSION}.tar.gz product/${PACKAGE}-${VERSION}.tar.gz
	mv -f product/fedora-${PACKAGE}-${VERSION}-1.fc24.src.rpm product/${PACKAGE}-${VERSION}-1.src.rpm

ubuntu:
	${SUDO} docker build ${BUILD_ARGS} -t ${PACKAGE}-ubuntu-dev \
		-f Dockerfile.ubuntu.dev .
	${SUDO} docker build ${BUILD_ARGS} -t ${PACKAGE}-ubuntu-build \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		-f Dockerfile.ubuntu.build .
	id=$$(${SUDO} docker run -d ${PACKAGE}-ubuntu-build sleep 180); \
	dir=/usr/local/src/${PACKAGE}; \
	for file in ${UBUNTU_FILES}; do \
		bn=$$(basename $$file); \
		${SUDO} docker cp $${id}:$${dir}/$${file} product/ubuntu-$${bn}; \
	done; \
	${SUDO} docker rm -f $${id}

container:
	${SUDO} docker build ${BUILD_ARGS} -t ${PACKAGE} \
		--build-arg VERSION=${VERSION} \
		-f Dockerfile.${PACKAGE}.deploy .
	${SUDO} docker tag ${PACKAGE} docker.io/cybermaggedon/${PACKAGE}:${VERSION}
	${SUDO} docker tag ${PACKAGE} docker.io/cybermaggedon/${PACKAGE}:latest

push:
	${SUDO} docker push docker.io/cybermaggedon/${PACKAGE}:${VERSION}
	${SUDO} docker push docker.io/cybermaggedon/${PACKAGE}:latest

