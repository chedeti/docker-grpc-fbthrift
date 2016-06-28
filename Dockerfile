# Copyright 2016, Google Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

FROM ubuntu:14.04

RUN apt-get update && \
	apt-get install -y \
	git build-essential \
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

# Configure Git
RUN git config --global user.name "grpc" && \
	git config --global user.email "grpc@google.com"

# Install protobuf
RUN git clone https://github.com/google/protobuf.git && \
	cd protobuf && ./autogen.sh && ./configure && make -j && \
	make check -j && make install && ldconfig

# Install grpc
RUN git clone https://github.com/grpc/grpc && \
	cd grpc && git submodule update --init && \
	git pull --no-commit https://github.com/chedeti/grpc.git \
	grpc-fbthrift-integration && \
	git commit -m "merge thrift utils" && \
	make -j && make install

RUN git clone https://github.com/facebook/fbthrift.git && \
	cd fbthrift/thrift && ./build/deps_ubuntu_14.04.sh

RUN git clone https://github.com/google/googletest.git && \
	cp -r googletest/googletest/* fbthrift/thrift/build/deps/folly/folly/test/gtest-1.7.0/

# Checkout to FOLLY Version 0.57.0
RUN cd fbthrift/thrift/build/deps/folly/folly && \
	git checkout 'v0.57.0' -b version-0.57.0

# Install Google Test
RUN	cd fbthrift/thrift/build/deps/folly/folly/test/gtest-1.7.0 &&  GTEST_DIR=$PWD && \
	g++ -isystem ${GTEST_DIR}/include -I${GTEST_DIR} \
	-pthread -c ${GTEST_DIR}/src/gtest-all.cc && \
	ar -rv libgtest.a gtest-all.o && \
	cd ${GTEST_DIR}/make && make -j && ./sample1_unittest

# Install Folly
RUN cd fbthrift/thrift/build/deps/folly/folly && \
	echo "int main() {return 0;}" >> test/TokenBucketTest.cpp && \
	make -j && make check -j && make install

# Install wangle
RUN git clone https://github.com/facebook/wangle.git && \
	cd wangle/wangle && git checkout 'v0.13.0' -b "version-0.13.0" && \
	cmake . && make -j && \
	make install

# Install Fbthrift
RUN cd fbthrift/thrift && \
	git checkout 'v0.31.0' -b version-0.31.0 && \
	git pull --no-commit https://github.com/chedeti/fbthrift.git level-5 && \
	autoreconf -if && ./configure && \
	make -j && make install