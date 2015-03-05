# Default variables
BUILDDIR ?=             /tmp/build/$(NAME)-$(VERSION)/
DESCRIPTION ?=          $(TITLE)
DISK ?=                 /dev/nbd1
DOCKER_NAMESPACE ?=     armbuild/
DOC_URL ?=              https://doc.cloud.online.net
HELP_URL ?=             https://community.cloud.online.net
IS_LATEST ?=            0
NAME ?=                 $(shell basename $(PWD))
S3_URL ?=               s3://test-images
SHELL ?=                /bin/bash
SOURCE_URL ?=           $(shell sh -c "git config --get remote.origin.url | sed 's_git@github.com:_https://github.com/_'" || echo https://github.com/online-labs/image-tools)
TITLE ?=                $(NAME)
VERSION ?=              latest
VERSION_ALIASES ?=


# Phonies
.PHONY: build release install install_on_disk publish_on_s3 clean shell re all run
.PHONY: publish_on_s3.tar publish_on_s3.sqsh publish_on_s3.tar.gz travis


# Default action
all: build


# Actions
build: .docker-container.built


info:
	@echo "Makefile variables:"
	@echo "-------------------"
	@echo "- BUILDDIR=$(BUILDDIR)"
	@echo "- DESCRIPTION=$(DESCRIPTION)"
	@echo "- DISK=$(DISK)"
	@echo "- DOCKER_NAMESPACE=$(DOCKER_NAMESPACE)"
	@echo "- DOC_URL=$(DOC_URL)"
	@echo "- HELP_URL=$(HELP_URL)"
	@echo "- IS_LATEST=$(IS_LATEST)"
	@echo "- NAME=$(NAME)"
	@echo "- S3_URL=$(S3_URL)"
	@echo "- SHELL=$(SHELL)"
	@echo "- SOURCE_URL=$(SOURCE_URL)"
	@echo "- TITLE=$(TITLE)"
	@echo "- VERSION=$(VERSION)"
	@echo "- VERSION_ALIASES=$(VERSION_ALIASES)"


release: build
	docker tag  $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$(VERSION)
	docker tag  $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$(shell date +%Y-%m-%d)
	docker push $(DOCKER_NAMESPACE)$(NAME):$(VERSION)
	docker push $(DOCKER_NAMESPACE)$(NAME):$(shell date +%Y-%m-%d)
	if [ "x$(IS_LATEST)" = "x1" ]; then \
	    docker tag  $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):latest; \
	    docker push $(DOCKER_NAMESPACE)$(NAME):latest; \
	fi


install_on_disk: /mnt/$(DISK)
	tar -C /mnt/$(DISK) -xf $(BUILDDIR)rootfs.tar


publish_on_s3.tar: $(BUILDDIR)rootfs.tar
	s3cmd put --acl-public $< $(S3_URL)/$(NAME)-$(VERSION).tar


publish_on_s3.tar.gz: $(BUILDDIR)rootfs.tar.gz
	s3cmd put --acl-public $< $(S3_URL)/$(NAME)-$(VERSION).tar.gz


publish_on_s3.sqsh: $(BUILDDIR)rootfs.sqsh
	s3cmd put --acl-public $< $(S3_URL)/$(NAME)-$(VERSION).sqsh


fclean: clean
	-docker rmi $(NAME):$(VERSION) || true


clean:
	-rm -f $(BUILDDIR)rootfs.tar $(BUILDDIR)export.tar .??*.built
	-rm -rf $(BUILDDIR)rootfs


shell:  .docker-container.built
	docker run --rm -it $(NAME):$(VERSION) $(SHELL)

test:  .docker-container.built
	docker run --rm -it -e SKIP_NON_DOCKER=1 $(NAME):$(VERSION) $(SHELL) -c 'SCRIPT=$$(mktemp); curl -s https://raw.githubusercontent.com/online-labs/image-tools/master/unit.bash > $$SCRIPT; bash $$SCRIPT'

travis:
	find . -name Dockerfile | xargs cat | grep -vi ^maintainer | bash -n

# Aliases
publish_on_s3: publish_on_s3.tar
install: install_on_disk
run: shell
re: clean build


# File-based rules
Dockerfile:
	@echo
	@echo "You need a Dockerfile to build the image using this script."
	@echo "Please give a look at https://github.com/online-labs/image-helloworld"
	@echo
	@exit 1

.docker-container.built: Dockerfile patches $(shell find patches -type f)
	-find patches -name '*~' -delete || true
	docker build -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$(VERSION)
	docker inspect -f '{{.Id}}' $(NAME):$(VERSION) > $@


patches:
	mkdir patches


$(BUILDDIR)rootfs: $(BUILDDIR)export.tar
	-rm -rf $@ $@.tmp
	-mkdir -p $@.tmp
	tar -C $@.tmp -xf $<
	rm -f $@.tmp/.dockerenv $@.tmp/.dockerinit
	chmod 1777 $@.tmp/tmp
	chmod 755 $@.tmp/etc $@.tmp/usr $@.tmp/usr/local $@.tmp/usr/sbin
	chmod 555 $@.tmp/sys
	-mv $@.tmp/etc/hosts.default $@.tmp/etc/hosts || true
	echo "IMAGE_ID=\"$(TITLE)\"" >> $@.tmp/etc/ocs-release
	echo "IMAGE_RELEASE=$(shell date +%Y-%m-%d)" >> $@.tmp/etc/ocs-release
	echo "IMAGE_CODENAME=$(NAME)" >> $@.tmp/etc/ocs-release
	echo "IMAGE_DESCRIPTION=\"$(DESCRIPTION)\"" >> $@.tmp/etc/ocs-release
	echo "IMAGE_HELP_URL=\"$(HELP_URL)\"" >> $@.tmp/etc/ocs-release
	echo "IMAGE_SOURCE_URL=\"$(SOURCE_URL)\"" >> $@.tmp/etc/ocs-release
	echo "IMAGE_DOC_URL=\"$(DOC_URL)\"" >> $@.tmp/etc/ocs-release
	mv $@.tmp $@


$(BUILDDIR)rootfs.tar.gz: $(BUILDDIR)rootfs
	tar --format=gnu -C $< -czf $@.tmp .
	mv $@.tmp $@


$(BUILDDIR)rootfs.tar: $(BUILDDIR)rootfs
	tar --format=gnu -C $< -cf $@.tmp .
	mv $@.tmp $@


$(BUILDDIR)rootfs.sqsh: $(BUILDDIR)rootfs
	mksquashfs $< $@ -noI -noD -noF -noX


$(BUILDDIR)export.tar: .docker-container.built
	-mkdir -p $(BUILDDIR)
	docker run --name $(NAME)-$(VERSION)-export --entrypoint /dontexists $(NAME):$(VERSION) 2>/dev/null || true
	docker export $(NAME)-$(VERSION)-export > $@.tmp
	docker rm $(NAME)-$(VERSION)-export
	mv $@.tmp $@


/mnt/$(DISK): $(BUILDDIR)rootfs.tar
	umount $(DISK) || true
	mkfs.ext4 $(DISK)
	mkdir -p $@
	mount $(DISK) $@
