import XCTest
@testable import SwiftUIReactor
import Combine

final class SwiftUIReactorTests: XCTestCase {
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

final class CountingReactor: Reactor {
    
    var action = PassthroughSubject<Action, Never>()
    
    var mutation = PassthroughSubject<Mutation, Never>()
    
    
    enum Action {
        case countUp
    }
    
    enum Mutation {
        case countUp
    }
    
    struct State {
        var currentCount: Int
    }
    
    var cancellables: Set<AnyCancellable> = []
    
    @Published
    var state: State = State(currentCount: 0)
    
    init() {
        createStateStream()
    }
    
    func mutate(action: Action) -> Mutations<Mutation> {
        return Mutations(sync: [.countUp])
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .countUp:
            newState.currentCount += 1
        }
        
        return newState
    }
    
}
