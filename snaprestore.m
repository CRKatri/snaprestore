#import <Foundation/Foundation.h>
#import <Foundation/NSFileManager.h>
#import <IOKit/IOKitLib.h>
#import <sys/snapshot.h>
#import <getopt.h>
#import "NSTask.h"

void usage(char *name) {
	printf(
		"Usage: %s [volume] [snapshot]\n", name);
}

NSString *bootsnapshot() {
	const io_registry_entry_t chosen = IORegistryEntryFromPath(0, "IODeviceTree:/chosen");
	const NSData *data = (__bridge const NSData *)IORegistryEntryCreateCFProperty(chosen, (__bridge CFStringRef)@"boot-manifest-hash", kCFAllocatorDefault, 0);
	IOObjectRelease(chosen);

	NSMutableString *manifestHash = [NSMutableString stringWithString:@""]; 
	NSUInteger len = [data length];
	Byte *buf = (Byte*)malloc(len);
	memcpy(buf, [data bytes], len);
	int buf2;
	for (buf2 = 0; buf2 <= 19; buf2++) {
		[manifestHash appendFormat:@"%02X", buf[buf2]];
	}
	// add com.apple.os.update-
	return [NSString stringWithFormat:@"%@%@", @"com.apple.os.update-", manifestHash];
}

int restore(const char *vol, const char *snap) {
	int fd = open(vol, O_RDONLY, 0);

	int ret = fs_snapshot_revert(fd, snap, 0);
	return ret;
}

int mount(const char *vol, const char *snap, const char *mnt) {
	int fd = open(vol, O_RDONLY, 0);

	BOOL isDir;
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
		if(![fileManager fileExistsAtPath:[NSString stringWithUTF8String:mnt] isDirectory:&isDir])
			if(![fileManager createDirectoryAtPath:[NSString stringWithUTF8String:mnt] withIntermediateDirectories:YES attributes:nil error:NULL])
				NSLog(@"Error: Create folder failed %s", mnt);

	int ret = fs_snapshot_mount(fd, mnt, snap, 0);
	
	return ret;
}

NSMutableSet *findApps(const char *root, const char *mnt) {
	NSMutableString *rootApplications = [NSMutableString stringWithUTF8String:root];
	rootApplications = [[rootApplications stringByAppendingString:@"/Applications"] mutableCopy];

	NSMutableString *mntApplications = [NSMutableString stringWithUTF8String:mnt];
	mntApplications = [[mntApplications stringByAppendingString:@"/Applications"] mutableCopy];

	NSArray *rootApps = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rootApplications error:nil];
	NSArray *mntApps = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntApplications error:nil];

	NSMutableSet *ret = [[NSMutableSet alloc] init];
	for (NSString *app in rootApps) {
		if (![mntApps containsObject:app]) {
			[ret addObject:[@"/Applications/" stringByAppendingString:app]];
		}
	}

	return ret;
}

int rename(const char *vol, const char *snap) {
	int fd = open(vol, O_RDONLY, 0);

	int ret = fs_snapshot_rename(fd, snap, [bootsnapshot() UTF8String], 0);
	return ret;
}

int main(int argc, char *argv[]) {
	if (argc != 3) {
		usage(argv[0]);
		return 0;
	}

	char *vol = argv[1];
	char *snap = argv[2];
	char *mnt = "/tmp/rootfsmnt";

	printf("Restoring snapshot %s...\n", snap);
	restore(vol, snap);
	printf("Restored snapshot...\n");
	printf("Mounting rootfs...\n");
	mount(vol, snap, mnt);
	printf("Mounted %s at %s\n", snap, mnt);
	NSMutableSet *appSet = findApps(vol, mnt);
	if ([appSet count]) {
		printf("Refreshing icon cache...\n");
		NSMutableArray *argArray = [[NSMutableArray alloc] init];
		for (NSString *app in appSet) {
			[argArray addObject:@"-u"];
			[argArray addObject:app];
		}
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:@"/usr/bin/uicache"];
		[task setArguments:argArray];
		[task launch];
		[task waitUntilExit];
	}
	printf("Renaming snapshot...\n");
	rename(vol, snap);
	printf("Restoring %s on %s has succeeded\n", snap, vol); 
	return 0;
}
