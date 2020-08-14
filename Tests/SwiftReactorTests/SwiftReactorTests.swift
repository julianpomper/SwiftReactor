import XCTest
@testable import SwiftReactor
import Combine

final class SwiftReactorTests: XCTestCase {
    var reactor: CountingReactor!
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        reactor = CountingReactor()
    }
    
    func testConcurrentAction() {
        let amount = 10000
        
        let exp = expectation(description: "counted")
        
        reactor.$state
            .sink { state in
                if state.currentCount == amount {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)
        
        for _ in (1...amount) {
            DispatchQueue.global().async {
                self.reactor.action(.countUp)
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertEqual(reactor.state.currentCount, amount)
    }
    
    func testConcurrentAsyncAction() {
        let amount = 10000
        
        let exp = expectation(description: "counted")
        
        reactor.$state
            .sink { state in
                if state.currentCount == amount {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)
        
        for _ in (1...amount) {
            DispatchQueue.global().async {
                self.reactor.action(.countUpAsync)
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        
        XCTAssertEqual(reactor.state.currentCount, amount)
    }
    
    func testConcurrentMixedAction() {
        let amount = 10000
        
        let exp = expectation(description: "counted")
        
        reactor.$state
            .sink { state in
                if state.currentCount == amount {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)
        
        for idx in (1...amount) {
            DispatchQueue.global().async {
                if idx % 2 == 0 {
                    self.reactor.action(.countUp)
                } else {
                    self.reactor.action(.countUpAsync)
                }
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        
        XCTAssertEqual(reactor.state.currentCount, amount)
    }
    
    func testCount() {
        let amount = 1000
        for _ in (1...amount) {
            reactor.action(.countUp)
        }
        XCTAssertEqual(reactor.state.currentCount, amount)
    }
}

final class CountingReactor: BaseReactor<CountingReactor.Action, CountingReactor.Mutation, CountingReactor.State> {

    enum Action {
        case countUp
        case countUpAsync
    }
    
    enum Mutation {
        case countUp
    }
    
    struct State {
        var currentCount: Int = 0
    }
    
    init() {
        super.init(initialState: State())
    }
    
    override func mutate(action: Action) -> Mutations<Mutation> {
        switch action {
        case .countUp:
            return [.countUp]
        case .countUpAsync:
            return Mutations(async: Just(.countUp).eraseToAnyPublisher())
        }
    }
    
    override func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .countUp:
            newState.currentCount += 1
        }
        
        return newState
    }
    
}
