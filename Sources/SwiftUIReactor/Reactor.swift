//
//  Reactor.swift
//  
//
//  Created by Julian Pomper on 26.12.19.
//

import Combine
import SwiftUI

public protocol Reactor: ObservableObject {
    
    /// An action represents user actions.
    associatedtype Action
    
    /// A mutation represents state changes.
    associatedtype Mutation
    
    /// A State represents the current state of a section in the app.
    associatedtype State

    /// ATTENTION: add @Published to this value.
    /// The State represents the current state of a section in the app.
    var state: State { get }
    
    /// Stores all type-erasing cancellable instances for this reactor
    var cancellables: Set<AnyCancellable> { get set }
    
    /// Use the `action(Action)` method to start the mutation and reduce chain, to ensure the state is mutated properly.
    /// Transforms a user action to a state mutation. Do all your (async) tasks here.
    func mutate(action: Action) -> AnyPublisher<Mutation, Never>
    
    /// Mutates the state baseed on the given mutation.
    /// There should not be any side effects in this method.
    func reduce(mutation: Mutation)
    
    /// Bind values to actions
    func mutate<Value>(binding keyPath: KeyPath<State, Value>, _ action: @escaping (Value) -> Action) -> Binding<Value>
    
    /// Bind values to mutations
    func reduce<Value>(binding keyPath: KeyPath<State, Value>, _ mutation: @escaping (Value) -> Mutation) -> Binding<Value>
}

public extension Reactor {
    
    /// Starts the mutate and reduce chain
    /// Takes an action, to get all necessary mutations and passes them to the reduce method
    func action(_ action: Action) {
        mutate(action: action)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reduce)
            .store(in: &cancellables)
    }
    
    func mutate<Value>(binding keyPath: KeyPath<State, Value>, _ action: @escaping (Value) -> Action) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { self.action(action($0)) }
        )
    }
    
    func reduce<Value>(binding keyPath: KeyPath<State, Value>, _ mutation: @escaping (Value) -> Mutation) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { self.reduce(mutation: mutation($0)) }
        )
    }
}