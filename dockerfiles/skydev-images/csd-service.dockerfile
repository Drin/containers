# ------------------------------
# [Stage] skytether tools

FROM drin/skydev:dev-base AS os-base

LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
LABEL       "name"="drin/skydev:csengine"
LABEL    "version"="0.1.0"


# ------------------------------
# [Stage] mohair-substrait (mohair protocol)

FROM os-base AS protocol-builder

ENV DEVTOOL_PREFIX="/usr/local/devtools"
ENV PROTOCOL_REPO_URI="https://github.com/drin/mohair-substrait.git"
ENV PROTOCOL_REPO_TAG="v1.0.3"
ENV SOURCE_DIR="/workspace/mohair-substrait"
ENV BUILD_DIR="/workspace/build-dir"

WORKDIR "/workspace"

RUN mkdir -p "${SOURCE_DIR}" "${BUILD_DIR}"
RUN git clone --branch ${PROTOCOL_REPO_TAG}           \
              --recursive                             \
              -- ${PROTOCOL_REPO_URI} "${SOURCE_DIR}"

RUN meson setup --prefix            "${DEVTOOL_PREFIX}"               \
                --libdir            "lib"                             \
                --cmake-prefix-path "${DEVTOOL_PREFIX}"               \
                --pkg-config-path   "${DEVTOOL_PREFIX}/lib/pkgconfig" \
                --buildtype         "release"                         \
                --default-library   "shared"                          \
                "${BUILD_DIR}"                                        \
                "${SOURCE_DIR}"

RUN meson compile -C "${BUILD_DIR}"
RUN meson install -C "${BUILD_DIR}"


# ------------------------------
# [Stage] duckdb-skytether (execution engine)

FROM os-base AS engine-builder

# need to grab artifacts for dependencies
COPY --from=protocol-builder "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"

ENV DEVTOOL_PREFIX="/usr/local/devtools"
ENV SKYDUCK_REPO_URI="https://github.com/drin/duckdb-skytether.git"
ENV SKYDUCK_REPO_TAG="v0.8.3"

ENV SOURCE_DIR="/workspace/duckdb-skytether"
ENV DUCKDB_SRC_DIR="${SOURCE_DIR}/subprojects/duckdb"
ENV DUCKSTRAIT_SRC_DIR="${SOURCE_DIR}/subprojects/duckdb-substrait"
ENV DUCKARROW_SRC_DIR="${SOURCE_DIR}/subprojects/duckdb-arrow"
ENV BUILD_DIR="/workspace/build-dir"

# define environment variables in this layer
ENV PKG_CONFIG_PATH="${DEVTOOL_PREFIX}/lib/pkgconfig"
ENV PATH="${DEVTOOL_PREFIX}/bin:${PATH}"

# Point a custom ld.so.conf file to our custom install prefix
COPY <<-CUSTOM_LD_CONF /etc/ld.so.conf.d/devtools.conf
${DEVTOOL_PREFIX}/lib
CUSTOM_LD_CONF

# Refresh the linker's cache so it picks up our devtool prefix
RUN ldconfig

WORKDIR "/workspace"

RUN    mkdir -p "${SOURCE_DIR}" "${BUILD_DIR}"          \
    && git clone --branch ${SKYDUCK_REPO_TAG}           \
                 --recursive                            \
                 -- ${SKYDUCK_REPO_URI} "${SOURCE_DIR}"

# Use clang because gcc has trouble type casting to `FunctionData`
RUN env CC=clang CXX=clang++                                                            \
    cmake -S "${DUCKDB_SRC_DIR}"                                                        \
          -B "${BUILD_DIR}"                                                             \
          -DCMAKE_INSTALL_PREFIX="${DEVTOOL_PREFIX}"                                    \
          -DCMAKE_PREFIX_PATH="${DEVTOOL_PREFIX}"                                       \
          -DCMAKE_BUILD_TYPE="Release"                                                  \
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

RUN cmake --build "${BUILD_DIR}" --config "Release" && cmake --install "${BUILD_DIR}"

# Grab the mohair repo to work with
WORKDIR "/workspace"
RUN git clone --branch v1.0.0 -- https://github.com/drin/mohair.git


# ------------------------------
# [Stage] Final

# FROM os-base AS cse-service

# Copy libraries from other layers into our final layer
# COPY --from=protocol-builder "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"
# COPY --from=engine-builder   "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"

# Point a custom ld.so.conf file to our custom install prefix
# COPY <<-CUSTOM_LD_CONF /etc/ld.so.conf.d/devtools.conf
# ${DEVTOOL_PREFIX}/lib
# CUSTOM_LD_CONF
# 
# # Refresh the linker's cache so it picks up our devtool prefix
# RUN ldconfig
# 
# # define environment variables in this layer
# ENV DEVTOOL_PREFIX="/usr/local/devtools"
# ENV PKG_CONFIG_PATH="${DEVTOOL_PREFIX}/lib/pkgconfig"
# ENV PATH="${DEVTOOL_PREFIX}/bin:${PATH}"
# 
# # Grab the mohair repo to work with
# WORKDIR "/workspace"
# RUN git clone --branch v1.0.0 -- https://github.com/drin/mohair.git
