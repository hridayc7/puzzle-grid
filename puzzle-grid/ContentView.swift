//
//  ContentView.swift
//  puzzle-grid
//
//  Created by Hriday Chhabria on 5/23/26.
//

import SwiftUI

struct ContentView: View {
    @State private var engine = PuzzleEngine()
    
    var body: some View {
        VStack(spacing: 16) {
            // Native cross-platform Segmented Picker control
            Picker("Game Mode", selection: $engine.activeMode) {
                ForEach(GameMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            Divider()
                .padding(.horizontal, 24)
            
            // Subview Container with a max width limit for elegant presentation on iPad and macOS
            VStack {
                switch engine.activeMode {
                case .human:
                    HumanSolverView(engine: engine)
                case .aStar:
                    AStarSolverView(engine: engine)
                case .oracle:
                    GeminiOracleView(engine: engine)
                }
            }
            .frame(maxWidth: 420) // Centers and constrains layout width on wide screens
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
    }
}

#Preview {
    ContentView()
}
