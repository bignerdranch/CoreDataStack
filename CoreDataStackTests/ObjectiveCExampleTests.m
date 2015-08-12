//
//  ObjectiveCExampleTests.m
//  CoreDataStack
//
//  Created by Robert Edwards on 5/4/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

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
    [CoreDataStack objc_constructStackWithModelName:@"TestModel" inBundle:bundle ofStoreType:StoreTypeSQLite callback:^(CoreDataStack * _Nullable stack, NSError * _Nullable error) {
        XCTAssertNotNil(stack);
        XCTAssertNil(error);
        self.stack = stack;
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
