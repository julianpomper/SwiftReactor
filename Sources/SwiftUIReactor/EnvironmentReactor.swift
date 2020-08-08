//
//  File.swift
//  
//
//  Created by Dominik on 08.08.20.
//

import SwiftUI

/// A property wrapper to get a reactor or one of its nested reactors from the environment.
@propertyWrapper
struct EnvironmentReactor<Root: Reactor, Target: Reactor>: DynamicProperty {
    @EnvironmentObject
    private var root: Root
    
    let keyPath: KeyPath<Root, Target>
    
    /**
    - Parameter keyPath: KeyPath to the desired Reactor
     
    # Example #
    ```
     // get the root Reactor
     @EnvironmentReactor()
     var reactor: AppReactor
     
     // get a nested reactor
     @EnvironmentReactor(\AppReactor.detailViewReactor)
     var reactor: DetailReactor
    ```
    */
    init(_ keyPath: KeyPath<Root, Target>) {
        self.keyPath = keyPath
    }
    
    init() where Root == Target {
        keyPath = \.self
    }
    
    var wrappedValue: Target {
        root[keyPath: keyPath]
    }
}
