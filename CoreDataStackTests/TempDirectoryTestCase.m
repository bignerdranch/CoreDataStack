//
//  TempDirectoryTestCase.m
//  CoreDataStack
//
//  Created by Brian Hardy on 8/13/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

#import "TempDirectoryTestCase.h"

@interface TempDirectoryTestCase()

@property (nonatomic, strong) NSURL *tempDirectory;

@end

@implementation TempDirectoryTestCase

- (NSURL *)makeTempDirectory {
    NSString *tempDir = NSTemporaryDirectory();
    NSString *nameTemplate = [NSString stringWithFormat:@"%@.XXXXX", self.class];
    NSString *combinedTempDirName = [tempDir stringByAppendingPathComponent:nameTemplate];
    // FIXME: how to get rid of this warning? copy the string?
    char *fsRep = combinedTempDirName.fileSystemRepresentation;
    char *uniqueName = mkdtemp(fsRep);
    if (uniqueName == NULL) {
        return nil;
    }
    NSString *tempDirPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:uniqueName length:strlen(uniqueName)];
    return [NSURL fileURLWithPath:tempDirPath isDirectory:YES];
}

- (void)removeTempDirectory {
    NSError *error;
    if (![[NSFileManager defaultManager] removeItemAtURL:self.tempDirectory error:&error]) {
        NSLog(@"Could not remove temp directory: %@", error);
    }
}

- (void)setUp {
    [super setUp];
    
    self.tempDirectory = [self makeTempDirectory];
    self.tempStoreURL = [self.tempDirectory URLByAppendingPathComponent:@"testmodel.sqlite"];
}

- (void)tearDown {
    [self removeTempDirectory];
    
    [super tearDown];
}

@end
