# Architecture Blueprint: SlideEval Platform
### A Multi-Model Visual Spatial Reasoning Benchmark for LLMs

This document outlines the architectural blueprint for a web-based evaluation platform (**SlideEval**). Users can upload custom images, scramble them, and benchmark different visual LLMs (including closed APIs like Gemini/Claude/OpenAI and open-weights models like Gemma 4) on their ability to visually reconstruct the scrambled board state for a local A* pathfinder.

---

## 1. System Architecture Overview

To minimize server costs, ensure API key security, and offer a frictionless user experience, the best architecture is a **Static Single Page Application (SPA)** written in **Next.js (React)** or **Vite (Vue)**.

```text
                  +----------------------------------------------+
                  |               Web Browser (Client)           |
                  |                                              |
                  |  +--------------------+  +----------------+  |
                  |  |  Interactive UI    |  |  A* Solver     |  |
                  |  |  (React/Canvas)    |  |  (TypeScript)  |  |
                  |  +---------+----------+  +--------^-------+  |
                  |            |                      |          |
                  |            v                      |          |
                  |  +--------------------------------+-------+  |
                  |  |         Eval Orchestrator              |  |
                  |  +---------+--------------------+---------+  |
                  |            |                    |            |
                  +------------|--------------------|------------+
                               |                    |
          (REST API Calls /    |                    | (Localhost CORS /
           User Key Auth)      |                    |  vLLM / Ollama)
                               v                    v
                  +------------+-----------+  +-----+----------+
                  |  Closed APIs           |  |  Local Models  |
                  |  (Gemini, Claude, GPT) |  |  (Gemma 4 via  |
                  |                        |  |   Ollama port) |
                  +------------------------+  +----------------+
```

### Key Architectural Decisions:
1. **Client-Side REST Calls**: Users enter their own API keys (stored securely in `localStorage`). The browser communicates directly with Google AI Studio, Anthropic, or OpenAI endpoints. The keys never touch a backend server, maximizing developer trust.
2. **Localhost Endpoint Integration**: To test open-weights models like **Gemma 4**, the web client can make local CORS fetch requests to `http://localhost:11434` (Ollama's default port) or `http://localhost:8000` (vLLM's default port).
3. **On-Device Solver**: The 3x3 A* pathfinder is compiled to pure JavaScript/TypeScript and runs instantly in the browser.

---

## 2. Technical Stack

* **Frontend Framework**: **Next.js** (App Router) + **TailwindCSS** for a premium glassmorphic/dark-mode theme.
* **Canvas Rendering**: HTML5 Canvas or CSS Grid transitions to render and capture the puzzle states.
* **State Capture**: HTML5 Canvas `.toDataURL("image/jpeg")` to convert the scrambled board directly to base64 JPEG bytes to send to the Vision APIs.
* **Database (Optional)**: **Supabase** (PostgreSQL) if you want to store anonymous benchmark runs to build a global **"Model Leaderboard"**. If not, all data remains in-memory/local-storage for the user.

---

## 3. The Evaluation Pipeline (Step-by-Step)

```text
[ Scrambled Canvas ] ---> [ HTML5 Canvas Capture ] ---> [ Base64 JPEG Data ]
                                                                 |
                                                                 v
[ Original Image ]   ---> [ Resized JPEG Bytes ]  ---> [ Base64 JPEG Data ]
                                                                 |
                                                                 v
                                                      [ LLM Vision Request ]
                                                                 |
                                                                 v (JSON schema)
                                                      [ State Array Output ]
                                                      e.g., [1,3,2,0,5,6,7,8,4]
                                                                 |
                                                                 v
                                                      [ True State Comparison ]
                                                                 |
                                                                 v
                                                      [ A* Solver Execution ]
```

1. **Upload & Crop**: User uploads an image, and the frontend crops it into a square.
2. **Scramble**: The app generates a random, solvable state array (e.g. `[1, 3, 2, 0, 5, 6, 7, 8, 4]`) and renders the visual tile grid.
3. **Capture**: The app captures the scrambled canvas as `scrambled.jpg` and stores the original cropped image as `original.jpg`.
4. **API Request**: The orchestrator wraps both images in a multi-modal request. The model is asked to return a strict JSON object:
   ```json
   {
     "reasoning": "A short spatial analysis of the grid alignment.",
     "state": [1, 3, 2, 0, 5, 6, 7, 8, 4]
   }
   ```
5. **A\* Integration**: The app compares the LLM's returned array to the true state array. If they match (or have a minor distance), we feed the LLM's array to the JavaScript A* solver to verify if the path is logically sound.

---

## 4. Serving Gemma 4

Since Gemma 4 is an open-weights model, it needs to be served. Here is how your platform will integrate it:

### Option A: Local Serving via Ollama (No Cloud Costs)
You instruct the user to run Gemma 4 locally using **Ollama**:
1. Run `ollama run gemma4` in terminal.
2. Enable CORS by setting the environment variable in the terminal:
   ```bash
   export OLLAMA_ORIGINS="*"
   ollama serve
   ```
3. Your SlideEval frontend will send requests directly to:
   `POST http://localhost:11434/api/chat`
   Using the OpenAI-compatible chat format containing base64 images.

### Option B: Cloud Provider APIs (Convenient)
Allow users to enter a Together AI, Groq, or Hugging Face API key, and hit their endpoints:
* **Together AI**: Supports open models with standard OpenAI-compatible formats on `https://api.together.xyz/v1/chat/completions`.
* **Groq**: Provides low-latency serving of open models like Gemma.

---

## 5. The Eval Leaderboard Metrics

To make this a genuine benchmark platform, you should calculate and display these metrics in a beautiful dashboard:

1. **Visual Reconstruction Accuracy**:
   $$\text{Accuracy} = \frac{\text{Perfect Matches}}{\text{Total Runs}} \times 100$$
2. **Normalized Hamming Distance**:
   Measures how close the model's guess was to the true state. For two arrays $A$ and $B$, the number of positions $i$ where $A[i] \neq B[i]$. (A score of 2 is close, a score of 9 is completely lost).
3. **Solvability Parity (Logical Check)**:
   Did the model output a state that is mathematically solvable (even number of inversions)? Or did it break puzzle physics?
4. **Latency (Seconds)**:
   How long did the vision network take to output the state?
5. **Texture Complexity Index**:
   Separate scores based on image type:
   - *High-Feature (Text/Faces)*
   - *Low-Feature (Grass/Sky)*
