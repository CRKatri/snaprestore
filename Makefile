CC     = aarch64-apple-darwin-clang
STRIP  = aarch64-apple-darwin-strip
LDID   = ldid
CFLAGS = -arch arm64  -isysroot /home/cameron/Documents/SDK/iPhoneOS14.2.sdk -miphoneos-version-min=13.0 -isystem /home/cameron/Documents/Procursus/build_base/iphoneos-arm64/1600/usr/include -isystem /home/cameron/Documents/Procursus/build_base/iphoneos-arm64/1600/usr/local/include -F/home/cameron/Documents/Procursus/build_base/iphoneos-arm64/1600/System/Library/Frameworks

all: snaprestore

snaprestore: snaprestore.m ent.xml NSTask.h
	$(CC) $(CFLAGS) -o snaprestore snaprestore.m -framework IOKit -framework Foundation -fobjc-arc
	$(LDID) -Sent.xml snaprestore

clean: 
	rm -f snaprestore
