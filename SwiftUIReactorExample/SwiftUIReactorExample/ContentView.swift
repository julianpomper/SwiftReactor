//
//  ContentView.swift
//  SwiftUIReactorExample
//
//  Created by Dominik Arnhof on 28.07.20.
//  Copyright © 2020 Dominik Arnhof. All rights reserved.
//

import SwiftUI
import SwiftUIReactor

struct ContentView: View {
    @ActionBinding(\ExampleReactor.self, keyPath: \.text, action: ExampleReactor.Action.enterText)
    private var text: String
    
    @ActionBinding(\ExampleReactor.self, keyPath: \.switchValue, action: ExampleReactor.Action.setSwitch)
    private var switchValue: Bool
    
    @ActionBinding(\ExampleReactor.self, keyPath: \.switchValue, action: ExampleReactor.Action.setSwitchAsync)
    private var switchValueAsync: Bool
    
    @ActionBinding(\ExampleReactor.self, keyPath: \.backgroundColor, action: ExampleReactor.Action.colorChangePressed)
    private var backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            TextField("Text", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text(text)
            
            Toggle(isOn: $switchValue, label: { Text("Switch \(String(switchValue))") })
            
            Toggle(isOn: $switchValueAsync, label: { Text("Switch async \(String(switchValueAsync))") })
            
            Button(action: {
                withAnimation(.spring()) {
                    self.backgroundColor = [Color.red, .orange, .green].randomElement() ?? .white
                }
            }, label: {
                Text("Random Color")
            })
        }
        .padding()
        .background(backgroundColor)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let reactor = ExampleReactor()
    
    static var previews: some View {
        ContentView()
            .environmentObject(reactor)
    }
}
