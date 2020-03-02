FROM ubuntu:xenial as base

# Env variables
ENV DEBIAN_FRONTEND noninteractive

# Install dependencies and required requisites
RUN apt-get update \
  && apt-get install --no-install-recommends --fix-missing -y \
  software-properties-common \
  python-software-properties \
  && add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable \
  && add-apt-repository -y ppa:george-edison55/cmake-3.x \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install --no-install-recommends --fix-missing -y \
  build-essential \
  cmake \
  gdal-bin \
  git \
  libatlas-base-dev \
  libavcodec-dev \
  libavformat-dev \
  libboost-date-time-dev \
  libboost-filesystem-dev \
  libboost-iostreams-dev \
  libboost-log-dev \
  libboost-python-dev \
  libboost-regex-dev \
  libboost-thread-dev \
  libeigen3-dev \
  libflann-dev \
  libgdal-dev \
  libgeotiff-dev \
  libgoogle-glog-dev \
  libgtk2.0-dev \
  libjasper-dev \
  libjpeg-dev \
  libjsoncpp-dev \
  liblapack-dev \
  liblas-bin \
  libpng-dev \
  libproj-dev \
  libsuitesparse-dev \
  libswscale-dev \
  libtbb2 \
  libtbb-dev \
  libtiff-dev \
  libvtk6-dev \
  libxext-dev \
  python-dev \
  python-gdal \
  python-matplotlib \
  python-pip \
  python-wheel \
  swig2.0 \
  grass-core \
  libssl-dev \
  && apt-get remove libdc1394-22-dev \
  && apt-get autoremove -y \
  && pip install --upgrade pip \
  && pip install setuptools

# Prepare directories
WORKDIR /code

# Copy everything
COPY . ./

ENV PYTHONPATH="$PYTHONPATH:/code/SuperBuild/install/lib/python2.7/dist-packages"
ENV PYTHONPATH="$PYTHONPATH:/code/SuperBuild/src/opensfm"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/code/SuperBuild/install/lib"

# Setup the builder image
FROM base as builder

# Compile code in SuperBuild and root directories
RUN rm -rf docker \
  && cd SuperBuild \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make -j$(nproc) \
  && cd ../.. \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make -j$(nproc)

ENTRYPOINT [ "bash" ]

# Setup the image used for production
FROM ubuntu:xenial as production

RUN apt-get update \
  && apt-get install --no-install-recommends --fix-missing -y \
  software-properties-common \
  python-software-properties \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get update \
  && apt-get install --no-install-recommends --fix-missing -y \
  build-essential \
  gdal-bin \
  git \
  python-dev \
  python-gdal \
  python-matplotlib \
  python-pip \
  python-wheel \
  swig2.0 \
  grass-core \
  libffi-dev \
  libssl-dev \
  && apt-get remove libdc1394-22-dev \
  && pip install --upgrade pip \
  && pip install setuptools

COPY . ./
COPY --from=builder /code/SuperBuild/build /code/SuperBuild/install /code/SuperBuild/

RUN apt-get install -y 

RUN pip install -r requirements.txt

# Entry point
ENTRYPOINT ["python", "/code/run.py"]