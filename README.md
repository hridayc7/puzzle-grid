# 3x3 Sliding Puzzle (SwiftUI & Gemini Experiment)

A tactile 3x3 sliding puzzle game built in **SwiftUI** for iOS and macOS. This project is a Neuro-Symbolic experiment comparing deterministic heuristic solvers against Large Language Models (LLMs) for spatial grid reasoning.

---

## Features

-   🎮 **Interactive Gameplay**: Tap adjacent tiles to slide them into the empty slot with smooth, hardware-accelerated animations.
-   📸 **Custom Photo Upload**: Select any image from the Photos library using `PhotosPicker`. It is automatically cropped to a centered square and sliced into a 3x3 grid in a background thread while preserving correct rotation/orientations.
-   ⚡ **A\* Pathfinder**: Instantly calculates and animates the mathematically optimal path to the solved state using a Manhattan distance heuristic.
-   🔮 **Gemini Oracle Solver**: Queries Google's Gemini API (e.g. `gemini-3.5-flash`) via structured JSON schema POST calls to retrieve the next move recommendation and natural language reasoning.
-   🖥️ **Multiplatform Ready**: Fully compatible with iOS, iPadOS, and native macOS window targets. Incorporates width-constraining wrappers for responsive layouts.

---

## File Structure

```text
puzzle-grid/
├── Config.swift                      # API key configuration and model settings
├── PuzzleEngine.swift                # State manager ViewModel coordinating moves & image slicing
├── PuzzleSolver.swift                # A* pathfinder logic and solvability checker
├── GeminiSolver.swift                # Client wrapping the Google Gemini API POST fetch
├── Views/
│   ├── PuzzleBoardView.swift         # Dynamic 3x3 grid using absolute positions
│   ├── SolverControlView.swift       # Playback controls (Play, Pause, Step, Reset)
│   ├── HumanSolverView.swift         # View for manual play and photo imports
│   ├── AStarSolverView.swift         # View for running the optimal A* search
│   └── GeminiOracleView.swift        # View for model reasoning and recommendations
├── ContentView.swift                 # App root with custom Segmented Picker navigation
├── experiment_results.md             # Quantitative comparison between A* and Gemini
└── future_exploration.md             # Proposal for vision-to-state mapping + A* solvers
```

---

## Setup Instructions

### 1. Requirements
-   Xcode 17.0+
-   iOS 17.0+ / macOS 14.0+

### 2. Add Gemini API Key
To use the **Gemini Oracle** tab, you need to provide your Google AI Studio API key. Open `Config.swift` and replace the placeholder value:

```swift
public struct Config {
    public static let geminiAPIKey: String = "YOUR_API_KEY_HERE"
    public static let geminiModel: String = "gemini-3.5-flash"
}
```

### 3. Open and Run
Open `puzzle-grid.xcodeproj` in Xcode, select your target device (e.g., iPhone Simulator, iPad, or My Mac), and run (⌘R).

*To run natively on Mac*: Select the `puzzle-grid` target -> General -> Under **Supported Destinations**, click the **+** icon and choose **macOS**. Select **My Mac** in the scheme menu and run.

---

## Research & Documentation

This project serves as a testbed for LLM spatial reasoning benchmarks. You can read the detailed research notes directly in this repository:
-   📊 **[Experiment Results](experiment_results.md)**: Comparing latency, optimality, and reliability between A* and LLMs.
-   🧠 **[Future Exploration (Neuro-Symbolic)](future_exploration.md)**: A proposal for using LLM Vision to detect board states and A* to solve them.
