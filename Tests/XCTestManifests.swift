import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwiftyReactorTests.allTests),
        #if canImport(UIKit)
        testCase(SwiftyReactorUIKitTests.allTests)
        #endif
    ]
}
#endif
