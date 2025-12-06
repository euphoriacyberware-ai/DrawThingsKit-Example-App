//
//  GenerationView.swift
//  DrawThingsKit Example App
//
//  Created by euphoriacyberware-ai on 2025-11-30.
//

import SwiftUI
import DrawThingsKit
import UniformTypeIdentifiers

struct GenerationView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var configurationManager: ConfigurationManager
    @EnvironmentObject var queue: JobQueue

    @State private var generatedImage: PlatformImage?
    @State private var previewImage: PlatformImage?
    @State private var isGenerating = false
    @State private var progressStep: Int = 0
    @State private var progressTotal: Int = 0
    @State private var errorMessage: String?
    @State private var zeroNegativePrompt = false

    private var isConnected: Bool {
        connectionManager.connectionState.isConnected
    }

    private var modelsManager: ModelsManager? {
        connectionManager.modelsManager
    }

    private var seedBinding: Binding<Int64> {
        Binding(
            get: { configurationManager.activeConfiguration.seed ?? -1 },
            set: { configurationManager.activeConfiguration.seed = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                configurationSection
                generateButton
                resultSection
            }
            .padding()
        }
        .navigationTitle("Generate")
        .onReceive(queue.events) { event in
            handleQueueEvent(event)
        }
    }

    // MARK: - Configuration Section

    @ViewBuilder
    private var configurationSection: some View {
        VStack(spacing: 16) {
            GroupBox("Prompt") {
                PromptSection(
                    prompt: $configurationManager.prompt,
                    negativePrompt: $configurationManager.negativePrompt,
                    zeroNegativePrompt: $zeroNegativePrompt
                )
            }

            if let modelsManager = modelsManager {
                GroupBox("Model") {
                    ModelSection(
                        modelsManager: modelsManager,
                        selectedCheckpoint: $configurationManager.selectedCheckpoint,
                        selectedRefiner: $configurationManager.selectedRefiner,
                        refinerStart: $configurationManager.activeConfiguration.refinerStart,
                        sampler: $configurationManager.activeConfiguration.sampler,
                        modelName: $configurationManager.activeConfiguration.model,
                        refinerName: $configurationManager.activeConfiguration.refinerModel
                    )
                }

                GroupBox("LoRA") {
                    LoRASection(
                        modelsManager: modelsManager,
                        selectedLoRAs: $configurationManager.selectedLoRAs
                    )
                }
            }

            GroupBox("Dimensions") {
                DimensionsSection(
                    width: $configurationManager.activeConfiguration.width,
                    height: $configurationManager.activeConfiguration.height
                )
            }

            GroupBox("Parameters") {
                ParametersSection(
                    steps: $configurationManager.activeConfiguration.steps,
                    guidanceScale: $configurationManager.activeConfiguration.guidanceScale,
                    cfgZeroStar: $configurationManager.activeConfiguration.cfgZeroStar,
                    cfgZeroInitSteps: $configurationManager.activeConfiguration.cfgZeroInitSteps,
                    resolutionDependentShift: $configurationManager.activeConfiguration.resolutionDependentShift,
                    shift: $configurationManager.activeConfiguration.shift
                )
            }

            GroupBox("Seed") {
                SeedSection(
                    seed: seedBinding,
                    seedMode: $configurationManager.activeConfiguration.seedMode
                )
            }
        }
    }

    // MARK: - Generate Button

    @ViewBuilder
    private var generateButton: some View {
        Button(action: generate) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(isGenerating ? "Generating..." : "Generate")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!isConnected)
    }

    // MARK: - Result Section

    @ViewBuilder
    private var resultSection: some View {
        GroupBox("Result") {
            VStack(spacing: 12) {
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if isGenerating && progressTotal > 0 {
                    VStack(spacing: 8) {
                        ProgressView(value: Double(progressStep), total: Double(progressTotal))
                        Text("Step \(progressStep) of \(progressTotal)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                imageView
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var imageView: some View {
        let displayImage = generatedImage ?? previewImage

        if let image = displayImage {
            VStack(spacing: 12) {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 512)
                #else
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 512)
                #endif

                if generatedImage != nil {
                    saveButton
                }
            }
        } else {
            ContentUnavailableView(
                "No Image",
                systemImage: "photo",
                description: Text("Generated images will appear here")
            )
            .frame(height: 200)
        }
    }

    @ViewBuilder
    private var saveButton: some View {
        #if os(macOS)
        Button("Save Image...") {
            saveImageMacOS()
        }
        #else
        if let image = generatedImage {
            ShareLink(item: Image(uiImage: image), preview: SharePreview("Generated Image", image: Image(uiImage: image))) {
                Label("Save Image", systemImage: "square.and.arrow.down")
            }
        }
        #endif
    }

    // MARK: - Actions

    private func generate() {
        errorMessage = nil
        configurationManager.syncModelsToConfiguration()

        do {
            let job = try GenerationJob(
                prompt: configurationManager.prompt,
                negativePrompt: configurationManager.negativePrompt,
                configuration: configurationManager.activeConfiguration
            )
            queue.enqueue(job)
        } catch {
            errorMessage = "Failed to create job: \(error.localizedDescription)"
        }
    }

    private func handleQueueEvent(_ event: JobEvent) {
        switch event {
        case .jobStarted:
            isGenerating = true
            progressStep = 0
            progressTotal = 0
            previewImage = nil
            generatedImage = nil

        case .jobProgress(_, let progress):
            progressStep = progress.currentStep
            progressTotal = progress.totalSteps
            if let preview = progress.previewImage {
                previewImage = preview
            }

        case .jobCompleted(_, let images):
            isGenerating = false
            progressStep = 0
            progressTotal = 0
            previewImage = nil
            if let image = images.first {
                generatedImage = image
            }

        case .jobFailed(_, let error):
            isGenerating = false
            progressStep = 0
            progressTotal = 0
            errorMessage = error

        case .jobCancelled:
            isGenerating = false
            progressStep = 0
            progressTotal = 0

        default:
            break
        }
    }

    #if os(macOS)
    private func saveImageMacOS() {
        guard let image = generatedImage else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.png]
        savePanel.nameFieldStringValue = "generated_image.png"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let tiffData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: url)
                }
            }
        }
    }
    #endif
}

#Preview {
    GenerationView()
        .environmentObject(ConnectionManager())
        .environmentObject(ConfigurationManager())
        .environmentObject(JobQueue())
}
