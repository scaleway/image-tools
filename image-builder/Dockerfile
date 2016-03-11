FROM scaleway/docker:amd64-1.10
# following 'FROM' lines are used dynamically thanks do the image-builder
# which dynamically update the Dockerfile if needed.
#FROM scaleway/docker:armhf-1.10	# arch=armv7l
#FROM scaleway/docker:arm64-1.10	# arch=arm64
#FROM scaleway/docker:i386-1.10		# arch=i386
#FROM scaleway/docker:mips-1.10		# arch=mips

MAINTAINER Scaleway <opensource@scaleway.com> (@scaleway)


# Prepare rootfs for image-builder
RUN /usr/local/sbin/builder-enter

# Install packages
RUN apt-get -qq update     \
 && apt-get -y -qq upgrade \
 && apt-get install -y -qq \
      s3cmd                \
      git                  \
      lftp                 \
      curl                 \
      nginx-full           \
 && apt-get clean

# Download scw
ENV SCW_VERSION 1.7.1

RUN case "${ARCH}" in                                                                                                               \
	armv7l|armhf|arm)                                                                                                               \
		curl -L https://github.com/scaleway/scaleway-cli/releases/download/v${SCW_VERSION}/scw_${SCW_VERSION}_armhf.deb  > scw.deb  \
      ;;                                                                                                                            \
    amd64|x86_64|i386)                                                                                                              \
        curl -L https://github.com/scaleway/scaleway-cli/releases/download/v${SCW_VERSION}/scw_${SCW_VERSION}_amd64.deb  > scw.deb  \
      ;;                                                                                                                            \
    *)                                                                                                                              \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                                              \
      ;;                                                                                                                            \
    esac

RUN dpkg -i scw.deb \
 && rm scw.deb

# Patch rootfs
ADD ./overlay/etc/ /etc/
ADD ./overlay/usr/ /usr/

# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
