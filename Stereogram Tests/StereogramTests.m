	//
	//  Stereogram_Tests.m
	//  Stereogram-iPad
	//
	//  Created by Patrick Wallace on 29/04/2015.
	//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
	//

#import "StereogramTestCase.h"
#import "Stereogram.h"
#import "PhotoStore.h"

static NSString *sz(CGSize size) {
	return [NSString stringWithFormat:@"(w:%0.2f, h:%0.2f)", size.width, size.height];
}

	/// Copy stereograms from a bundle directory into a url
	///
	/// :param: url        File URL to copy stereograms into.
	/// :param: fromBundle Bundle to search for the directory named _sourceName_
	/// :param: sourceName Name of a directory in the test bundle which has stereograms to copy.
	/// :returns: An array of file URLs of the stereograms copied.

NSArray *copyStereogramsIntoURL(NSURL *url, NSBundle *bundle, NSString *sourceName) {
	NSError *error = nil;
	NSArray *subdirs = [NSArray array];
	NSURL *bundleRootURL = [bundle URLForResource:sourceName withExtension:nil];
	if (bundleRootURL) {
		NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants
		|                                       NSDirectoryEnumerationSkipsHiddenFiles;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *dirs = [fileManager contentsOfDirectoryAtURL:bundleRootURL
								   includingPropertiesForKeys:nil
													  options:options
														error:&error];
		if (dirs) {
			subdirs = dirs;
			NSCAssert(dirs.count == 2
					  , @"Wrong number of URLs under %@. Was %lu expected 2", bundleRootURL, (unsigned long)subdirs.count);
			for (NSURL *subdir in dirs) {
				NSURL *fullNewPath = [url URLByAppendingPathComponent:subdir.lastPathComponent isDirectory: YES];
				BOOL success = [fileManager copyItemAtURL:subdir
													toURL:fullNewPath
													error:&error];
				NSCAssert(success, @"Failed to copy stereogram from %@ to %@: error %@", subdir, url, error);
			}
		} else {
			NSCAssert(false, @"File manager failed to search URL %@: error %@", bundleRootURL, error);
		}
	} else {
		NSCAssert(false, @"Failed to find directory %@ in bundle %@", sourceName, bundle);
	}
	return subdirs;
}

#pragma mark -

	// Name of a directory under our testing bundle containing 2 stereograms.
static NSString *photoStore2Directory = @"PhotoStore 2 Directory";

@interface StereogramTests: StereogramTestCase {
}
@end

	/// Returns the filename part of a URL.
	///
	/// :param: url A File URL to strip.
	/// :returns: The name of the file without the preceding directory.

NSString *fileNameFromURL(NSURL *url) {
	NSString *leaf = url.lastPathComponent;
	NSCAssert(leaf != nil, @"Couldn't get the directory name during the test.");
	return leaf;
}

typedef NSString*(*transformFn)(NSURL *obj);

NSArray *map(NSArray *array, transformFn fn) {
	NSMutableArray *rv = [NSMutableArray array];
	for (id obj in array) {
		id newObj = fn(obj);
		[rv addObject:newObj];
	}
	return rv;
}

@implementation StereogramTests

#pragma mark Private methods

	/// Fails the unit test if result is an error, otherwise returns whatever the result contained.
	///
	/// :param: result The result to test.
	/// :param: errorMessage The text to print out if the message fails.
	///                      I append the error text to this.
	/// :returns: The value contained in result if successful, or aborts if unsuccessful.


	//-(id) checkAndReturnResult {
	//		,       @autoclosure errorMessage: () -> String) -> T! {
	//			switch result {
	//			case .Success(let value):
	//				return value.contents
	//			case .Error(let error):
	//				XCTFail(errorMessage() + ": Error \(error)")
	//				return nil
	//			}
	//	}



-(NSArray *)fileNamesFromURLs: (NSArray*)urls {
	return map(urls, fileNameFromURL);
	//	NSMutableArray *rv = [NSMutableArray array];
	//	for (NSURL *fn in urls) {
	//		[rv addObject: [self fileNameFromURL:fn]];
	//	}
	//	return rv;
	//}
}


	/// Creates a new stereogram object under the base URL provided, and returns it.
	/// Asserts if the construction fails.
	///
	/// :note: This fails with a regular assert, not XCTFail()).
	///        So don't use when testing the Stereogram constructor,
	///        only when creating a Stereogram to test something else.
	///
	/// :param: url The URL to create the stereogram under.
	/// :returns: The stereogram created.

-(Stereogram *) makeStereogram: (NSURL *)url {
	NSError *error = nil;
	Stereogram *stereogram = [Stereogram stereogramWithDirectoryURL:url
														  leftImage:self.leftImage
														 rightImage:self.rightImage
															  error:&error];
	NSAssert(stereogram != nil, @"Stereogram.init() failed. Error: %@", error);
	return stereogram;
}


#pragma mark - Unit Test methods

	/// Test that initializing with images and a base URL
	/// actually creates the stereogram as a subdirectory of the base URL.
-(void) testInit_BaseURL {

	NSAssert([self url:self.emptyDirURL containsSubdirs:0]
			 , @"After setup 'empty' array %@ is not really empty.", self.emptyDirURL);
	
	NSError *error = nil;
	Stereogram *sgm = [Stereogram stereogramWithDirectoryURL:self.emptyDirURL
												   leftImage:self.leftImage
												  rightImage:self.rightImage
													   error:&error];
	if (sgm) {
		XCTAssert([self url:self.emptyDirURL containsSubdirs:1]
				  , @"Stereogram create - Creating stereogram in the wrong place.");
		NSURL *sgmURL = sgm.baseURL;
		NSURL *sgmBaseURL = sgmURL.URLByDeletingLastPathComponent;
		XCTAssertEqualObjects(self.emptyDirURL, sgmBaseURL
					   , @"Base URL %@ is not the url we gave it %@", sgmBaseURL, self.emptyDirURL);
	} else {
		XCTFail(@"Stereogram initializer failed with error %@", error);
	}
}

	/// Test the class function to ensure searching an empty directory returns no stereograms.
-(void) testFindStereogramsUnderURL_Empty {

		// Test against an empty directory.
	NSError *error = nil;
	NSArray *stereograms = [Stereogram allStereogramsUnderURL:self.emptyDirURL
														error:&error];
	XCTAssertNotNil(stereograms, @"Stereogram failed to search empty directory.");
	XCTAssertNil(error, @"Error retrieved after searching an empty directory: %@", error);
	XCTAssertEqual(stereograms.count, 0, @"Returned a value when searching an empty directory.");
}

	/// Test the class function to ensure it returns the right number of stereograms.
-(void) testFindStereogramsUnderURL_Existing {

		// Set up a base URL to search by copying two stereograms in from the bundle.
		// Returns an array with the full file URLs of the stereograms copied.
	NSArray *subdirs = copyStereogramsIntoURL(self.emptyDirURL, self.bundle, photoStore2Directory);

		// Test that we find them.
	NSError *error = nil;
	NSArray *stereograms = [Stereogram allStereogramsUnderURL:self.emptyDirURL error:&error];
	XCTAssertNotNil(stereograms, @"allStereogramsUnderURL failed with error %@", error);
		// Check that the right number of stereograms have been retrieved.
	XCTAssertEqual(stereograms.count, 2, "Returned the wrong number of stereograms when searching a directory.");

	NSArray *fileNames = map(subdirs, fileNameFromURL);
		// Check that each stereogram in the list has the same name as one in the source directory.
	for (Stereogram *s in stereograms) {
		NSString *stereogramName = s.baseURL.lastPathComponent;
		if (stereogramName) {
			NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(NSString *object, NSDictionary *d) {
				return [object isEqualToString:stereogramName];
			}];
			NSArray *filtered = [fileNames filteredArrayUsingPredicate:pred];
			NSUInteger numFound = filtered.count;
			XCTAssertEqual(numFound, 1, "Stereogram %@ name %@ not found in subdirs %@", s, stereogramName, fileNames);
		} else {
			XCTFail("Bad URL Stereogram.baseURL <%@>", s.baseURL);
		}
	}
}

-(void)testProperty_ViewingMethod {
	Stereogram *stereogram = [self makeStereogram:self.emptyDirURL];

	XCTAssertEqual(stereogram.viewingMethod, ViewingMethod_CrossEye
				   , @"Default viewing method %d is not CrossEyed", stereogram.viewingMethod);
	stereogram.viewingMethod = ViewingMethod_WallEye;
	XCTAssertEqual(stereogram.viewingMethod, ViewingMethod_WallEye
				   , @"Changing mode to walleyed resulted in a method of %d", stereogram.viewingMethod);
	stereogram.viewingMethod = ViewingMethod_AnimatedGIF;
	XCTAssertEqual(stereogram.viewingMethod, ViewingMethod_AnimatedGIF
				   , @"Changing mode to Animated resulted in a method of %u", stereogram.viewingMethod);
}

-(void)testProperty_BaseURL {
	Stereogram *s = [self makeStereogram:self.emptyDirURL];
	NSURL *stereogramParentURL = s.baseURL.URLByDeletingLastPathComponent.URLByStandardizingPath;
	XCTAssertNotNil(stereogramParentURL, @"Stereogram.baseURL of %@: Couldn't get parent directory.", s.baseURL);
	XCTAssertEqualObjects(stereogramParentURL, self.emptyDirURL
				   , @"Stereogram.baseURL %@ is not under parent URL %@, but under %@"
				   , s.baseURL, self.emptyDirURL, stereogramParentURL);
}

-(void) testProperty_MimeType {
	Stereogram *stereogram = [self makeStereogram:self.emptyDirURL];
	NSAssert(stereogram.viewingMethod == ViewingMethod_CrossEye
			 , @"Default viewing mode is not crosseyed.");
	NSString *mimeType = nil;
	NSError *error = nil;
	NSData *exportData = [stereogram exportDataWithMimeType:&mimeType
														  error:&error];
	XCTAssertNotNil(mimeType, @"Stereogram %@ has no mime type.", stereogram);
	XCTAssertEqualObjects(mimeType, @"image/jpeg"
				   , @"Default mime type %@ should be image/jpeg", mimeType);
	stereogram.viewingMethod = ViewingMethod_WallEye;
	mimeType = nil;
	exportData = [stereogram exportDataWithMimeType:&mimeType
											  error:&error];
	XCTAssertNotNil(stereogram, @"Stereogram %@ has no mime type.", stereogram);
	XCTAssertEqualObjects(mimeType, @"image/jpeg"
				   , @"Mime type for Walleyed is %@ should be image/jpeg", mimeType);
	stereogram.viewingMethod = ViewingMethod_AnimatedGIF;
	mimeType = nil;
	exportData = [stereogram exportDataWithMimeType:&mimeType
											  error:&error];
	XCTAssertNotNil(mimeType, @"Stereogram %@ has no mime type.", stereogram);
	XCTAssertEqualObjects(mimeType, @"image/gif"
				   , @"Mime type for AnimatedGIF is %@ should be image/gif", mimeType);
}

-(void) testStereogramImage {
	CGSize const combinedSize = CGSizeMake(self.leftImage.size.width + self.rightImage.size.width, self.leftImage.size.height);
	Stereogram *stereogram = [self makeStereogram:self.emptyDirURL];

		//	checkCrosseyed
	stereogram.viewingMethod = ViewingMethod_CrossEye;
	NSError *error = nil;
	UIImage *crossImage = [stereogram stereogramImage:&error];
	XCTAssertNotNil(crossImage, @"Stereogram %@ failed to create stereogram image with error %@.", stereogram, error);
	XCTAssert(CGSizeEqualToSize(crossImage.size, combinedSize)
				   , "Resultant image %@ size %@ should be %@", crossImage, sz(crossImage.size), sz(combinedSize));
	XCTAssertNil(crossImage.images, @"Crosseyed image should not have animation frames.");

		// checkWalleyed
	stereogram.viewingMethod = ViewingMethod_WallEye;
	error = nil;
	UIImage *wallImage = [stereogram stereogramImage:&error];
	XCTAssertNotNil(wallImage, @"Stereogram %@ failed to create stereogram image.", stereogram);
	XCTAssert(CGSizeEqualToSize(wallImage.size, combinedSize)
				   , "Resultant image %@ size %@ should be %@", wallImage, sz(wallImage.size), sz(combinedSize));
	XCTAssertNil(wallImage.images, @"Walleyed image should not have animation frames.");

		// checkAnimated
	stereogram.viewingMethod = ViewingMethod_AnimatedGIF;
	error = nil;
	UIImage *gifImage = [stereogram stereogramImage:&error];
	XCTAssertNotNil(gifImage, @"Stereogram %@ failed to create stereogram image.", stereogram);
	XCTAssert(CGSizeEqualToSize(gifImage.size, self.leftImage.size), "Resultant image %@ size mismatch", gifImage);
	XCTAssertNotNil(gifImage.images, "Animated image has no animation frames.");
	XCTAssertEqual(gifImage.images.count, 2
				   , @"Animated image has %lu animation frames, should be 2", (unsigned long)gifImage.images.count);
}

-(void)testThumbnailImage {
		//		XCTFail("Test not implemented.")
}

-(void)testImageCaching {
		//		XCTFail("Test not implemented.")
}

@end


