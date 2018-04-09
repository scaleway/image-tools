# Environment checkup
ifndef IMAGE_DIR
$(error "No image directory specified (IMAGE_DIR)")
endif
include $(IMAGE_DIR)/env.mk
ifndef IMAGE_NAME
$(error "No image base name found (IMAGE_NAME), e.g. 'ubuntu'")
endif
ifndef IMAGE_VERSION
$(error "No image version found (IMAGE_VERSION), e.g. 'xenial'")
endif
ifndef IMAGE_TITLE
$(error "No image title found (IMAGE_TITLE), e.g. 'Ubuntu Xenial (16.04)'")
endif

# Architecture variables setup
## Normalize host arch
HOST_ARCH := $(shell uname -m)
ifeq ($(HOST_ARCH), $(filter $(HOST_ARCH),arm armhf armv7l))
	HOST_ARCH = arm
else ifeq ($(HOST_ARCH), $(filter $(HOST_ARCH),arm64 aarch64))
	HOST_ARCH = arm64
else ifeq ($(HOST_ARCH), $(filter $(HOST_ARCH),x86_64 amd64))
	HOST_ARCH = x86_64
endif
ARCH ?= $(HOST_ARCH)

## Normalize other arch variables
ifeq ($(ARCH), $(filter $(ARCH),arm armhf armv7l))
	TARGET_QEMU_ARCH=arm
	TARGET_SCW_ARCH=arm
	TARGET_DOCKER_REPO_ARCH=arm32v7
	TARGET_MULTIARCH_ARCH=armhf
	TARGET_GOLANG_ARCH=arm
else ifeq ($(ARCH), $(filter $(ARCH),arm64 aarch64))
	TARGET_QEMU_ARCH=aarch64
	TARGET_SCW_ARCH=arm64
	TARGET_DOCKER_REPO_ARCH=arm64v8
	TARGET_MULTIARCH_ARCH=aarch64
	TARGET_GOLANG_ARCH=arm64
else ifeq ($(ARCH), $(filter $(ARCH),x86_64 amd64))
	TARGET_QEMU_ARCH=x86_64
	TARGET_SCW_ARCH=x86_64
	TARGET_DOCKER_REPO_ARCH=amd64
	TARGET_MULTIARCH_ARCH=amd64
	TARGET_GOLANG_ARCH=amd64
endif

DOCKER_NAMESPACE ?= scaleway
BUILD_OPTS ?=
override BUILD_ARGS += SCW_ARCH=$(TARGET_SCW_ARCH) MULTIARCH_ARCH=$(TARGET_MULTIARCH_ARCH) DOCKER_ARCH=$(TARGET_DOCKER_REPO_ARCH)
REGION ?= par1
export REGION
BUILD_METHOD ?= from-rootfs
SERVE_ASSETS ?= y
EXPORT_DIR ?= $(IMAGE_DIR)/export/$(TARGET_IMAGE_ARCH)
ASSETS_DIR ?= $(EXPORT_DIR)/assets
OUTPUT_ID_TO ?= $(EXPORT_DIR)/image_id
export OUTPUT_ID_TO

ifdef IMAGE_BOOTSCRIPT_$(TARGET_SCW_ARCH)
IMAGE_BOOTSCRIPT = $(IMAGE_BOOTSCRIPT_$(TARGET_SCW_ARCH))
endif

ifeq ($(shell which scw-metadata >/dev/null 2>&1; echo $$?), 0)
IS_SCW_HOST := y
LOCAL_SCW_REGION := $(shell scw-metadata --cached LOCATION_ZONE_ID)
export LOCAL_SCW_REGION
ifeq ($(LOCAL_SCW_REGION), $(REGION))
SERVE_IP := $(shell scw-metadata --cached PRIVATE_IP)
else
SERVE_IP := $(shell scw-metadata --cached PUBLIC_IP_ADDRESS)
endif
SERVE_PORT := $(shell shuf -i 10000-60000 -n 1)
else
IS_SCW_HOST := n
ifeq ($(SERVE_ASSETS), n)
ifndef SERVE_IP
$(error "Not a Scaleway host and no server IP given")
endif
ifndef SERVE_PORT
$(error "Not a Scaleway host and no server port given")
endif
endif
endif
export IS_SCW_HOST

# Default action: display usage
.PHONY: usage
usage:
	@echo 'Usage'
	@echo ' image                   build the Docker image'
	@echo ' rootfs.tar              export the Docker image to a rootfs.tar'
	@echo ' scaleway_image          create a Scaleway image, requires a working `scaleway-cli'
	@echo ' local_tests             run TIM tests against the Docker image'
	@echo ' tests                   run TIM tests against the image on Scaleway'

.PHONY: fclean
fclean: clean
	for tag in latest $(shell docker images | grep "^$(DOCKER_NAMESPACE)/$(IMAGE_NAME) " | awk '{print $$2}'); do\
	  echo "Creating a backup of '$(DOCKER_NAMESPACE)/$(IMAGE_NAME):$$tag' for caching"; \
	  docker tag $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$$tag old$(DOCKER_NAMESPACE)/$(IMAGE_NAME):$$tag; \
	  docker rmi -f $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$$tag; \
	done

.PHONY: clean
clean:
	-rm -f $(ASSETS_DIR) $(EXPORT_DIR)/export.tar $(EXPORT_DIR)/image_built
	-rm -rf $(EXPORT_DIR)/rootfs

$(EXPORT_DIR):
	mkdir -p $(EXPORT_DIR)

$(ASSETS_DIR):
	mkdir -p $(ASSETS_DIR)

.PHONY: image
image: $(EXPORT_DIR)
ifneq ($(TARGET_SCW_ARCH), $(HOST_ARCH))
	docker run --rm --privileged multiarch/qemu-user-static:register --reset
endif
ifdef IMAGE_BASE_FLAVORS
	$(foreach bf,$(IMAGE_BASE_FLAVORS),rsync -az bases/overlay-$(bf)/ $(IMAGE_DIR)/overlay-base;)
endif
	docker build $(BUILD_OPTS) -t $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$(TARGET_SCW_ARCH)-$(IMAGE_VERSION) $(foreach ba,$(BUILD_ARGS),--build-arg $(ba)) $$([ -r Dockerfile.$(TARGET_SCW_ARCH) ] && echo "-f Dockerfile.$(TARGET_SCW_ARCH)") $(IMAGE_DIR)
	$(eval IMAGE_BUILT_UUID := $(shell docker inspect -f '{{.Id}}' $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$(TARGET_SCW_ARCH)-$(IMAGE_VERSION)))
	if [ "$$(cat $(EXPORT_DIR)/image_built 2>/dev/null)" != "$(IMAGE_BUILT_UUID)" ]; then \
	    printf "%s" "$(IMAGE_BUILT_UUID)" > $(EXPORT_DIR)/image_built; \
	    echo $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$(TARGET_SCW_ARCH)-$(IMAGE_VERSION) >$(EXPORT_DIR)/docker_tags; \
	    $(eval IMAGE_VERSION_ALIASES += $(shell date +%Y-%m-%d)) \
	    $(foreach v,$(IMAGE_VERSION_ALIASES),\
	        docker tag $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$(TARGET_SCW_ARCH)-$(IMAGE_VERSION) $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$(TARGET_SCW_ARCH)-$v;\
	        echo $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$(TARGET_SCW_ARCH)-$v >>$(EXPORT_DIR)/docker_tags;) \
	fi

$(EXPORT_DIR)/image_built: image

$(ASSETS_DIR)/rootfs.tar: $(EXPORT_DIR)/image_built $(ASSETS_DIR)
	echo "IMAGE_ID=\"$(IMAGE_TITLE)\"" >> $(EXPORT_DIR)/scw-release
	echo "IMAGE_RELEASE=$(shell date +%Y-%m-%d)" >> $(EXPORT_DIR)/scw-release
	echo "IMAGE_CODENAME=$(IMAGE_NAME)" >> $(EXPORT_DIR)/scw-release
	echo "IMAGE_DESCRIPTION=\"$(IMAGE_DESCRIPTION)\"" >> $(EXPORT_DIR)/scw-release
	echo "IMAGE_HELP_URL=\"$(IMAGE_SOURCE_URL)\"" >> $(EXPORT_DIR)/scw-release
	echo "IMAGE_SOURCE_URL=\"$(IMAGE_SOURCE_URL)\"" >> $(EXPORT_DIR)/scw-release
	echo "IMAGE_DOC_URL=\"$(IMAGE_SOURCE_URL)\"" >> $(EXPORT_DIR)/scw-release
	cat $(EXPORT_DIR)/scw-release | docker run --name $(IMAGE_NAME)-$(IMAGE_VERSION)-export -i $(DOCKER_NAMESPACE)/$(IMAGE_NAME):$(TARGET_SCW_ARCH)-$(IMAGE_VERSION) sh -c "rm /.dockerenv; cat >/etc/scw-release" 2>/dev/null || true
	docker export -o $@.tmp $(IMAGE_NAME)-$(IMAGE_VERSION)-export
	docker rm $(IMAGE_NAME)-$(IMAGE_VERSION)-export
	mv $@.tmp $@

rootfs.tar: $(ASSETS_DIR)/rootfs.tar
	ls -la $<
	@echo $<

from-rootfs-common: rootfs.tar
	$(eval ROOTFS_URL := $(SERVE_IP):$(SERVE_PORT)/rootfs.tar)
ifeq ($(SERVE_ASSETS), y)
	scripts/assets_server.sh start $(SERVE_PORT) $(ASSETS_DIR)
endif
	scripts/create_image_live_from_rootfs.sh "$(ROOTFS_URL)" "$(IMAGE_TITLE)" "$(TARGET_SCW_ARCH)" "$(IMAGE_BOOTSCRIPT)" "$(BUILD_METHOD)"
ifeq ($(SERVE_ASSETS), y)
	scripts/assets_server.sh stop $(SERVE_PORT)
endif

from-rootfs: from-rootfs-common

unpartitioned-from-rootfs: from-rootfs-common

.PHONY: scaleway_image
scaleway_image: $(BUILD_METHOD)

.PHONY: tests
tests:
	scripts/test_image.sh start $(TARGET_SCW_ARCH) $(REGION) $(IMAGE_ID) $(EXPORT_DIR)/$(IMAGE_ID).servers $(IMAGE_DIR)/tim_tests
ifneq ($(NO_CLEANUP), true)
	scripts/test_image.sh stop $(EXPORT_DIR)/$(IMAGE_ID).servers
endif
