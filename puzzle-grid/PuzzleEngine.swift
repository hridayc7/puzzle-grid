//
//  PuzzleEngine.swift
//  puzzle-grid
//
//  Created by Antigravity on 5/23/26.
//

import SwiftUI
import Observation

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// The main enum representing the different gameplay and solver modes.
public enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case human = "Human Solver"
    case aStar = "A* Solver"
    case oracle = "Gemini Oracle"
    
    public var id: String { self.rawValue }
}

/// The main state manager and view model for the puzzle game, handling gameplay,
/// solver orchestration, and custom image processing.
@Observable
@MainActor
public final class PuzzleEngine {
    
    // MARK: - Game State
    
    /// Flat array of 9 elements representing the board state (1 to 8 are tiles, 0 is empty).
    public private(set) var board: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 0]
    
    /// Target/Goal board state indicating a win.
    public let goalBoard = [1, 2, 3, 4, 5, 6, 7, 8, 0]
    
    /// Keeps track of the total number of moves made in the current session.
    public var movesCount: Int = 0
    
    /// Selected game mode (Human, A*, Gemini Oracle)
    public var activeMode: GameMode = .human {
        didSet {
            clearSolution()
            pausePlayback()
        }
    }
    
    /// Whether the game is completed/solved.
    public var isSolved: Bool {
        board == goalBoard
    }
    
    // MARK: - Custom Image State
    
    /// The user-provided custom image (if any).
    public var selectedImage: PlatformImage?
    
    /// Slices of the custom image mapped to tile numbers 1...8.
    public var slicedImages: [Int: PlatformImage] = [:]
    
    // MARK: - A* Solver State
    
    /// A flag showing whether the A* solver is currently computing a solution.
    public var isSolving: Bool = false
    
    /// Cached steps returned by the solver.
    public var solutionSteps: [PuzzleSolver.SolutionStep] = []
    
    /// The starting board state when the solver was run (used for playback resets).
    public var startBoard: [Int] = []
    
    /// The index in the solution path (-1 represents the initial scrambled state).
    public var currentStepIndex: Int = -1
    
    /// Whether the playback is currently running.
    public var isPlaying: Bool = false
    
    /// A flag indicating that A* solver finished but could not find a path (should not happen if solvable).
    public var isNoSolutionFound: Bool = false
    
    // MARK: - Gemini Oracle State
    
    /// The reasoning text returned by the Gemini model.
    public var geminiReasoning: String = ""
    
    /// The next move predicted by the Gemini Oracle ("UP", "DOWN", "LEFT", "RIGHT").
    public var geminiNextMove: String = ""
    
    /// Error message from the Gemini Oracle if query failed.
    public var geminiErrorMessage: String? = nil
    
    /// Flag indicating if the Gemini Oracle API call is in progress.
    public var isGeminiLoading: Bool = false
    
    // MARK: - Private Timer Property
    
    @ObservationIgnored
    private var playbackTimer: Task<Void, Never>? = nil
    
    // MARK: - Initializer
    
    public init() {
        // Initialize with a fresh board
    }
    
    // MARK: - Actions
    
    /// Handles user tapping a cell on the board (only allowed in Human Solver mode).
    public func tapTile(at index: Int) {
        guard activeMode == .human else { return }
        makeMove(at: index)
    }
    
    /// Triggers the movement of a tile if it is adjacent to the empty spot.
    public func makeMove(at index: Int) {
        guard let emptyIndex = board.firstIndex(of: 0) else { return }
        if isAdjacent(index, emptyIndex) {
            board.swapAt(index, emptyIndex)
            movesCount += 1
            clearSolution()
        }
    }
    
    /// Returns true if two board positions are adjacent.
    public func isAdjacent(_ index1: Int, _ index2: Int) -> Bool {
        let r1 = index1 / 3
        let c1 = index1 % 3
        let r2 = index2 / 3
        let c2 = index2 % 3
        return (abs(r1 - r2) == 1 && c1 == c2) || (abs(c1 - c2) == 1 && r1 == r2)
    }
    
    /// Scrambles the puzzle board with 80 random valid moves, guaranteeing a solvable state.
    public func scramble() {
        board = goalBoard
        movesCount = 0
        clearSolution()
        pausePlayback()
        
        var currentEmpty = 8
        var previousEmpty = -1
        
        for _ in 0..<80 {
            let r = currentEmpty / 3
            let c = currentEmpty % 3
            var possibleSwaps: [Int] = []
            
            if r > 0 { possibleSwaps.append((r - 1) * 3 + c) }
            if r < 2 { possibleSwaps.append((r + 1) * 3 + c) }
            if c > 0 { possibleSwaps.append(r * 3 + c - 1) }
            if c < 2 { possibleSwaps.append(r * 3 + c + 1) }
            
            let filteredSwaps = possibleSwaps.filter { $0 != previousEmpty }
            let chosenIndex = (filteredSwaps.isEmpty ? possibleSwaps : filteredSwaps).randomElement() ?? currentEmpty
            
            board.swapAt(currentEmpty, chosenIndex)
            previousEmpty = currentEmpty
            currentEmpty = chosenIndex
        }
    }
    
    /// Resets the board back to the goal solved state.
    public func resetToSolved() {
        board = goalBoard
        movesCount = 0
        clearSolution()
        pausePlayback()
    }
    
    // MARK: - A* Solver Playback & Execution
    
    /// Runs the A* solver from the current board state.
    public func runAStarSolver() async {
        guard !isSolved else { return }
        isSolving = true
        isNoSolutionFound = false
        clearSolution()
        pausePlayback()
        
        startBoard = board
        
        // Execute the A* solver asynchronously
        if let steps = await PuzzleSolver.solve(startBoard: startBoard) {
            solutionSteps = steps
            currentStepIndex = -1
        } else {
            isNoSolutionFound = true
        }
        
        isSolving = false
    }
    
    /// Advances one step in the solution path.
    public func nextStep() {
        guard currentStepIndex < solutionSteps.count - 1 else {
            pausePlayback()
            return
        }
        currentStepIndex += 1
        board = solutionSteps[currentStepIndex].board
        movesCount += 1
    }
    
    /// Steps back one step in the solution path.
    public func previousStep() {
        guard currentStepIndex >= 0 else { return }
        currentStepIndex -= 1
        
        if currentStepIndex == -1 {
            board = startBoard
        } else {
            board = solutionSteps[currentStepIndex].board
        }
        movesCount = max(0, movesCount - 1)
    }
    
    /// Toggles automatic playback of solution steps.
    public func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        isPlaying = true
        playbackTimer = Task {
            while isPlaying && currentStepIndex < solutionSteps.count - 1 {
                do {
                    try await Task.sleep(for: .seconds(0.6))
                } catch {
                    break
                }
                guard !Task.isCancelled else { break }
                nextStep()
            }
            isPlaying = false
        }
    }
    
    public func pausePlayback() {
        isPlaying = false
        playbackTimer?.cancel()
        playbackTimer = nil
    }
    
    /// Resets the solver path playback to the start of the solution path.
    public func resetSolverPlayback() {
        pausePlayback()
        currentStepIndex = -1
        board = startBoard
        movesCount = 0
    }
    
    /// Clears any computed solution path.
    public func clearSolution() {
        solutionSteps = []
        currentStepIndex = -1
        startBoard = []
        isNoSolutionFound = false
    }
    
    // MARK: - Gemini Oracle Execution
    
    /// Queries the Gemini API for the next best move and explains the reasoning.
    public func queryGeminiOracle() async {
        guard !isSolved else { return }
        isGeminiLoading = true
        geminiErrorMessage = nil
        
        let apiKey = Config.geminiAPIKey
        
        do {
            let response = try await GeminiSolver.getNextMove(board: board, apiKey: apiKey)
            geminiReasoning = response.reasoning
            geminiNextMove = response.move.uppercased()
        } catch {
            geminiErrorMessage = error.localizedDescription
            geminiReasoning = ""
            geminiNextMove = ""
        }
        
        isGeminiLoading = false
    }
    
    /// Applies the recommended Gemini Oracle move to the board.
    public func applyGeminiMove() {
        guard !geminiNextMove.isEmpty else { return }
        
        if let targetTileIndex = tileIndexForGeminiMove(geminiNextMove) {
            makeMove(at: targetTileIndex)
            geminiNextMove = ""
            geminiReasoning = ""
        }
    }
    
    private func tileIndexForGeminiMove(_ move: String) -> Int? {
        guard let emptyIndex = board.firstIndex(of: 0) else { return nil }
        let r = emptyIndex / 3
        let c = emptyIndex % 3
        
        switch move {
        case "UP":
            return r < 2 ? (r + 1) * 3 + c : nil
        case "DOWN":
            return r > 0 ? (r - 1) * 3 + c : nil
        case "LEFT":
            return c < 2 ? r * 3 + c + 1 : nil
        case "RIGHT":
            return c > 0 ? r * 3 + c - 1 : nil
        default:
            return nil
        }
    }
    
    // MARK: - Custom Image Upload & Slicing
    
    /// Sets a new custom image and processes it into 3x3 slices on a background thread.
    public func setCustomImage(_ image: PlatformImage) async {
        selectedImage = image
        
        // Process and slice image in background thread to keep UI smooth.
        let slices = await Task.detached(priority: .userInitiated) {
            PuzzleEngine.cropAndSliceImage(image, into: 3)
        }.value
        
        var newSliced: [Int: PlatformImage] = [:]
        for i in 0..<slices.count {
            // First 8 slices correspond to tile values 1...8
            if i < 8 {
                newSliced[i + 1] = slices[i]
            }
        }
        
        self.slicedImages = newSliced
        clearSolution()
    }
    
    /// Clears the custom image, reverting tiles to standard text style.
    public func clearCustomImage() {
        selectedImage = nil
        slicedImages = [:]
        clearSolution()
    }
    
    nonisolated private static func cropAndSliceImage(_ image: PlatformImage, into parts: Int) -> [PlatformImage] {
        #if canImport(UIKit)
        // 1. Normalize orientation and crop to a square by rendering to an upright CGContext
        let size = image.size
        let cropSize = min(size.width, size.height)
        
        let xOffset = (size.width - cropSize) / 2
        let yOffset = (size.height - cropSize) / 2
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Normalize scale to 1.0 for simplicity
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize), format: format)
        let normalizedSquareImage = renderer.image { _ in
            image.draw(at: CGPoint(x: -xOffset, y: -yOffset))
        }
        
        guard let normalizedCgImage = normalizedSquareImage.cgImage else { return [] }
        
        let partSize = Int(cropSize) / parts
        var segments: [UIImage] = []
        
        for row in 0..<parts {
            for col in 0..<parts {
                let segmentRect = CGRect(
                    x: CGFloat(col * partSize),
                    y: CGFloat(row * partSize),
                    width: CGFloat(partSize),
                    height: CGFloat(partSize)
                )
                if let segmentCg = normalizedCgImage.cropping(to: segmentRect) {
                    segments.append(UIImage(cgImage: segmentCg))
                }
            }
        }
        
        return segments
        
        #elseif canImport(AppKit)
        // macOS AppKit Implementation
        let size = image.size
        let cropSize = min(size.width, size.height)
        let xOffset = (size.width - cropSize) / 2
        let yOffset = (size.height - cropSize) / 2
        
        let squareImage = NSImage(size: NSSize(width: cropSize, height: cropSize))
        squareImage.lockFocus()
        
        let fromRect = NSRect(x: xOffset, y: yOffset, width: cropSize, height: cropSize)
        image.draw(
            in: NSRect(x: 0, y: 0, width: cropSize, height: cropSize),
            from: fromRect,
            operation: .copy,
            fraction: 1.0
        )
        
        squareImage.unlockFocus()
        
        guard let cgImage = squareImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }
        
        let partSize = Int(cropSize) / parts
        var segments: [NSImage] = []
        
        for row in 0..<parts {
            for col in 0..<parts {
                // In macOS, the coordinate system origin is at the bottom-left!
                // So we need to invert the row coordinate to slice from top to bottom
                let invertedRow = parts - 1 - row
                let segmentRect = CGRect(
                    x: CGFloat(col * partSize),
                    y: CGFloat(invertedRow * partSize),
                    width: CGFloat(partSize),
                    height: CGFloat(partSize)
                )
                
                if let segmentCg = cgImage.cropping(to: segmentRect) {
                    segments.append(NSImage(cgImage: segmentCg, size: NSSize(width: partSize, height: partSize)))
                }
            }
        }
        
        return segments
        #endif
    }
}
