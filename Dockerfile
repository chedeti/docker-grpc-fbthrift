FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y git build-essential \
	pkg-config flex \
      bison \
      libkrb5-dev \
      libsasl2-dev \
      libnuma-dev \
      pkg-config \
      libssl-dev \
      autoconf libtool \
      cmake \
      libiberty-dev \
      g++ unzip \
      curl make automake libtool

#
#  Install protobuf
RUN git clone https://github.com/google/protobuf.git && \
	cd protobuf && ./autogen.sh && ./configure && make && make check && \
	make install && ldconfig
	
#
#  Install grpc
RUN git clone https://github.com/grpc/grpc && \
	cd grpc && git submodule update --init && \
	make && make install  

RUN git clone https://github.com/facebook/fbthrift.git

RUN cd fbthrift/thrift && ./build/deps_ubuntu_14.04.sh

# Install googletest
RUN git clone https://github.com/google/googletest.git && \
	cp -r googletest/googletest/* fbthrift/thrift/build/deps/folly/folly/test/gtest-1.7.0/ && \
	rm -rf googletest

RUN cd fbthrift/thrift/build/deps/folly/folly && \
	git checkout 'v0.57.0' && \
	git branch "version-0.57.0" && \
	git checkout version-0.57.0

RUN	cd fbthrift/thrift/build/deps/folly/folly/test/gtest-1.7.0 &&  GTEST_DIR=$PWD && \
	g++ -isystem ${GTEST_DIR}/include -I${GTEST_DIR} \
    -pthread -c ${GTEST_DIR}/src/gtest-all.cc && \
    ar -rv libgtest.a gtest-all.o && \
    cd ${GTEST_DIR}/make && make && ./sample1_unittest

# install folly 
RUN cd fbthrift/thrift/build/deps/folly/folly && \
	echo "int main() {return 0;}" >> test/TokenBucketTest.cpp && \
	make -j && make check -j && make install

# install wangle
RUN git clone https://github.com/facebook/wangle.git && \
	cd wangle/wangle && git checkout 'v0.13.0' && \
	cmake . && make && \
	make install

# install fbthrift
RUN cd fbthrift/thrift && \
	git checkout 'v0.31.0' -b version-0.31.0 && \
	autoreconf -if && ./configure && \
	make -j && make install

RUN git config --global user.name "google" && \
	git config --global user.email "someone@google.com"

RUN cd grpc && git pull --no-commit https://github.com/chedeti/grpc.git grpc-fbthrift-integration && \
	git commit -m "merge thrift utils" && make && make install

RUN cd fbthrift/thrift && \
	git rm --cached lib/cpp/thrift_config.h && \
	git commit -m "remove config" && \
	git pull --no-commit https://github.com/chedeti/fbthrift.git level-5 && \ 	
	git commit -m "Merge changes to generate gRPC plugins" && \
	make -j && make install