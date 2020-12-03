CC               = aarch64-apple-darwin-clang
STRIP            = aarch64-apple-darwin-strip
LDID             = ldid
CFLAGS           = -arch arm64  -isysroot /home/cameron/Documents/SDK/iPhoneOS14.2.sdk -miphoneos-version-min=13.0 -isystem /home/cameron/Documents/Procursus/build_base/iphoneos-arm64/1600/usr/include -isystem /home/cameron/Documents/Procursus/build_base/iphoneos-arm64/1600/usr/local/include -F/home/cameron/Documents/Procursus/build_base/iphoneos-arm64/1600/System/Library/Frameworks
INSTALL          = install
FAKEROOT         = fakeroot
PREFIX          ?= /usr
DESTDIR         ?= 

DEB_MAINTAINER  ?= Cameron Katri <me@cameronkatri.com>
DEB_ARCH        ?= iphoneos-arm
SNAPRESTORE_V   := 0.1
DEB_SNAPRESTORE := $(SNAPRESTORE_V)

all: snaprestore

snaprestore: snaprestore.m ent.xml NSTask.h
	$(CC) $(CFLAGS) -o snaprestore snaprestore.m -framework IOKit -framework Foundation -fobjc-arc
	$(LDID) -Sent.xml snaprestore

install: snaprestore
	$(INSTALL) -Dm755 snaprestore $(DESTDIR)$(PREFIX)/bin/snaprestore
	$(INSTALL) -Dm644 LICENSE $(DESTDIR)$(PREFIX)/share/snaprestore/LICENSE

package: snaprestore
	rm -rf staging
	$(INSTALL) -Dm755 snaprestore staging$(PREFIX)/bin/snaprestore
	$(INSTALL) -Dm644 LICENSE staging$(PREFIX)/share/snaprestore/LICENSE
	$(FAKEROOT) chown -R 0:0 staging
	SIZE=$$(du -s staging | cut -f 1); \
	$(INSTALL) -Dm755 snaprestore.control staging/DEBIAN/control; \
	sed -i ':a; s/@DEB_SNAPRESTORE@/$(DEB_SNAPRESTORE)/g; ta' staging/DEBIAN/control; \
	sed -i ':a; s/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g; ta' staging/DEBIAN/control; \
	sed -i ':a; s/@DEB_ARCH@/$(DEB_ARCH)/g; ta' staging/DEBIAN/control; \
	cd staging && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '"%P" ' | xargs md5sum > DEBIAN/md5sum; \
	cd ..; \
	echo "Installed-Size: $$SIZE" >> staging/DEBIAN/control
	$(FAKEROOT) dpkg-deb -z9 -b staging .
	rm -rf staging

clean: 
	rm -f snaprestore
