//
//  BaseReactorView.swift
//  
//
//  Created by Julian Pomper on 08.08.20.
//

#if canImport(UIKit)

import UIKit
import Combine
import SwiftReactor

/// A base class that can be used to simplify
/// the implementation of the `ReactorView` protocol.
///
/// It adds all necessary properties and calls the `bind(reactor:)` method for you, when the `reactor` is being set
open class BaseReactorView<Reactor: SwiftReactor.Reactor>: UIView, ReactorView {
    
    public var reactor: Reactor? {
        didSet {
            guard let reactor = reactor else { return }
            cancellables = []
            bind(reactor: reactor)
        }
    }
    
    public var cancellables: Set<AnyCancellable> = []
    
    open func bind(reactor: Reactor) { }
}

/// A base class that can be used to simplify
/// the implementation of the `ReactorView` protocol.
///
/// It adds all necessary properties and calls the `bind(reactor:)` method for you, when the `reactor` is being set
open class BaseReactorViewController<Reactor: SwiftReactor.Reactor>: UIViewController, ReactorView {
    public var reactor: Reactor? {
        didSet {
            guard let reactor = reactor else { return }
            cancellables = []
            bind(reactor: reactor)
        }
    }
    
    public var cancellables: Set<AnyCancellable> = []
    
    open func bind(reactor: Reactor) { }
}

#endif
