//
//  SwiftUIReactorUIKitTests.swift
//  
//
//  Created by Julian Pomper on 08.08.20.
//

#if canImport(UIKit)

import UIKit
import Combine
import XCTest
@testable import SwiftUIReactor
@testable import SwiftUIReactorUIKit

final class SwiftUIReactorUIKitTests: XCTestCase {
    var reactor: CountingReactor!
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        reactor = CountingReactor()
    }
    
    func testSetAndBind() {
        let countingViewController = CountingViewController()
        countingViewController.setAndBind(reactor: reactor)
        
        XCTAssertNotNil(countingViewController.reactor)
        
        reactor.action(.countUp)
        
        XCTAssertEqual(countingViewController.label.text, "1")
    }
    
    func testBaseReactorView() {
        let countingView = BaseCountingView()
        countingView.reactor = reactor
                
        reactor.action(.countUp)
        
        XCTAssertEqual(countingView.label.text, "1")
    }
    
    func testBaseReactorViewController() {
        let countingViewController = BaseCountingViewController()
        countingViewController.reactor = reactor
        
        reactor.action(.countUp)
        
        XCTAssertEqual(countingViewController.label.text, "1")
    }
}

final class BaseCountingView: BaseReactorView<CountingReactor> {
    
    var label = UILabel()
    
    override func bind(reactor: Reactor) {
        reactor.$state
            .map { String($0.currentCount) }
            .assign(to: \.label.text, on: self)
            .store(in: &cancellables)
    }
}

final class BaseCountingViewController: BaseReactorViewController<CountingReactor> {
    
    var label = UILabel()
    
    override func bind(reactor: Reactor) {
        reactor.$state
            .map { String($0.currentCount) }
            .assign(to: \.label.text, on: self)
            .store(in: &cancellables)
    }
}

final class CountingViewController: UIViewController, ReactorView {
    typealias Reactor = CountingReactor
    
    var reactor: Reactor?
    var cancellables: Set<AnyCancellable> = []
    
    var label = UILabel()
    
    func bind(reactor: Reactor) {
        reactor.$state
            .map { String($0.currentCount) }
            .assign(to: \.label.text, on: self)
            .store(in: &cancellables)
    }
}

final class CountingReactor: BaseReactor<CountingReactor.Action, CountingReactor.Mutation, CountingReactor.State> {

    enum Action {
        case countUp
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

#endif
