COMPANY_NAME ?= gcr.io/nuclearis-168517
GIT_BRANCH ?= origin/develop
PRODUCT_NAME ?= onlyoffice-dev
PRODUCT_VERSION ?= 5.1.3
BUILD_NUMBER ?= 38

# File where to store auto increments                                          
BUILDER_FILE ?= .build_version

# Initiate BUILDER_FILE if not exists                                              
BUILDER_VERSION_CREATE := $(shell if ! test -f $(BUILDER_FILE); then echo 0 > $(BUILDER_FILE); fi)

# Prepare callable function. This function updates BUILDER_FILE
BUILDER_VERSION = $(shell echo $$(($$(cat $(BUILDER_FILE)) + 1)) > $(BUILDER_FILE))

BUILD_NUMBER = $(shell cat $(BUILDER_FILE))

PACKAGE_VERSION := $(PRODUCT_VERSION)-$(BUILD_NUMBER)

UPDATE_LATEST := false

ifneq (,$(findstring develop,$(GIT_BRANCH)))
DOCKER_TAGS += $(subst -,.,$(PACKAGE_VERSION))
DOCKER_TAGS += latest
else ifneq (,$(findstring release,$(GIT_BRANCH)))
DOCKER_TAGS += $(subst -,.,$(PACKAGE_VERSION))
else ifneq (,$(findstring hotfix,$(GIT_BRANCH)))
DOCKER_TAGS += $(subst -,.,$(PACKAGE_VERSION))
else
DOCKER_TAGS += $(subst -,.,$(PACKAGE_VERSION))-$(subst /,-,$(GIT_BRANCH))
endif

DOCKER_REPO = $(COMPANY_NAME)/$(PRODUCT_NAME)

COLON := \:
DOCKER_TARGETS := $(foreach TAG,$(DOCKER_TAGS),$(DOCKER_REPO)$(COLON)$(TAG))

.PHONY: all clean clean-docker deploy docker

$(DOCKER_TARGETS): $(DEB_REPO_DATA)
	#@echo $(BUILD_NUMBER)
	mkdir -p app_onlyoffice/documentserver
	mkdir -p app_onlyoffice/documentserver/server
	cp -fpR ../sdkjs/deploy/web-apps/sdkjs app_onlyoffice/documentserver/
	cp -fpR ../sdkjs/deploy/web-apps/web-apps app_onlyoffice/documentserver/
	cp -fpR ../SpellChecker-5.1.3.x app_onlyoffice/documentserver/server/
	cp -fpR ../../core/Modulos/nuclearis-web/src/main/webapp/resources/js/onlyoffice/sdkjs-plugins app_onlyoffice/documentserver/
	docker build -t $(subst $(COLON),:,$@) . &&\
	mkdir -p $$(dirname $@) &&\
	echo "Done" > $@
	$(call BUILDER_VERSION)

all: $(DOCKER_TARGETS)

clean:
	rm -Rf app_onlyoffice/documentserver
	rm -rfv $(DOCKER_TARGETS)
		
clean-docker:
	docker rmi -f $$(docker images -q $(COMPANY_NAME)/*) || exit 0

deploy: $(DOCKER_TARGETS)
	$(foreach TARGET,$(DOCKER_TARGETS), docker push $(subst $(COLON),:,$(TARGET));)
