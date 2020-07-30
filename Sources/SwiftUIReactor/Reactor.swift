//
//  Reactor.swift
//  
//
//  Created by Julian Pomper on 26.12.19.
//

import Combine
import SwiftUI

public struct Mutations<Mutation> {
    public let sync: [Mutation]
    public let async: AnyPublisher<Mutation, Never>
    
    public init(sync: Mutation, async: AnyPublisher<Mutation, Never> = Empty().eraseToAnyPublisher()) {
        self.init(sync: [sync], async: async)
    }
    
    public init(sync: [Mutation] = [], async: AnyPublisher<Mutation, Never> = Empty().eraseToAnyPublisher()) {
        self.sync = sync
        self.async = async
    }
}

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

public extension Reactor {
    
    /// Starts the mutate and reduce chain
    /// Takes an action, to get all necessary mutations and passes them to the reduce method
    func action(_ action: Action) {
        self.action.send(action)
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
            set: { self.mutation.send(mutation($0)) }
        )
    }
}

/// Property wrapper to get a binding to a state keyPath and a associated Action
/// Can be used and behaves like the `@State` property wrapper
@propertyWrapper
public struct ActionBinding<R: Reactor, Value>: DynamicProperty {
    @EnvironmentObject
    var reactor: R
    
    let keyPath: KeyPath<R.State, Value>
    let action: (Value) -> R.Action
    
    /**
     - Parameters:
         - reactorType: Type of the reactor in the view´s `EnvironmentObject`
         - keyPath: Keypath to the value in the reactor´s state
         - action: Action to perform in the reactor
     */
    public init(_ reactorType: R.Type, keyPath: KeyPath<R.State, Value>, action: @escaping (Value) -> R.Action) {
        self.keyPath = keyPath
        self.action = action
    }
    
    public var wrappedValue: Value {
        get { projectedValue.wrappedValue }
        nonmutating set { projectedValue.wrappedValue = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        get { reactor.mutate(binding: keyPath, action) }
    }
}

/// Property wrapper to get a binding to a state keyPath and a associated Mutation
/// Can be used and behaves like the `@State` property wrapper
@propertyWrapper
public struct MutationBinding<R: Reactor, Value>: DynamicProperty {
    @EnvironmentObject
    var reactor: R
    
    let keyPath: KeyPath<R.State, Value>
    let mutation: (Value) -> R.Mutation
    
    /**
     - Parameters:
         - reactorType: Type of the reactor in the view´s `EnvironmentObject`
         - keyPath: Keypath to the value in the reactor´s state
         - mutation: Mutation to perform in the reactor
     */
    public init(_ reactorType: R.Type, keyPath: KeyPath<R.State, Value>, mutation: @escaping (Value) -> R.Mutation) {
        self.keyPath = keyPath
        self.mutation = mutation
    }
    
    public var wrappedValue: Value {
        get { projectedValue.wrappedValue }
        nonmutating set { projectedValue.wrappedValue = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        get { reactor.reduce(binding: keyPath, mutation) }
    }
}

open class BaseReactor<Action, Mutation, State>: Reactor {
    public let action = PassthroughSubject<Action, Never>()
    
    public let mutation = PassthroughSubject<Mutation, Never>()
    
    @Published
    public var state: State
    
    public var cancellables = Set<AnyCancellable>()
    
    public init(initialState: State) {
        state = initialState
        createStateStream()
    }
    
    open func mutate(action: Action) -> Mutations<Mutation> {
        Mutations()
    }
    
    open func reduce(state: State, mutation: Mutation) -> State {
        state
    }
}
