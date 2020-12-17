CC              ?= aarch64-apple-darwin-clang
STRIP           ?= aarch64-apple-darwin-strip
LDID            ?= ldid
CFLAGS          ?= -arch arm64  -isysroot /home/cameron/Documents/SDK/iPhoneOS14.2.sdk -miphoneos-version-min=13.0
INSTALL         ?= install
FAKEROOT        ?= fakeroot
PREFIX          ?= /usr
DESTDIR         ?= 

DEB_MAINTAINER  ?= Cameron Katri <me@cameronkatri.com>
DEB_ARCH        ?= iphoneos-arm
SNAPRESTORE_V   := 0.3
DEB_SNAPRESTORE := $(SNAPRESTORE_V)

all: build/snaprestore

build/snaprestore: src/snaprestore.m src/ent.xml
	mkdir -p build
	$(CC) $(CFLAGS) -o build/snaprestore src/snaprestore.m -framework IOKit -framework Foundation -framework CoreServices -fobjc-arc
	$(STRIP) build/snaprestore
	$(LDID) -Ssrc/ent.xml build/snaprestore

install: build/snaprestore
	$(INSTALL) -Dm755 build/snaprestore $(DESTDIR)$(PREFIX)/bin/snaprestore
	$(INSTALL) -Dm644 LICENSE $(DESTDIR)$(PREFIX)/share/snaprestore/LICENSE

package: build/snaprestore
	rm -rf staging
	$(INSTALL) -Dm755 build/snaprestore staging$(PREFIX)/bin/snaprestore
	$(INSTALL) -Dm644 LICENSE staging$(PREFIX)/share/snaprestore/LICENSE
	$(FAKEROOT) chown -R 0:0 staging
	SIZE=$$(du -s staging | cut -f 1); \
	$(INSTALL) -Dm755 src/snaprestore.control staging/DEBIAN/control; \
	sed -i ':a; s/@DEB_SNAPRESTORE@/$(DEB_SNAPRESTORE)/g; ta' staging/DEBIAN/control; \
	sed -i ':a; s/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g; ta' staging/DEBIAN/control; \
	sed -i ':a; s/@DEB_ARCH@/$(DEB_ARCH)/g; ta' staging/DEBIAN/control; \
	cd staging && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '"%P" ' | xargs md5sum > DEBIAN/md5sum; \
	cd ..; \
	echo "Installed-Size: $$SIZE" >> staging/DEBIAN/control
	$(FAKEROOT) dpkg-deb -z9 -b staging build
	rm -rf staging

clean: 
	rm -f build/snaprestore
