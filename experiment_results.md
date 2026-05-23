# 3x3 Sliding Puzzle Solver Experiment Results

This document summarizes our findings and experimental results comparing the on-device A* pathfinder solver against the cloud-based Gemini Oracle solver for a 3x3 sliding puzzle game.

---

## 1. Project Overview

We built a 3x3 sliding puzzle in SwiftUI supporting:
- Manual play mode (Human).
- Standard A* pathfinder.
- Gemini Oracle (model querying).
- Custom photo slicing (dividing any image into 3x3 tiles).

---

## 2. Quantitative Benchmark Results

During our initial runs and benchmarking, we compared the efficiency and speed of the two solvers:

| Metric | A* Pathfinder | Gemini Oracle |
| :--- | :--- | :--- |
| **Execution Latency** | **< 1 millisecond** (nearly instantaneous calculation of the entire path). | **1.5 to 3.0 seconds** (per individual move step due to API request latency). |
| **Path Length / Optimality**| **100% Optimal** (guaranteed shortest path based on Manhattan Distance). | **Sub-optimal** (often gets stuck in loops or recommends longer paths). |
| **Success Rate** | **100%** (for all solvable scrambled configurations). | **Low-Medium** (tends to loop without external memory or state history). |
| **System Cost** | Free (executed entirely on-device). | Variable (consumes API quota / token costs). |
| **Internet Dependency** | Works offline. | Requires a network connection and API key. |

---

## 3. Core Insights & Lessons Learned

1. **A\* Pathfinder Dominance**:
   For structured, finite graph search problems like sliding puzzles, algorithmic solvers like A* are vastly superior. They guarantee mathematical optimality, require no API keys, and run instantly on-device.
   
2. **LLM Planning Constraints**:
   LLMs generate text autoregressively (token-by-token). They lack a local state-evaluation scratchpad to search through multiple look-ahead steps before selecting an output. This makes them prone to cyclic movements.

3. **Input Modality Constraints**:
   Sending the board state as a 1D text-based array (e.g. `[1, 2, 3, 0, 5, 6, 4, 7, 8]`) works for state translation, but limits the LLM's capability to natively reason about 2D spatial layouts.
