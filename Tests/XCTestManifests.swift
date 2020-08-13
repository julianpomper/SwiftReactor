import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwiftUIReactorTests.allTests),
        #if canImport(UIKit)
        testCase(SwiftUIReactorUIKitTests.allTests)
        #endif
    ]
}
#endif
