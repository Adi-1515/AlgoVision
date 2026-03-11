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

fileprivate struct LogNode: Identifiable, Equatable {
    let id: Int // also serves as index
    let value: Int
    var isRevealed: Bool = true
    var isEliminated: Bool = false
}

enum SearchPhase {
    case intro
    case promptMid
    case promptElimination
    case success
}

struct InteractiveBinarySearchView: View {
    let pattern: AlgoPattern
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    
    @State private var phase: SearchPhase = .intro
    @State private var logs: [LogNode] = [
        LogNode(id: 0, value: 5),
        LogNode(id: 1, value: 12),
        LogNode(id: 2, value: 18),
        LogNode(id: 3, value: 25),
        LogNode(id: 4, value: 30),
        LogNode(id: 5, value: 36),
        LogNode(id: 6, value: 42),
        LogNode(id: 7, value: 55),
        LogNode(id: 8, value: 68),
        LogNode(id: 9, value: 72),
        LogNode(id: 10, value: 85)
    ]
    @State private var targetValue: Int = 42
    @State private var low: Int = 0
    @State private var high: Int = 10
    @State private var currentMid: Int? = nil
    
    @State private var stepCount: Int = 0
    @State private var shakeTriggers: [Int: CGFloat] = [:]
    private var maxValue: Int { logs.map { $0.value }.max() ?? 100 }
    
    private let darkBg = Color(red: 0.08, green: 0.07, blue: 0.12)
    private let boxBg = Color(red: 0.13, green: 0.13, blue: 0.17)
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 0) {
                    topLabel
                    
                    Spacer()
                    
                    headerArea
                    
                    Spacer()
                        .frame(minHeight: 30)
                    
                    visualizationArea
                    
                    Spacer()
                        .frame(minHeight: 40)
                    
                    controlArea
                    
                    Spacer()
                }
                .padding(isCompact ? 16 : 32)
                .frame(minHeight: isCompact ? 500 : 640)
                .background(darkBg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(pattern.accent.opacity(0.4), lineWidth: 1)
                )
                
                if phase == .success {
                    keyInsightArea
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, isCompact ? 16 : 32)
            .padding(.bottom, 64)
            .impactHapticIfAvailable(trigger: phase)
            .selectionHapticIfAvailable(trigger: currentMid)
            .successHapticIfAvailable(trigger: phase == .success)
        }
    }
    
    private var topLabel: some View {
        HStack {
            Image(systemName: "cpu")
            Text("ANIMATED WALKTHROUGH")
            Spacer()
        }
        .font(.system(size: 13, weight: .bold, design: .monospaced))
        .tracking(1.5)
        .foregroundColor(Color(white: 0.6))
    }
    
    private var headerArea: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                Text("FIND TARGET")
                    .font(.system(size: isCompact ? 14 : 16, weight: .bold, design: .monospaced))
                    .tracking(2.0)
                    .foregroundColor(Color(white: 0.6))
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(pattern.accent.opacity(0.15))
                        .shadow(color: pattern.accent.opacity(0.4), radius: 12, y: 0)
                    
                    Text("\(targetValue)")
                        .font(.system(size: isCompact ? 24 : 32, weight: .bold))
                        .foregroundColor(pattern.accentSecondary)
                }
                .frame(width: isCompact ? 68 : 88, height: isCompact ? 50 : 64)
            }
            if phase != .intro {
                HStack(spacing: 12) {
                    Text("L=\(low)").foregroundColor(.teal).fontWeight(.bold)
                    Text("•").foregroundColor(Color(white: 0.4))
                    Text("R=\(high)").foregroundColor(.pink).fontWeight(.bold)
                    Text("•").foregroundColor(Color(white: 0.4))
                    Text("Range: \(max(0, high - low + 1)) elements")
                        .foregroundColor(Color(white: 0.6))
                }
                .font(.system(size: isCompact ? 12 : 14, weight: .bold, design: .monospaced))
            } else {
                Text("Range: 11 elements")
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.clear)
            }
        }
    }
    
    private var visualizationArea: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let spacing: CGFloat = isCompact ? 6 : 12
            let totalSpacing = spacing * CGFloat(max(0, logs.count - 1))
            let barWidth = max(20, min(isCompact ? 44 : 64, (availableWidth - totalSpacing) / CGFloat(max(1, logs.count))))
            
            HStack(alignment: .bottom, spacing: spacing) {
                Spacer(minLength: 0)
                ForEach(logs) { log in
                    logView(for: log, barWidth: barWidth)
                        .opacity(log.isEliminated ? 0.05 : 1.0)
                }
                Spacer(minLength: 0)
            }
            .frame(height: isCompact ? 200 : 260)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: isCompact ? 200 : 260)
    }
    
    private func logView(for log: LogNode, barWidth: CGFloat) -> some View {
        let isMid = log.id == currentMid && phase == .promptElimination
        let isFoundTarget = phase == .success && log.value == targetValue
        let heightRatio = CGFloat(log.value) / CGFloat(maxValue)
        let totalHeight: CGFloat = isCompact ? 170 : 230
        let minHeight: CGFloat = isCompact ? 60 : 80
        let calculatedHeight = minHeight + (heightRatio * (totalHeight - minHeight))
        
        return VStack(spacing: 8) {
            if !log.isEliminated {
                if isFoundTarget {
                    Text("") // Takes space but empty
                        .frame(height: 16)
                } else if log.id == low && phase != .intro {
                    Text("LOW")
                        .font(.system(size: isCompact ? 9 : 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.teal)
                        .frame(height: 16)
                } else if log.id == high && phase != .intro {
                    Text("HIGH")
                        .font(.system(size: isCompact ? 9 : 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.pink)
                        .frame(height: 16)
                } else {
                    Text("")
                        .frame(height: 16)
                }
            } else {
                Text("")
                    .frame(height: 16)
            }
            
            ZStack {
                if isFoundTarget {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.5), radius: 12)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isMid ? pattern.accent.opacity(0.8) : boxBg)
                        .shadow(color: isMid ? pattern.accent.opacity(0.5) : .clear, radius: 12)
                }
                
                if log.isRevealed {
                    Text("\(log.value)")
                        .font(.system(size: isCompact ? 18 : 24, weight: .heavy))
                        .foregroundColor(.white)
                } else {
                    Text("?")
                        .font(.system(size: isCompact ? 18 : 24, weight: .heavy))
                        .foregroundColor(Color(white: 0.4))
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
            }
            .frame(width: barWidth, height: calculatedHeight)
            .rotation3DEffect(.degrees(log.isRevealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .modifier(ShakeEffect(animatableData: shakeTriggers[log.id] ?? 0))
            .onTapGesture { handleLogTap(log) }
            .accessibilityLabel(log.isRevealed ? "Value \(log.value)" : "Hidden value")
            
            Text("[\(log.id)]")
                .font(.system(size: isCompact ? 9 : 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(white: 0.3))
        }
    }
    
    @ViewBuilder
    private var controlArea: some View {
        VStack(spacing: 24) {
            switch phase {
            case .intro:
                Text("Observe the sorted values & their heights. Tap \"Start\" when ready.")
                    .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                HStack(spacing: 16) {
                    Button(action: startSimulation) {
                        Text("Start")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [pattern.accentSecondary, .pink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                    }
                }
                
            case .promptMid:
                Text(stepCount == 0 ? "All values are now hidden. Tap \"Begin Search\" to start." : "Good! Now find the new middle element.")
                    .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                if stepCount == 0 {
                    HStack(spacing: 16) {
                        Button(action: {
                            withAnimation(.easeInOut) { phase = .promptMid; stepCount += 1 }
                        }) {
                            Text("Begin Search")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [pattern.accentSecondary, .pink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button(action: resetAll) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(white: 0.7))
                                .frame(width: 56, height: 56)
                                .background(boxBg)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                } else {
                    Text("Where is the middle element? Tap the log you think is the midpoint.")
                        .font(.system(size: isCompact ? 14 : 16))
                        .foregroundColor(Color(white: 0.5))
                    
                    Button(action: resetAll) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(white: 0.7))
                            .frame(width: 56, height: 56)
                            .background(boxBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                
            case .promptElimination:
                if let midIndex = currentMid {
                    let midVal = logs[midIndex].value
                    let relation = targetValue < midVal ? "smaller" : (targetValue > midVal ? "larger" : "equal")
                    
                    Text("Mid value is \(midVal). Target \(targetValue) is \(relation). Which half should be eliminated?")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(Color(white: 0.9))
                        .multilineTextAlignment(.center)
                    
                    if targetValue == midVal {
                        Button(action: finishSuccess) {
                            Text("Target Found")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.2, green: 0.8, blue: 0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    } else {
                        HStack(spacing: 16) {
                            Button(action: { eliminate(left: true) }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Eliminate Left")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color(white: 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                            
                            Button(action: { eliminate(left: false) }) {
                                HStack {
                                    Text("Eliminate Right")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color(white: 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                            
                            Button(action: resetAll) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(white: 0.7))
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                }
                
            case .success:
                VStack(spacing: 20) {
                    Text("Target \(targetValue) found in \(stepCount) steps!")
                        .font(.system(size: isCompact ? 18 : 22, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "trophy")
                        Text("Found in \(stepCount) steps")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.3), lineWidth: 1))
                    
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            Text("YOUR STEPS")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                            Text("\(stepCount)")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.teal)
                        }
                        
                        Divider().background(Color(white: 0.3)).frame(height: 40)
                        
                        VStack(spacing: 8) {
                            Text("LOG₂(11)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                            Text("≈ 4")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.pink)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(spacing: 8) {
                        Text("SEARCH SPACE HALVED EACH STEP")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.5))
                            .padding(.bottom, 4)
                        
                        spaceBar(width: 200, label: "11 elements", opacity: 0.3)
                        spaceBar(width: 100, label: "5 elements", opacity: 0.5)
                        spaceBar(width: 40, label: "2 elements", opacity: 0.8)
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
                        
                        Button(action: resetAll) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(white: 0.7))
                                .frame(width: 50, height: 50)
                                .background(Color(white: 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
    }
    
    private func spaceBar(width: CGFloat, label: String, opacity: Double) -> some View {
        ZStack {
            Capsule()
                .fill(Color(white: 0.15))
                .frame(width: 250, height: 24)
            
            Capsule()
                .fill(pattern.accentSecondary.opacity(opacity))
                .frame(width: width, height: 24)
            
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.8))
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
            
            Text("Binary search achieves O(log n) time by halving the search space at every step. For 1 billion elements, it takes at most ~30 comparisons instead of 1 billion.")
                .font(.system(size: isCompact ? 16 : 18, weight: .medium))
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
    
    private func startSimulation() {
        withAnimation(.easeInOut(duration: 0.6)) {
            for i in 0..<logs.count {
                logs[i].isRevealed = false
            }
            stepCount = 1
            phase = .promptMid
        }
    }
    
    private func handleLogTap(_ log: LogNode) {
        guard phase == .promptMid, stepCount > 0, !log.isEliminated else { return }
        
        let calculatedMid = low + (high - low) / 2
        
        if log.id == calculatedMid {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                logs[log.id].isRevealed = true
                currentMid = log.id
                stepCount += 1
                
                if logs[log.id].value == targetValue {
                    phase = .success
                } else {
                    phase = .promptElimination
                }
            }
        } else {
            withAnimation(.default) {
                shakeTriggers[log.id, default: 0] += 1
            }
        }
    }
    
    private func eliminate(left: Bool) {
        guard let mid = currentMid else { return }
        let midVal = logs[mid].value
        let shouldEliminateLeft = targetValue > midVal
        
        if left == shouldEliminateLeft {
            withAnimation(.easeInOut(duration: 0.6)) {
                if left {
                    for i in low...mid {
                        if i >= 0 && i < logs.count { logs[i].isEliminated = true }
                    }
                    low = mid + 1
                } else {
                    for i in mid...high {
                        if i >= 0 && i < logs.count { logs[i].isEliminated = true }
                    }
                    high = mid - 1
                }
                
                currentMid = nil
                
                if low > high {
                    phase = .success
                } else {
                    phase = .promptMid
                }
            }
        } else {
        }
    }
    
    private func finishSuccess() {
        withAnimation(.easeOut) {
            phase = .success
        }
    }
    
    private func resetAll() {
        withAnimation(.easeInOut) {
            logs = [
                LogNode(id: 0, value: 5),
                LogNode(id: 1, value: 12),
                LogNode(id: 2, value: 18),
                LogNode(id: 3, value: 25),
                LogNode(id: 4, value: 30),
                LogNode(id: 5, value: 36),
                LogNode(id: 6, value: 42),
                LogNode(id: 7, value: 55),
                LogNode(id: 8, value: 68),
                LogNode(id: 9, value: 72),
                LogNode(id: 10, value: 85)
            ]
            targetValue = 42
            low = 0
            high = 10
            currentMid = nil
            stepCount = 0
            phase = .intro
        }
    }
    
    private func randomizeData() {
        withAnimation(.easeInOut) {
            // Generate 8-14 random sorted unique integers between 1 and 100
            let targetCount = Int.random(in: 8...14)
            var newVals = Set<Int>()
            while newVals.count < targetCount {
                newVals.insert(Int.random(in: 1...100))
            }
            let sortedVals = Array(newVals).sorted()
            
            logs = sortedVals.enumerated().map { index, val in
                LogNode(id: index, value: val)
            }
            
            if Double.random(in: 0...1) < 0.8 {
                targetValue = sortedVals.randomElement() ?? 42
            } else {
                targetValue = Int.random(in: 1...100)
                while newVals.contains(targetValue) {
                    targetValue = Int.random(in: 1...100)
                }
            }
            
            low = 0
            high = sortedVals.count - 1
            currentMid = nil
            stepCount = 0
            phase = .intro
        }
    }
}
