//
//  GeminiSolver.swift
//  puzzle-grid
//
//  Created by Antigravity on 5/23/26.
//

import Foundation

/// Defines error scenarios that can occur when calling the Gemini API.
public enum GeminiError: LocalizedError, Sendable {
    case invalidAPIKey
    case networkError(String)
    case invalidResponse(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            "The Gemini API key is missing or invalid. Please check your Config.swift file."
        case .networkError(let message):
            "Network error occurred: \(message)"
        case .invalidResponse(let reason):
            "Unable to parse the Gemini Oracle's solution: \(reason)"
        }
    }
}

/// Structured response returned by the Gemini Oracle solver.
public struct GeminiOracleResponse: Decodable, Sendable {
    public let reasoning: String
    public let move: String // "UP", "DOWN", "LEFT", "RIGHT"
    
    public init(reasoning: String, move: String) {
        self.reasoning = reasoning
        self.move = move
    }
}

/// Client that communicates with the Google Gemini API to retrieve hints/next moves.
public struct GeminiSolver {
    
    /// Queries the Gemini API for the next best move based on the current board configuration.
    public static func getNextMove(board: [Int], apiKey: String) async throws -> GeminiOracleResponse {
        guard !apiKey.isEmpty && apiKey != "YOUR_API_KEY_HERE" else {
            throw GeminiError.invalidAPIKey
        }
        
        let model = Config.geminiModel
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidResponse("Invalid service URL.")
        }
        
        let boardString = board.map { String($0) }.joined(separator: ", ")
        let emptyIndex = board.firstIndex(of: 0) ?? 8
        let r = emptyIndex / 3
        let c = emptyIndex % 3
        
        var availableMoves: [String] = []
        if r > 0 {
            let neighborVal = board[(r - 1) * 3 + c]
            availableMoves.append("DOWN (slides tile \(neighborVal) above empty space DOWN)")
        }
        if r < 2 {
            let neighborVal = board[(r + 1) * 3 + c]
            availableMoves.append("UP (slides tile \(neighborVal) below empty space UP)")
        }
        if c > 0 {
            let neighborVal = board[r * 3 + c - 1]
            availableMoves.append("RIGHT (slides tile \(neighborVal) left of empty space RIGHT)")
        }
        if c < 2 {
            let neighborVal = board[r * 3 + c + 1]
            availableMoves.append("LEFT (slides tile \(neighborVal) right of empty space LEFT)")
        }
        
        let movesDescription = availableMoves.joined(separator: "\n- ")
        
        let prompt = """
        You are a sliding puzzle solver. The grid is 3x3, represented by a flat 1D array of 9 elements.
        The goal is [1, 2, 3, 4, 5, 6, 7, 8, 0], where 0 represents the empty space.
        
        Current board: [\(boardString)]
        Empty space (0) is at Row \(r), Col \(c) (0-indexed).
        
        The adjacent tiles that can slide into the empty space are:
        - \(movesDescription)
        
        Determine the single best next move to reach the goal state.
        
        Output a JSON object with:
        - "reasoning": explanation of the move selection.
        - "move": which direction the tile slides. It must be exactly one of: "UP", "DOWN", "LEFT", "RIGHT".
        """
        
        // Form JSON request body for structured JSON response schema
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": [
                    "type": "OBJECT",
                    "properties": [
                        "reasoning": [
                            "type": "STRING",
                            "description": "Short explanation of the board state and why the next move is chosen."
                        ],
                        "move": [
                            "type": "STRING",
                            "enum": ["UP", "DOWN", "LEFT", "RIGHT"],
                            "description": "The tile movement direction into the empty space."
                        ]
                    ],
                    "required": ["reasoning", "move"]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw GeminiError.invalidResponse("Failed to serialize request payload.")
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiError.networkError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError("Invalid response type.")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP status \(httpResponse.statusCode)"
            throw GeminiError.invalidResponse("Server error details: \(errorMsg)")
        }
        
        struct GeminiAPIResponse: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable {
                        let text: String
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
            guard let rawJSONText = apiResponse.candidates.first?.content.parts.first?.text else {
                throw GeminiError.invalidResponse("Empty model response parts.")
            }
            
            guard let rawJSONData = rawJSONText.data(using: .utf8) else {
                throw GeminiError.invalidResponse("Unable to convert response output to JSON format.")
            }
            
            let result = try JSONDecoder().decode(GeminiOracleResponse.self, from: rawJSONData)
            return result
        } catch {
            throw GeminiError.invalidResponse(error.localizedDescription)
        }
    }
}
