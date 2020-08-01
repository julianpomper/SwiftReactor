//
//  Reactor.swift
//  
//
//  Created by Julian Pomper on 26.12.19.
//

import Combine
import SwiftUI

/// A protocol to structure your data flow in SwiftUI
///
/// - Important: call the `createStateStream` method in the initializer to
/// make sure all actions are passed to the proper methods
///
public protocol Reactor: ObservableObject {
    
    /// An action represents user actions.
    associatedtype Action
    
    /// A mutation represents state changes.
    associatedtype Mutation
    
    /// A State represents the current state of a section in the app.
    associatedtype State
    
    /// Passes all receiving actions down the state stream which is
    /// defined in the `createStateStream` method
    ///
    /// - Important: call the `createStateStream` method in the initializer to
    /// make sure all actions are passed to the proper methods
    ///
    var action: PassthroughSubject<Action, Never> { get }
    
    var mutation: PassthroughSubject<Mutation, Never> { get }
    
    /// The State represents the current state of a section in the app.
    ///
    /// - Warning: if you do not add @Published to this property
    /// you cannot subscribe to state changes
    ///
    /// - Important: add @Published to this property to be
    /// able to subscribe to changes in the state
    var state: State { get set }
    
    /// Stores all type-erasing cancellable instances for this reactor
    var cancellables: Set<AnyCancellable> { get set }
    
    /// Use the `action(Action)` method to start the state stream, to ensure the state is mutated properly.
    /// Transforms a user action to a state mutation.
    ///
    /// - Important: If you have any side effects do it here.
    ///
    /// - Important: `Binding` and `withAnimation` require the state to be changed
    /// on the main thread synchronously. For that reason use `sync` mutations for
    /// this use cases
    ///
    ///
    /// # Usage:
    ///
    /// return `sync` mutations if you want to mutate the state instantly
    /// and sychronously on the main thread. Use them for `Binding` or
    /// if you want state changes to be animated in SwiftUI (ex.: `withAnimation`)
    ///
    ///
    /// return `async` mutations if you have to do async tasks (ex.: network requests)
    /// or expensive tasks on a background queue
    ///
    ///
    /// ```swift
    /// func mutate(action: Action) -> Mutations {
    ///     switch action {
    ///     case .noMutationNeededAction:
    ///         return .none
    ///     case .enterText(let text):
    ///         return Mutations(sync: .setText(text))
    ///     case .setSwitchAsync(let value):
    ///         let mutation = Just(Mutation.setSwitch(!value)
    ///             .delay(for: 2, scheduler: DispatchQueue.global())
    ///             .eraseToAnyPublisher()
    ///
    ///         return Mutations(sync: .setSwitch(value), async: mutation)
    ///     }
    /// }
    /// ```
    ///
    func mutate(action: Action) -> Mutations<Mutation>
    
    /// Mutates the state based on the given mutation.
    ///
    /// - Warning: There should not be any side effects in this method.
    ///
    /// # Usage:
    /// ```swift
    /// func reduce(state: State, mutation: Mutation) -> State {
    ///     var newState = state
    ///
    ///     switch mutation {
    ///     case .myMutation(let text):
    ///         newState.text = text
    ///     }
    ///
    ///     return newState
    /// }
    /// ```
    ///
    func reduce(state: State, mutation: Mutation) -> State
    
    /// Bind values to actions
    func mutate<Value>(binding keyPath: KeyPath<State, Value>, _ action: @escaping (Value) -> Action) -> Binding<Value>
    
    /// Bind values to mutations
    func reduce<Value>(binding keyPath: KeyPath<State, Value>, _ mutation: @escaping (Value) -> Mutation) -> Binding<Value>
    
    /// Transforms an action and can be used to combine it with other publishers.
    /// It is called once when the state stream is created in the `createStateStream` method.
    func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never>
    
    /// Transforms an mutation and can be used to combine it with other publishers.
    /// It is called once when the state stream is created in the `createStateStream` method.
    func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never>
    
    /// Transforms the state and can be used to combine it with other publishers.
    /// It is called once when the state stream is created in the `createStateStream` method.
    func transform(state: AnyPublisher<State, Never>) -> AnyPublisher<State, Never>
}

public extension Reactor {
    
    /// A convenience method to send actions to the `action` subject
    func action(_ action: Action) {
        self.action.send(action)
    }
    
    /// Creates the state stream to properly call all methods on
    /// their dedicated threads.
    ///
    /// - Warning: This methods should only be called once when
    /// the reactor is initialized
    ///
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
