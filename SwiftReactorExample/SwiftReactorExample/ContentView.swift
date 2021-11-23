//
//  ContentView.swift
//  SwiftReactorExample
//
//  Created by oanhof on 28.07.20.
//  Copyright © 2020 oanhof. All rights reserved.
//

import SwiftUI
import SwiftReactor

struct ContentView: View {
    @ActionBinding(\ExampleReactor.self, keyPath: \.text, action: ExampleReactor.Action.enterText)
    private var text: String
    
    @ActionBinding(\ExampleReactor.self, keyPath: \.switchValue, action: ExampleReactor.Action.setSwitch)
    private var switchValue: Bool
    
    @ActionBinding(\ExampleReactor.self, keyPath: \.switchValue, action: ExampleReactor.Action.setSwitchAsync)
    private var switchValueAsync: Bool
    
    @ActionBinding(\ExampleReactor.self, keyPath: \.backgroundColor, action: ExampleReactor.Action.colorChangePressed)
    private var backgroundColor: Color
    
    @State
    private var sheetPresented = false
    
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
            
            if #available(iOS 14.0, *) {
                NavigationLink("Navigate") {
                    ReactorView(ExampleReactor()) {
                        ContentView()
                    }
                }
                
                Button("Present") {
                    sheetPresented = true
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .sheet(isPresented: $sheetPresented) {
            if #available(iOS 14.0, *) {
                ReactorView(ExampleReactor()) {
                    ContentView()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let reactor = ExampleReactor()
    
    static var previews: some View {
        ContentView()
            .environmentObject(reactor)
    }
}
