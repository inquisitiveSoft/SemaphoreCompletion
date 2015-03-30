//
//  Created by Harry Jordan on 25/10/2013.
//  Copyright (c) 2014 Harry Jordan. All rights reserved.
//
//  Released under the MIT license: http://opensource.org/licenses/mit-license.php
//


#import "SYMLSemaphoreCompletion.h"


typedef NS_ENUM(NSUInteger, SYMLSemaphoreState) {
	SYMLSemaphoreStateNoTasksAdded,
	SYMLSemaphoreStateTasksInProgress,
	SYMLSemaphoreStateHasFailedTasks,
	SYMLSemaphoreStateAllTasksSuccessful,
	SYMLSemaphoreStateCompleted
};


@interface SYMLSemaphoreCompletion () {
	__block SYMLSemaphoreState __semaphoreState;
	NSMutableSet *__semaphoreTokens;
}

@property (strong) dispatch_queue_t internalQueue, internalResultQueue;
@property (strong, nonatomic) dispatch_queue_t resultQueue;

@property (copy) void (^successBlock)(void);
@property (copy) void (^failureBlock)(BOOL);

@end



@implementation SYMLSemaphoreCompletion


- (instancetype)init
{
	self = [super init];
	
	if(self) {
		__semaphoreState = SYMLSemaphoreStateNoTasksAdded;
		__semaphoreTokens = [NSMutableSet set];
		
		_internalQueue = dispatch_queue_create("internal semaphore completion queue", DISPATCH_QUEUE_SERIAL);
		_resultQueue = dispatch_queue_create("results semaphore completion queue", DISPATCH_QUEUE_SERIAL);
	}
	
	return self;
}


- (instancetype)initWithResultQueue:(dispatch_queue_t)queue
{
	self = [self init];
	
	if(self) {
		self.resultQueue = queue;
	}
	
	return self;
}



- (id <NSCopying>)addTask
{
	if(__semaphoreState == SYMLSemaphoreStateHasFailedTasks) {
		return nil;
	}
	
	NSString *uniqueIdentifier = [[NSProcessInfo processInfo] globallyUniqueString];
	
	dispatch_sync(self.internalQueue, ^{
		__semaphoreState = SYMLSemaphoreStateTasksInProgress;
		
		[__semaphoreTokens addObject:uniqueIdentifier];
	});
	
	return uniqueIdentifier;
}


- (void)finishedTaskForToken:(id <NSCopying>)token success:(BOOL)success
{
	__weak SYMLSemaphoreCompletion *semaphore = self;
	
	dispatch_sync(self.internalQueue, ^{
		if(__semaphoreState == SYMLSemaphoreStateHasFailedTasks
			|| __semaphoreState == SYMLSemaphoreStateAllTasksSuccessful) {
			return;
		}
		
		if(!token) {
			NSLog(@"Couldn't finish empty token");
			return;
		}
		
		
		if(success) {
			switch(__semaphoreState) {
				case SYMLSemaphoreStateNoTasksAdded:
					NSLog(@"%@: No tasks have been added", self);
					break;

				case SYMLSemaphoreStateTasksInProgress:
					if([__semaphoreTokens containsObject:token]) {
						[__semaphoreTokens removeObject:token];
						
						if([__semaphoreTokens count] == 0) {
							__semaphoreState = SYMLSemaphoreStateAllTasksSuccessful;
							[semaphore performSuccessBlock];
						}
					} else {
						NSLog(@"%@: Unmatched token", self);
					}
					
					break;

				default:
					break;
			}
		} else {
			__semaphoreTokens = nil;
			__semaphoreState = SYMLSemaphoreStateHasFailedTasks;
			
			[semaphore performFailureBlock:TRUE];
		}
	});
}


- (void)addSuccessBlock:(void (^) (void))successBlock failureBlock:(void (^)(BOOL))failureBlock
{
	SYMLSemaphoreCompletion *semaphore = self;
	
	dispatch_sync(self.internalQueue, ^{
		_successBlock = [successBlock copy];
		_failureBlock = [failureBlock copy];
		
		switch(__semaphoreState) {
			case SYMLSemaphoreStateAllTasksSuccessful:
				[semaphore performSuccessBlock];
				break;
			
			case SYMLSemaphoreStateHasFailedTasks:
				[semaphore performFailureBlock:TRUE];
				break;
			
			default:
				break;
		}
	});
}


- (void)performSuccessBlock
{
	void (^successBlock) (void)  = self.successBlock;
	
	if(successBlock) {
		dispatch_async(self.resultQueue, successBlock);
		__semaphoreState = SYMLSemaphoreStateCompleted;
	}
}


- (void)performFailureBlock:(BOOL)finished
{
	[self performFailureBlock:finished asynchronously:TRUE];
}


- (void)performFailureBlock:(BOOL)finished asynchronously:(BOOL)asynchronously
{
	// The only time when this should be called asynchronously is from -dealloc
	// so that the failure block can be called before the object is released
	void (^failureBlock)(BOOL)  = self.failureBlock;
	
	if(failureBlock) {
		dispatch_block_t completion = ^{
			failureBlock(finished);
		};
		
		if(asynchronously) {
			dispatch_async(self.resultQueue, completion);
		} else {
			dispatch_sync(self.resultQueue, completion);
		}
		
		__semaphoreState = SYMLSemaphoreStateCompleted;
	}
}


- (dispatch_queue_t)resultQueue
{
	return _resultQueue ?: self.internalResultQueue;
}


- (void)dealloc
{
	dispatch_sync(self.internalQueue, ^{
		if(__semaphoreState != SYMLSemaphoreStateCompleted
			&& __semaphoreState != SYMLSemaphoreStateNoTasksAdded) {
			// Treat this as programmer error
			NSLog(@"SYMLSemaphoreCompletion was deallocated with %ld unfinished tasks", (long)[__semaphoreTokens count]);
			[self performFailureBlock:FALSE asynchronously:FALSE];
		}
	});
}


@end
