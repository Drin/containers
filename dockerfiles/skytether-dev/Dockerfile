# ------------------------------
# [Stage] skytether-devbase

# >> Image preamble
# Use debian as base to be portable to various platforms
FROM debian:stable-20240408-slim AS skytether-devbase

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
RUN apt install -y -V libbrotli-dev          \
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
ENV INSTALL_PREFIX="/usr/local/lib/skytether-tools"
COPY <<-CUSTOM_LD_CONF /etc/ld.so.conf.d/skytether.conf
  ${INSTALL_PREFIX}
CUSTOM_LD_CONF

WORKDIR "/workspace"

#   |> Build and install Arrow (need to build with substrait)
ENV ARROW_REPO_URI="https://github.com/apache/arrow.git"
ENV ARROW_REPO_TAG="apache-arrow-15.0.2"
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


#   |> Build and install duckdb (built with customized substrait extension)
ENV DUCKSTRAIT_REPO_URI="https://github.com/drin/duckdb-substrait.git"
ENV DUCKSTRAIT_SRC_DIR="/workspace/tools/duckdb-substrait"
ENV DUCKSTRAIT_BLD_DIR="/workspace/builds/duckdb-substrait"
ENV DUCKSTRAIT_REPO_TAG="v0.10.1"

RUN    mkdir -p "${DUCKSTRAIT_SRC_DIR}" "${DUCKSTRAIT_BLD_DIR}"    \
    && git clone --branch ${DUCKSTRAIT_REPO_TAG}                   \
                 --recursive                                       \
                 -- ${DUCKSTRAIT_REPO_URI} "${DUCKSTRAIT_SRC_DIR}"

# Use clang because gcc has trouble type casting to `FunctionData`
RUN env CC=clang CXX=clang++                                                            \
    cmake -S "${DUCKSTRAIT_SRC_DIR}/duckdb"                                             \
          -B "${DUCKSTRAIT_BLD_DIR}"                                                    \
          -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"                                    \
          -DCMAKE_BUILD_TYPE=Release                                                    \
          -DEXTENSION_STATIC_BUILD=1                                                    \
          -DBUILD_EXTENSIONS="tpch;json"                                                \
          -DDUCKDB_EXTENSION_NAMES="substrait"                                          \
          -DDUCKDB_EXTENSION_SUBSTRAIT_SHOULD_LINK=1                                    \
          -DDUCKDB_EXTENSION_SUBSTRAIT_LOAD_TESTS=1                                     \
          -DDUCKDB_EXTENSION_SUBSTRAIT_PATH="${DUCKSTRAIT_SRC_DIR}"                     \
          -DDUCKDB_EXTENSION_SUBSTRAIT_TEST_PATH="${DUCKSTRAIT_SRC_DIR}/test"           \
          -DDUCKDB_EXTENSION_SUBSTRAIT_INCLUDE_PATH="${DUCKSTRAIT_SRC_DIR}/src/include" \
          -GNinja

RUN    cmake --build   "${DUCKSTRAIT_BLD_DIR}" --config Release \
    && cmake --install "${DUCKSTRAIT_BLD_DIR}"


# ------------------------------
# [Stage] skytether-devenv

# >> Image preamble
FROM skytether-devbase

COPY --from=skytether-devtools /etc/ld.so.conf.d/skytether.conf /etc/ld.so.conf.d/skytether.conf
COPY --from=skytether-devtools /usr/local/lib/skytether-tools   /usr/local/lib/skytether-tools

LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
LABEL       "name"="skytether-devenv"
LABEL    "version"="0.0.1"

COPY  dotfiles/bash_environment "${HOME}/.bash_environment"
COPY  dotfiles/bash_aliases     "${HOME}/.bash_aliases"
COPY  dotfiles/bashrc           "${HOME}/.bashrc"
COPY  dotfiles/vimrc            "${HOME}/.vimrc"
