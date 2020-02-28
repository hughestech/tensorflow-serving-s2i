FROM centos/s2i-base-centos7

MAINTAINER Subin Modeel smodeel@redhat.com

ENV BUILDER_VERSION 2.0

ARG TF_SERVING_PORT=6006
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


RUN yum install -y epel-release
RUN yum install -y tree which wget \
        "Development Tools" 
        ca-certificates \
        curl \
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
	&& yum clean all -y \
	&& wget $TF_SERVING_PACKAGE -P /opt/app-root/ \
	&& chmod 777 /opt/app-root/tensorflow_model_server


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
