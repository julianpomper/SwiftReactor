//
//  Bindings.swift
//  
//
//  Created by oanhof on 31.07.20.
//

import SwiftUI

public extension Reactor {
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
public struct ActionBinding<Root: Reactor, Target: Reactor, Value>: DynamicProperty {
    let target: EnvironmentReactor<Root, Target>
    
    let keyPath: KeyPath<Target.State, Value>
    let action: (Value) -> Target.Action
    
    /**
     - Parameters:
         - reactorPath: The keyPath to the Reactor in the views environment. eg. \AppReactor.self or \AppReactor.detailViewReactor for nested reactors
         - keyPath: Keypath to the value in the reactor´s state
         - action: Action to perform in the reactor
     */
    init(_ reactorPath: KeyPath<Root, Target>, keyPath: KeyPath<Target.State, Value>, action: @escaping (Value) -> Target.Action) {
        target = EnvironmentReactor(reactorPath)
        self.keyPath = keyPath
        self.action = action
    }
    
    public var wrappedValue: Value {
        get { projectedValue.wrappedValue }
        nonmutating set { projectedValue.wrappedValue = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        get { target.wrappedValue.mutate(binding: keyPath, action) }
    }
}
