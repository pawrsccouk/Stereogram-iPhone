//
//  Stereogram_Unit_Tests.m
//  Stereogram Unit Tests
//
//  Created by Patrick Wallace on 30/06/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "Stereogram_Unit_Tests.h"
#import "PWPhotoStore.h"

@interface Stereogram_Unit_Tests ()
{
    PWPhotoStore *_photoStore;
}
@end

@implementation Stereogram_Unit_Tests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here -  Code is run before each testXX method.
    NSError *error = [PWPhotoStore setupStore];
    if(error) {
        @throw [NSException exceptionWithName:@"Setup Error"
                                       reason:error.localizedDescription
                                     userInfo:error.userInfo];
    }
    _photoStore = [PWPhotoStore sharedStore];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
    _photoStore = nil;
}

static NSString *getDocumentDir()
{
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *photoDir = [folders[0] stringByAppendingPathComponent:@"Pictures"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO, fileExists = [fileManager fileExistsAtPath:photoDir isDirectory:&isDirectory];
    if(fileExists && isDirectory) return photoDir;
    return nil;
}

static int countPhotosInDirectory(NSString *documentDir)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentDir error:nil];
    int count = 0;
    for(NSString *file in files)
        count++;
    return count;
}

static BOOL equalFiles(NSArray *storeFiles, NSString *documentDir)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentDir error:nil].mutableCopy;
    NSMutableArray *onDirNotStore = [NSMutableArray array], * onStoreNotDir = [NSMutableArray array];
    
    for (NSString *file in files)
        if(! [storeFiles containsObject:file])
            [onDirNotStore addObject:file];
    
    for (NSString *file in storeFiles)
        if(! [files containsObject:file])
            [onStoreNotDir addObject:file];
    
    return onDirNotStore.count == 0 && onStoreNotDir.count == 0;
}

-(void)testInitialSetup
{
    int dirCount = countPhotosInDirectory(getDocumentDir());
    STAssertEquals(dirCount, _photoStore.count, @"Photo count and count in directory not equal.");
}

- (void)testExample
{
    STFail(@"Unit tests are not implemented yet in Stereogram Unit Tests");
}

@end
