# syntax=docker/dockerfile:1

FROM ubuntu:latest AS builder

LABEL authors="coalition-of-freeware-developers"

ENV DEBIAN_FRONTEND=noninteractive \
    CMAKE_POLICY_VERSION_MINIMUM=3.5

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        build-essential \
        gcc-multilib \
        g++-multilib \
        cmake \
        pkg-config \
        automake \
        autoconf \
        libtool \
        patch \
        unzip \
        bzip2 \
        xz-utils \
        perl \
        python3 \
        qtbase5-dev \
        qtchooser \
        qt5-qmake \
        qtbase5-dev-tools \
        libx11-dev \
        libxcursor-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libpulse-dev \
        libasound2-dev \
        mingw-w64 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY . .

#
# Pass 1: Linux + static MinGW
#
# Expected:
#   lin64/
#   mingw64/
#
RUN ./build_deps
RUN ./build_redist
RUN ls -la libacfutils-redist
RUN test -d libacfutils-redist/lin64
RUN test -d libacfutils-redist/mingw64

#
# Pass 2: Linux + Windows DLL
#
# build_redist -d deletes and recreates libacfutils-redist,
# so mingw64 was saved above.
#
RUN ./build_deps -c
RUN ./build_deps -d
RUN ./build_redist -d
RUN test -d libacfutils-redist/lin64
RUN test -d libacfutils-redist/win64

#
# Restore the static MinGW build.
#
RUN test -d libacfutils-redist/lin64
RUN test -d libacfutils-redist/mingw64
RUN test -d libacfutils-redist/win64
RUN find libacfutils-redist -maxdepth 2 -type d -print

FROM scratch AS redist

LABEL authors="coalition-of-freeware-developers"

COPY --from=builder /src/libacfutils-redist /libacfutils-redist
