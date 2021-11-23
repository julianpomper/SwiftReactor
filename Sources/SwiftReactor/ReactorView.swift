//
//  ReactorView.swift
//  
//
//  Created by oanhof on 23.11.21.
//

import SwiftUI

/**
 Used to create a view, where the Reactor lifetime is tied to the views lifecycle.
 
 Example usage:
 ```
 .sheet(isPresented: $sheetPresented) {
     ReactorView(SheetReactor()) {
         SheetContentView()
     }
 }
 ```
 */
@available(watchOS 7.0, *)
@available(tvOS 14.0, *)
@available(macOS 11.0, *)
@available(iOS 14.0, *)
public struct ReactorView<Content: View, R: Reactor>: View {
    let content: Content
    
    @StateObject
    private var reactor: R
    
    public init(_ reactor: @escaping @autoclosure () -> R, @ViewBuilder content: () -> Content) {
        _reactor = StateObject(wrappedValue: reactor())
        self.content = content()
    }
    
    public var body: some View {
        content
            .environmentObject(reactor)
    }
}
