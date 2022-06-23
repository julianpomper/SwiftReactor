//
//  AsyncReactor.swift
//  
//
//  Created by oanhof on 23.06.22.
//

import Foundation

public protocol AsyncReactor: ObservableObject {
    associatedtype Action
    associatedtype State
    
    @MainActor
    var state: State { get }
    
    @MainActor
    func action(_ action: Action) async
}
