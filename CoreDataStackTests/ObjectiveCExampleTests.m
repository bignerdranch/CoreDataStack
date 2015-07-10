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
#import <CoreDataStack/CoreDataStack-Swift.h>

@interface ObjectiveCExampleTests : XCTestCase

@property (nonatomic, strong) CoreDataStack *stack;

@end

@implementation ObjectiveCExampleTests

- (void)setUp {
    [super setUp];

    XCTestExpectation *ex = [self expectationWithDescription:@"Callback"];

    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    self.stack = [[CoreDataStack alloc] initWithModelName:@"TestModel" inBundle:bundle callback:^(BOOL success, NSError *error) {
        XCTAssertTrue(success);
        [ex fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testInitializaton {
    XCTAssert(YES, @"Pass");

    XCTAssertNotNil(self.stack);
    XCTAssertNotNil(self.stack.mainQueueContext);

    NSManagedObjectContext *worker = [self.stack newBackgroundWorkerMOC];
    XCTAssertNotNil(worker);
}

@end
