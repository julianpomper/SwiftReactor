//
//  Mutations.swift
//  
//
//  Created by oanhof on 31.07.20.
//

import Foundation
import Combine

/// Holds `sync` and `async` Mutations
///
/// # Properties:
/// - `sync` are mutations that mutate the state instantly and
/// are always automatically forced on the main thread synchronously.
/// Use them specifically for UI interactions like Bindings, especially
/// if the change should be animated (ex.: `withAnimation`)
///
/// - `async` are mutations that happen asynchronously and can mutate the state
/// at any given time (ex.: if a network request returns a result).
/// The state is always mutated on the main thread asychronously, everything
/// before that everything happens on the thread of your choice
///
/// # Intitializing:
/// Because it conforms to the `ExpressibleByArrayLiteral`
/// it is possible to initialize it with `sync` mutations like an array
///
/// ``` swift
/// [.mySyncMutation]
/// ```
///
/// For convinience the static property `.none` can be used
/// if there should not be a state muatation
/// ``` swift
/// Mutations.none
/// ```
///
public struct Mutations<Mutation> {
    
    /// `sync` are mutations that mutate the state instantly and
    /// are always automatically forced on the main thread synchronously.
    /// Use them specifically for UI interactions like Bindings, especially
    /// if the change should be animated (ex.: `withAnimation`)
    public let sync: [Mutation]
    
    /// `async` are mutations that happen asynchronously and can mutate the state
    /// at any given time (ex.: if a network request returns a result).
    /// The state is always mutated on the main thread asychronously, everything
    /// before that everything happens on the thread of your choice
    public let async: AnyPublisher<Mutation, Never>
    
    public init(sync: Mutation, async: AnyPublisher<Mutation, Never> = Empty().eraseToAnyPublisher()) {
        self.init(sync: [sync], async: async)
    }
    
    public init(sync: [Mutation] = [], async: AnyPublisher<Mutation, Never> = Empty().eraseToAnyPublisher()) {
        self.sync = sync
        self.async = async
    }
}

public extension Mutations {
    /// intializes without any mutations
    static var none: Mutations<Mutation> { [] }
}

extension Mutations: ExpressibleByArrayLiteral {
    /// initialize with an array of sync `Mutation`s
    public init(arrayLiteral elements: Mutation...) {
        self.init(sync: elements)
    }
}
