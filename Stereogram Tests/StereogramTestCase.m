//
//  StereogramTestCase.m
//  Stereogram-iPad
//
//  Created by Patrick Wallace on 29/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.

#import "StereogramTestCase.h"

BOOL urlIsDirectory(NSFileManager *fileManager, NSURL *path) {
	BOOL isValid = NO, isDir = NO;
	if ([fileManager fileExistsAtPath:path.path isDirectory:&isDir]) {
		isValid = isDir;
	}
	return isValid;
}


@implementation StereogramTestCase


-(NSURL *) makeEmptyDirectory {
	NSString *tmpDir = NSTemporaryDirectory();
	NSURL *tmpURL = [NSURL fileURLWithPath:tmpDir isDirectory:YES];
	NSURL *srcURL = [self.bundle URLForResource:self.emptyDirectoryName withExtension: nil];
	if (tmpDir && tmpURL && srcURL) {
		NSURL *newDir = [tmpURL URLByAppendingPathComponent:self.tmpdirURL.path];
		NSError *error = nil;
		BOOL result = [self.fileManager copyItemAtURL:srcURL toURL: newDir error: &error];
		NSAssert(result, @"File Manager copy from %@ to %@ failed with error %@", srcURL, newDir, error);
		return newDir.URLByStandardizingPath;
	}
	return nil; // Copy failed.
}

	// This method is called before the invocation of each test method in the class.
-(void) setUp {
	[super setUp];
	
	NSBundle *bundle = [NSBundle bundleForClass:self.class];

	_tmpdirURL = [NSURL fileURLWithPath:@"Photostore Temp Empty Directory"];
	_fileManager = [NSFileManager defaultManager];
	_bundle = bundle;
	_leftImage  = [UIImage imageNamed:@"LeftPhoto"  inBundle:bundle compatibleWithTraitCollection:nil];
	_rightImage = [UIImage imageNamed:@"RightPhoto" inBundle:bundle compatibleWithTraitCollection:nil];
	_emptyDirURL = nil;
	_emptyDirectoryName = @"PhotoStore Empty Directory";

		// Delete the temporary directory in case any previous test left it behind.
	[self deleteTempDirectory];
	_emptyDirURL = [self makeEmptyDirectory];
}

	// This method is called after the invocation of each test method in the class.
-(void) tearDown {
		// Ensure nothing has deleted the temporary directory during the tests.
	XCTAssert(urlIsDirectory(self.fileManager, self.emptyDirURL), "URL %@ has been deleted during the previous test.", self.emptyDirURL);

		// Delete the temporary directory in case any previous test left it behind.
	[self deleteTempDirectory];

	[super tearDown];
}


-(BOOL) deleteTempDirectory {
	NSString *path = NSTemporaryDirectory();
	NSURL *tmpURL = [NSURL fileURLWithPath:path isDirectory:YES];
	NSString *dirName = self.tmpdirURL.path;
	if (dirName && tmpURL && path) {
		NSURL *mydirURL = [tmpURL URLByAppendingPathComponent:dirName];
		NSError *error = nil;
		if ([self.fileManager removeItemAtURL:mydirURL error:&error]) {
			return YES;
		}
	}
	return NO;
}


	/// Asserts that the directory under URL contains the number of sub-directories in NUMSUBDIRS.
	///
	/// Makes no assumptions about any other contents under the URL, just counts the directories.
-(BOOL) url: (NSURL *)url containsSubdirs: (NSUInteger)numSubdirs {
	NSError *error = nil;
	NSArray *fileArray = [self.fileManager contentsOfDirectoryAtURL:url
										 includingPropertiesForKeys:nil
															options:NSDirectoryEnumerationSkipsHiddenFiles
															  error:&error];
	if (fileArray) {
		NSArray *validStereograms = [fileArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *object, NSDictionary *bindings) {
			return urlIsDirectory(self.fileManager, object);
		}]];
		NSUInteger numStereograms = validStereograms.count;
		return numStereograms == numSubdirs;
	} else {
		XCTFail(@"Error searching test directory: %@", error);
		return NO;
	}
}

@end

//BOOL URLContainsSubdirs(NSFileManager *fileManager, NSURL *url, NSUInteger numSubdirs) {
//	NSError *error = nil;
//	NSArray *fileArray = [fileManager contentsOfDirectoryAtURL:url
//									includingPropertiesForKeys:nil
//													   options:NSDirectoryEnumerationSkipsHiddenFiles
//														 error:&error];
//	if (fileArray) {
//		NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(NSURL *evaluatedObject, NSDictionary *bindings) {
//			BOOL isDir = NO;
//			return [fileManager fileExistsAtPath:evaluatedObject.path isDirectory:&isDir] && isDir;
//		}];
//		NSArray *numDirectories = [fileArray filteredArrayUsingPredicate:pred];
//		NSUInteger numStereograms = numDirectories.count;
//		return numStereograms == numSubdirs;
//	} else {
//		XCTFail(@"Error searching test directory: %@", error);
//		return NO;
//	}
//}


