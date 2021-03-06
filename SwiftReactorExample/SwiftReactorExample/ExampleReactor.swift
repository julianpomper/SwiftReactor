//
//  ExampleReactor.swift
//  SwiftReactorExample
//
//  Created by oanhof on 28.07.20.
//  Copyright © 2020 oanhof. All rights reserved.
//

import Foundation
import SwiftReactor
import Combine
import SwiftUI

class ExampleReactor: BaseReactor<ExampleReactor.Action, ExampleReactor.Mutation, ExampleReactor.State> {
    enum Action {
        case enterText(String)
        case setSwitch(Bool)
        case setSwitchAsync(Bool)
        case colorChangePressed(Color)
    }
    
    enum Mutation {
        case setText(String)
        case setSwitch(Bool)
        case setBackgroundColor(Color)
    }
    
    struct State {
        var text = "initial text"
        var switchValue = false
        var backgroundColor = Color.white
    }
    
    init() {
        super.init(initialState: State())
    }
    
    override func mutate(action: Action) -> Mutations<Mutation> {
        switch action {
        case .enterText(let text):
            return [.setText(text)]
        case .setSwitch(let value):
            return [.setSwitch(value)]
        case .setSwitchAsync(let value):
            let mutation = Just(Mutation.setSwitch(!value)).delay(for: 2, scheduler: DispatchQueue.global())
                .eraseToAnyPublisher()
            
            return Mutations(sync: .setSwitch(value), async: mutation)
        case .colorChangePressed(let color):
            return [.setBackgroundColor(color)]
        }
    }
    
    override func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setText(let text):
            newState.text = text
        case .setSwitch(let value):
            newState.switchValue = value
        case .setBackgroundColor(let color):
            newState.backgroundColor = color
        }
        
        return newState
    }

    override func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
        action
            .prepend(.setSwitchAsync(true))
            .eraseToAnyPublisher()
    }
    
    override func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never> {
        mutation
            .prepend(.setText("hello"))
            .eraseToAnyPublisher()
    }
}
