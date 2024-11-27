# ------------------------------
# [Stage] os-base

FROM drin/skydev:base AS os-base

LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
LABEL       "name"="drin/skydev:dev-base"
LABEL    "version"="20240722.0"


# ------------------------------
# [Stage] abseil-static

FROM os-base AS abseil-builder

ENV DEVTOOL_PREFIX="/usr/local/devtools"
WORKDIR "/workspace"

ENV RELEASE_FILENAME="20240722.0.tar.gz"
ENV RELEASE_URI="https://github.com/abseil/abseil-cpp/archive/refs/tags/${RELEASE_FILENAME}"
ENV RELEASE_CHECKSUM="f50e5ac311a81382da7fa75b97310e4b9006474f9560ac46f54a9967f07d4ae3"
ENV SOURCE_DIR="/workspace/abseil-cpp-20240722.0"
ENV BUILD_DIR="/workspace/build-dir"

RUN    wget "${RELEASE_URI}"          \
    && tar -xzf "${RELEASE_FILENAME}"

RUN cmake -S "${SOURCE_DIR}"                       \
          -B "${BUILD_DIR}"                        \
          -DCMAKE_INSTALL_PREFIX=${DEVTOOL_PREFIX} \
          -DCMAKE_PREFIX_PATH=${DEVTOOL_PREFIX}    \
          -DCMAKE_CXX_STANDARD=17                  \
          -DCMAKE_POSITION_INDEPENDENT_CODE=ON     \
          -DABSL_PROPAGATE_CXX_STD=ON              \
          -DBUILD_STATIC_LIBS=ON                   \
          -DABSL_ENABLE_INSTALL=ON                 \
          -DABSL_BUILD_TEST_HELPERS=ON             \
          -DABSL_USE_EXTERNAL_GOOGLETEST=ON        \
          -DABSL_FIND_GOOGLETEST=ON                \
          -GNinja

RUN cmake --build "${BUILD_DIR}" && cmake --install "${BUILD_DIR}"


# ------------------------------
# [Stage] protobuf-static

FROM os-base AS protobuf-builder

ENV DEVTOOL_PREFIX="/usr/local/devtools"
ENV RELEASE_FILENAME="protobuf-28.3.tar.gz"
ENV RELEASE_URI="https://github.com/protocolbuffers/protobuf/releases/download/v28.3/${RELEASE_FILENAME}"
ENV RELEASE_CHECKSUM="7c3ebd7aaedd86fa5dc479a0fda803f602caaf78d8aff7ce83b89e1b8ae7442a"
ENV SOURCE_DIR="/workspace/protobuf-28.3"
ENV BUILD_DIR="/workspace/build-dir"

# need to grab artifacts for dependencies
COPY --from=abseil-builder "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"

WORKDIR "/workspace"
RUN wget "${RELEASE_URI}" && tar -xzf "${RELEASE_FILENAME}"
RUN cmake -S "${SOURCE_DIR}"                       \
          -B "${BUILD_DIR}"                        \
          -DCMAKE_INSTALL_PREFIX=${DEVTOOL_PREFIX} \
          -DCMAKE_PREFIX_PATH=${DEVTOOL_PREFIX}    \
          -DCMAKE_CXX_STANDARD=17                  \
          -DCMAKE_POSITION_INDEPENDENT_CODE=ON     \
          -Dprotobuf_BUILD_SHARED_LIBS=OFF         \
          -Dprotobuf_BUILD_LIBPROTOC=ON            \
          -Dprotobuf_BUILD_TESTS=ON                \
          -Dprotobuf_USE_EXTERNAL_GTEST=ON         \
          -Dprotobuf_ABSL_PROVIDER=package         \
          -Dprotobuf_JSONCPP_PROVIDER=package      \
          -GNinja

RUN cmake --build "${BUILD_DIR}" && cmake --install "${BUILD_DIR}"


# ------------------------------
# [Stage] grpc

FROM os-base AS grpc-builder

ENV DEVTOOL_PREFIX="/usr/local/devtools"
ENV GRPC_REPO_URI="https://github.com/grpc/grpc.git"
ENV GRPC_REPO_TAG="v1.68.0"
ENV SOURCE_DIR="/workspace/grpc-${GRPC_REPO_TAG}"
ENV BUILD_DIR="/workspace/build-dir"

# need to grab artifacts for dependencies
COPY --from=abseil-builder   "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"
COPY --from=protobuf-builder "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"

WORKDIR "/workspace"
RUN    mkdir -p "${SOURCE_DIR}" "${BUILD_DIR}"       \
    && git clone --branch ${GRPC_REPO_TAG}           \
                 --recursive                         \
                 -- ${GRPC_REPO_URI} "${SOURCE_DIR}"

RUN cmake -S "${SOURCE_DIR}"                       \
          -B "${BUILD_DIR}"                        \
          -DCMAKE_INSTALL_PREFIX=${DEVTOOL_PREFIX} \
          -DCMAKE_PREFIX_PATH=${DEVTOOL_PREFIX}    \
          -DCMAKE_CXX_STANDARD=17                  \
          -DCMAKE_CXX_STANDARD_REQUIRED=TRUE       \
          -DBUILD_SHARED_LIBS=ON                   \
          -DgRPC_INSTALL=ON                        \
          -DgRPC_ABSL_PROVIDER=package             \
          -DgRPC_CARES_PROVIDER=package            \
          -DgRPC_PROTOBUF_PROVIDER=package         \
          -DgRPC_SSL_PROVIDER=package              \
          -DgRPC_ZLIB_PROVIDER=package             \
          -DgRPC_RE2_PROVIDER=package              \
          -GNinja

RUN cmake --build "${BUILD_DIR}" && cmake --install "${BUILD_DIR}"


# ------------------------------
# [Stage] apache-arrow-substrait

FROM os-base AS arrow-builder

ENV DEVTOOL_PREFIX="/usr/local/devtools"
ENV ARROW_REPO_URI="https://github.com/apache/arrow.git"
ENV ARROW_REPO_TAG="apache-arrow-18.0.0"
ENV SOURCE_DIR="/workspace/${ARROW_REPO_TAG}"
ENV BUILD_DIR="/workspace/build-dir"

WORKDIR "/workspace"
RUN    mkdir -p "${SOURCE_DIR}" "${BUILD_DIR}"        \
    && git clone --branch ${ARROW_REPO_TAG}           \
                 --recursive                          \
                 -- ${ARROW_REPO_URI} "${SOURCE_DIR}"

# NOTE: we set absl, protobuf, and gRPC to BUNDLED for simplicity
RUN cmake -S "${SOURCE_DIR}/cpp"                         \
          -B "${BUILD_DIR}"                              \
          -DCMAKE_INSTALL_PREFIX="${DEVTOOL_PREFIX}"     \
          -DCMAKE_PREFIX_PATH="${DEVTOOL_PREFIX}"        \
          -DARROW_INSTALL_NAME_RPATH=OFF                 \
          -DAWSSDK_SOURCE=BUNDLED                        \
          -Dabsl_SOURCE=BUNDLED                          \
          -DProtobuf_SOURCE=BUNDLED                      \
          -DgRPC_SOURCE=BUNDLED                          \
          -DARROW_PROTOBUF_USE_SHARED=OFF                \
          -DARROW_ACERO=ON                               \
          -DARROW_COMPUTE=ON                             \
          -DARROW_CSV=ON                                 \
          -DARROW_DATASET=ON                             \
          -DARROW_FILESYSTEM=ON                          \
          -DARROW_FLIGHT=ON                              \
          -DARROW_FLIGHT_SQL=OFF                         \
          -DARROW_GANDIVA=OFF                            \
          -DARROW_GCS=OFF                                \
          -DARROW_HDFS=OFF                               \
          -DARROW_JSON=OFF                               \
          -DARROW_ORC=OFF                                \
          -DARROW_PARQUET=ON                             \
          -DARROW_S3=OFF                                 \
          -DARROW_SUBSTRAIT=ON                           \
          -DARROW_WITH_BZ2=ON                            \
          -DARROW_WITH_ZLIB=ON                           \
          -DARROW_WITH_ZSTD=ON                           \
          -DARROW_WITH_LZ4=ON                            \
          -DARROW_WITH_SNAPPY=ON                         \
          -DARROW_WITH_BROTLI=ON                         \
          -DARROW_WITH_UTF8PROC=ON                       \
          -DPARQUET_BUILD_EXECUTABLES=ON                 \
          -GNinja
RUN cmake --build   "${BUILD_DIR}" && cmake --install "${BUILD_DIR}"


# ------------------------------
# [Stage] meson build system

FROM os-base AS meson-builder

ENV DEVTOOL_PREFIX="/usr/local/devtools"
ENV RELEASE_FILENAME="meson-1.6.0.tar.gz"
ENV RELEASE_URI="https://github.com/mesonbuild/meson/releases/download/1.6.0/${RELEASE_FILENAME}"

WORKDIR "/workspace"
RUN    wget "${RELEASE_URI}"                 \
    && tar -xzf "${RELEASE_FILENAME}"        \
    && mkdir -p "${DEVTOOL_PREFIX}"          \
    && mv "meson-1.6.0" "${DEVTOOL_PREFIX}/"


# ------------------------------
# [Stage] Final

FROM os-base AS dev-base

# define environment variables in this layer
ENV DEVTOOL_PREFIX="/usr/local/devtools"
ENV PKG_CONFIG_PATH="${DEVTOOL_PREFIX}/lib/pkgconfig"

# Point a custom ld.so.conf file to our custom install prefix
COPY <<-CUSTOM_LD_CONF /etc/ld.so.conf.d/devtools.conf
${DEVTOOL_PREFIX}/lib
CUSTOM_LD_CONF

# Point a simple bash script to meson to act as a facade
COPY <<-"MESON_CLI" /usr/bin/meson
#!/usr/bin/env bash
/usr/bin/env python3 "/usr/local/devtools/meson-1.6.0/meson.py" "$@"
MESON_CLI
RUN chmod u+x /usr/bin/meson

# Copy libraries from other layers into our final layer
COPY --from=abseil-builder   "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"
COPY --from=protobuf-builder "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"
COPY --from=grpc-builder     "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"
COPY --from=arrow-builder    "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"
COPY --from=meson-builder    "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"

