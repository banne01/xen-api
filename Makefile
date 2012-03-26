ifdef B_BASE
include $(B_BASE)/common.mk
include $(B_BASE)/rpmbuild.mk
REPO=$(call git_loc,xen-api)
else
MY_OUTPUT_DIR ?= $(CURDIR)/output
MY_OBJ_DIR ?= $(CURDIR)/obj
REPO ?= $(CURDIR)

RPM_SPECSDIR?=$(shell rpm --eval='%_specdir')
RPM_SRPMSDIR?=$(shell rpm --eval='%_srcrpmdir')
RPM_SOURCESDIR?=$(shell rpm --eval='%_sourcedir')
RPMBUILD?=rpmbuild
XEN_RELEASE?=unknown
endif

BASE_PATH=$(shell scripts/base-path scripts/xapi.conf)

JQUERY=$(CARBON_DISTFILES)/javascript/jquery/jquery-1.1.3.1.pack.js
JQUERY_TREEVIEW=$(CARBON_DISTFILES)/javascript/jquery/treeview/jquery.treeview.zip

COMPILE_NATIVE=yes
COMPILE_BYTE=no # bytecode version does not build
export COMPILE_NATIVE COMPILE_BYTE

# FHS stuff
VARDIR=/var/xapi
VARPATCHDIR=/var/patch
ETCDIR=/etc/xensource
OPTDIR=/opt/xensource
PLUGINDIR=/etc/xapi.d/plugins
HOOKSDIR=/etc/xapi.d
INVENTORY=/etc/xensource-inventory
XAPICONF=/etc/xapi.conf
LIBEXECDIR=/opt/xensource/libexec
SCRIPTSDIR=/etc/xensource/scripts
SHAREDIR=/opt/xensource
WEBDIR=/opt/xensource/www
XHADIR=/opt/xensource/xha
BINDIR=/opt/xensource/bin
SBINDIR=/opt/xensource/bin

export VARDIR ETCDIR OPTDIR PLUGINDIR HOOKSDIR INVENTORY VARPATCHDIR LIBEXECDIR XAPICONF SCRIPTSDIR SHAREDIR WEBDIR XHADIR BINDIR SBINDIR

.PHONY: all
all: version ocaml/fhs.ml
	omake phase1
	omake phase2
	omake phase3

.PHONY: phase3
phase3:
	omake phase3

.PHONY: test
test:
	omake test

.PHONY: install
install:
	omake install
	omake lib-uninstall
	omake lib-install

.PHONY: lib-install
lib-install:
	omake DESTDIR=$(DESTDIR) lib-install

.PHONY: lib-uninstall
lib-uninstall:
	omake DESTDIR=$(DESTDIR) lib-uninstall

.PHONY: sdk-install
sdk-install: doc
	omake sdk-install

.PHONY: clean
clean:
	omake clean
	omake lib-uninstall
	rm -rf dist/staging
	rm -f .omakedb .omakedb.lock xapi.spec

.PHONY: otags
otags:
	otags -vi -r . -o tags

.PHONY: doc
doc: api-doc api-libs-doc

.PHONY: api-doc
api-doc: version
	omake phase1 phase2 # autogenerated files might be required
	omake doc

.PHONY: api-libs-doc
api-libs-doc:
	@(cd ../xen-api-libs 2> /dev/null && $(MAKE) doc) || \
	 (echo ">>> If you have a myclone of xen-api-libs, its documentation will be included. <<<")

PLATFORM_VERSION ?= 0.0.0

.PHONY: version
version:
	@printf "(* This file is autogenerated.  Grep for e17512ce-ba7c-11df-887b-0026b9799147 (random uuid) to see where it comes from. ;o) *) \n \
	let git_id = \"$(shell git show-ref --head | grep -E ' HEAD$$' | cut -f 1 -d ' ')\" \n \
	let hostname = \"$(shell hostname)\" \n \
	let date = \"$(shell date -u +%Y-%m-%d)\" \n \
	let product_version = Util_inventory.lookup ~default:\"\" \"PRODUCT_VERSION\" \n \
	let product_version_text = Util_inventory.lookup ~default:\"\" \"PRODUCT_VERSION_TEXT\" \n \
	let product_version_text_short = Util_inventory.lookup ~default:\"\" \"PRODUCT_VERSION_TEXT_SHORT\" \n \
	let platform_name = \"$(PLATFORM_NAME)\" \n \
	let platform_version = \"$(PLATFORM_VERSION)\" \n \
	let product_brand = Util_inventory.lookup ~default:\"\" \"PRODUCT_BRAND\" \n \
	let build_number = Util_inventory.lookup ~default:\"$(BUILD_NUMBER)\" \"BUILD_NUMBER\" \n \
	let xapi_version_major = $(shell cut -d. -f1 VERSION) \n \
	let xapi_version_minor = $(shell cut -d. -f2 VERSION) \n" \
	> ocaml/util/version.ml

ocaml/fhs.ml :
	@printf "(* This file is autogenerated by xen-api.git/Makefile *)\n \
	let vardir=\"$(VARDIR)\"\n \
	let etcdir=\"$(ETCDIR)\"\n \
	let optdir=\"$(OPTDIR)\"\n \
	let plugindir=\"$(PLUGINDIR)\"\n \
	let inventory=\"$(INVENTORY)\"\n \
	let hooksdir=\"$(HOOKSDIR)\"\n \
	let libexecdir=\"$(LIBEXECDIR)\"\n \
	let xapiconf=\"$(XAPICONF)\"\n \
	let scriptsdir=\"$(SCRIPTSDIR)\"\n \
	let varpatchdir=\"$(VARPATCHDIR)\"\n \
	let webdir=\"$(WEBDIR)\"\n \
	let xhadir=\"$(XHADIR)\"\n \
	let bindir=\"$(BINDIR)\"\n \
	let sbindir=\"$(SBINDIR)\"\n \
	let sharedir=\"$(SHAREDIR)\"\n" \
	> ocaml/fhs.ml
 
.PHONY: clean
 clean:

.PHONY: xapi.spec
xapi.spec: xapi.spec.in
	sed -e 's/@RPM_RELEASE@/$(shell git rev-list HEAD | wc -l)/g' < $< > $@
	sed -i "s!@OPTDIR@!${OPTDIR}!g" $@

.PHONY: srpm
srpm: xapi.spec
	mkdir -p $(RPM_SOURCESDIR) $(RPM_SPECSDIR) $(RPM_SRPMSDIR)
	while ! [ -d .git ]; do cd ..; done; \
	git archive --prefix=xapi-0.2/ --format=tar HEAD | bzip2 -z > $(RPM_SOURCESDIR)/xapi-0.2.tar.bz2 # xen-api/Makefile
	cp $(JQUERY) $(JQUERY_TREEVIEW) $(RPM_SOURCESDIR)
	make -C $(REPO) version
	rm -f $(RPM_SOURCESDIR)/xapi-version.patch
	(cd $(REPO); diff -u /dev/null ocaml/util/version.ml > $(RPM_SOURCESDIR)/xapi-version.patch) || true
	cp -f xapi.spec $(RPM_SPECSDIR)/
	chown root.root $(RPM_SPECSDIR)/xapi.spec || true
	$(RPMBUILD) -bs --nodeps $(RPM_SPECSDIR)/xapi.spec


.PHONY: build
build: all

