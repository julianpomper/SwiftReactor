import XCTest
@testable import SwiftReactor
import Combine

final class SwiftReactorTests: XCTestCase {
    var reactor: CountingReactor!
    var transformReactor: TransformCountingReactor!
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        reactor = CountingReactor()
        transformReactor = TransformCountingReactor()
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
                XCTAssertTrue(Thread.current.isMainThread)
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

    func testTransforms() {
        let exp = expectation(description: "counted")
        exp.expectedFulfillmentCount = 2

        transformReactor.$state
            .sink { state in
                XCTAssertTrue(Thread.current.isMainThread)
                print("currentCount", state.currentCount)
                exp.fulfill()
            }
            .store(in: &cancellables)

        transformReactor.action(.countUp)

        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertEqual(transformReactor.state.currentCount, 4)
    }
    
    func testInitialState() {
        let exp = expectation(description: "initial")

            reactor.$state
            .sink { state in
                XCTAssertTrue(Thread.current.isMainThread)
                XCTAssertEqual(state.currentCount, 0)
                exp.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertEqual(reactor.state.currentCount, 0)
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

final class TransformCountingReactor: BaseReactor<TransformCountingReactor.Action, TransformCountingReactor.Mutation, TransformCountingReactor.State> {

    enum Action {
        case countUp
        case countUpTwo
        case countUpAsync
    }

    enum Mutation {
        case countUp
        case countUpTwo
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
        case .countUpTwo:
            return [.countUpTwo]
        case .countUpAsync:
            return Mutations(async: Just(.countUp).eraseToAnyPublisher())
        }
    }

    override func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .countUp:
            newState.currentCount += 1
        case .countUpTwo:
            newState.currentCount += 2
        }

        return newState
    }

    override func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
        action
            .prepend(.countUpTwo)
            .eraseToAnyPublisher()
    }

    override func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never> {
        mutation
            .prepend(.countUp)
            .eraseToAnyPublisher()
    }
}
