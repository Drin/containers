FROM phusion/baseimage:0.11

# ------------------------------
# Setup base image packages and environment

# update and install needed packages
RUN        apt-get update                             \
        && apt-get install -y --no-install-recommends \
               dpkg-dev                               \
               gcc                                    \
               libbz2-dev                             \
               libc6-dev                              \
               libexpat1-dev                          \
               libffi-dev                             \
               libgdbm-dev                            \
               liblzma-dev                            \
               libncursesw5-dev                       \
               libreadline-dev                        \
               libsqlite3-dev                         \
               libssl-dev                             \
               make                                   \
               tk-dev                                 \
               uuid-dev                               \
               wget                                   \
               xz-utils                               \
               zlib1g-dev                             \
        && rm -rf /var/lib/apt/lists/*

# prep basic directories and configs
ENV         LANG C.UTF-8
ENV TOOLBOX_ROOT "/toolbox"

ENV            PATH $TOOLBOX_ROOT/python/bin:$TOOLBOX_ROOT/pip/bin:$PATH
ENV LD_LIBRARY_PATH $TOOLBOX_ROOT/python/lib:$TOOLBOX_ROOT/pip/lib:$PATH

ARG python_version=3.7.4
ENV        GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV  DOWNLOAD_ROOT "/usr/src/python"
ENV         PY_URI "https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tar.xz"

# download and verify python installation
RUN    set   -ex                                                                 \
    && mkdir -p $TOOLBOX_ROOT/python                                             \
    && mkdir -p $DOWNLOAD_ROOT                                                   \
                                                                                 \
    && cd $DOWNLOAD_ROOT                                                         \
    && wget -O python.tar.xz     "${PY_URI}"                                     \
    && wget -O python.tar.xz.asc "${PY_URI}.asc"

RUN    set   -ex                                                                 \
    && cd $DOWNLOAD_ROOT                                                         \
    && export GNUPGHOME="$(mktemp -d)";                                          \
       gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
    && gpg --batch --verify python.tar.xz.asc python.tar.xz                      \
    && { command -v gpgconf > /dev/null && gpgconf --kill all || :; }            \
    && rm -rf "$GNUPGHOME" python.tar.xz.asc                                     \
                                                                                 \
    && tar -xJC $DOWNLOAD_ROOT --strip-components=1 -f python.tar.xz             \
    && rm python.tar.xz


# configure and build and install and clean python
RUN    set -ex                                                                   \
    && cd $DOWNLOAD_ROOT                                                         \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"                 \
    && ./configure                                                               \
        --build="$gnuArch"                                                       \
        --prefix=$TOOLBOX_ROOT/python                                            \
        --enable-loadable-sqlite-extensions                                      \
        --enable-optimizations                                                   \
        --enable-shared                                                          \
        --with-system-expat                                                      \
        --with-system-ffi                                                        \
        --without-ensurepip                                                      \
    && make -j "$(nproc)"                                                        \
        PROFILE_TASK='-m test.regrtest --pgo                                     \
            test_array                                                           \
            test_base64                                                          \
            test_binascii                                                        \
            test_binhex                                                          \
            test_binop                                                           \
            test_bytes                                                           \
            test_c_locale_coercion                                               \
            test_class                                                           \
            test_cmath                                                           \
            test_codecs                                                          \
            test_compile                                                         \
            test_complex                                                         \
            test_csv                                                             \
            test_decimal                                                         \
            test_dict                                                            \
            test_float                                                           \
            test_fstring                                                         \
            test_hashlib                                                         \
            test_io                                                              \
            test_iter                                                            \
            test_json                                                            \
            test_long                                                            \
            test_math                                                            \
            test_memoryview                                                      \
            test_pickle                                                          \
            test_re                                                              \
            test_set                                                             \
            test_slice                                                           \
            test_struct                                                          \
            test_threading                                                       \
            test_time                                                            \
            test_traceback                                                       \
            test_unicode                                                         \
        '                                                                        \
    && make install                                                              \
    && ldconfig                                                                  \
                                                                                 \
    && find /usr/local -depth                                                    \
           \(                                                                    \
                  \( -type d -a \( -name test    -o -name tests   \) \)          \
               -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \)          \
           \) -exec rm -rf '{}' +                                                \
    && rm -rf $DOWNLOAD_ROOT                                                     \
                                                                                 \
    && python3 --version

# make some useful symlinks that are expected to exist
RUN    cd $TOOLBOX_ROOT/python/bin                                               \
    && ln -s idle3          idle                                                 \
    && ln -s pydoc3         pydoc                                                \
    && ln -s python3        python                                               \
    && ln -s python3-config python-config

# ------------------------------
# download and install pip
# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV    PIP_VER 19.2.3
ENV    PIP_URL https://bootstrap.pypa.io/get-pip.py
ENV PIP_SHA256 57e3643ff19f018f8a00dfaa6b7e4620e3c1a7a2171fd218425366ec006b3bfe

RUN set -ex;                                                         \
                                                                     \
    wget -O get-pip.py "$PIP_URL";                                   \
    echo "$PIP_SHA256 *get-pip.py" | sha256sum --check --strict -;   \
                                                                     \
    python get-pip.py                                                \
        --prefix=$TOOLBOX_ROOT/pip                                   \
        --disable-pip-version-check                                  \
        --no-cache-dir                                               \
        "pip==$PIP_VER"                                              \
    ;                                                                \
    #pip --version;                                                   \
                                                                     \
    find /usr/local -depth                                           \
        \(                                                           \
               \( -type d -a \( -name test    -o -name tests   \) \) \
            -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' +;                                      \
    rm -f get-pip.py

# ------------------------------
# setup entrypoint and default command
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["--help"]
