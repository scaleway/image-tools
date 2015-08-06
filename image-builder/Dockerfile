## -*- docker-image-name: "armbuild/scw-image-builder:latest" -*-
FROM armbuild/scw-app-docker:latest
MAINTAINER Scaleway <opensource@scaleway.com> (@scaleway)


# Prepare rootfs for image-builder
RUN /usr/local/sbin/builder-enter

# Install packages
RUN apt-get -qq update     \
 && apt-get -y -qq upgrade \
 && apt-get install -y -qq \
      s3cmd                \
      git                  \
      curl                 \
 && apt-get clean

# Download the awesome scaleway-cli ;)
RUN curl -L https://github.com/scaleway/scaleway-cli/releases/download/v1.3.0/scw-Linux-armv7 > /usr/local/bin/scw && chmod +x /usr/local/bin/scw

# Generate ssh key
RUN ssh-keygen  -f ~/.ssh/id_rsa -t rsa  -N  ''

# Patch rootfs
ADD ./patches/etc/ /etc/
ADD ./patches/usr/ /usr/

# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
