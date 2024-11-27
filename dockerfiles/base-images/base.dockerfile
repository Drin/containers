# ------------------------------
# [Stage] base image

# >> Image preamble
# Use debian as base to be portable to various platforms
FROM debian:stable-20241111-slim AS os-base

LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
LABEL       "name"="drin/skydev:base"
LABEL    "version"="0.1.0"


# >> System packages
#    NOTE: anything needed that is not here should be built from source

# general dependencies
RUN    apt update                             \
    && apt install -y -V libssl-dev           \
                         libcurl4-openssl-dev \
                         lsb-release          \
                         ca-certificates      \
                         wget                 \
                         vim                  \
                         git                  \
                         git-lfs              \
                         uuid-dev             \
                         python3-pip          \
                         python3-poetry

# compilers and build tools
RUN    apt update                     \
    && apt install -y -V llvm         \
                         lldb         \
                         clang        \
                         clang-tools  \
                         clang-format \
                         clang-tidy   \
                         gcc          \
                         g++          \
                         automake     \
                         autoconf     \
                         ninja-build  \
                         cmake

# external deps for Arrow
RUN    apt update                           \
    && apt install -y -V libboost-dev       \
                         libbrotli-dev      \
                         liblz4-dev         \
                         libbz2-dev         \
                         zlib1g-dev         \
                         libsnappy-dev      \
                         libutf8proc-dev    \
                         libthrift-dev      \
                         libgoogle-glog-dev \
                         libgoogle-glog0v6  \
                         brotli             \
                         lz4                \
                         bzip2              \
                         zstd               \
                         rapidjson-dev

# protobuf and grpc deps for Substrait and Arrow Flight
RUN    apt update                       \
    && apt install -y -V libc-ares-dev  \
                         libc-ares2     \
                         libtool        \
                         rpcsvc-proto   \
                         googletest     \
                         google-mock    \
                         libgtest-dev   \
                         libgmock-dev   \
                         libre2-dev     \
                         libsystemd-dev

# Packages we remove so that we can install from source
RUN    apt update                    \
    && apt remove -y libabsl20220623

