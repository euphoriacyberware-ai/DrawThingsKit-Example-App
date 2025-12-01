//
//  ContentView.swift
//  DrawThingsKit Example App
//
//  Created by euphoriacyberware-ai on 2025-11-30.
//

import SwiftUI
import DrawThingsKit

struct ContentView: View {
    @EnvironmentObject var connectionManager: ConnectionManager

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            GenerationView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectionManager())
        .environmentObject(ConfigurationManager())
        .environmentObject(JobQueue())
        .environmentObject(QueueProcessor())
}
