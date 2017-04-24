# Default variables
NAME ?=                 $(shell basename $(PWD))
VERSION ?=              latest
FULL_NAME ?=            $(NAME)-$(VERSION)
DESCRIPTION ?=          $(TITLE)
DISK ?=                 /dev/nbd1
DOCKER_NAMESPACE ?=     scaleway/
DOC_URL ?=              https://scaleway.com/docs
HELP_URL ?=             https://community.scaleway.com
IS_LATEST ?=            0
S3_URL ?=               s3://test-images
STORE_HOSTNAME ?=       store.scw.42.am
STORE_USERNAME ?=       $(shell whoami)
STORE_PATH ?=           scw
SHELL_BIN ?=            /bin/bash
SHELL_DOCKER_OPTS ?=
SOURCE_URL ?=           $(shell sh -c "git config --get remote.origin.url | sed 's_git@github.com:_https://github.com/_'" || echo https://github.com/scaleway/image-tools)
TITLE ?=                $(NAME)
VERSION_ALIASES ?=
BUILD_OPTS ?=
HOST_ARCH :=            $(shell uname -m)
IMAGE_VOLUME_SIZE ?=    50G
IMAGE_NAME ?=           $(NAME)
IMAGE_BOOTSCRIPT ?=     stable
S3_FULL_URL ?=          $(S3_URL)/$(FULL_NAME).tar
ADDITIONAL_ASSETS ?=
LOCAL_HTTPD_PORT ?=	80
EMBEDDED_HTTPD = (printf "HTTP/1.1 200 OK\r\nContent-type: $(3)\r\nContent-Disposition: attachment; filename=\"$(2)\"\r\nContent-Length: $(shell stat -c %s $(1))\r\nConnection: close\r\n\r\n"; cat $(1)) | nc -l -p $(4) > /dev/null &
DEFAULT_IMAGE_ARCH ?=	armv7l
ARCH ?=			$(HOST_ARCH)
ARCHS :=		amd64 x86_64 i386 arm armhf armel arm64 mips mipsel powerpc
ifeq ($(ARCH),arm)
	TARGET_QEMU_ARCH=arm
	TARGET_IMAGE_ARCH=arm
	TARGET_UNAME_ARCH=armv7l
	TARGET_DOCKER_TAG_ARCH=armhf
	TARGET_GOLANG_ARCH=arm
endif
ifeq ($(ARCH),armhf)
	TARGET_QEMU_ARCH=arm
	TARGET_IMAGE_ARCH=arm
	TARGET_UNAME_ARCH=armv7l
	TARGET_DOCKER_TAG_ARCH=armhf
	TARGET_GOLANG_ARCH=arm
endif
ifeq ($(ARCH),armv7l)
	TARGET_QEMU_ARCH=arm
	TARGET_IMAGE_ARCH=arm
	TARGET_UNAME_ARCH=armv7l
	TARGET_DOCKER_TAG_ARCH=armhf
	TARGET_GOLANG_ARCH=arm
endif
ifeq ($(ARCH),arm64)
	TARGET_QEMU_ARCH=aarch64
	TARGET_IMAGE_ARCH=arm64
	TARGET_UNAME_ARCH=arm64
	TARGET_DOCKER_TAG_ARCH=arm64
	TARGET_GOLANG_ARCH=arm64
endif
ifeq ($(ARCH),x86_64)
	TARGET_QEMU_ARCH=x86_64
	TARGET_IMAGE_ARCH=x86_64
	TARGET_UNAME_ARCH=x86_64
	TARGET_DOCKER_TAG_ARCH=amd64
	TARGET_GOLANG_ARCH=amd64
endif
ifeq ($(ARCH),amd64)
	TARGET_QEMU_ARCH=x86_64
	TARGET_IMAGE_ARCH=x86_64
	TARGET_UNAME_ARCH=x86_64
	TARGET_DOCKER_TAG_ARCH=amd64
	TARGET_GOLANG_ARCH=amd64
endif
ifeq ($(ARCH),mips)
	TARGET_QEMU_ARCH=mips
	TARGET_IMAGE_ARCH=mips
	TARGET_UNAME_ARCH=mips
	TARGET_DOCKER_TAG_ARCH=mips
	TARGET_GOLANG_ARCH=unsupported
endif
ifeq ($(ARCH),powerpc)
	TARGET_QEMU_ARCH=powerpc
	TARGET_IMAGE_ARCH=powerpc
	TARGET_UNAME_ARCH=powerpc
	TARGET_DOCKER_TAG_ARCH=powerpc
	TARGET_GOLANG_ARCH=unsupported
endif
OVERLAY_DIRS :=		overlay overlay-common overlay-$(TARGET_UNAME_ARCH) patches patches-common patches-$(TARGET_UNAME_ARCH) overlay-image-tools
OVERLAY_FILES :=	$(shell for dir in $(OVERLAY_DIRS); do test -d $$dir && find $$dir -type f; done || true)
TMP_BUILD_DIR :=	tmp-$(TARGET_UNAME_ARCH)
BUILD_DIR :=		$(shell test $(TARGET_UNAME_ARCH) = $(DEFAULT_IMAGE_ARCH) && echo "." || echo $(TMP_BUILD_DIR))
EXPORT_DIR ?=           /tmp/build/$(TARGET_UNAME_ARCH)-$(FULL_NAME)/


# Default action
all: help


# Actions
.PHONY: help
help:
	@echo 'General purpose commands'
	@echo ' build                   build the Docker image'
	@echo ' image                   create a Scaleway image (requires a working `scaleway-cli`) from s3 by default'
	@echo ' image_on_s3             create a Scaleway image (requires a working `scaleway-cli`) from s3'
	@echo ' image_on_store          create a Scaleway image (requires a working `scaleway-cli`) from the store'
	@echo ' image_on_local          create a Scaleway image (requires a working `scaleway-cli`) from your local webserver'
	@echo ' rootfs.tar              build and print the location of a rootfs.tar'
	@echo ' info                    print build information'
	@echo ' install_on_disk         write the image to /dev/nbd1'
	@echo ' publish_on_s3           push a tarball of the image on S3 (for rescue testing)'
	@echo ' publish_on_store        push a tarball of the image on store using ssh'
	@echo ' rebuild                 rebuild the Docker image without cache'
	@echo ' release                 push the image on Docker registry'
	@echo ' shell                   open a shell in the image using `docker run`'
	@echo ' test                    run unit test using `docker run` (limited testing)'


.PHONY: build
build:	.docker-container-$(TARGET_UNAME_ARCH).built


.PHONY: rebuild
rebuild: clean
	$(MAKE) build BUILD_OPTS=--no-cache


.PHONY: info
info:
	@echo "Makefile variables:"
	@echo "-------------------"
	@echo "- EXPORT_DIR           $(EXPORT_DIR)"
	@echo "- BUILD_DIR            $(BUILD_DIR)"
	@echo "- DESCRIPTION          $(DESCRIPTION)"
	@echo "- DISK                 $(DISK)"
	@echo "- DOCKER_NAMESPACE     $(DOCKER_NAMESPACE)"
	@echo "- DOC_URL              $(DOC_URL)"
	@echo "- HELP_URL             $(HELP_URL)"
	@echo "- IS_LATEST            $(IS_LATEST)"
	@echo "- NAME                 $(NAME)"
	@echo "- S3_URL               $(S3_URL)"
	@echo "- SHELL_BIN            $(SHELL_BIN)"
	@echo "- SOURCE_URL           $(SOURCE_URL)"
	@echo "- TITLE                $(TITLE)"
	@echo "- VERSION              $(VERSION)"
	@echo "- VERSION_ALIASES      $(VERSION_ALIASES)"
	@echo
	@echo "Arch:"
	@echo "-----"
	@echo "- HOST_ARCH            $(HOST_ARCH)"
	@echo "- DEFAULT_IMAGE_ARCH   $(DEFAULT_IMAGE_ARCH)"
	@echo "- ARCH                 $(ARCH)"
	@echo "- TARGET_QEMU_ARCH     $(TARGET_QEMU_ARCH)"
	@echo "- TARGET_UNAME_ARCH    $(TARGET_UNAME_ARCH)"
	@echo
	@echo "Computed information:"
	@echo "---------------------"
	@echo "- Docker image         $(DOCKER_NAMESPACE)$(NAME):$(VERSION)"
	@echo "- S3 URL               $(S3_FULL_URL)"
	@#echo "- S3 public URL        $(shell s3cmd info $(S3_FULL_URL) | grep URL | awk '{print $$2}')"
	@#test -f $(EXPORT_DIR)rootfs.tar && echo "- Image size        $(shell stat -c %s $(EXPORT_DIR)rootfs.tar | numfmt --to=iec-i --suffix=B --format=\"%3f\")" || true


.PHONY: image_dep
image_dep:
	test -f /tmp/create-image-from-http.sh \
		|| wget -qO /tmp/create-image-from-http.sh https://github.com/scaleway/scaleway-cli/raw/master/examples/create-image-from-http.sh
	chmod +x /tmp/create-image-from-http.sh


.PHONY: image_on_s3
image_on_s3: image_dep
	s3cmd ls $(S3_URL) || s3cmd mb $(S3_URL)
	s3cmd ls $(S3_FULL_URL) | grep -q '.tar' || $(MAKE) publish_on_s3.tar
	IMAGE_ARCH="$(TARGET_IMAGE_ARCH)" VOLUME_SIZE="$(IMAGE_VOLUME_SIZE)" IMAGE_NAME="$(IMAGE_NAME)" IMAGE_BOOTSCRIPT="$(IMAGE_BOOTSCRIPT)" /tmp/create-image-from-http.sh $(shell s3cmd info $(S3_FULL_URL) | grep URL | awk '{print $$2}')


.PHONY: image_on_store
image_on_store: image_dep
	IMAGE_ARCH="$(TARGET_IMAGE_ARCH)" VOLUME_SIZE="$(IMAGE_VOLUME_SIZE)" IMAGE_NAME="$(IMAGE_NAME)" IMAGE_BOOTSCRIPT="$(IMAGE_BOOTSCRIPT)" /tmp/create-image-from-http.sh http://$(STORE_HOSTNAME)/$(STORE_PATH)/$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar


.PHONY: image_on_local
image_on_local: image_dep $(EXPORT_DIR)rootfs.tar
	ln -sf $(EXPORT_DIR)rootfs.tar $(EXPORT_DIR)$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar
	$(eval USE_INTERNAL_HTTPD ?= $(shell mkdir -p /tmp/build; marker=$$(date); echo $$marker > /tmp/build/httpd_check; test "$$(curl --silent --noproxy '*' http://127.0.0.1/httpd_check)" = "$$marker"; echo $$?; rm /tmp/build/httpd_check))
	$(if [ $(USE_INTERNAL_HTTPD) -eq 1 ], \
		$(eval LOCAL_HTTPD_PORT := $(shell for candidate in $$(seq 8000 8100); do lsof -i tcp:$$candidate >/dev/null 2>&1; if [ $$? = 1 ]; then echo $$candidate; break; fi; done)) \
		$(shell sh -c '$(call EMBEDDED_HTTPD,$(EXPORT_DIR)rootfs.tar,$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar,application/x-tar,$(LOCAL_HTTPD_PORT))') \
	)
	IMAGE_ARCH="$(TARGET_IMAGE_ARCH)" VOLUME_SIZE="$(IMAGE_VOLUME_SIZE)" IMAGE_NAME="$(IMAGE_NAME)" IMAGE_BOOTSCRIPT="$(IMAGE_BOOTSCRIPT)" /tmp/create-image-from-http.sh http://$(shell scw-metadata --cached PUBLIC_IP_ADDRESS):$(LOCAL_HTTPD_PORT)/$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION)/$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar


.PHONY: image
image:	image_on_s3


.PHONY: pull_image
pull_image:
	docker pull $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$(VERSION)


.PHONY: release
release: build
	docker push $(DOCKER_NAMESPACE)$(NAME)


.PHONY: install_on_disk
install_on_disk: /mnt/$(DISK)
	tar -C /mnt/$(DISK) -xf $(EXPORT_DIR)rootfs.tar


.PHONY: fast-publish_on_s3.tar
fast-publish_on_s3.tar: $(EXPORT_DIR)rootfs.tar
	s3cmd put --acl-public $< $(S3_URL)/$(NAME)-$(VERSION).tar


.PHONY: publish_on_s3.tar
publish_on_s3.tar: fast-publish_on_s3.tar
	$(MAKE) check_s3 || $(MAKE) publish_on_s3.tar


.PHONY: publish_on_store
publish_on_store: $(EXPORT_DIR)rootfs.tar
	rsync -Pave ssh $(EXPORT_DIR)rootfs.tar $(STORE_HOSTNAME):store/$(STORE_PATH)/$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar
	@echo http://$(STORE_HOSTNAME)/$(STORE_PATH)/$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar


.PHONY: publish_on_store_ftp
publish_on_store_ftp: $(EXPORT_DIR)rootfs.tar
	cd $(EXPORT_DIR) && curl -T rootfs.tar --netrc ftp://$(STORE_HOSTNAME)/images/$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar


.PHONY: publish_on_store_sftp
publish_on_store_sftp: $(EXPORT_DIR)rootfs.tar
	cd $(EXPORT_DIR) && lftp -u $(STORE_USERNAME) -p 2222 sftp://$(STORE_HOSTNAME) -e "set sftp:auto-confirm yes; mkdir store/images; cd store/images; put rootfs.tar -o $(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar; bye"


.PHONY: check_s3.tar
check_s3.tar:
	wget --read-timeout=3 --tries=0 -O - $(shell s3cmd info $(S3_FULL_URL) | grep URL | awk '{print $$2}') >/dev/null


.PHONY: publish_on_s3.tar.gz
publish_on_s3.tar.gz: $(EXPORT_DIR)rootfs.tar.gz
	s3cmd put --acl-public $< $(S3_URL)/$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).tar.gz


.PHONY: publish_on_s3.sqsh
publish_on_s3.sqsh: $(EXPORT_DIR)rootfs.sqsh
	s3cmd put --acl-public $< $(S3_URL)/$(TARGET_UNAME_ARCH)-$(NAME)-$(VERSION).sqsh


.PHONY: fclean
fclean: clean
	for tag in latest $(shell docker images | grep "^$(DOCKER_NAMESPACE)$(NAME) " | awk '{print $$2}'); do\
	  echo "Creating a backup of '$(DOCKER_NAMESPACE)$(NAME):$$tag' for caching"; \
	  docker tag $(DOCKER_NAMESPACE)$(NAME):$$tag old$(DOCKER_NAMESPACE)$(NAME):$$tag; \
	  docker rmi -f $(DOCKER_NAMESPACE)$(NAME):$$tag; \
	done

.PHONY: clean
clean:
	-rm -f $(EXPORT_DIR)rootfs.tar $(EXPORT_DIR)export.tar .??*.built
	-rm -rf $(EXPORT_DIR)rootfs


.PHONY: shell
shell:  .docker-container-$(TARGET_UNAME_ARCH).built
	test $(HOST_ARCH) = $(TARGET_UNAME_ARCH) || $(MAKE) setup_binfmt
	docker run --rm -it $(SHELL_DOCKER_OPTS) $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$(VERSION) $(SHELL_BIN)


.PHONY: test
test:  .docker-container-$(TARGET_UNAME_ARCH).built
	test $(HOST_ARCH) = $(TARGET_UNAME_ARCH) || $(MAKE) setup_binfmt
	docker run --rm -it -e SKIP_NON_DOCKER=1 $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$(VERSION) $(SHELL_BIN) -c 'SCRIPT=$$(mktemp); curl -s https://raw.githubusercontent.com/scaleway/image-tools/master/builder/unit.bash > $$SCRIPT; bash $$SCRIPT'


.PHONY: travis
travis:
	npm install dockerfile_lint
	wget https://raw.githubusercontent.com/scaleway/image-tools/master/builder/dockerlint.rules
	find . -name Dockerfile -print0 | xargs -L 1 -r -0 ./node_modules/.bin/dockerfile_lint -r dockerlint.rules -f

.PHONY:
setup_binfmt:
	@echo "Configuring binfmt-misc on the Docker(/Boot2Docker) kernel"
	docker run --rm --privileged multiarch/qemu-user-static:register --reset


# Aliases
.PHONY: publish_on_s3
publish_on_s3: publish_on_s3.tar

.PHONY: check_s3
check_s3: check_s3.tar

.PHONY: install
install: install_on_disk

.PHONY: run
run: shell

.PHONY: re
re: rebuild


# File-based rules
$(TMP_BUILD_DIR)/Dockerfile: Dockerfile
	mkdir -p "$(TMP_BUILD_DIR)"
	cp $< $@
	for arch in $(ARCHS); do							\
	  if [ "$$arch" != "$(TARGET_UNAME_ARCH)" ]; then				\
	    mv $@ $@.tmp;								\
	    sed "/#[[:space:]]*arch=$$arch[[:space:]]*$$/d" $@.tmp > $@;		\
	    rm -f $@.tmp;								\
	  fi										\
	done
	mv $@ $@.tmp
	sed '/#[[:space:]]*arch=$(TARGET_UNAME_ARCH)[[:space:]]*$$/s/^#//' $@.tmp > $@
	mv $@ $@.tmp
	sed 's/#[[:space:]]*arch=$(TARGET_UNAME_ARCH)[[:space:]]*$$//g' $@.tmp > $@
	if [ "`grep ^FROM $(TMP_BUILD_DIR)/Dockerfile | wc -l`" = "2" ]; then		\
	  mv $@ $@.tmp;									\
	  sed 0,/^FROM/d $@.tmp > $@;							\
	fi
	rm -f $@.tmp
	#cat $@


$(TMP_BUILD_DIR)/.overlays: $(OVERLAY_FILES)
	mkdir -p $(TMP_BUILD_DIR)
	for dir in $(OVERLAY_DIRS); do                           			\
	  if [ -d "$$dir" ]; then				 			\
	    rm -rf "$(TMP_BUILD_DIR)/$$dir";             				\
	    cp -rf "$$dir" "$(TMP_BUILD_DIR)/$$dir";     				\
	  fi                                                     			\
	done
	touch $@


.overlays:
	touch $@


.docker-container-$(TARGET_UNAME_ARCH).built: $(BUILD_DIR)/Dockerfile $(BUILD_DIR)/.overlays $(ADDITIONAL_ASSETS)
	test $(HOST_ARCH) = $(TARGET_UNAME_ARCH) || $(MAKE) setup_binfmt
	@find $(BUILD_DIR) -name "*~" -delete || true
	docker build $(BUILD_OPTS) -t $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$(VERSION) $(BUILD_DIR)
	for tag in $(shell date +%Y-%m-%d) $(VERSION_ALIASES); do							                                   \
	  echo docker tag $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$$tag;   \
	  docker tag $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$$tag;	   \
	done
	docker inspect -f '{{.Id}}' $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$(VERSION) > $@


$(EXPORT_DIR)rootfs: $(EXPORT_DIR)export.tar
	-rm -rf $@ $@.tmp
	-mkdir -p $@.tmp
	tar -C $@.tmp -xf $<
	rm -f $@.tmp/.dockerenv $@.tmp/.dockerinit
	-chmod 1777 $@.tmp/tmp
	-chmod 755 $@.tmp/etc $@.tmp/usr $@.tmp/usr/local $@.tmp/usr/sbin
	-chmod 555 $@.tmp/sys
	-chmod 700 $@.tmp/root
	-mv $@.tmp/etc/hosts.default $@.tmp/etc/hosts || true
	echo "IMAGE_ID=\"$(TITLE)\"" >> $@.tmp/etc/scw-release
	echo "IMAGE_RELEASE=$(shell date +%Y-%m-%d)" >> $@.tmp/etc/scw-release
	echo "IMAGE_CODENAME=$(NAME)" >> $@.tmp/etc/scw-release
	echo "IMAGE_DESCRIPTION=\"$(DESCRIPTION)\"" >> $@.tmp/etc/scw-release
	echo "IMAGE_HELP_URL=\"$(HELP_URL)\"" >> $@.tmp/etc/scw-release
	echo "IMAGE_SOURCE_URL=\"$(SOURCE_URL)\"" >> $@.tmp/etc/scw-release
	echo "IMAGE_DOC_URL=\"$(DOC_URL)\"" >> $@.tmp/etc/scw-release
	mv $@.tmp $@


$(EXPORT_DIR)rootfs.tar.gz: $(EXPORT_DIR)rootfs
	tar --format=gnu -C $< -czf $@.tmp .
	mv $@.tmp $@


.PHONY: rootfs.tar
rootfs.tar: $(EXPORT_DIR)rootfs.tar
	ls -la $<
	@echo $<


$(EXPORT_DIR)rootfs.tar: $(EXPORT_DIR)rootfs
	tar --format=gnu -C $< -cf $@.tmp .
	mv $@.tmp $@


$(EXPORT_DIR)rootfs.sqsh: $(EXPORT_DIR)rootfs
	mksquashfs $< $@ -noI -noD -noF -noX


$(EXPORT_DIR)export.tar: .docker-container-$(TARGET_UNAME_ARCH).built
	-mkdir -p $(EXPORT_DIR)
	docker run --name $(NAME)-$(VERSION)-export --entrypoint /dontexists $(DOCKER_NAMESPACE)$(NAME):$(TARGET_DOCKER_TAG_ARCH)-$(VERSION) 2>/dev/null || true
	docker export $(NAME)-$(VERSION)-export > $@.tmp
	docker rm $(NAME)-$(VERSION)-export
	mv $@.tmp $@


/mnt/$(DISK): $(EXPORT_DIR)rootfs.tar
	umount $(DISK) || true
	mkfs.ext4 $(DISK)
	mkdir -p $@
	mount $(DISK) $@


patches/usr/bin/qemu-$(TARGET_QEMU_ARCH)-static:
	mkdir -p patches/usr/bin
	wget https://github.com/multiarch/qemu-user-static/releases/download/v2.0.0/amd64_qemu-$(TARGET_QEMU_ARCH)-static.tar.gz
	tar -xf amd64_qemu-$(TARGET_QEMU_ARCH)-static.tar.gz
	rm -f amd64_qemu-$(TARGET_QEMU_ARCH)-static.tar.gz


.PHONY: sync-image-tools
sync-image-tools:
	rm -rf overlay-image-tools
	mkdir -p overlay-image-tools
	curl -sLq https://j.mp/scw-skeleton | FLAVORS=$(IMAGE_TOOLS_FLAVORS) ROOTDIR=overlay-image-tools BRANCH=$(IMAGE_TOOLS_CHECKOUT) bash -e


.PHONY: bump-image-tools
bump-image-tools:
	$(eval SHA := $(shell curl -s https://api.github.com/repos/scaleway/image-tools/branches/master | jq -r .commit.sha))
	sed -i.bak 's/^\(IMAGE_TOOLS_CHECKOUT[[:space:]=]*\).*$$/\1$(SHA)/' Makefile
	rm Makefile.bak
