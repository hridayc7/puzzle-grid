# Sliding Puzzle Solver Project Report: A* vs. Gemini Oracle

This report summarizes our findings from developing and testing a 3x3 sliding puzzle game in SwiftUI for iOS, focusing on the comparison between a traditional heuristic pathfinder (A*) and a Large Language Model solver (Gemini Oracle).

---

## Executive Summary

The project successfully built a fully interactive 3x3 sliding puzzle game in SwiftUI. The architecture supports:
1. **Manual Gameplay (Human)**: Playable tile-based tactile sliding moves.
2. **Custom Photo Slicing**: Slices any user-uploaded photo into a 3x3 grid with correct orientation handling and centering.
3. **A\* Pathfinder Solver**: Instantly computes and animates the mathematically optimal path.
4. **Gemini Oracle Solver**: Queries the Gemini API to get the next recommended move alongside natural language reasoning.

While the Gemini integration was a successful experiment, testing showed that the traditional A* algorithm is significantly superior for low-level slide-by-slide pathfinding.

---

## Technical Comparison

| Feature | A* Solver (Traditional Heuristic) | Gemini Oracle (LLM / API-Driven) |
| :--- | :--- | :--- |
| **Latency & Speed** | **Instantaneous** (usually < 1ms to compute the entire 31-move maximum path). | **Slow** (1.5s to 3.0s per single move query due to network round-trip and text generation). |
| **Path Optimality** | **Guaranteed Optimal** (always finds the mathematical shortest path using Manhattan Distance). | **Heuristic/Variable** (can select sub-optimal moves; prone to repeating cycles without state history). |
| **Offline Capability**| Yes (runs entirely on-device, zero network required). | No (requires active internet access and API key configuration). |
| **Cost** | **Free** (utilizes local CPU cycles). | **Variable** (depends on API billing tier, input/output tokens). |
| **Code Complexity** | Low-Medium (requires a hashable state graph search and priority queue). | Medium (requires HTTP request management, token parsing, and JSON schema formatting). |
| **User Experience** | High-tactility (user can play/pause or step through the entire path instantly). | Interactive (provides interesting natural language reasoning behind each decision). |

---

## Why A* Outperforms LLMs in Graph Search

Sliding puzzles are a classic class of graph search problems where the state space of reachable configurations (181,440 states) is structured and well-defined.

1. **Deterministic Logic vs. Autoregressive Sampling**: 
   A* explores the state graph systematically, maintaining an open set of states and checking exact costs ($f(n) = g(n) + h(n)$). LLMs generate outputs token-by-token using probabilistic patterns. They cannot "backtrack" or evaluate multiple look-ahead states in memory before outputting a token.
2. **Spatial Representation Constraints**: 
   An LLM reads the board as a text-based 1D array (e.g., `[1, 2, 3, 0, 5, 6, 4, 7, 8]`). While it can parse adjacent indices, it has no native spatial hardware to visualize the 2D transformations that occur when moving a tile, which often leads to invalid or cyclic path recommendations.
3. **The Latency Bottleneck**: 
   Even if an LLM is prompted to output the entire solution path at once (which degrades accuracy significantly), generating 20+ steps of structured JSON reasoning takes a long time. In contrast, A* runs a pre-compiled search loop directly in native CPU machine code.

---

## Future Improvements for LLM Solvers

If you want to continue experimenting with LLMs for grid games in the future, we recommend:
* **Hybrid Search (MCTS + LLM)**: Use the LLM only to evaluate the "vibe" or "heuristics" of a few candidate board states (acting as a value network), while using a traditional tree search (like Monte Carlo Tree Search) to select and trace the path.
* **Vector-Mapped Solutions**: Pass the entire solved state history as part of the system instructions so the model knows which paths it has already attempted, avoiding infinite loops.
* **Vibe Commentary**: Instead of having Gemini compute the moves, use A* to calculate the path and let Gemini serve as a "live commentator" or "coach" who explains the strategy behind the A* moves in a fun, friendly voice.
