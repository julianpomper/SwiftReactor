//
//  ReactorView.swift
//  
//
//  Created by Julian Pomper on 08.08.20.
//

#if canImport(UIKit)

import UIKit
import Combine

import SwiftReactor

/// A protocol to use the `Reactor` with UIKit
///
/// - Important: call the `setAndBind(reactor:)` method to set the reactor and call the `bind(reactor:)` method
///
public protocol ReactorView: AnyObject {
    associatedtype Reactor = SwiftReactor.Reactor
    /**
        use `setAndBind` to set the reactor and call the `bind(reactor:)` method
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

#endif
