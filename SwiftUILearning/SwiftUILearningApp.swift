//
//  SwiftUILearningApp.swift
//  SwiftUILearning
//
//  App entry: one WindowGroup for both iOS and tvOS. ContentView switches root UI per platform.
//

import SwiftUI

@main
struct SwiftUILearningApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
