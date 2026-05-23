//
//  GeminiOracleView.swift
//  puzzle-grid
//
//  Created by Antigravity on 5/23/26.
//

import SwiftUI

/// Renders the Gemini Oracle tab, showcasing reasoning and recommendation results from Gemini API.
public struct GeminiOracleView: View {
    
    /// The shared puzzle engine.
    let engine: PuzzleEngine
    
    public init(engine: PuzzleEngine) {
        self.engine = engine
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header status
                VStack(spacing: 4) {
                    if engine.isSolved {
                        Text("Grid is Solved! 🎉")
                            .font(.headline)
                            .foregroundStyle(.green)
                    } else if !engine.geminiNextMove.isEmpty {
                        Text("Suggested Move: \(engine.geminiNextMove)")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    } else {
                        Text("Gemini AI Assistant")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)
                
                // Puzzle Board
                PuzzleBoardView(engine: engine)
                
                // API Config Warnings
                if Config.geminiAPIKey == "YOUR_API_KEY_HERE" || Config.geminiAPIKey.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Gemini API Key Required", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                        
                        Text("Please set your API key in Config.swift to query the Gemini Oracle solver.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                
                // Action Buttons
                if engine.isGeminiLoading {
                    ProgressView("Consulting Gemini Oracle...")
                        .padding()
                } else if !engine.geminiNextMove.isEmpty {
                    VStack(spacing: 12) {
                        Button("Apply Move", action: applyMovePressed)
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        
                        Button("Clear Suggestion", action: clearPressed)
                            .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                } else {
                    Button("Ask Gemini Oracle", action: askOraclePressed)
                        .buttonStyle(.borderedProminent)
                        .disabled(engine.isSolved || Config.geminiAPIKey == "YOUR_API_KEY_HERE" || Config.geminiAPIKey.isEmpty)
                        .padding(.top, 8)
                }
                
                // Gemini Oracle Reasoning Output
                if !engine.geminiReasoning.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gemini's Reasoning:")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text(engine.geminiReasoning)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Error Alert Box
                if let errorMsg = engine.geminiErrorMessage {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Oracle Query Failed", systemImage: "xmark.octagon.fill")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                        
                        Text(errorMsg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }
                
                Spacer()
            }
        }
        .background(Color.white)
        .scrollContentBackground(.visible)
    }
    
    // MARK: - Actions
    
    private func askOraclePressed() {
        Task {
            await engine.queryGeminiOracle()
        }
    }
    
    private func applyMovePressed() {
        engine.applyGeminiMove()
    }
    
    private func clearPressed() {
        engine.geminiNextMove = ""
        engine.geminiReasoning = ""
        engine.geminiErrorMessage = nil
    }
}

#Preview {
    let engine = PuzzleEngine()
    return GeminiOracleView(engine: engine)
}
