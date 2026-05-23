//
//  SolverControlView.swift
//  puzzle-grid
//
//  Created by Antigravity on 5/23/26.
//

import SwiftUI

/// A clean, modern playback control bar for navigating the solver's path step-by-step or automatically.
public struct SolverControlView: View {
    
    /// The shared puzzle engine managing the solver states.
    let engine: PuzzleEngine
    
    public init(engine: PuzzleEngine) {
        self.engine = engine
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Step counter text
            if !engine.solutionSteps.isEmpty {
                let current = engine.currentStepIndex + 1
                let total = engine.solutionSteps.count
                
                Text("Step \(current) of \(total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            } else {
                Text("No active path")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Playback controls
            HStack(spacing: 24) {
                // Reset Button
                Button(action: resetPressed) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .disabled(engine.solutionSteps.isEmpty || engine.currentStepIndex == -1)
                
                // Previous Step Button
                Button(action: prevPressed) {
                    Label("Previous", systemImage: "backward.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .disabled(engine.solutionSteps.isEmpty || engine.currentStepIndex == -1)
                
                // Play/Pause Button
                Button(action: playPausePressed) {
                    Label(
                        engine.isPlaying ? "Pause" : "Play",
                        systemImage: engine.isPlaying ? "pause.fill" : "play.fill"
                    )
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(.circle)
                }
                .disabled(engine.solutionSteps.isEmpty || engine.currentStepIndex == engine.solutionSteps.count - 1)
                
                // Next Step Button
                Button(action: nextPressed) {
                    Label("Next", systemImage: "forward.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .disabled(engine.solutionSteps.isEmpty || engine.currentStepIndex == engine.solutionSteps.count - 1)
            }
            .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Solver Playback Controls")
    }
    
    // MARK: - Actions
    
    private func resetPressed() {
        engine.resetSolverPlayback()
    }
    
    private func prevPressed() {
        engine.previousStep()
    }
    
    private func playPausePressed() {
        engine.togglePlayback()
    }
    
    private func nextPressed() {
        engine.nextStep()
    }
}

#Preview {
    let engine = PuzzleEngine()
    return SolverControlView(engine: engine)
        .padding()
}
