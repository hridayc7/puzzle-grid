//
//  HumanSolverView.swift
//  puzzle-grid
//
//  Created by Antigravity on 5/23/26.
//

import SwiftUI
import PhotosUI

/// Renders the Human Solver tab where the user can manually play the puzzle,
/// scramble, reset, and upload custom images to slide.
public struct HumanSolverView: View {
    
    /// The shared puzzle engine.
    let engine: PuzzleEngine
    
    /// PhotosPicker item binding.
    @State private var selectedItem: PhotosPickerItem? = nil
    
    public init(engine: PuzzleEngine) {
        self.engine = engine
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Stats panel
            HStack {
                Text("Moves: \(engine.movesCount)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
                
                Spacer()
                
                if engine.isSolved {
                    Text("Solved! 🎉")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Puzzle Board
            PuzzleBoardView(engine: engine)
            
            // Core Game Action buttons
            HStack(spacing: 16) {
                Button("Scramble", action: scramblePressed)
                    .buttonStyle(.borderedProminent)
                    .fontWeight(.medium)
                
                Button("Reset Grid", action: resetPressed)
                    .buttonStyle(.bordered)
                    .fontWeight(.medium)
            }
            .padding(.top, 8)
            
            Divider()
                .padding(.horizontal, 24)
            
            // Photo upload integration
            VStack(spacing: 12) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(
                        engine.selectedImage == nil ? "Use Custom Photo" : "Change Photo",
                        systemImage: "photo.badge.plus"
                    )
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 8))
                }
                .onChange(of: selectedItem) { _, newItem in
                    handlePhotoSelection(newItem)
                }
                
                if engine.selectedImage != nil {
                    Button("Remove Photo", role: .destructive, action: removePhotoPressed)
                        .buttonStyle(.borderless)
                        .font(.subheadline)
                }
            }
            
            Spacer()
        }
        .background(Color.white)
    }
    
    // MARK: - Actions
    
    private func scramblePressed() {
        engine.scramble()
    }
    
    private func resetPressed() {
        engine.resetToSolved()
    }
    
    private func removePhotoPressed() {
        engine.clearCustomImage()
        selectedItem = nil
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    #if canImport(UIKit)
                    if let image = UIImage(data: data) {
                        await engine.setCustomImage(image)
                    }
                    #elseif canImport(AppKit)
                    if let image = NSImage(data: data) {
                        await engine.setCustomImage(image)
                    }
                    #endif
                }
            } catch {
                // Fail silently
            }
        }
    }
}

#Preview {
    let engine = PuzzleEngine()
    return HumanSolverView(engine: engine)
}
