//
//  DrawThingsKit_Example_AppApp.swift
//  DrawThingsKit Example App
//
//  Created by Brian Cantin on 2025-11-30.
//

import SwiftUI
import SwiftData
import DrawThingsKit

@main
struct DrawThingsKit_Example_AppApp: App {
    @StateObject private var connectionManager = ConnectionManager()
    @StateObject private var configurationManager = ConfigurationManager()
    @StateObject private var queue = JobQueue()
    @StateObject private var processor = QueueProcessor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
                .environmentObject(configurationManager)
                .environmentObject(queue)
                .environmentObject(processor)
                .task {
                    processor.startProcessing(queue: queue, connectionManager: connectionManager)
                }
        }
        .modelContainer(for: SavedConfiguration.self)
    }
}
