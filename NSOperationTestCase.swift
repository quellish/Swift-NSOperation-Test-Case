//
//  NSOperationTestCase.swift
//
//
//  Created by quellish on 1/27/16.
//  Copyright 2016 Dan Zinngrabe. All rights reserved.
//
//  Original by Dan Zinngrabe on 1/27/16.
//

import XCTest

/**
    `Operation` objects are expected to implement logic and state transitions that allow them to be safely used with `OperationQueue` instances. This test case exercises the behavior expected of `Operation` instances.
 
    - SeeAlso: `Operation`
 */

public class TestCase: XCTestCase {
    
 /// A shared static serial queue used by some tests.
    
    static var sharedSerialQueue:OperationQueue? = {
        var result:OperationQueue?

        result = TestCase.serialQueueWithName(name:String(describing: type(of: self)))
        return result
    }()

 /// A shared static concurrent queue used by some tests.
    
    static var concurrentSerialQueue:OperationQueue? = {
        var result:OperationQueue?
        
        result =  TestCase.concurrentQueueWithName(name:String(describing: type(of: self)))
        return result
    }()

    // MARK: - Test Support
    
    /**
        The Operation instance to be tested.
    
        **Important** Test cases must implement this method to return an instance of the custom Operation class initialized with test values.
    
    - returns: The operation to test
    */
    
    public func operationUnderTest() -> Operation {
        fatalError("Function must be overridden")
    }
    
    /**
     *  The default timeout for asynchronous tests.
     *  Test cases may override this method as appropriate.
     
     - returns: The default timeout
     */
    
    public func defaultTimeout() -> TimeInterval {
        var result:TimeInterval  = 10
        
        #if (arch(arm) || arch(arm64)) && (os(iOS) || os(watchOS) || os(tvOS))
            result = 30
        #endif
            
        return result
    }
    
    /**
     Returns a serial queue created with the name provided.
     
     - parameter name: The name of the queue.
     
     - returns: An `OperationQueue` with the name provided and a maxConcurrentOperationCount of 1.
     */
    
    public static func serialQueueWithName(name:String) -> OperationQueue {
        let result:OperationQueue = self.concurrentQueueWithName(name:name)
        
        result.maxConcurrentOperationCount = 1
        return result
    }
    
    /**
     Returns a concurrent queue created with the name provided.
     
     - parameter name: The name of the queue.
     
     - returns: An `OperationQueue` with the name provided.
     */
    
    public static func concurrentQueueWithName(name:String) -> OperationQueue {
        let result:OperationQueue = OperationQueue()
        
        result.name = name
        return result
    }

    // MARK: - Tests
    
    /**
      Tests wether the operation class is actually a subclass of Operation.
    */
    
    func testClassIsSubclassOfOperation() {
        XCTAssertTrue(self.operationUnderTest().isKind(of:Operation.self), "Test class is not a subclass of Operation")
    }
    
    /**
      Tests wether upon completion the operation invokes the completion block when it is used in a serial queue.
    */
    
    func testCanExecuteCompletionBlockWithSerialQueue() {
        let testOperation:Operation         = self.operationUnderTest();
        let queue:OperationQueue            = type(of: self).serialQueueWithName(name:#function)
        let expectation:XCTestExpectation   = self.expectation(description: #function)
    
        
        testOperation.completionBlock = {
            expectation.fulfill()
        }
        queue.isSuspended = true
        queue.addOperation(testOperation)
        queue.isSuspended = false
        
        self.waitForExpectations(timeout: self.defaultTimeout()) { error -> Void in
            if let testError = error as NSError? {
                if (testError.domain == XCTestErrorDomain){
                    XCTFail( "The operation completion block did not execute within the timeout: \(String(describing: error))");
                }
            }
        }    

    }
    
    /**
       Tests wether upon completion the operation invokes the completion block when it is used in a concurrent queue.
     */
    
    func testCanExecuteCompletionBlockWithConcurrentQueue() {
        let testOperation:Operation         = self.operationUnderTest();
        let queue:OperationQueue            = type(of: self).concurrentQueueWithName(name:#function)
        let expectation:XCTestExpectation   = self.expectation(description: #function)

        
        
        testOperation.completionBlock = {
            expectation.fulfill()
        }
        queue.isSuspended = true
        queue.addOperation(testOperation)
        queue.isSuspended = false
        
        self.waitForExpectations(timeout: self.defaultTimeout()) { error -> Void in
            if let testError = error as NSError? {
                if (testError.domain == XCTestErrorDomain){
                    XCTFail( "The operation completion block did not execute within the timeout: \(String(describing: error))");
                }
            }
        }
        
    }
    
    /**
      Tests wether the operation can be executed with a dependent operation when it is used in a serial queue.
    */
    
    func testCanExecuteDependentOperationWithSerialQueue() {
        let testOperation:Operation         = self.operationUnderTest();
        let queue:OperationQueue            = type(of: self).serialQueueWithName(name:#function)
        let expectation:XCTestExpectation   = self.expectation(description: #function)
        let dependant:Operation             = BlockOperation { () -> Void in
            expectation.fulfill()
        }
        
        testOperation.addDependency(dependant)
        queue.isSuspended = true
        queue.addOperation(testOperation)
        queue.addOperation(dependant)
        queue.isSuspended = false
        
        self.waitForExpectations(timeout: self.defaultTimeout()) { error -> Void in
            if let testError = error as NSError? {
                if (testError.domain == XCTestErrorDomain){
                    XCTFail( "The operation dependency did not execute within the timeout: \(String(describing: error))");
                }
            }
        }
    }
    
    /**
       Tests wether the operation can be executed with a dependent operation when it is used in a concurrent queue.
     */
    
    func testCanExecuteDependentOperationWithConcurrentQueue() {
        let testOperation:Operation         = self.operationUnderTest();
        let queue:OperationQueue            = type(of: self).concurrentQueueWithName(name:#function)
        let expectation:XCTestExpectation   = self.expectation(description:#function)
        let dependant:Operation             = BlockOperation { () -> Void in
            expectation.fulfill()
        }
        
        testOperation.addDependency(dependant)
        queue.isSuspended = true
        queue.addOperation(testOperation)
        queue.addOperation(dependant)
        queue.isSuspended = false
        
        self.waitForExpectations(timeout: self.defaultTimeout()) { error -> Void in
            if let testError = error as NSError? {
                if (testError.domain == XCTestErrorDomain){
                    XCTFail( "The operation dependency did not execute within the timeout: \(String(describing: error))");
                }
            }
        }
    }
    
    /**
      Tests wether the operation correctly sends the "isCancelled" key value notification when used in a concurrent queue.
    */
    
    func testCanCancelOperationWithSerialQueue() {
        let testOperation:Operation         = self.operationUnderTest();
        let queue:OperationQueue            = type(of: self).serialQueueWithName(name:#function)
        var expectation:XCTestExpectation?  = self.keyValueObservingExpectation(for: testOperation, keyPath: "isCancelled", expectedValue: true)
        
        queue.isSuspended = true
        queue.addOperation(testOperation)
        queue.cancelAllOperations()
        queue.isSuspended = false
        
        self.waitForExpectations(timeout: self.defaultTimeout()) { error -> Void in
            if let testError:NSError = error as NSError? {
                if (testError.domain == XCTestErrorDomain){
                    XCTFail( "Operation did not move to the cancelled state within the timeout: \(String(describing: error))");
                }
            }
            
            if (expectation != nil){
                expectation = nil
            }
        }
    }
    
    /**
       Tests wether the operation correctly sends the "isCancelled" key value notification when used in a concurrent queue.
     */
    
    func testCanCancelOperationWithConcurrentQueue() {
        let testOperation:Operation         = self.operationUnderTest();
        let queue:OperationQueue            = type(of: self).concurrentQueueWithName(name:#function)
        var expectation:XCTestExpectation?  = self.keyValueObservingExpectation(for: testOperation, keyPath: "isCancelled", expectedValue: true)
        
        queue.isSuspended = true
        queue.addOperation(testOperation)
        queue.cancelAllOperations()
        queue.isSuspended = false
        
        self.waitForExpectations(timeout: self.defaultTimeout()) { error -> Void in
            if let testError = error as NSError? {
                if (testError.domain == XCTestErrorDomain){
                    XCTFail( "Operation did not move to the cancelled state within the timeout: \(String(describing: error))");
                }
            }
            
            if (expectation != nil){
                expectation = nil
            }

        }
    }
}
