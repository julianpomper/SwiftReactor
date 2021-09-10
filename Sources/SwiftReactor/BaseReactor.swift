//
//  BaseReactor.swift
//  
//
//  Created by oanhof on 31.07.20.
//

import Foundation
import Combine

/// A base class that can be used to simplify
/// the implementation of the `Reactor` protocol.
///
/// It adds all necessary properties and calls the `createStateStream` function for you
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
        .none
    }
    
    open func reduce(state: State, mutation: Mutation) -> State {
        state
    }
    
    open func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
        action
    }
    
    open func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never> {
        mutation
    }
    
    open func transform(state: AnyPublisher<State, Never>) -> AnyPublisher<State, Never> {
        state
    }
}

#if compiler(>=5.5)
@available(iOS 15.0.0, macOS 12, tvOS 15, watchOS 8, *)
extension BaseReactor {

    /// Sends an action and suspends while the predicate is `true`.
    ///
    /// This method can be used to interact with async/await code, allowing you to suspend during an async mutation.
    ///
    /// Example:
    /// ```swift
    /// .refreshable {
    ///     await reactor.action(.refresh, while: \.isLoading)
    /// }
    /// ```
    ///
    public func action(_ action: Action, `while` predicate: @escaping (State) -> Bool) async {
        self.action(action)
        _ = await $state
            .values
            .first(where: { !predicate($0) })
    }
}
#endif

