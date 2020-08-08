//
//  SwiftUIReactorUIKitTests.swift
//  
//
//  Created by Julian Pomper on 08.08.20.
//

import UIKit
import Combine
import XCTest
@testable import SwiftUIReactor
@testable import SwiftUIReactorUIKit

final class SwiftUIReactorUIKitTests: XCTestCase {
    var countingViewController: CountingViewController!
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        countingViewController = CountingViewController()
    }
    
    func testSetAndBind() {
        let reactor = CountingReactor()
        countingViewController.setAndBind(reactor: reactor)
        
        reactor.action(.countUp)
        
        XCTAssertEqual(countingViewController.label.text, "1")
    }
}

final class CountingViewController: UIViewController, ReactorView {
    
    var reactor: CountingReactor?
    var cancellables: Set<AnyCancellable> = []
    
    var label = UILabel()
    
    func bind(reactor: CountingReactor) {
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
