DOCKER_NAMESPACE ?=	armbuild/
DISK ?=			/dev/nbd1
S3_URL ?=		s3://test-images
IS_LATEST ?=		0
BUILDDIR ?=		/tmp/build/$(NAME)-$(VERSION)/
SOURCE_URL ?=		https://github.com/online-labs/image-builder
DOC_URL ?=		https://doc.cloud.online.net
HELP_URL ?=		https://community.cloud.online.net
TITLE ?=		$(NAME)
DESCRIPTION ?=		$(TITLE)


.PHONY: build release install_on_disk publish_on_s3 clean shell re all
.PHONY: publish_on_s3.tar publish_on_s3.sqsh


all: build


re: clean build


build: .docker-container.built


run: build
	docker run -it --rm $(NAME):$(VERSION) /bin/bash


release:
	docker tag  $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$(VERSION)
	docker tag  $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$(shell date +%Y-%m-%d)
	docker push $(DOCKER_NAMESPACE)$(NAME):$(VERSION)
	docker push $(DOCKER_NAMESPACE)$(NAME):$(shell date +%Y-%m-%d)
	if [ "x$(IS_LATEST)" = "x1" ]; then \
	    docker tag  $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):latest; \
	    docker push $(DOCKER_NAMESPACE)$(NAME):latest; \
	fi


install_on_disk: $(BUILDDIR)rootfs.tar /mnt/$(DISK)
	tar -C /mnt/$(DISK) -xf $(BUILDDIR)rootfs.tar


publish_on_s3: publish_on_s3.tar publish_on_s3.sqsh


publish_on_s3.tar: $(BUILDDIR)rootfs.tar
	s3cmd put --acl-public $(BUILDDIR)rootfs.tar $(S3_URL)/$(NAME)-$(VERSION).tar


publish_on_s3.sqsh: $(BUILDDIR)rootfs.sqsh
	s3cmd put --acl-public $(BUILDDIR)rootfs.sqsh $(S3_URL)/$(NAME)-$(VERSION).sqsh


fclean: clean
	-docker rmi $(NAME):$(VERSION) || true


clean:
	-rm -f $(BUILDDIR)rootfs.tar $(BUILDDIR)export.tar .??*.built
	-rm -rf $(BUILDDIR)rootfs


shell:  .docker-container.built
	docker run --rm -it $(NAME):$(VERSION) /bin/bash


.docker-container.built: Dockerfile
	-find patches -name '*~' -delete || true
	docker build -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) $(DOCKER_NAMESPACE)$(NAME):$(VERSION)
	docker inspect -f '{{.Id}}' $(NAME):$(VERSION) > .docker-container.built


$(BUILDDIR)rootfs: $(BUILDDIR)export.tar
	-rm -rf $(BUILDDIR)rootfs $(BUILDDIR)rootfs.tmp
	-mkdir -p $(BUILDDIR)rootfs.tmp
	tar -C $(BUILDDIR)rootfs.tmp -xf $(BUILDDIR)export.tar
	rm -f $(BUILDDIR)rootfs.tmp/.dockerenv $(BUILDDIR)rootfs.tmp/.dockerinit
	chmod 1777 $(BUILDDIR)rootfs.tmp/tmp
	chmod 755 $(BUILDDIR)rootfs.tmp/etc $(BUILDDIR)rootfs.tmp/usr $(BUILDDIR)rootfs.tmp/usr/local $(BUILDDIR)rootfs.tmp/usr/sbin
	chmod 555 $(BUILDDIR)rootfs.tmp/sys
	-mv $(BUILDDIR)rootfs.tmp/etc/hosts.default $(BUILDDIR)rootfs.tmp/etc/hosts || true
	echo "IMAGE_ID=\"$(TITLE)\"" >> $(BUILDDIR)rootfs.tmp/etc/ocs-release
	echo "IMAGE_RELEASE=$(shell date +%Y-%m-%d)" >> $(BUILDDIR)rootfs.tmp/etc/ocs-release
	echo "IMAGE_CODENAME=$(NAME)" >> $(BUILDDIR)rootfs.tmp/etc/ocs-release
	echo "IMAGE_DESCRIPTION=\"$(DESCRIPTION)\"" >> $(BUILDDIR)rootfs.tmp/etc/ocs-release
	echo "IMAGE_HELP_URL=\"$(HELP_URL)\"" >> $(BUILDDIR)rootfs.tmp/etc/ocs-release
	echo "IMAGE_SOURCE_URL=\"$(SOURCE_URL)\"" >> $(BUILDDIR)rootfs.tmp/etc/ocs-release
	echo "IMAGE_DOC_URL=\"$(DOC_URL)\"" >> $(BUILDDIR)rootfs.tmp/etc/ocs-release
	mv $(BUILDDIR)rootfs.tmp $(BUILDDIR)rootfs


$(BUILDDIR)rootfs.tar: $(BUILDDIR)rootfs
	tar --format=gnu -C $(BUILDDIR)rootfs -cf $(BUILDDIR)rootfs.tar.tmp .
	mv $(BUILDDIR)rootfs.tar.tmp $(BUILDDIR)rootfs.tar


$(BUILDDIR)rootfs.sqsh: $(BUILDDIR)rootfs
	mksquashfs $(BUILDDIR)rootfs $(BUILDDIR)rootfs.sqsh -noI -noD -noF -noX


$(BUILDDIR)export.tar: .docker-container.built
	-mkdir -p $(BUILDDIR)
	docker run --name $(NAME)-$(VERSION)-export --entrypoint /dontexists $(NAME):$(VERSION) 2>/dev/null || true
	docker export $(NAME)-$(VERSION)-export > $(BUILDDIR)export.tar.tmp
	docker rm $(NAME)-$(VERSION)-export
	mv $(BUILDDIR)export.tar.tmp $(BUILDDIR)export.tar


/mnt/$(DISK):
	umount $(DISK) || true
	mkfs.ext4 $(DISK)
	mkdir -p /mnt/$(DISK)
	mount $(DISK) /mnt/$(DISK)
