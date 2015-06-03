//
//  StereogramTestCase.h
//  Stereogram
//
//  Created by Patrick Wallace on 02/06/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import UIKit;
@import XCTest;

	/// This is a subclass which creates and tears down common objects used when handling stereograms
	/// (such as a temp directory to put stereograms into).

@interface StereogramTestCase : XCTestCase

@property (nonatomic, readonly) NSURL *tmpdirURL;
@property (nonatomic, readonly) NSFileManager *fileManager;
@property (nonatomic, readonly) NSBundle *bundle;
@property (nonatomic, readonly) UIImage *leftImage;
@property (nonatomic, readonly) UIImage *rightImage;
@property (nonatomic, readonly) NSURL *emptyDirURL;
@property (nonatomic, readonly) NSString *emptyDirectoryName;


/*!
 * Asserts that the directory under URL contains the number of sub-directories in NUMSUBDIRS.
 *
 * Makes no assumptions about any other contents under the URL, just counts the directories.
 */
-(BOOL) url: (NSURL *)url containsSubdirs: (NSUInteger)numSubdirs;

@end

