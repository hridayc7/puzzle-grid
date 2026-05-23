//
//  PuzzleBoardView.swift
//  puzzle-grid
//
//  Created by Antigravity on 5/23/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A tactile 3x3 sliding puzzle board view that renders tiles either with numbers
/// or sliced custom image segments. It uses absolute positioning for a smooth sliding effect.
public struct PuzzleBoardView: View {
    
    /// The shared puzzle engine managing the game state.
    let engine: PuzzleEngine
    
    private let tileSize: CGFloat = 96
    private let spacing: CGFloat = 8
    
    public init(engine: PuzzleEngine) {
        self.engine = engine
    }
    
    public var body: some View {
        ZStack {
            // Background Grid Slots (to visually indicate the grid spaces)
            ForEach(0..<9, id: \.self) { index in
                let r = index / 3
                let c = index % 3
                let x = CGFloat(c) * (tileSize + spacing) + tileSize / 2
                let y = CGFloat(r) * (tileSize + spacing) + tileSize / 2
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: tileSize, height: tileSize)
                    .position(x: x, y: y)
            }
            
            // Movable Tiles (values 1 to 8)
            ForEach(1...8, id: \.self) { val in
                if let currentPos = engine.board.firstIndex(of: val) {
                    let r = currentPos / 3
                    let c = currentPos % 3
                    let x = CGFloat(c) * (tileSize + spacing) + tileSize / 2
                    let y = CGFloat(r) * (tileSize + spacing) + tileSize / 2
                    
                    Button {
                        tileTapped(at: currentPos)
                    } label: {
                        tileContent(for: val)
                    }
                    .buttonStyle(.plain)
                    .frame(width: tileSize, height: tileSize)
                    .position(x: x, y: y)
                    // Animates the tile sliding into the empty space
                    .animation(.bouncy(duration: 0.25), value: currentPos)
                    .accessibilityLabel("Tile \(val)")
                    .accessibilityHint("Tap to slide if adjacent to the empty slot")
                }
            }
        }
        .frame(
            width: 3 * tileSize + 2 * spacing,
            height: 3 * tileSize + 2 * spacing
        )
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func tileContent(for value: Int) -> some View {
        if let imageSegment = engine.slicedImages[value] {
            // Render custom image segment (handling iOS/macOS platform images)
            #if canImport(UIKit)
            Image(uiImage: imageSegment)
                .resizable()
                .scaledToFill()
                .frame(width: tileSize, height: tileSize)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
            #elseif canImport(AppKit)
            Image(nsImage: imageSegment)
                .resizable()
                .scaledToFill()
                .frame(width: tileSize, height: tileSize)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
            #endif
        } else {
            // Render default numbered tile
            let isCorrect = engine.board.firstIndex(of: value) == (value - 1)
            
            Text("\(value)")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(isCorrect ? .white : .primary)
                .frame(width: tileSize, height: tileSize)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCorrect ? Color.green : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCorrect ? Color.green : Color.gray.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Actions
    
    private func tileTapped(at position: Int) {
        engine.tapTile(at: position)
    }
}

#Preview {
    let engine = PuzzleEngine()
    return PuzzleBoardView(engine: engine)
        .padding()
}
