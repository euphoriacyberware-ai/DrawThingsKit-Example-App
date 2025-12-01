//
//  SidebarView.swift
//  DrawThingsKit Example App
//
//  Created by euphoriacyberware-ai on 2025-11-30.
//

import SwiftUI
import SwiftData
import DrawThingsKit

struct SidebarView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var queue: JobQueue

    @State private var showingServerProfiles = false

    var body: some View {
        VStack(spacing: 0) {
            // Connection section
            VStack(alignment: .leading, spacing: 8) {
                Text("Connection")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                HStack {
                    ServerProfilePicker(connectionManager: connectionManager)

                    Button {
                        showingServerProfiles = true
                    } label: {
                        Image(systemName: "network")
                    }
                    .buttonStyle(.borderless)
                    .help("Manage servers")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()

            Divider()

            // Configuration actions section
            VStack(alignment: .leading, spacing: 8) {
                Text("Configuration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                ConfigurationActionsView(modelsManager: connectionManager.modelsManager)
            }
            .padding()

            Divider()

            // Queue section - QueueSidebarView manages its own layout
            QueueSidebarView(queue: queue)
        }
        .navigationTitle("Draw Things")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        #endif
        .sheet(isPresented: $showingServerProfiles) {
            NavigationStack {
                ServerProfilesView(connectionManager: connectionManager)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingServerProfiles = false
                            }
                        }
                    }
            }
            #if os(macOS)
            .frame(minWidth: 400, minHeight: 300)
            #endif
        }
    }
}

#Preview {
    SidebarView()
        .environmentObject(ConnectionManager())
        .environmentObject(ConfigurationManager())
        .environmentObject(JobQueue())
        .modelContainer(for: SavedConfiguration.self, inMemory: true)
}
