//
//  Bindings.swift
//  
//
//  Created by Julian Pomper on 31.07.20.
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
