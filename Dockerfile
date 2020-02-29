FROM centos/s2i-base-centos7

MAINTAINER Anton Hughes anton.hughes@priceinsight.trade

ENV BUILDER_VERSION 2.0

ARG TF_SERVING_PORT=6006
ARG AUTOCONF_VERSION=2.69
ARG AUTOMAKE_VERSION=1.16
ARG TF_SERVING_PACKAGE=https://github.com/sub-mod/mnist-app/releases/download/2017_tensorflow_model_server/tensorflow_model_server
ENV TF_SERVING_PACKAGE $TF_SERVING_PACKAGE

LABEL io.k8s.description="Tensorflow serving builder" \
      io.k8s.display-name="tensorflow serving builder" \
      io.openshift.expose-services="6006:http" \
      io.openshift.tags="tensorflow"
      
ARG TF_SERVING_VERSION_GIT_BRANCH=master
ARG TF_SERVING_VERSION_GIT_COMMIT=head


LABEL tensorflow_serving_github_branchtag=${TF_SERVING_VERSION_GIT_BRANCH}
LABEL tensorflow_serving_github_commit=${TF_SERVING_VERSION_GIT_COMMIT}


RUN yum install -y epel-release centos-release-scl devtoolset-8 && source scl_source enable devtoolset-8
#RUN scl enable devtoolset-7 bash
#RUN source scl_source enable devtoolset-8
RUN scl enable devtoolset-8 bash

ENV HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:/opt/rh/devtoolset-8/root/usr/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#ENV CC=/opt/rh/devtoolset-8/root/usr/bin/gcc
#ENV CXX=/opt/rh/devtoolset-/root/usr/bin/g++
#ENV GCC_VERSION=9.2.0
#RUN yum -y update && yum -y install bzip2 wget gcc gcc-c++ gmp-devel mpfr-devel libmpc-devel make
#RUN gcc --version
#RUN wget http://gnu.mirror.constant.com/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz && tar zxf gcc-$GCC_VERSION.tar.gz \
#	&& mkdir gcc-build \
#	&& cd gcc-build \
#	&& ../gcc-$GCC_VERSION/configure --enable-languages=c,c++ --disable-multilib \
#	&& make -j$(nproc) \
#	&& make install \
#	&& gcc --version \
#	&& cd ..\
#	&& rm -rf gcc-build


RUN yum install -y tree which wget devtoolset-8-toolchain \
	python3 \
        "Development Tools" \
        ca-certificates \
        curl \
	libtool \
        git \
        curl-devel \
        freetype-devel \
        libpng-devel \
        zeromq-devel \
        mlocate \
        java-1.8.0-openjdk \
        pkg-config \
        python-devel \
        swig \
        unzip \
        wget \
        zip \
        zlib1g-devel \
        python3-distutils \
	&& yum clean all -y 
#	&& wget $TF_SERVING_PACKAGE -P /opt/app-root/ \
#	&& chmod 777 /opt/app-root/tensorflow_model_server
RUN ln -s /opt/rh/devtoolset-8/root/usr/bin/g++ /usr/local/bin/g++
RUN which gcc
RUN gcc -v





COPY ./s2i/bin/ /usr/libexec/s2i

#Drop the root user and make the content of /opt/app-root owned by user 1001
## RUN chown -R 1001:1001 /opt/app-root

# This default user is created in the openshift/base-centos7 image
USER 1001
## COPY ./tensorflow_model_server /opt/app-root/tensorflow_model_server


EXPOSE $TF_SERVING_PORT
EXPOSE 8500

# TODO: Set the default CMD for the image
CMD ["/usr/libexec/s2i/usage"]
