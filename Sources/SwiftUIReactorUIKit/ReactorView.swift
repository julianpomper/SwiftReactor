//
//  ReactorView.swift
//  
//
//  Created by Julian Pomper on 08.08.20.
//

import UIKit
import Combine

import SwiftUIReactor

/// A protocol to use the `Reactor` with UIKit
///
/// - Important: call the `setAndBind(reactor:)` method to set the reactor and call the `bind(reactor:)` method
///
public protocol ReactorView: class {
    associatedtype Reactor = SwiftUIReactor.Reactor
    /**
        use `bindAndSet` to set the reactor and call the `bind(reactor:)` func
        otherwise you can set your custom `didSet` for your reactor variable
        ~~~
        {
            didSet {
                guard let reactor = reactor else { return }
                cancellables = Set<AnyCancellable>()
                bind(reactor: reactor)
            }
        }
        ~~~
    */
    var reactor: Reactor? { get set }
    
    /// Stores all type-erasing cancellable instances for this reactor
    var cancellables: Set<AnyCancellable> { get set }
    
    /**
     Bind/Assign state values and actions
     
    # Usage:
     ```swift
     func bind(reactor: CountingReactor) {
        reactor.$state
            .map { String($0.currentCount) }
            .assign(to: \.label.text, on: self)
            .store(in: &cancellables)
    }
    ```
    */
    func bind(reactor: Reactor)
    func setAndBind(reactor: Reactor)
}

public extension ReactorView {
    func setAndBind(reactor: Reactor) {
        self.reactor = reactor
        bind(reactor: reactor)
    }
}
