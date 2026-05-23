//
//  PuzzleSolver.swift
//  puzzle-grid
//
//  Created by Antigravity on 5/23/26.
//

import Foundation

/// A high-performance solver for 3x3 sliding puzzles using the A* pathfinding algorithm.
public struct PuzzleSolver {
    
    /// Represents a single transition step in the solution path.
    public struct SolutionStep: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let board: [Int]
        public let moveDescription: String // "UP", "DOWN", "LEFT", "RIGHT"
        public let tileValue: Int
        
        public init(board: [Int], moveDescription: String, tileValue: Int) {
            self.id = UUID()
            self.board = board
            self.moveDescription = moveDescription
            self.tileValue = tileValue
        }
    }
    
    private struct Node: Comparable {
        let board: [Int]
        let emptyIndex: Int
        let g: Int // Cost from start node
        let h: Int // Manhattan distance heuristic
        let parent: [Int]?
        let lastMoveDescription: String
        let lastTileValue: Int
        
        var f: Int { g + h }
        
        static func < (lhs: Node, rhs: Node) -> Bool {
            lhs.f < rhs.f
        }
    }
    
    private static let goalBoard = [1, 2, 3, 4, 5, 6, 7, 8, 0]
    
    /// Solves the sliding puzzle from the given start board using A* search.
    /// Returns the sequence of steps to reach the goal, or nil if no solution exists.
    public static func solve(startBoard: [Int]) async -> [SolutionStep]? {
        guard isSolvable(startBoard) else { return nil }
        if startBoard == goalBoard { return [] }
        
        var openSet: [Node] = []
        var closedSet: Set<[Int]> = []
        var parentMap: [[Int]: (parent: [Int], move: String, value: Int)] = [:]
        
        let startEmpty = startBoard.firstIndex(of: 0) ?? 8
        let startH = manhattanDistance(startBoard)
        let startNode = Node(
            board: startBoard,
            emptyIndex: startEmpty,
            g: 0,
            h: startH,
            parent: nil,
            lastMoveDescription: "",
            lastTileValue: 0
        )
        
        openSet.append(startNode)
        
        while !openSet.isEmpty {
            let current = openSet.removeFirst()
            
            if current.board == goalBoard {
                return reconstructPath(startBoard: startBoard, currentBoard: current.board, parentMap: parentMap)
            }
            
            closedSet.insert(current.board)
            
            for neighbor in getNeighbors(current) {
                if closedSet.contains(neighbor.board) {
                    continue
                }
                
                if let existingIndex = openSet.firstIndex(where: { $0.board == neighbor.board }) {
                    if neighbor.g < openSet[existingIndex].g {
                        openSet.remove(at: existingIndex)
                        insertSorted(&openSet, neighbor)
                        parentMap[neighbor.board] = (current.board, neighbor.lastMoveDescription, neighbor.lastTileValue)
                    }
                } else {
                    insertSorted(&openSet, neighbor)
                    parentMap[neighbor.board] = (current.board, neighbor.lastMoveDescription, neighbor.lastTileValue)
                }
            }
        }
        
        return nil
    }
    
    private static func insertSorted(_ array: inout [Node], _ node: Node) {
        var low = 0
        var high = array.count
        
        while low < high {
            let mid = (low + high) / 2
            if array[mid].f < node.f {
                low = mid + 1
            } else if array[mid].f == node.f && array[mid].h < node.h {
                low = mid + 1
            } else {
                high = mid
            }
        }
        array.insert(node, at: low)
    }
    
    private static func getNeighbors(_ node: Node) -> [Node] {
        var neighbors: [Node] = []
        let r = node.emptyIndex / 3
        let c = node.emptyIndex % 3
        
        // Directions: (row offset, col offset, movement direction name)
        let moves = [
            (-1, 0, "DOWN"), // Tile above empty space moves DOWN
            (1, 0, "UP"),    // Tile below empty space moves UP
            (0, -1, "RIGHT"),// Tile left of empty space moves RIGHT
            (0, 1, "LEFT")   // Tile right of empty space moves LEFT
        ]
        
        for (dr, dc, dirName) in moves {
            let nr = r + dr
            let nc = c + dc
            
            if nr >= 0 && nr < 3 && nc >= 0 && nc < 3 {
                let neighborEmptyIndex = nr * 3 + nc
                var newBoard = node.board
                let tileValue = newBoard[neighborEmptyIndex]
                newBoard.swapAt(node.emptyIndex, neighborEmptyIndex)
                
                let h = manhattanDistance(newBoard)
                let neighborNode = Node(
                    board: newBoard,
                    emptyIndex: neighborEmptyIndex,
                    g: node.g + 1,
                    h: h,
                    parent: node.board,
                    lastMoveDescription: dirName,
                    lastTileValue: tileValue
                )
                neighbors.append(neighborNode)
            }
        }
        
        return neighbors
    }
    
    private static func manhattanDistance(_ board: [Int]) -> Int {
        var distance = 0
        for i in 0..<9 {
            let value = board[i]
            if value != 0 {
                let targetIndex = value - 1
                let targetRow = targetIndex / 3
                let targetCol = targetIndex % 3
                let currentRow = i / 3
                let currentCol = i % 3
                distance += abs(currentRow - targetRow) + abs(currentCol - targetCol)
            }
        }
        return distance
    }
    
    private static func reconstructPath(
        startBoard: [Int],
        currentBoard: [Int],
        parentMap: [[Int]: (parent: [Int], move: String, value: Int)]
    ) -> [SolutionStep] {
        var steps: [SolutionStep] = []
        var curr = currentBoard
        
        while curr != startBoard {
            guard let info = parentMap[curr] else { break }
            let step = SolutionStep(board: curr, moveDescription: info.move, tileValue: info.value)
            steps.append(step)
            curr = info.parent
        }
        
        return steps.reversed()
    }
    
    /// Checks if a 3x3 board is solvable.
    /// A board is solvable if the number of inversions is even.
    public static func isSolvable(_ board: [Int]) -> Bool {
        var inversions = 0
        let flat = board.filter { $0 != 0 }
        
        for i in 0..<flat.count {
            for j in (i + 1)..<flat.count {
                if flat[i] > flat[j] {
                    inversions += 1
                }
            }
        }
        
        return inversions % 2 == 0
    }
}
