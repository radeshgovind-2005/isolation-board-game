# ISOLA Game - Artificial Intelligence Project

This project consists of the implementation of the **Isola** strategy game as part of the **Inteligência Artificial** (Artificial Intelligence) course at **ISEL** (Instituto Superior de Engenharia de Lisboa).

## 📋 Project Overview
* **Course:** Inteligência Artificial.
* **Semester:** Summer Semester 2025/2026.
* **Department:** Departamento de Engenharia Informática.
* **Professor:** Nuno Leite.

## 🎮 The Game: Isola
Isola is a two-player strategy game (also known as Isolation) where the objective is to block the opponent's pawn by moving like a chess queen and removing tiles from the board.

### Game Rules
* **Objective:** Isolate the opponent so they have no valid moves in any direction (horizontal, vertical, or diagonal).
* **Turn Phases:** Every turn must include two mandatory steps:
    1.  **Move:** Move your pawn to an adjacent free square.
    2.  **Remove:** Choose and remove any square on the board that is not occupied by a pawn.
* **Constraints:** Players cannot jump over an opponent or move into squares that have already been removed.

## 🤖 Artificial Intelligence Implementation
The project includes an AI player developed using the following logic:
* **Algorithm:** Alpha-beta pruning, which is an efficient implementation of the Minimax principle.
* **Depth Control:** For larger boards, the AI utilizes a depth-limited search (recommended depth of 4) to maintain performance.
* **Model:** The game board is represented and manipulated using Prolog lists.

## 🛠️ Requirements & Usage
* **Language:** Prolog.
* **I/O:** The program uses standard `read(N)` and `write(N)` predicates for interaction.
* **Testing:** It is recommended to test first with 3x3 boards before moving to larger dimensions.

## 📝 Delivery Details
* **Deadline:** April 13, 2026, 23:59.
* **Deliverables:** Technical report and Prolog source code.
* **Criteria:** All AI-based code sections must be clearly marked and justified in the report.

## 👥 Group Members
* [No. 51620 - Radesh Govind]
* [No. 51619 - Martim Monteiro]
