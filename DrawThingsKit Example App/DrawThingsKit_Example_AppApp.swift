//
//  DrawThingsKit_Example_AppApp.swift
//  DrawThingsKit Example App
//
//  Created by Brian Cantin on 2025-11-30.
//

import SwiftUI
import SwiftData

@main
struct DrawThingsKit_Example_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
