//
//  ObjectiveCExampleTests.m
//  CoreDataStack
//
//  Created by Robert Edwards on 5/4/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "CoreDataStackTests-Swift.h"
#import <CoreDataStack/CoreDataStack.h>

@interface ObjectiveCExampleTests : XCTestCase

@property (nonatomic, strong) NestedMOCStack *nestedStack;
@property (nonatomic, strong) SharedStoreMOCStack *sharedStoreStack;

@end

@implementation ObjectiveCExampleTests

- (void)setUp {
    [super setUp];

    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    self.nestedStack = [[NestedMOCStack alloc] initWithModelName:@"TestModel" inBundle:bundle];
    self.sharedStoreStack = [[SharedStoreMOCStack alloc] initWithModelName:@"TestModel" inBundle:bundle];
}

- (void)testNestedInitializaton {
    XCTAssert(YES, @"Pass");

    XCTAssertNotNil(self.nestedStack);
    XCTAssertNotNil(self.nestedStack.mainQueueContext);

    NSManagedObjectContext *worker = [self.nestedStack newBackgroundWorkerMOC];
    XCTAssertNotNil(worker);
}

- (void)testSharedStoreInitialization {
    XCTAssertNotNil(self.sharedStoreStack);
    XCTAssertNotNil(self.sharedStoreStack.mainContext);

    NSManagedObjectContext *worker = [self.sharedStoreStack newBackgroundContextWithShouldReceiveUpdates:YES];
    XCTAssertNotNil(worker);
}

@end
