//
//  Mutations.swift
//  
//
//  Created by Julian Pomper on 31.07.20.
//

import Foundation
import Combine

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

public extension Mutations {
    static var none: Mutations<Mutation> { [] }
}

extension Mutations: ExpressibleByArrayLiteral {
    /// initialize with an array of sync `Mutation`s
    public init(arrayLiteral elements: Mutation...) {
        self.init(sync: elements)
    }
}
