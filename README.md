# AlgoVision

Interactive algorithm learning and visualization app built with **SwiftUI**.  
Designed to help students and developers understand algorithm behavior through **visual patterns, step-by-step execution, and interactive exploration**.

The project focuses on making complex algorithmic concepts intuitive through clean UI, animations, and structured explanations.

---

## Overview

AlgoVision is a SwiftUI-based learning tool that combines **algorithm theory with visual simulation**.  
Instead of reading static pseudocode, users can observe how algorithms operate internally.

Core goals:

- Visual understanding of algorithm patterns
- Interactive exploration of algorithm behavior
- Clean, minimal UI focused on learning
- Educational tool for computer science students

---

## Features

### Algorithm Visualization
- Real-time visual representation of algorithm execution
- Step-by-step progression
- Pattern and structure visualization

### Learning Module
- Concept explanations
- Algorithm breakdowns
- Logical flow understanding

### Interactive Interface
- SwiftUI based responsive UI
- Structured navigation between learning and visualization
- Lightweight and optimized design

---

## Screenshots

<p align="center">
  <img src="images/home.png" width="30%" />
  <img src="images/visualization.png" width="30%" />
  <img src="images/learn.png" width="30%" />
</p>

---

## Project Structure
```
AlgoVision
│
├── AlgoVision.swiftpm
│   ├── Package.swift
│   ├── VisionAlgoApp.swift
│   ├── HomeView.swift
│   ├── AlgoPattern.swift
│   └── Views
│       ├── InteractiveBFSView.swift
│       ├── InteractiveBinarySearchView.swift
│       ├── InteractiveSlidingWindowView.swift
│       ├── InteractiveTwoPointerView.swift
│       └── PatternDetailView.swift
│
├── README.md
└── LICENSE
```

### Main Components

- **VisionAlgoApp.swift** — Application entry point that initializes the SwiftUI app lifecycle.
- **HomeView.swift** — Main navigation interface for accessing algorithm modules and visualizations.
- **AlgoPattern.swift** — Core data model describing algorithm patterns and metadata used by the UI.
- **Views/** — SwiftUI views implementing algorithm visualizations, UI rendering, state handling, and interaction logic.

#### Views Directory
```
Views
│
├── InteractiveBFSView.swift
├── InteractiveBinarySearchView.swift
├── InteractiveSlidingWindowView.swift
├── InteractiveTwoPointerView.swift
└── PatternDetailView.swift
```
These views contain the primary **visualization logic, state management, and user interaction behavior** for the application.

---

## Technology Stack

- **Swift**
- **SwiftUI**
- **Swift Package Manager**
- **Xcode / Swift Playgrounds**

---

## Installation

1. Clone the repository:
```bash
*git clone https://github.com/Adi-1515/AlgoVision.git*
```
3. Navigate to the project.
4. Open in Xcode or Swift Playgrounds.
5. Choose iPhone or iPad simulator.
6. Finally build and run the project.

---

## Educational Purpose

AlgoVision is built as a **learning tool for computer science students**, helping bridge the gap between theoretical algorithms and their actual execution.

It focuses on visual intuition rather than purely textual explanations.

---

## Future Improvements

- More algorithm visualizations
- Interactive user controls for algorithm parameters
- Additional learning modules
- Improved animations and graphics
- Performance benchmarking views

---

## Contributing

Contributions that improve visualization quality, UI design, or algorithm coverage are welcome.

### Typical Workflow

1. Fork the repository
2. Create a new feature branch
3. Commit your changes
4. Push the branch to your fork
5. Open a Pull Request

---

## License

This project is licensed under the MIT License.

See the `LICENSE` file for details.
