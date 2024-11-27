# ------------------------------
# [Stage] os-base

FROM drin/skydev:base AS os-base

LABEL "maintainer"="Aldrin Montana <octalene.dev@pm.me>"
LABEL       "name"="drin/skydev:dev-base"
LABEL    "version"="20240722.0"


# ------------------------------
# [Stage] protobuf-static

FROM os-base AS protobuf-builder


# >> Build Library

# set an installation prefix
ENV DEVTOOL_PREFIX="/usr/local/devtools"


#   |> Build and install protobuf (static) and grpc
WORKDIR "/workspace"

ENV RELEASE_FILENAME="protobuf-28.3.tar.gz"
ENV RELEASE_URI="https://github.com/protocolbuffers/protobuf/releases/download/v28.3/${RELEASE_FILENAME}"
ENV RELEASE_CHECKSUM="7c3ebd7aaedd86fa5dc479a0fda803f602caaf78d8aff7ce83b89e1b8ae7442a"
ENV SOURCE_DIR="/workspace/protobuf-28.3"
ENV BUILD_DIR="/workspace/build-dir"

RUN    wget "${RELEASE_URI}"          \
    && tar -xzf "${RELEASE_FILENAME}"

RUN cmake -S "${SOURCE_DIR}"                       \
          -B "${BUILD_DIR}"                        \
          -DCMAKE_INSTALL_PREFIX=${DEVTOOL_PREFIX} \
          -DCMAKE_PREFIX_PATH=${DEVTOOL_PREFIX}    \
          -DBUILD_STATIC_LIBS=ON                   \
          -DCMAKE_CXX_STANDARD=17                  \
          -Dprotobuf_BUILD_LIBPROTOC=ON            \
          -Dprotobuf_BUILD_TESTS=ON                \
          -Dprotobuf_USE_EXTERNAL_GTEST=ON         \
          -Dprotobuf_JSONCPP_PROVIDER=package      \
          -GNinja

RUN    cmake --build   "${BUILD_DIR}" \
    && cmake --install "${BUILD_DIR}"


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

# Copy libraries from other layers into our final layer
COPY --from=protobuf-builder "${DEVTOOL_PREFIX}" "${DEVTOOL_PREFIX}"
