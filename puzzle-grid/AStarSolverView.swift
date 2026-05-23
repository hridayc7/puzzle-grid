//
//  AStarSolverView.swift
//  puzzle-grid
//
//  Created by Antigravity on 5/23/26.
//

import SwiftUI

/// Renders the A* Pathfinder tab where the user can execute A* search to solve the board
/// and watch the solution step-by-step or auto-play.
public struct AStarSolverView: View {
    
    /// The shared puzzle engine.
    let engine: PuzzleEngine
    
    public init(engine: PuzzleEngine) {
        self.engine = engine
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Path stats or status
            VStack(spacing: 4) {
                if engine.isSolving {
                    Text("Calculating optimal path...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } else if engine.isSolved {
                    Text("Grid is Solved! 🎉")
                        .font(.headline)
                        .foregroundStyle(.green)
                                } else if !engine.solutionSteps.isEmpty {
                    let moveText = currentMoveDescription()
                    Text(moveText)
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.opacity)
                } else {
                    Text("Optimal Solver")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
            
            // Puzzle Board
            PuzzleBoardView(engine: engine)
            
            // Solver Controls
            if engine.isSolving {
                ProgressView()
                    .padding()
            } else if engine.solutionSteps.isEmpty {
                Button("Solve with A*", action: solvePressed)
                    .buttonStyle(.borderedProminent)
                    .disabled(engine.isSolved)
                    .padding()
            } else {
                VStack(spacing: 16) {
                    SolverControlView(engine: engine)
                    
                    Button("Clear Solution", action: clearPressed)
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
            }
            
            Spacer()
        }
        .background(Color.white)
    }
    
    // MARK: - Helper Methods
    
    private func currentMoveDescription() -> String {
        let stepIndex = engine.currentStepIndex
        if stepIndex == -1 {
            return "Start state (solvable in \(engine.solutionSteps.count) steps)"
        }
        guard stepIndex < engine.solutionSteps.count else { return "" }
        let step = engine.solutionSteps[stepIndex]
        return "Tile \(step.tileValue) slides \(step.moveDescription)"
    }
    
    // MARK: - Actions
    
    private func solvePressed() {
        Task {
            await engine.runAStarSolver()
        }
    }
    
    private func clearPressed() {
        engine.clearSolution()
    }
}

#Preview {
    let engine = PuzzleEngine()
    return AStarSolverView(engine: engine)
}
