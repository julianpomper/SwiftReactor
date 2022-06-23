//
//  AsyncReactorTests.swift
//  
//
//  Created by oanhof on 23.06.22.
//

import XCTest
import AsyncReactor
import Combine

@MainActor
class AsyncReactorTests: XCTestCase {
    
    var reactor: CountingReactor!
    
    var cancellables = Set<AnyCancellable>()
    
    @MainActor
    override func setUpWithError() throws {
        reactor = CountingReactor()
    }

    @MainActor
    override func tearDownWithError() throws {
        cancellables.removeAll()
    }

    func testCount() async {
        let amount = 1000
        
        for _ in (1...amount) {
            await reactor.action(.countUp)
        }
        
        XCTAssertEqual(reactor.state.count, amount)
    }
    
    func testConcurrentAction() {
        let amount = 10000
        
        let exp = expectation(description: "counted")
        
        reactor.$state
            .sink { state in
                if state.count == amount {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)
        
        for _ in (1...amount) {
            DispatchQueue.global().async {
                Task { await self.reactor.action(.countUp) }
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertEqual(reactor.state.count, amount)
    }
    
    func testConcurrentTaskAction() {
        let amount = 10000
        
        let exp = expectation(description: "counted")
        
        reactor.$state
            .sink { state in
                if state.count == amount {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)
        
        for _ in (1...amount) {
            Task { await self.reactor.action(.countUp) }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertEqual(reactor.state.count, amount)
    }
    
    func testConcurrentDetachedTaskAction() {
        let amount = 10000
        
        let exp = expectation(description: "counted")
        
        reactor.$state
            .sink { state in
                if state.count == amount {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)
        
        for _ in (1...amount) {
            Task.detached { await self.reactor.action(.countUp) }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertEqual(reactor.state.count, amount)
    }
}

class CountingReactor: AsyncReactor {
    enum Action {
        case countUp
    }
    
    struct State {
        var count = 0
    }
    
    @Published
    private(set) var state = State()
    
    func action(_ action: Action) async {
        switch action {
        case .countUp:
            state.count += 1
        }
    }
}
