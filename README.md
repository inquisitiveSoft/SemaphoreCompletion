# Semaphore Completion

SYMLSemaphoreCompletion performs a completion block when a group of tasks have finished. It's similar to how XCTest's expectations work. Released under MIT License.

# Usage

```
SYMLSemaphoreCompletion *semaphore = [SYMLSemaphoreCompletion new];

id <NSCopying> firstTask = [semaphore addTask];
id <NSCopying> secondTask = [semaphore addTask];

[semaphore addSuccessBlock:^{
	// Called if all success
} failureBlock:^(BOOL finishedResult) {
	// Called if any of the tasts fail, or the semaphore object is deallocated with tasks remaining
}];


[self preformAsynchronousTask:^{
	[semaphore finishedTaskForToken:firstTask success:TRUE];
}];

[self preformAsynchronousTask:^{
	[semaphore finishedTaskForToken:secondTask success:TRUE]
}];
```

