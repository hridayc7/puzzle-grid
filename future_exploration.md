# Future Exploration: Neuro-Symbolic 3x3 Sliding Puzzle Solver

This document outlines the proposal for a **Neuro-Symbolic** approach to solving sliding puzzles with custom images. It details the architecture, experimental setup, and benchmarking metrics.

---

## 1. The Neuro-Symbolic Concept

Instead of relying on the LLM to plan the sequence of moves (where it performs poorly), or hardcoding the image-to-state mapping in the app, we split the responsibilities:

1.  **The Neural Component (Gemini)**: Translates the visual scrambled board into a numeric array state.
2.  **The Symbolic Component (A\*)**: Takes the array state and solves it mathematically.

```
+-----------------------------+
| Original Image              |
| + Scrambled Screenshot      |
+--------------+--------------+
               |
               v (Multi-modal Vision API)
+--------------+--------------+
| Gemini state reconstruction | --> [3, 1, 2, 8, 0, 5, 4, 7, 6]
+--------------+--------------+
               |
               v (Deterministic State Array)
+--------------+--------------+
| Local A* Solver              | --> Optimal Move Path
+-----------------------------+
```

---

## 2. Experimental Pipeline

To implement this experiment:

1.  **Image Upload & Scrambling**:
    - The user uploads an image, and the app scrambles the tiles.
    - Unlike our current setup, the app does *not* track which tile is which numerically. It only knows the visual layout.
2.  **Screenshot Generation**:
    - The app uses SwiftUI's `ImageRenderer` to capture a screenshot of the scrambled board.
3.  **Oracle Multi-modal Query**:
    - Send the original image and the scrambled screenshot to the Gemini API.
    - Prompt the model to match the visual segments in the screenshot back to their original coordinates, returning a reconstructed 1D array state (e.g. `[1, 2, 3, 0, 5, 6, 4, 7, 8]`).
4.  **Optimal Pathfinding**:
    - Feed the array state into the on-device A* pathfinder.

---

## 3. Benchmarking Metrics

We can benchmark different visual models (e.g., `gemini-3.5-flash`, `gemini-3.1-pro`, `gemini-2.5-pro`) against the following metrics:

-   **State Reconstruction Accuracy**: The percentage of times the model correctly identifies the numeric position of all 9 tiles.
-   **Distance Error (Hamming Distance)**: For incorrect states, how many tiles did the model misidentify? (e.g. swapping tiles 4 and 5 results in a Hamming distance of 2).
-   **Solvability Parity**: How often does the model reconstruct a mathematically possible state? (3x3 sliding puzzles require an even number of inversions to be solvable. An invalid reconstruction can result in an unsolvable board).
-   **Texture Sensitivity**: How does the model's accuracy change when switching between:
    -   *High-Feature Images*: Text grids, faces, geometric patterns.
    -   *Low-Feature Images*: Repetitive flower patterns, gradients, skies.
