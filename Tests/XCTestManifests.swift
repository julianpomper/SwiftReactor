import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwiftUIReactorTests.allTests),
        testCase(SwiftUIReactorUIKitTests.allTests),
    ]
}
#endif
