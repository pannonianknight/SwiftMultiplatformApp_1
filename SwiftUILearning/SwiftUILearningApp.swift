//
//  SwiftUILearningApp.swift
//  SwiftUILearning
//

import SwiftUI

@main
struct SwiftUILearningApp: App {
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1000, height: 700)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
