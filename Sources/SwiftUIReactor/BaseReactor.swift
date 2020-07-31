//
//  BaseReactor.swift
//  
//
//  Created by Julian Pomper on 31.07.20.
//

import Foundation
import Combine

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
}
