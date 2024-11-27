# ------------------------------
# [Stage] os-base

FROM drin/skydev:base AS os-base

LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
LABEL       "name"="drin/skydev:base-abseil-static"
LABEL    "version"="20240722.0"


# ------------------------------
# [Stage] abseil-static

FROM os-base AS abseil-builder


# >> Build Library

# set an installation prefix
ENV DEVTOOL_PREFIX="/usr/local/devtools"


#   |> Build and install abseil (static)
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
          -DCMAKE_DEVTOOL_PREFIX=${DEVTOOL_PREFIX} \
          -DCMAKE_PREFIX_PATH=${DEVTOOL_PREFIX}    \
          -DBUILD_STATIC_LIBS=ON                   \
          -DCMAKE_CXX_STANDARD=17                  \
          -DABSL_PROPAGATE_CXX_STD=ON              \
          -DABSL_ENABLE_INSTALL=ON                 \
          -DABSL_BUILD_TEST_HELPERS=ON             \
          -DABSL_USE_EXTERNAL_GOOGLETEST=ON        \
          -DABSL_FIND_GOOGLETEST=ON                \
          -GNinja

RUN    cmake --build   "${BUILD_DIR}" \
    && cmake --install "${BUILD_DIR}"


# ------------------------------
# [Stage] Final

FROM os-base AS dev-base

ENV DEVTOOL_PREFIX="/usr/local/devtools"
ENV PKG_CONFIG_PATH="${DEVTOOL_PREFIX}/lib/pkgconfig"

# Point a custom ld.so.conf file to our custom install prefix
COPY <<-CUSTOM_LD_CONF /etc/ld.so.conf.d/devtools.conf
${DEVTOOL_PREFIX}/lib
CUSTOM_LD_CONF

COPY --from=lib-builder "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"
