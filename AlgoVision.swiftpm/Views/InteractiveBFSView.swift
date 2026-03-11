import SwiftUI

fileprivate struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 4
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

enum BFSPhase {
    case intro
    case pickStartNode
    case enqueueStartNode
    case dequeue
    case analyze
    case done
}

struct InteractiveBFSView: View {
    let pattern: AlgoPattern
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    
    // UI Constants
    private let darkBg = Color(red: 0.08, green: 0.07, blue: 0.12)
    private let boxBg = Color(red: 0.13, green: 0.13, blue: 0.17)
    
    // Animation Namespace for moving nodes
    @Namespace private var nodeMovement
    
    @State private var phase: BFSPhase = .intro
    
    enum NodeLocation {
        case graph
        case graphActive
        case queue
        case visited
    }
    
    @State private var nodeLocations: [Int: NodeLocation] = [:]
    
    @State private var queue: [Int] = []
    @State private var visited: [Int] = []
    @State private var currentNode: Int? = nil
    
    struct Edge: Hashable {
        let u: Int
        let v: Int
        init(_ a: Int, _ b: Int) {
            self.u = min(a, b)
            self.v = max(a, b)
        }
    }
    @State private var treeEdges: Set<Edge> = []
    
    @State private var graphEdges: [Int: [Int]] = [
        0: [1, 2],
        1: [0, 3, 4],
        2: [0, 4, 5],
        3: [1],
        4: [1, 2],
        5: [2]
    ]
    
    @State private var nodePositions: [Int: CGPoint] = [
        0: CGPoint(x: 0.5, y: 0.1),
        1: CGPoint(x: 0.35, y: 0.45),
        2: CGPoint(x: 0.65, y: 0.45),
        3: CGPoint(x: 0.28, y: 0.8),
        4: CGPoint(x: 0.5, y: 0.8),
        5: CGPoint(x: 0.72, y: 0.8)
    ]
    
    @State private var pendingStartNode: Int? = nil
    @State private var shakeTriggers: [Int: CGFloat] = [:]
    @State private var containerShake: CGFloat = 0
    @State private var stepCount: Int = 0
    
    init(pattern: AlgoPattern) {
        self.pattern = pattern
        var initialLocs: [Int: NodeLocation] = [:]
        for i in 0...7 { initialLocs[i] = .graph }
        self._nodeLocations = State(initialValue: initialLocs)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 0) {
                    topLabel
                    
                    Spacer().frame(height: 24)
                    
                    graphArea
                    
                    Spacer().frame(height: 32)
                    
                    queueArea
                    
                    Spacer().frame(height: 24)
                    
                    visitedArea
                    
                    Spacer().frame(height: 32)
                    
                    controlArea
                }
                .padding(isCompact ? 16 : 32)
                .frame(minHeight: isCompact ? 500 : 700)
                .background(darkBg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(pattern.accent.opacity(0.4), lineWidth: 1)
                )
                
                if phase == .done {
                    keyInsightArea
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, isCompact ? 16 : 32)
            .padding(.bottom, 64)
            .impactHapticIfAvailable(trigger: phase)
            .successHapticIfAvailable(trigger: phase == .done)
        }
    }
    
    private var topLabel: some View {
        HStack {
            Image(systemName: "cpu")
            Text("ANIMATED WALKTHROUGH")
            Spacer()
            
            Text("EXPLORE GRAPH")
                .foregroundColor(Color(white: 0.6))
            Text("BFS")
                .foregroundColor(pattern.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(pattern.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .font(.system(size: 13, weight: .bold, design: .monospaced))
        .tracking(1.5)
        .foregroundColor(Color(white: 0.6))
    }
    
    private var graphArea: some View {
        GeometryReader { geo in
            ZStack {
            
                ForEach(0..<nodeCount + 1, id: \.self) { u in
                    ForEach(graphEdges[u] ?? [], id: \.self) { v in
                        if u < v { // Draw each edge only once
                            let p1 = CGPoint(x: (nodePositions[u]?.x ?? 0.5) * geo.size.width, y: (nodePositions[u]?.y ?? 0.5) * geo.size.height)
                            let p2 = CGPoint(x: (nodePositions[v]?.x ?? 0.5) * geo.size.width, y: (nodePositions[v]?.y ?? 0.5) * geo.size.height)
                            
                            let isTreeEdge = treeEdges.contains(Edge(u, v))
                            
                            Path { path in
                                path.move(to: p1)
                                path.addLine(to: p2)
                            }
                            .stroke(isTreeEdge ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(white: 0.2), lineWidth: 2)
                        }
                    }
                }
             
                ForEach(0..<nodeCount + 1, id: \.self) { id in
                    let loc = nodeLocations[id] ?? .graph
                    let pos = CGPoint(x: (nodePositions[id]?.x ?? 0.5) * geo.size.width, y: (nodePositions[id]?.y ?? 0.5) * geo.size.height)
                    
                    if loc == .graph || loc == .graphActive {
                        NodeView(id: id, state: loc, pattern: pattern, isGraphContext: true)
                            .matchedGeometryEffect(id: "node\(id)", in: nodeMovement)
                            .position(pos)
                            .modifier(ShakeEffect(animatableData: shakeTriggers[id] ?? 0))
                            .onTapGesture { handleNodeTap(id) }
                            .zIndex(loc == .graphActive ? 2 : 1)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                            .position(pos)
                            .onTapGesture { handleNodeTap(id) }
                    }
                }
            }
        }
        .frame(height: isCompact ? 220 : 280)
    }
    
    private var queueArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("QUEUE")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2.0)
                    .foregroundColor(Color(white: 0.8))
                
                Text("(FIFO — front is left)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
            }
            
            HStack(spacing: 12) {
                if queue.isEmpty {
                    Text("empty")
                        .font(.system(size: 14, weight: .medium, design: .monospaced).italic())
                        .foregroundColor(Color(white: 0.3))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(queue, id: \.self) { id in
                                if nodeLocations[id] == .queue {
                                    NodeView(id: id, state: .queue, pattern: pattern, isGraphContext: false)
                                        .matchedGeometryEffect(id: "node\(id)", in: nodeMovement)
                                        .onTapGesture { handleQueueTap(id) }
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(white: 0.11))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(white: 0.15), lineWidth: 1)
            )
            .modifier(ShakeEffect(animatableData: containerShake))
            .onTapGesture {
                if phase == .enqueueStartNode {
                    processEnqueueStartNode()
                } else if phase == .dequeue {
                    withAnimation(.default) { containerShake += 1 }
                }
            }
        }
    }
    
    private var visitedArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VISITED")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(2.0)
                .foregroundColor(Color(white: 0.8))
            
            HStack(spacing: 12) {
                if visited.isEmpty {
                    Text("none yet")
                        .font(.system(size: 14, weight: .medium, design: .monospaced).italic())
                        .foregroundColor(Color(white: 0.3))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                } else {
                    ForEach(visited, id: \.self) { id in
                        if nodeLocations[id] == .visited {
                            NodeView(id: id, state: .visited, pattern: pattern, isGraphContext: false)
                                .matchedGeometryEffect(id: "node\(id)", in: nodeMovement)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(Color(red: 0.08, green: 0.14, blue: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1) 
            )
        }
    }
    
    @ViewBuilder
    private var controlArea: some View {
        VStack(spacing: 24) {
            switch phase {
            case .intro:
                Text("A graph with 6 nodes. Tap \"Start\" to begin BFS exploration.")
                    .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation { phase = .pickStartNode }
                    }) {
                        Text("Start")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [.pink, pattern.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    Button(action: randomizeData) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(white: 0.7))
                            .frame(width: 56, height: 56)
                            .background(boxBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(pattern.accent.opacity(0.3), lineWidth: 1))
                    }
                }
                
            case .pickStartNode:
                Text("Select a starting node. Tap any node on the graph.")
                    .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                resetButton
                
            case .enqueueStartNode:
                if let startNode = pendingStartNode {
                    Text("Node \(startNode) selected. Tap the queue container to enqueue it.")
                        .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                        .foregroundColor(Color(white: 0.9))
                        .multilineTextAlignment(.center)
                }
                
                resetButton
                
            case .dequeue:
                if queue.first != nil {
                    if visited.isEmpty {
                        Text("Node 0 added to queue. Tap the front of the queue to dequeue it.")
                            .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                            .foregroundColor(Color(white: 0.9))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Good! Tap the front of the queue to dequeue next.")
                            .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                            .foregroundColor(Color(white: 0.9))
                            .multilineTextAlignment(.center)
                    }
                }
                
                resetButton
                
            case .analyze:
                Text("Tap the unvisited neighbors to enqueue them.")
                    .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                resetButton
                
            case .done:
                VStack(spacing: 24) {
                    Text("BFS complete! All reachable nodes visited in \(visited.count) steps.")
                        .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "trophy")
                        Text("BFS complete — \(visited.count) nodes visited")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.1, green: 0.3, blue: 0.15))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.4), lineWidth: 1))
                    
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            Text("STEPS")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(Color(white: 0.6))
                            Text("\(visited.count)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(pattern.accent)
                        }
                        
                        Divider().background(Color(white: 0.3)).frame(height: 40)
                        
                        VStack(spacing: 8) {
                            Text("COMPLEXITY")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(Color(white: 0.6))
                            Text("O(V+E)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(pattern.accent)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Text("TRAVERSAL ORDER")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.6))
                        
                        HStack(spacing: 8) {
                            ForEach(Array(visited.enumerated()), id: \.element) { i, node in
                                HStack(spacing: 8) {
                                    Text("\(node)")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                                        .frame(width: 32, height: 32)
                                        .background(pattern.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    
                                    if i < visited.count - 1 {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color(white: 0.4))
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: randomizeData) {
                            HStack {
                                Image(systemName: "shuffle")
                                Text("Randomize")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color(white: 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        
                        resetButton
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private var resetButton: some View {
        Button(action: resetAll) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(white: 0.7))
                .frame(width: 50, height: 50)
                .background(boxBg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private var keyInsightArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.pages")
                Text("KEY INSIGHT")
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .tracking(1.5)
            .foregroundColor(Color(white: 0.6))
            
            Text("BFS guarantees the shortest path in unweighted graphs because it explores all nodes at distance d before any node at distance d+1. It runs in O(V + E) time.")
                .font(.system(size: isCompact ? 15 : 17, weight: .medium))
                .foregroundColor(.white)
                .lineSpacing(4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(darkBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(pattern.accent.opacity(0.4), lineWidth: 1)
        )
    }
    
    private func handleNodeTap(_ id: Int) {
        if phase == .pickStartNode {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                pendingStartNode = id
                nodeLocations[id] = .graphActive
                phase = .enqueueStartNode
            }
        } else if phase == .analyze {
            guard let current = currentNode else { return }
            let neighbors = graphEdges[current] ?? []
            
            if current == id {
                // Tapped the active node to complete it
                let unvisitedNeighbors = neighbors.filter { nodeLocations[$0] == .graph }
                if unvisitedNeighbors.isEmpty {
                    processMarkVisited()
                } else {
                    withAnimation(.default) { shakeTriggers[id, default: 0] += 1 }
                }
            } else if neighbors.contains(id) {
                // Tapped a neighbor
                if nodeLocations[id] == .graph {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        nodeLocations[id] = .queue
                        queue.append(id)
                        treeEdges.insert(Edge(current, id))
                        stepCount += 1
                        
                        // Check if we should auto-complete this node
                        let unvisitedNeighbors = neighbors.filter { nodeLocations[$0] == .graph }
                        if unvisitedNeighbors.isEmpty { // All queued
                            processMarkVisited()
                        }
                    }
                } else {
                    // Tapped a neighbor that's already processed or queued
                    withAnimation(.default) { shakeTriggers[id, default: 0] += 1 }
                }
            } else {
                // Tapped completely wrong node
                withAnimation(.default) { shakeTriggers[id, default: 0] += 1 }
            }
        } else {
            // General wrong tap
            withAnimation(.default) { shakeTriggers[id, default: 0] += 1 }
        }
    }
    
    private func handleQueueTap(_ id: Int) {
        if phase == .dequeue {
            if id == queue.first {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    let popped = queue.removeFirst()
                    currentNode = popped
                    nodeLocations[popped] = .graphActive
                    stepCount += 1
                    phase = .analyze
                    
                    let neighbors = graphEdges[popped] ?? []
                    let unvisitedNeighbors = neighbors.filter { nodeLocations[$0] == .graph }
                    if unvisitedNeighbors.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if currentNode == popped {
                                processMarkVisited()
                            }
                        }
                    }
                }
            } else {
                withAnimation(.default) { containerShake += 1 }
            }
        }
    }
    
    private func processEnqueueStartNode() {
        guard let id = pendingStartNode else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            nodeLocations[id] = .queue
            queue.append(id)
            pendingStartNode = nil
            stepCount += 1
            phase = .dequeue
        }
    }
    
    private func processMarkVisited() {
        guard let current = currentNode else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            nodeLocations[current] = .visited
            visited.append(current)
            currentNode = nil
            stepCount += 1
            
            if queue.isEmpty {
                phase = .done
            } else {
                phase = .dequeue
            }
        }
    }
    
    private func resetAll() {
        withAnimation(.easeInOut) {
            queue.removeAll()
            visited.removeAll()
            treeEdges.removeAll()
            currentNode = nil
            pendingStartNode = nil
            stepCount = 0
            
            for i in 0...nodeCount { nodeLocations[i] = .graph }
            
            phase = .intro
        }
    }
    
    private var nodeCount: Int {
        return nodePositions.keys.max() ?? 5
    }
    
    private func randomizeData() {
        withAnimation(.easeInOut) {
            let n = Int.random(in: 5...7)
            var newEdges: [Int: [Int]] = [:]
            var newPositions: [Int: CGPoint] = [:]
            
            for i in 0..<n { newEdges[i] = [] }
            
            // Generate a random connected tree
            for i in 1..<n {
                let parent = Int.random(in: 0..<i)
                newEdges[i]?.append(parent)
                newEdges[parent]?.append(i)
            }
            
            // Add 1 or 2 random extra edges to create cycles
            let extraEdges = Int.random(in: 1...2)
            for _ in 0..<extraEdges {
                let u = Int.random(in: 0..<n)
                var v = Int.random(in: 0..<n)
                while u == v || (newEdges[u]?.contains(v) == true) {
                    v = Int.random(in: 0..<n)
                }
                newEdges[u]?.append(v)
                newEdges[v]?.append(u)
            }
            
            newPositions[0] = CGPoint(x: 0.5, y: 0.15) // root-ish
            
            var yOffset: CGFloat = 0.45
            var startNode = 1
            
            while startNode < n {
                let nodesInLayer = min(Int.random(in: 2...3), n - startNode)
                let spacing = 0.8 / CGFloat(nodesInLayer) // 10% margins on sides
                
                for i in 0..<nodesInLayer {
                    let id = startNode + i
                    let xOffset = 0.1 + spacing * CGFloat(i) + (spacing / 2.0) + CGFloat.random(in: -0.05...0.05)
                    newPositions[id] = CGPoint(x: min(0.9, max(0.1, xOffset)), y: yOffset + CGFloat.random(in: -0.05...0.05))
                }
                startNode += nodesInLayer
                yOffset += 0.35
            }
            
            graphEdges = newEdges
            nodePositions = newPositions
            
            queue.removeAll()
            visited.removeAll()
            treeEdges.removeAll()
            currentNode = nil
            pendingStartNode = nil
            stepCount = 0
            
            nodeLocations.removeAll()
            for i in 0..<n { nodeLocations[i] = .graph }
            
            phase = .intro
        }
    }
}

fileprivate struct NodeView: View {
    let id: Int
    let state: InteractiveBFSView.NodeLocation
    let pattern: AlgoPattern
    let isGraphContext: Bool
    
    var body: some View {
        ZStack {
            if state == .graphActive {
                RoundedRectangle(cornerRadius: isGraphContext ? 22 : 12, style: .continuous)
                    .fill(pattern.accent)
                    .shadow(color: pattern.accent.opacity(0.8), radius: 12)
            } else if state == .visited {
                RoundedRectangle(cornerRadius: isGraphContext ? 22 : 12, style: .continuous)
                    .fill(Color(red: 0.1, green: 0.25, blue: 0.15)) // dark green
            } else if state == .queue {
                RoundedRectangle(cornerRadius: isGraphContext ? 22 : 12, style: .continuous)
                    .fill(pattern.accent)
            } else { // default .graph
                RoundedRectangle(cornerRadius: isGraphContext ? 22 : 12, style: .continuous)
                    .fill(Color(white: 0.15))
            }
            
            if state == .graphActive {
                RoundedRectangle(cornerRadius: isGraphContext ? 22 : 12, style: .continuous)
                    .stroke(Color.white, lineWidth: 2)
            } else if state == .visited {
                RoundedRectangle(cornerRadius: isGraphContext ? 22 : 12, style: .continuous)
                    .stroke(Color(red: 0.2, green: 0.8, blue: 0.4), lineWidth: 1.5)
            } else if state == .queue {
                // solid yellow/orange
            } else {
                RoundedRectangle(cornerRadius: isGraphContext ? 22 : 12, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
            
            Text("\(id)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(
                    (state == .graphActive || state == .queue) ? Color(red: 0.1, green: 0.1, blue: 0.15) :
                    (state == .visited) ? Color(red: 0.2, green: 0.8, blue: 0.4) :
                    (state == .graph) ? Color(white: 0.8) : .white
                )
        }
        .frame(width: isGraphContext ? 44 : 36, height: isGraphContext ? 44 : 36)
    }
}
