`NSOperation` objects are expected to implement logic and state transitions that allow them to be safely used with `NSOperationQueue` instances. These behaviors are documented in the [NSOperation class documentation](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSOperation_class/). 

This test case exercises the behavior expected of `NSOperation` instances. When subclassing an object that has expected behaviors it is critical to have tests to verify that those behaviors perform as they are expected to.
