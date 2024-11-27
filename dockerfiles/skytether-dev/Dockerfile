# ------------------------------
# [Stage] skytether-devbase

# >> Image preamble
# Use debian as base to be portable to various platforms
FROM debian:stable-20241111-slim AS skytether-devbase

LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
LABEL       "name"="skytether-devbase"
LABEL    "version"="0.0.1"


# >> System packages
RUN apt update

# general dependencies
RUN apt install -y -V libssl-dev           \
                      libcurl4-openssl-dev \
                      lsb-release          \
                      ca-certificates      \
                      wget                 \
                      vim                  \
                      git                  \
                      git-lfs              \
                      uuid-dev             \
                      python3-poetry

# compilers and build tools
RUN apt install -y -V llvm         \
                      lldb         \
                      clang        \
                      clang-tools  \
                      clang-format \
                      clang-tidy   \
                      gcc          \
                      g++          \
                      ninja-build  \
                      cmake        \
                      meson

# external deps for Arrow
RUN apt install -y -V libboost-dev           \
                      libbrotli-dev          \
                      liblz4-dev             \
                      libbz2-dev             \
                      zlib1g-dev             \
                      libsnappy-dev          \
                      libutf8proc-dev        \
                      libthrift-dev          \
                      libgoogle-glog-dev     \
                      libgoogle-glog0v6      \
                      brotli                 \
                      lz4                    \
                      bzip2                  \
                      zstd                   \
                      rapidjson-dev

# protobuf and grpc deps for Substrait and Arrow Flight
RUN apt install -y -V libprotobuf-dev        \
                      libprotoc-dev          \
                      libgrpc++-dev          \
                      libgrpc++1.51          \
                      libgrpc-dev            \
                      libgrpc29              \
                      libc-ares-dev          \
                      libc-ares2             \
                      protobuf-compiler      \
                      protobuf-compiler-grpc \
                      rpcsvc-proto


# ------------------------------
# [Stage] skytether-devtools
# NOTE: this stage needs more than 2G of memory

# >> Image preamble
FROM skytether-devbase AS skytether-devtools

LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
LABEL       "name"="skytether-devtools"
LABEL    "version"="0.0.1"


# >> Install tools

# set an installation prefix, then point a custom ld.so.conf file to it
ENV INSTALL_PREFIX="/usr/local/skytether-tools"
COPY <<-CUSTOM_LD_CONF /etc/ld.so.conf.d/skytether.conf
${INSTALL_PREFIX}/lib
CUSTOM_LD_CONF


#   |> Build and install Arrow (need to build with substrait)
WORKDIR "/workspace"

ENV ARROW_REPO_URI="https://github.com/apache/arrow.git"
ENV ARROW_REPO_TAG="apache-arrow-18.0.0"
ENV ARROW_SRC_DIR="/workspace/tools/${ARROW_REPO_TAG}"
ENV ARROW_BLD_DIR="/workspace/builds/${ARROW_REPO_TAG}"

RUN    mkdir -p "${ARROW_SRC_DIR}" "${ARROW_BLD_DIR}"    \
    && git clone --branch ${ARROW_REPO_TAG}              \
                 -- ${ARROW_REPO_URI} "${ARROW_SRC_DIR}"

# Later, we might want to re-enable: GCS, S3
RUN cmake -S "${ARROW_SRC_DIR}/cpp"                \
          -B "${ARROW_BLD_DIR}"                    \
          -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
          -DAWSSDK_SOURCE=BUNDLED                  \
          -DARROW_ACERO=ON                         \
          -DARROW_COMPUTE=ON                       \
          -DARROW_CSV=ON                           \
          -DARROW_DATASET=ON                       \
          -DARROW_FILESYSTEM=ON                    \
          -DARROW_FLIGHT=ON                        \
          -DARROW_FLIGHT_SQL=ON                    \
          -DARROW_GANDIVA=ON                       \
          -DARROW_GCS=OFF                          \
          -DARROW_HDFS=ON                          \
          -DARROW_JSON=ON                          \
          -DARROW_ORC=ON                           \
          -DARROW_PARQUET=ON                       \
          -DARROW_PROTOBUF_USE_SHARED=ON           \
          -DARROW_S3=OFF                           \
          -DARROW_SUBSTRAIT=ON                     \
          -DARROW_WITH_BZ2=ON                      \
          -DARROW_WITH_ZLIB=ON                     \
          -DARROW_WITH_ZSTD=ON                     \
          -DARROW_WITH_LZ4=ON                      \
          -DARROW_WITH_SNAPPY=ON                   \
          -DARROW_WITH_BROTLI=ON                   \
          -DARROW_WITH_UTF8PROC=ON                 \
          -DPARQUET_BUILD_EXECUTABLES=ON           \
          -GNinja

RUN    cmake --build   "${ARROW_BLD_DIR}" \
    && cmake --install "${ARROW_BLD_DIR}"


#   |> Build and install libmohair-substrait
WORKDIR "/workspace"

ENV PROTOCOL_REPO_URI="https://github.com/drin/mohair-substrait.git"
ENV PROTOCOL_REPO_TAG="v1.0.0"
ENV PROTOCOL_BLD_DIR="/workspace/builds/mohair-substrait"
ENV PROTOCOL_SRC_DIR="/workspace/tools/mohair-substrait"

RUN    mkdir -p "${PROTOCOL_SRC_DIR}" "${PROTOCOL_BLD_DIR}"    \
    && git clone --branch ${PROTOCOL_REPO_TAG}                 \
                 --recursive                                   \
                 -- ${PROTOCOL_REPO_URI} "${PROTOCOL_SRC_DIR}"

WORKDIR "${PROTOCOL_SRC_DIR}"
meson setup "${PROTOCOL_BLD_DIR}"
meson configure -D default_library=both "${PROTOCOL_BLD_DIR}"

meson compile -C "${PROTOCOL_BLD_DIR}"
meson install -C "${PROTOCOL_BLD_DIR}"


#   |> Build and install duckdb (built with customized substrait extension)
WORKDIR "/workspace"

ENV SKYDUCK_REPO_URI="https://github.com/drin/duckdb-skytether.git"
ENV SKYDUCK_REPO_TAG="v0.8.1"
ENV SKYDUCK_BLD_DIR="/workspace/builds/duckdb-skytether"
ENV SKYDUCK_SRC_DIR="/workspace/tools/duckdb-skytether"

ENV DUCKSTRAIT_SRC_DIR="${SKYDUCK_SRC_DIR}/subprojects/duckdb-substrait"
ENV DUCKARROW_SRC_DIR="${SKYDUCK_SRC_DIR}/subprojects/duckdb-arrow"

RUN    mkdir -p "${SKYDUCK_SRC_DIR}" "${SKYDUCK_BLD_DIR}"    \
    && git clone --branch ${SKYDUCK_REPO_TAG}                \
                 --recursive                                 \
                 -- ${SKYDUCK_REPO_URI} "${SKYDUCK_SRC_DIR}"

# Use clang because gcc has trouble type casting to `FunctionData`
ENV BUILD_TYPE="Release"
RUN env CC=clang CXX=clang++                                                            \
    cmake -S "${SKYDUCK_SRC_DIR}/subprojects/duckdb"                                    \
          -B "${SKYDUCK_BLD_DIR}"                                                       \
          -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"                                    \
          -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"                                            \
          -DEXTENSION_STATIC_BUILD=1                                                    \
          -DBUILD_EXTENSIONS="tpch;json"                                                \
          -DDUCKDB_EXTENSION_NAMES="substrait;arrow"                                    \
          -DDUCKDB_EXTENSION_SUBSTRAIT_SHOULD_LINK=1                                    \
          -DDUCKDB_EXTENSION_SUBSTRAIT_LOAD_TESTS=1                                     \
          -DDUCKDB_EXTENSION_SUBSTRAIT_PATH="${DUCKSTRAIT_SRC_DIR}"                     \
          -DDUCKDB_EXTENSION_SUBSTRAIT_TEST_PATH="${DUCKSTRAIT_SRC_DIR}/test"           \
          -DDUCKDB_EXTENSION_SUBSTRAIT_INCLUDE_PATH="${DUCKSTRAIT_SRC_DIR}/src/include" \
          -DDUCKDB_EXTENSION_ARROW_SHOULD_LINK=1                                        \
          -DDUCKDB_EXTENSION_ARROW_LOAD_TESTS=1                                         \
          -DDUCKDB_EXTENSION_ARROW_PATH="${DUCKARROW_SRC_DIR}"                          \
          -DDUCKDB_EXTENSION_ARROW_TEST_PATH="${DUCKARROW_SRC_DIR}/test"                \
          -DDUCKDB_EXTENSION_ARROW_INCLUDE_PATH="${DUCKARROW_SRC_DIR}/src/include"      \
          -GNinja

RUN    cmake --build   "${SKYDUCK_BLD_DIR}" --config "${BUILD_TYPE}" \
    && cmake --install "${SKYDUCK_BLD_DIR}"


#   |> Build and install mohair
WORKDIR "/workspace"

ENV MOHAIR_REPO_URI="https://github.com/drin/mohair.git"
ENV MOHAIR_REPO_TAG="v1.0.0"
ENV MOHAIR_BLD_DIR="/workspace/builds/mohair"
ENV MOHAIR_SRC_DIR="/workspace/tools/mohair"

RUN    mkdir -p "${MOHAIR_SRC_DIR}" "${MOHAIR_BLD_DIR}"    \
    && git clone --branch ${MOHAIR_REPO_TAG}               \
                 --recursive                               \
                 -- ${MOHAIR_REPO_URI} "${MOHAIR_SRC_DIR}"

WORKDIR "${MOHAIR_SRC_DIR}"
meson setup "${MOHAIR_BLD_DIR}"
meson configure -D default_library=both "${MOHAIR_BLD_DIR}"

meson compile -C "${MOHAIR_BLD_DIR}"
# meson install -C "${MOHAIR_BLD_DIR}"


# ------------------------------
# [Stage] skytether-devenv

# >> Image preamble
# FROM skytether-devbase
# 
# COPY --from=skytether-devtools /etc/ld.so.conf.d/skytether.conf /etc/ld.so.conf.d/skytether.conf
# COPY --from=skytether-devtools /usr/local/skytether-tools   /usr/local/skytether-tools
# 
# LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
# LABEL       "name"="skytether-devenv"
# LABEL    "version"="0.0.1"

ENV PKG_CONFIG_PATH="/usr/local/skytether-tools/lib/pkgconfig"
env CMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"

COPY  dotfiles/bash_environment "${HOME}/.bash_environment"
COPY  dotfiles/bash_aliases     "${HOME}/.bash_aliases"
COPY  dotfiles/bashrc           "${HOME}/.bashrc"
COPY  dotfiles/vimrc            "${HOME}/.vimrc"

WORKDIR "/workspace"

# Configure LFS to not automatically pull files
RUN git lfs install --skip-smudge

RUN git clone --branch "feat-duckdb-skytether" -- "https://github.com/drin/mohair"
RUN git clone "https://github.com/drin/mohair-experiments"

# Only pull an example Arrow file from LFS in mohair-experiments repo
WORKDIR "/workspace/mohair-experiments"
RUN     git lfs pull --include="resources/examples/1_1_1_1_1_500000.expression.arrow"
WORKDIR "/workspace"

