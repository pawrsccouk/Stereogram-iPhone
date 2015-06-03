//
//  Stereogram_iPadTests.m
//  Stereogram-iPadTests
//
//  Created by Patrick Wallace on 11/01/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "Stereogram.h"
#import "PhotoStore.h"
#import "StereogramTestCase.h"

// MARK: Setup & Support
@interface PhotoStoreTests : StereogramTestCase
@end

@implementation PhotoStoreTests

-(BOOL) stereogram: (Stereogram *)stereogram
      inPhotoStore: (PhotoStore *)photoStore {
	// Now check the stereograms.
	for(Stereogram *existingStereogram in photoStore.objectEnumerator) {
		if (existingStereogram == stereogram) {
			return YES;
		}
	}
	return NO;
}

-(Stereogram *) addStereogramForURL: (NSURL*)url
					   inPhotoStore: (PhotoStore*)photoStore {
	NSError*error = nil;
	Stereogram *stereogram = [Stereogram stereogramWithDirectoryURL: url
														  leftImage: self.leftImage
														 rightImage: self.rightImage
															  error: &error];
	if (stereogram) {
		[photoStore addStereogram:stereogram];
		return stereogram;
	}
	else {
		NSAssert(false, @"Failed to create stereogram with error %@", error);
		return nil;
	}
}


-(NSArray *)addStereograms: (NSURL *)url
				photoStore: (PhotoStore *)photoStore
					 count: (NSUInteger) count {
	NSMutableArray *sgms = [NSMutableArray array];
	for (NSUInteger i = 0; i < count; i++) {
		[sgms addObject:[self addStereogramForURL:url inPhotoStore:photoStore]];
	}
	return sgms;
}

#pragma mark - Tests

	/// Test that the store initializes with an empty directory
-(void) testInitEmptyDirectory {
	NSError *error = nil;
	NSURL *rootDir    = [self.bundle URLForResource:self.emptyDirectoryName
									  withExtension:nil];
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:rootDir
															 error:&error];
	if(rootDir && photoStore) {
		XCTAssertEqual(photoStore.count, 0, "Invalid no. of stereograms %lu should be 0", (unsigned long)photoStore.count);
	} else {
		XCTFail("Failed to create photo store.");
	}
}

	/// Test the store initializes with an existing directory with exactly 1 entry.
-(void) testInitExistingDirectory_1Stereogram {
	NSError *error = nil;
	NSURL *folder1URL = [self.bundle URLForResource:@"PhotoStore 1 Directory" withExtension:nil];
	XCTAssertNotNil(folder1URL, @"Failed to retrieve photo directory");
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:folder1URL error:&error];
	XCTAssertNotNil(photoStore, @"Failed to create photo store with error %@", error);
	XCTAssertEqual(photoStore.count, 1
				   , @"Invalid no. of stereograms %lu should be 1", (unsigned long)photoStore.count);
}

	/// Test the store initializes with an existing directory with exactly 2 entries and finds them.
-(void) testInitExistingDirectory_2Stereograms {
	NSError *error = nil;
	NSURL *folder2URL = [self.bundle URLForResource:@"PhotoStore 2 Directory" withExtension:nil];
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:folder2URL error:&error];
	if (folder2URL && photoStore) {
				XCTAssertEqual(photoStore.count, 2
							   , @"Invalid no. of stereograms %lu should be 2", (unsigned long)photoStore.count);
		}
		else {
			XCTFail(@"Failed to create photo store.");
		}
	}

	/// Test the store fails if it cannot access the directory.
-(void) testInitBadDirectory {
	NSURL *badDirURL = [NSURL fileURLWithPath:@"/asdfasfas"];
	XCTAssertNotNil(badDirURL, @"URL create failed.");
	NSError *error = nil;
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:badDirURL
															 error:&error];
	XCTAssertNil(photoStore, @"PhotoStore %@ created with invalid URL %@", photoStore, badDirURL);
	XCTAssertNotNil(error
					, @"PhotoStore setup with URL %@ failed but didn't set an error.", badDirURL);
}

	/// Test adding one stereogram (as UIImages) creates it in the right place.
-(void) testAddOneStereogram {
	NSError *error = nil;
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:self.emptyDirURL error:&error];
	XCTAssertNotNil(photoStore, @"Failed to set up photo store on URL %@ with error %@", self.emptyDirURL, error);
	XCTAssertEqual(photoStore.count, 0, @"Invalid photo store.");

	Stereogram *sgm = [self addStereogramForURL:self.emptyDirURL
								   inPhotoStore:photoStore];
	XCTAssertNotNil(sgm, @"addStereogramForURL:inPhotoStore failed.");
	XCTAssertEqual(photoStore.count, 1
				   , @"Photo Store %@ has %lu stereograms.", photoStore, (unsigned long)photoStore.count);
	XCTAssert([self url:self.emptyDirURL containsSubdirs:1]
			  , @"Stereogram created in wrong place.");
	XCTAssert([self stereogram: sgm inPhotoStore:photoStore]
			  , @"Stereogram is not in the photo store after addition.");
}

	/// Check adding a stereogram to a photoStore looking over an existing directory.
-(void)testAddMultipleStereograms {
	NSError *error = nil;
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:self.emptyDirURL error:&error];
	XCTAssertNotNil(photoStore, @"Failed to create photo store with error %@", error);
	XCTAssertEqual(photoStore.count, 0, @"Invalid photo store has %lu stereograms on startup", (unsigned long)photoStore.count);

	NSArray *sgms = [self addStereograms:self.emptyDirURL photoStore:photoStore count:3];

	XCTAssertEqual(photoStore.count, 3, @"Photo Store %@ has %lu stereograms.", photoStore, (unsigned long)photoStore.count);
	XCTAssert([self url:self.emptyDirURL containsSubdirs:3], @"Stereograms created in wrong place.");

	NSUInteger i = 0;
	for (Stereogram *stereogram in sgms) {
		XCTAssertEqual(stereogram, [photoStore stereogramAtIndex:i], @"After addition, stereogram is missing.");
		i++;
	}
}

-(void) testRemoveOneStereogram {
	NSError *error = nil;
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:self.emptyDirURL error:&error];
	XCTAssertNotNil(photoStore, @"Failed to create photo store with error %@", error);

	[self addStereogramForURL:self.emptyDirURL inPhotoStore:photoStore];
	XCTAssert([self url:self.emptyDirURL containsSubdirs:1], @"addStereogram failed.");
			// Now add 2 steregrams and test we can remove one.
			// I add twice to avoid anything where the 'last' created stereogram is cached somewhere
			// as I want to do a 'real' delete.
	error = nil;
	Stereogram *stereogram = [photoStore createStereogramFromLeftImage:self.leftImage
															rightImage:self.rightImage
																 error:&error];
	XCTAssertNotNil(stereogram, @"createStereogram failed with error %@.", error);

	XCTAssert([self url:self.emptyDirURL containsSubdirs:2], @"createStereogramFrom... failed.");

	[self addStereogramForURL:self.emptyDirURL inPhotoStore:photoStore];
	XCTAssert([self url:self.emptyDirURL containsSubdirs:3], @"createStereogramFrom... failed.");
	XCTAssert([self stereogram:stereogram inPhotoStore:photoStore], @"add failed when testing remove.");

	error = nil;
	BOOL res = [photoStore deleteStereogram:stereogram error:&error];
	XCTAssertTrue(res, @"deleteStereograms failed with error %@", error);
	XCTAssert(![self stereogram:stereogram inPhotoStore:photoStore], @"The stereogram was not removed.");
	XCTAssert([self url:self.emptyDirURL containsSubdirs:2], @"Should be 2 stereograms after the deletion.");
}

-(void) testRemoveAllStereograms {
	NSError *error = nil;
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:self.emptyDirURL error:&error];
	XCTAssertNotNil(photoStore, @"Photo store creation failed with error %@", error);
	XCTAssertEqual(photoStore.count, 0, @"New photo store has %lu stereograms attached.", (unsigned long)photoStore.count);
	NSArray *sgms = [self addStereograms:self.emptyDirURL photoStore:photoStore count:5];
	XCTAssertEqual(photoStore.count, 5, @"addStereograms failed: Has %lu stereograms", (unsigned long)photoStore.count);
	XCTAssertTrue([self url:self.emptyDirURL containsSubdirs:5]
				   , @"addStereogram failed testing remove all stereograms.");

	for (Stereogram *sgm in sgms) {
		BOOL res = [photoStore deleteStereogram:sgm error:&error];
		XCTAssertTrue(res, @"deleteStereogram failed with error %@", error);
	}

	XCTAssertEqual(photoStore.count, 0, @"One or more stereograms present after full delete.");
	XCTAssertTrue([self url:self.emptyDirURL containsSubdirs:0], @"Subdirs present after full delete.");
}


	/// Tests that indexing the photo store works as expected.

-(void) testStereogramAtIndex {
	NSError *error = nil;
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:self.emptyDirURL error:&error];
	XCTAssertNotNil(photoStore, @"Error setting up photo store: %@", error);
	NSArray *sgms = [self addStereograms:self.emptyDirURL photoStore:photoStore count:5];
	XCTAssert([self url:self.emptyDirURL containsSubdirs:5], @"addStereograms failed testing stereogram at index.");

	NSUInteger i = 0;
	for (Stereogram *sgm in sgms) {
		XCTAssertEqual(sgm, [photoStore stereogramAtIndex:i], @"Stereogram index %lu failed.", (unsigned long)i);
		i++;
	}
}

-(void) testDeleteByIndexPaths {
	NSError *error = nil;
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:self.emptyDirURL
															 error:&error];
	XCTAssertNotNil(photoStore, @"PhotoStore create failed with error %@", error);
	NSArray *sgms = [self addStereograms:self.emptyDirURL photoStore:photoStore count:6];
	XCTAssert([self url:self.emptyDirURL containsSubdirs:6], "addSteregrams failed.");

		// Remove the 2nd and 4th items.
	NSArray *indexPaths = @[ [NSIndexPath indexPathForItem:1 inSection:0],
							 [NSIndexPath indexPathForItem:3 inSection:0] ];
	error = nil;
	BOOL res = [photoStore deleteStereogramsAtIndexPaths:indexPaths error:&error];
	XCTAssertTrue(res, @"deleteStereogramsAtIndexPaths failed with error: %@", error);
	XCTAssertEqual(photoStore.count, 4, @"Photostore has \(photoStore.count) items, should be 4");
	XCTAssert([self url: self.emptyDirURL containsSubdirs:4], @"Photo URL should have 4 subdirs.");

	NSUInteger i = 0;
	for (Stereogram *sgm in sgms) {
		switch (i) {
			case 1:
			case 3: XCTAssertFalse([self stereogram:sgm inPhotoStore:photoStore]
							  , @"Stereogram %@ at index %lu is present after delete.", sgm, (unsigned long)i);
				break;
			default:
				XCTAssertTrue([self stereogram:sgm inPhotoStore:photoStore]
						  , @"Stereogram %@ at index %lu is not in the photo store.", sgm, (unsigned long)i);
				break;
		}
		i++;
	}
}

-(void)testReplaceAtIndex {
	NSError *error = nil;
	PhotoStore *photoStore = [[PhotoStore alloc] initWithFolderURL:self.emptyDirURL error:&error];
	XCTAssertNotNil(photoStore, @"Error creating photo store: %@", error);
	NSArray *sgms = [self addStereograms:self.emptyDirURL photoStore:photoStore count:2];
	XCTAssert([self url:self.emptyDirURL containsSubdirs:2], @"addSteregrams failed.");

	error = nil;
	Stereogram *newSgm = [Stereogram stereogramWithDirectoryURL:self.emptyDirURL
													  leftImage:self.leftImage
													 rightImage:self.rightImage
														  error:&error];
	XCTAssertNotNil(newSgm, @"Create stereogram failed with error %@", error);

	error = nil;
	BOOL res = [photoStore replaceStereogramAtIndex:1 withStereogram:newSgm error:&error];
	XCTAssertTrue(res, @"replaceStereogramAtIndex:withStereogram:error failed with error %@", error);
	XCTAssertEqual(photoStore.count, 2, @"Replace changed the number of stereograms in the store.");
	XCTAssert([self url:self.emptyDirURL containsSubdirs:2], @"Replace changed the number of stereograms in the base URL");
	XCTAssertEqual([photoStore stereogramAtIndex:0], sgms[0], @"Replace changed item 0 which shouldn't change.");
	XCTAssertNotEqual([photoStore stereogramAtIndex:1], sgms[1], @"Replace item 1 but the original is still present.");
	XCTAssertEqual([photoStore stereogramAtIndex:1], newSgm, @"Replacement stereogram is not present.");
}

-(void) testCopyToCameraRoll {
		// I'm not testing this as it would fill up my camera roll.
		// I don't think I can retrieve pictures from there programmatically. So I'll just do nothing in this test.
}

@end

