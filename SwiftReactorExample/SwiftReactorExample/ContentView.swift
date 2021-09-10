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

    @EnvironmentObject
    private var reactor: ExampleReactor
    
    var body: some View {
        #if compiler(>=5.5)
        if #available(iOS 15.0, *) {
            list
                .refreshable {
                    await reactor.action(.setSwitchAsync(true), while: \.switchValue)
                }
        } else {
            list
        }
        #else
        list
        #endif
    }

    private var list: some View {
        List {
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
}

struct ContentView_Previews: PreviewProvider {
    static let reactor = ExampleReactor()
    
    static var previews: some View {
        ContentView()
            .environmentObject(reactor)
    }
}
