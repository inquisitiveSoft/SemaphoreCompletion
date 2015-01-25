//
//  SYMLSemaphoreCompletionTests.m
//  SYMLSemaphoreCompletionTests
//
//  Created by Harry Jordan on 24/10/2013.
//  Copyright (c) 2013 Harry Jordan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SYMLSemaphoreCompletion.h"


@interface SYMLSemaphoreCompletion ()

@property (readonly) dispatch_queue_t internalQueue;

@end



@interface SYMLSemaphoreCompletionTests : XCTestCase

@end


@implementation SYMLSemaphoreCompletionTests


- (void)testSemaphore_trailingCompletionBlocks
{
	SYMLSemaphoreCompletion *semaphore = [SYMLSemaphoreCompletion new];
	XCTAssertTrue(semaphore, @"");
	
	XCTestExpectation *expectation = [self expectationWithDescription:@"expect blocks added after tasks completed to be called"];

	__block NSInteger success = 0;
	__block NSInteger failure = 0;
	
	id <NSCopying> firstToken = [semaphore addTask];
	id <NSCopying> secondToken = [semaphore addTask];
	
	[semaphore finishedTaskForToken:firstToken success:TRUE];
	[semaphore finishedTaskForToken:secondToken success:TRUE];
	
	[semaphore addSuccessBlock:^{
		success++;
		[expectation fulfill];
	} failureBlock:^(BOOL finishedResult) {
		failure++;
	}];
	
	
	semaphore = nil;	// Deallcates semaphore, shouldn't make any differenct
	
	[self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
		XCTAssertTrue(success == 1, @"");
		XCTAssertTrue(failure == 0, @"");
		
		if(error) {
			XCTFail(@"Expectation Failed with error: %@", error);
		}
	}];
}



- (void)testSemaphore_leadingCompletionBlocks
{
	SYMLSemaphoreCompletion *semaphore = [SYMLSemaphoreCompletion new];
	XCTAssertTrue(semaphore, @"");
	
	__block NSInteger success = 0;
	__block NSInteger failure = 0;
	
	XCTestExpectation *expectation = [self expectationWithDescription:@"expect blocks added before tasks completed to be called"];
	
	[semaphore addSuccessBlock:^{
		success++;
		[expectation fulfill];
	} failureBlock:^(BOOL finishedResult) {
		failure++;
	}];
	
	XCTAssertTrue(success == 0, @"");
	XCTAssertTrue(failure == 0, @"");
	
	id <NSCopying> firstToken = [semaphore addTask];
	id <NSCopying> secondToken = [semaphore addTask];
	
	[semaphore finishedTaskForToken:secondToken success:TRUE];
	[semaphore finishedTaskForToken:firstToken success:TRUE];
	
	
	[self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
		XCTAssertTrue(success == 1, @"");
		XCTAssertTrue(failure == 0, @"");
		
		if(error) {
			XCTFail(@"Expectation Failed with error: %@", error);
		}
	}];
}


- (void)testSemaphore_deallocationWithoutAnyTasks
{
	SYMLSemaphoreCompletion *semaphore = [SYMLSemaphoreCompletion new];
	XCTAssertTrue(semaphore, @"");
	
	__block NSInteger success = 0;
	__block NSInteger failure = 0;
	__block NSInteger finished = 0;

	[semaphore addSuccessBlock:^{
		success++;
	} failureBlock:^(BOOL finishedResult) {
		failure++;
		finished += finishedResult;
	}];
	
	XCTAssertTrue(success == 0, @"");
	XCTAssertTrue(failure == 0, @"");
	XCTAssertTrue(finished == 0, @"");
	
	semaphore = nil;	// Deallcates semaphore, shouldn't make any difference
	
	XCTAssertTrue(success == 0, @"");
	XCTAssertTrue(failure == 0, @"");
	XCTAssertTrue(finished == 0, @"");
}


- (void)testSemaphore_deallocationWithUnfinishedTasks
{
	XCTestExpectation *expectation = [self expectationWithDescription:@"expect deallocation to trigger failure block"];
	dispatch_queue_t resultQueue = dispatch_queue_create("resultQueue", 0);
	SYMLSemaphoreCompletion *semaphore = [[SYMLSemaphoreCompletion alloc] initWithResultQueue:resultQueue];
	XCTAssertTrue(semaphore, @"");
		
	__block NSInteger failure = 0;
	__block NSInteger finished = 0;

	[semaphore addSuccessBlock:NULL failureBlock:^(BOOL finishedResult) {
		[expectation fulfill];
		
		NSLog(@"finishedResult: %ld", (NSInteger)finishedResult);
		failure++;
		
		if(finishedResult) {
			finished++;
		}
	}];
	
	[semaphore addTask];
	
	XCTAssertTrue(failure == 0, @"");
	XCTAssertTrue(finished == 0, @"");
	
	semaphore = nil;	// Deallcates semaphore, should call the failure block with FALSE
	
	[self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
		XCTAssertTrue(failure == 1, @"");
		XCTAssertTrue(finished == 0, @"");
		
		if(error) {
			XCTFail(@"Expectation Failed with error: %@", error);
		}
	}];
}


@end
