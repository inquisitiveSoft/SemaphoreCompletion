//
//  Created by Harry Jordan on 25/10/2013.
//  Copyright (c) 2014 Harry Jordan. All rights reserved.
//
//  Released under the MIT license: http://opensource.org/licenses/mit-license.php
//


#import <Foundation/Foundation.h>


@interface SYMLSemaphoreCompletion : NSObject

- (instancetype)init;	// Will use an internal queue
- (instancetype)initWithResultQueue:(dispatch_queue_t)queue;

- (id <NSCopying>)addTask;
- (void)finishedTaskForToken:(id <NSCopying>)token success:(BOOL)success;

- (void)addSuccessBlock:(void (^) (void))successBlock failureBlock:(void (^)(BOOL))failureBlock;


@end
