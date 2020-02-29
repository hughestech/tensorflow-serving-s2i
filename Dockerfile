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

WORKDIR ${HOME}

# Enable the SCL for all bash scripts.
ENV BASH_ENV=/opt/app-root/etc/scl_enable \
    ENV=/opt/app-root/etc/scl_enable \
    PROMPT_COMMAND=". /opt/app-root/etc/scl_enable"
    
    
RUN which gcc
RUN gcc -v


RUN curl -fSsL -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

RUN pip3 --no-cache-dir install glibc \
    future>=0.17.1 \
    grpcio \
    h5py \
    keras_applications>=1.0.8 \
    keras_preprocessing>=1.1.0 \
    mock \
    numpy \
    requests \
    --ignore-installed setuptools \
    --ignore-installed six
    
    
# Set up Bazel
ENV BAZEL_VERSION 1.2.1
WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download TF Serving sources (optionally at specific commit).
WORKDIR /tensorflow-serving
RUN git clone --recurse-submodules --branch=${TF_SERVING_VERSION_GIT_BRANCH} https://github.com/tensorflow/serving . && \
    git remote add upstream https://github.com/tensorflow/serving.git && \
    if [ "${TF_SERVING_VERSION_GIT_COMMIT}" != "head" ]; then git checkout ${TF_SERVING_VERSION_GIT_COMMIT} ; fi


#FROM base_build as binary_build
# Build, and install TensorFlow Serving
ARG TF_SERVING_BUILD_OPTIONS="--config=nativeopt"
RUN echo "Building with build options: ${TF_SERVING_BUILD_OPTIONS}"
#ARG TF_SERVING_BAZEL_OPTIONS="--cxxopt=\"-D_GLIBCXX_USE_CXX11_ABI=0\""
#ARG TF_SERVING_BAZEL_OPTIONS="--host_linkopt=-lm"
ARG TF_SERVING_BAZEL_OPTIONS=""
RUN echo "Building with Bazel options: ${TF_SERVING_BAZEL_OPTIONS}"

RUN bazel build --color=yes --curses=yes --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
    ${TF_SERVING_BAZEL_OPTIONS} \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    ${TF_SERVING_BUILD_OPTIONS} \
    tensorflow_serving/model_servers:tensorflow_model_server && \
    cp bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server \
    /usr/local/bin/

# Build and install TensorFlow Serving API
RUN bazel build --color=yes --curses=yes --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
    ${TF_SERVING_BAZEL_OPTIONS} \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    ${TF_SERVING_BUILD_OPTIONS} \
    tensorflow_serving/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow_serving/tools/pip_package/build_pip_package \
    /tmp/pip && \
    pip --no-cache-dir install --upgrade \
    /tmp/pip/tensorflow_serving_api-*.whl && \
    rm -rf /tmp/pip

# FROM binary_build as clean_build
# Clean up Bazel cache when done.
RUN bazel clean --expunge --color=yes && \
    rm -rf /root/.cache


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
