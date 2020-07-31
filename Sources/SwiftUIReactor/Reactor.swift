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
    
    var action: PassthroughSubject<Action, Never> { get }
    
    var mutation: PassthroughSubject<Mutation, Never> { get }
    
    /// ATTENTION: add @Published to this value.
    /// The State represents the current state of a section in the app.
    var state: State { get set }
    
    /// Stores all type-erasing cancellable instances for this reactor
    var cancellables: Set<AnyCancellable> { get set }
    
    /// Use the `action(Action)` method to start the mutation and reduce chain, to ensure the state is mutated properly.
    /// Transforms a user action to a state mutation. Do all your (async) tasks here.
    func mutate(action: Action) -> Mutations<Mutation>
    
    /// Mutates the state baseed on the given mutation.
    /// There should not be any side effects in this method.
    func reduce(state: State, mutation: Mutation) -> State
    
    /// Bind values to actions
    func mutate<Value>(binding keyPath: KeyPath<State, Value>, _ action: @escaping (Value) -> Action) -> Binding<Value>
    
    /// Bind values to mutations
    func reduce<Value>(binding keyPath: KeyPath<State, Value>, _ mutation: @escaping (Value) -> Mutation) -> Binding<Value>
    
    func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never>
    
    func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never>
    
    func transform(state: AnyPublisher<State, Never>) -> AnyPublisher<State, Never>
}

public extension Reactor {
    
    /// Starts the mutate and reduce chain
    /// Takes an action, to get all necessary mutations and passes them to the reduce method
    func action(_ action: Action) {
        self.action.send(action)
    }
    
    func createStateStream() {
        let stateLock = NSLock()
        
        let action = self.action
            .eraseToAnyPublisher()
        
        let transformedAction = transform(action: action)
        
        let initialState = self.state
        
        let mutation = transformedAction
            .flatMap { [weak self] action -> AnyPublisher<Mutation, Never> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                let mutations = self.mutate(action: action)
                
                self.processSyncMutations(mutations.sync, lock: stateLock)
                
                return mutations.async.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        let transformedMutation = transform(mutation: mutation)
            .merge(with: self.mutation)

        let state = transformedMutation
            .scan(initialState) { [weak self] state, mutation -> State in
                guard let self = self else { return state }
                return self.reduce(state: state, mutation: mutation)
            }
            .prepend(initialState)
            .eraseToAnyPublisher()
        
        transform(state: state)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                self?.state = state
            })
            .store(in: &cancellables)
    }
    
    private func processSyncMutations(_ mutations: [Mutation], lock: NSLock) {
        lock.lock()
        mutations.forEach { mutation in
            if Thread.current.isMainThread {
                state = reduce(state: state, mutation: mutation)
            } else {
                DispatchQueue.main.sync {
                    state = reduce(state: state, mutation: mutation)
                }
            }
        }
        lock.unlock()
    }
    
    func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
        action
    }
    
    func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never> {
        mutation
    }
    
    func transform(state: AnyPublisher<State, Never>) -> AnyPublisher<State, Never> {
        state
    }
}
