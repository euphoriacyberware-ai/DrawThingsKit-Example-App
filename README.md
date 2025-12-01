# DrawThingsKit Example App

A simple example application demonstrating how to use [DrawThingsKit](https://github.com/euphoriacyberware-ai/DrawThingsKit) to build a Draw Things gRPC client application.

## Overview

This app showcases the key components of DrawThingsKit in a functional implementation:

- **Connection Management** - Connect to Draw Things gRPC servers
- **Configuration Management** - Copy, paste, save, and load generation presets
- **Model Selection** - Choose checkpoints, refiners, and LoRAs from connected servers
- **Generation Parameters** - Configure dimensions, steps, CFG scale, seed, and more
- **Job Queue** - Queue multiple generation jobs with progress tracking
- **Image Generation** - Generate images and save results

## Requirements

- macOS 13.0+ / iOS 16.0+
- Xcode 15.0+
- A running [Draw Things](https://drawthings.ai) instance with API Server enabled

## Setup

1. Clone this repository
2. Open `DrawThingsKit Example App.xcodeproj` in Xcode
3. Build and run the app
4. In Draw Things, enable the API Server (Settings > API Server)
5. Add a server profile in the example app and connect

## Architecture

### App Entry Point

The app initializes four core DrawThingsKit managers as `@StateObject` and injects them into the view hierarchy:

```swift
@StateObject private var connectionManager = ConnectionManager()
@StateObject private var configurationManager = ConfigurationManager()
@StateObject private var queue = JobQueue()
@StateObject private var processor = QueueProcessor()
```

The `QueueProcessor` is started on app launch to begin processing queued jobs:

```swift
.task {
    processor.startProcessing(queue: queue, connectionManager: connectionManager)
}
```

SwiftData is configured for persisting configuration presets:

```swift
.modelContainer(for: SavedConfiguration.self)
```

### Sidebar Components

The sidebar demonstrates several DrawThingsKit UI components:

| Component | Purpose |
|-----------|---------|
| `ServerProfilePicker` | Dropdown to select and connect to server profiles |
| `ServerProfilesView` | Full server profile management (add/edit/delete) |
| `ConfigurationActionsView` | Copy, paste, save presets, and JSON editor |
| `QueueSidebarView` | Compact queue display with job list and controls |

**Note:** `QueueSidebarView` manages its own internal layout including a `List`. Do not wrap it inside another `List` or `Section` to avoid nested list issues.

### Generation View Components

The main generation interface uses DrawThingsKit's configuration section views:

| Component | Purpose |
|-----------|---------|
| `PromptSection` | Prompt and negative prompt input |
| `ModelSection` | Checkpoint, refiner, and sampler selection |
| `LoRASection` | LoRA selection with weight controls |
| `DimensionsSection` | Width and height with presets |
| `ParametersSection` | Steps, CFG scale, and advanced parameters |
| `SeedSection` | Seed value and mode |

These sections bind directly to `ConfigurationManager` properties and `activeConfiguration`.

### Image Generation Flow

1. User configures generation parameters
2. Call `configurationManager.syncModelsToConfiguration()` to sync model selections
3. Create a `GenerationJob` with prompt and configuration
4. Enqueue the job with `queue.enqueue(job)`
5. Subscribe to `queue.events` to receive progress updates and results

```swift
let job = try GenerationJob(
    prompt: configurationManager.prompt,
    negativePrompt: configurationManager.negativePrompt,
    configuration: configurationManager.activeConfiguration
)
queue.enqueue(job)
```

### Handling Queue Events

Subscribe to job lifecycle events to update UI:

```swift
.onReceive(queue.events) { event in
    switch event {
    case .jobStarted(let job):
        // Generation started
    case .jobProgress(let job, let progress):
        // Update progress UI, show preview
    case .jobCompleted(let job, let images):
        // Display generated images
    case .jobFailed(let job, let error):
        // Show error message
    case .jobCancelled(let job):
        // Handle cancellation
    default:
        break
    }
}
```

## Project Structure

```
DrawThingsKit Example App/
├── DrawThingsKit_Example_AppApp.swift  # App entry, manager setup
├── ContentView.swift                    # NavigationSplitView layout
├── SidebarView.swift                    # Connection, config, queue UI
└── GenerationView.swift                 # Generation form and results
```

## Learn More

- [DrawThingsKit Documentation](https://github.com/euphoriacyberware-ai/DrawThingsKit)
- [Draw Things App](https://drawthings.ai)
