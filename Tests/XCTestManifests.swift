import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwiftReactorTests.allTests),
        #if canImport(UIKit)
        testCase(SwiftReactorUIKitTests.allTests)
        #endif
    ]
}
#endif
