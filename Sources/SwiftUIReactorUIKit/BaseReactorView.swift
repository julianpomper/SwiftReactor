//
//  BaseReactorView.swift
//  
//
//  Created by Julian Pomper on 08.08.20.
//

import UIKit
import Combine
import SwiftUIReactor

/// A base class that can be used to simplify
/// the implementation of the `ReactorView` protocol.
///
/// It adds all necessary properties and calls the `bind(reactor:)` method for you, when the `reactor` is being set
open class BaseReactorView<Reactor: SwiftUIReactor.Reactor>: UIView, ReactorView {
    
    public var reactor: Reactor? {
        didSet {
            guard let reactor = reactor else { return }
            cancellables = Set<AnyCancellable>()
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
open class BaseReactorViewController<Reactor: SwiftUIReactor.Reactor>: UIViewController, ReactorView {
    public var reactor: Reactor? {
        didSet {
            guard let reactor = reactor else { return }
            cancellables = Set<AnyCancellable>()
            bind(reactor: reactor)
        }
    }
    
    public var cancellables: Set<AnyCancellable> = []
    
    open func bind(reactor: Reactor) { }
}
