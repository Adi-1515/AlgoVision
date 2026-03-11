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

fileprivate struct LogNode: Identifiable {
    let id: Int // uses index as ID
    let value: Int
}

enum TwoPointersPhase {
    case intro
    case setupLeft
    case setupRight
    case evaluate
    case success
    case noSolution
}

struct InteractiveTwoPointersView: View {
    let pattern: AlgoPattern
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    
    @State private var phase: TwoPointersPhase = .intro
    @State private var array = [1, 3, 5, 7, 8, 11, 14, 17]
    @State private var targetValue: Int = 19
    
    @State private var leftIndex: Int? = nil
    @State private var rightIndex: Int? = nil
    @State private var pointerHistory: [(Int, Int)] = []
    
    @State private var stepCount: Int = 0
    @State private var shakeTriggers: [Int: CGFloat] = [:]
    @State private var buttonShake: CGFloat = 0
    
    private var maxValue: Int { array.max() ?? 20 }
    
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
                        .frame(minHeight: isCompact ? 20 : 40)
                    
                    visualizationArea
                    
                    Spacer()
                        .frame(minHeight: isCompact ? 30 : 60)
                    
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
                
                if phase == .success || phase == .noSolution {
                    keyInsightArea
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, isCompact ? 16 : 32)
            .padding(.bottom, 64)
            .impactHapticIfAvailable(trigger: phase)
            .selectionHapticIfAvailable(trigger: leftIndex)
            .selectionHapticIfAvailable(trigger: rightIndex)
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
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Text("FIND PAIR SUM")
                    .font(.system(size: isCompact ? 14 : 16, weight: .bold, design: .monospaced))
                    .tracking(2.0)
                    .foregroundColor(Color(white: 0.6))
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(pattern.accent.opacity(0.15))
                        .shadow(color: pattern.accent.opacity(0.4), radius: 12, y: 0)
                    
                    Text("\(targetValue)")
                        .font(.system(size: isCompact ? 20 : 26, weight: .bold))
                        .foregroundColor(pattern.accentSecondary)
                }
                .frame(width: isCompact ? 68 : 88, height: isCompact ? 40 : 54)
            }
            
            if phase == .evaluate || phase == .success || phase == .noSolution {
                if let l = leftIndex, let r = rightIndex {
                    let sum = array[l] + array[r]
                    HStack(spacing: 12) {
                        Text("L=[\(l)] \(array[l])").foregroundColor(.cyan).fontWeight(.bold)
                        Text("•").foregroundColor(Color(white: 0.4))
                        Text("R=[\(r)] \(array[r])").foregroundColor(.pink).fontWeight(.bold)
                        Text("•").foregroundColor(Color(white: 0.4))
                        Text("Sum: \(sum)").foregroundColor(.white).fontWeight(.bold)
                    }
                    .font(.system(size: isCompact ? 13 : 16, weight: .bold, design: .monospaced))
                }
            } else if phase == .setupRight, let l = leftIndex {
                HStack(spacing: 12) {
                    Text("L=[\(l)] \(array[l])").foregroundColor(.cyan).fontWeight(.bold)
                    Text("•").foregroundColor(Color(white: 0.4))
                    Text("R=[] ?").foregroundColor(.pink).fontWeight(.bold)
                }
                .font(.system(size: isCompact ? 13 : 16, weight: .bold, design: .monospaced))
            } else {
                Text("Placeholder")
                    .font(.system(size: isCompact ? 13 : 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.clear)
            }
        }
    }
    
    private var visualizationArea: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let barSpacing = isCompact ? 6.0 : 12.0
            let totalSpacing = barSpacing * CGFloat(max(0, array.count - 1))
            let barWidth = max(20, min(isCompact ? 44.0 : 64.0, (availableWidth - totalSpacing) / CGFloat(max(1, array.count))))
            let totalCellWidth = barWidth + barSpacing
            
            VStack(spacing: 16) {
                // Range Bar
                ZStack(alignment: .leading) {
                    // Full subtle background
                    Capsule()
                        .fill(Color(white: 0.15))
                        .opacity(phase == .intro || phase == .setupLeft ? 0 : 1)
                        .frame(height: 6)
                    
                    // Gradient active range
                    if let l = leftIndex, let r = rightIndex, phase != .setupLeft && phase != .setupRight {
                        let activeWidth = CGFloat(r - l) * totalCellWidth + barWidth
                        let startOffset = CGFloat(l) * totalCellWidth
                        
                        Capsule()
                            .fill(LinearGradient(colors: [.cyan, .pink], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(activeWidth, 0), height: 6)
                            .offset(x: startOffset)
                            .shadow(color: .cyan.opacity(0.3), radius: 4)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: leftIndex)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: rightIndex)
                            .opacity(l >= r ? 0 : 1)
                    }
                }
                .frame(maxWidth: CGFloat(array.count) * totalCellWidth - barSpacing, alignment: .center)
                .frame(maxWidth: .infinity)
                .frame(height: 6)
                
                // Logs
                HStack(alignment: .bottom, spacing: barSpacing) {
                    Spacer(minLength: 0)
                    ForEach(0..<array.count, id: \.self) { index in
                        logView(for: index, barWidth: barWidth)
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: isCompact ? 200 : 260)
            }
        }
        .frame(height: isCompact ? 222 : 282)
    }
    
    private func logView(for index: Int, barWidth: CGFloat) -> some View {
        let val = array[index]
        let heightRatio = CGFloat(val) / CGFloat(maxValue)
        let totalHeight: CGFloat = isCompact ? 170 : 230
        let minHeight: CGFloat = isCompact ? 60 : 80
        let calculatedHeight = minHeight + (heightRatio * (totalHeight - minHeight))
        
        // State checking
        let isLeft = index == leftIndex
        let isRight = index == rightIndex
        
        // barWidth is now passed functionally
        
        return VStack(spacing: 8) {
            // Badges overlay layer
            ZStack(alignment: .top) {
                if isLeft {
                    Text("L")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.08, green: 0.07, blue: 0.12))
                        .frame(width: isCompact ? 24 : 32, height: isCompact ? 24 : 32)
                        .background(.cyan)
                        .clipShape(Capsule())
                        .offset(y: isCompact ? -28 : -36)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(2)
                }
                
                if isRight {
                    Text("R")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.08, green: 0.07, blue: 0.12))
                        .frame(width: isCompact ? 24 : 32, height: isCompact ? 24 : 32)
                        .background(.pink)
                        .clipShape(Capsule())
                        .offset(y: isCompact ? -28 : -36)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(2)
                }
                
                // The main block
                ZStack {
                    if isLeft && phase == .success {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                            .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.6), radius: 12)
                    } else if isRight && phase == .success {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                            .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.6), radius: 12)
                    } else if isLeft {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(colors: [.cyan.opacity(0.8), .cyan.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                            .shadow(color: .cyan.opacity(0.5), radius: 12)
                    } else if isRight {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(colors: [.pink.opacity(0.8), .pink.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                            .shadow(color: .pink.opacity(0.5), radius: 12)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(boxBg)
                    }
                    
                    Text("\(val)")
                        .font(.system(size: isCompact ? 18 : 24, weight: .heavy))
                        .foregroundColor(.white)
                }
                .frame(width: barWidth, height: calculatedHeight)
            }
            .modifier(ShakeEffect(animatableData: shakeTriggers[index] ?? 0))
            .onTapGesture { handleTap(index) }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLeft)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRight)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: phase)
            
            // Index Label
            Text("[\(index)]")
                .font(.system(size: isCompact ? 9 : 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(white: 0.3))
        }
    }
    
    @ViewBuilder
    private var controlArea: some View {
        VStack(spacing: 24) {
            switch phase {
            case .intro:
                Text("Observe the sorted array. Each bar's height represents its value. Tap \"Start\" when ready.")
                    .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation { phase = .setupLeft }
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
                
            case .setupLeft:
                Text("Where should the left pointer start? Tap the correct log.")
                    .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                resetButton
                
            case .setupRight:
                Text("Good! Now where should the right pointer start?")
                    .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                resetButton
                
            case .evaluate:
                if let l = leftIndex, let r = rightIndex {
                    let sum = array[l] + array[r]
                    let relation = sum < targetValue ? "<" : (sum > targetValue ? ">" : "=")
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Text("\(array[l])")
                                .foregroundColor(.cyan)
                                .fontWeight(.bold)
                            Text("+")
                                .foregroundColor(Color(white: 0.5))
                            Text("\(array[r])")
                                .foregroundColor(.pink)
                                .fontWeight(.bold)
                            Text("=")
                                .foregroundColor(Color(white: 0.5))
                            Text("\(sum)")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                            Text("\(relation)")
                                .foregroundColor(Color(white: 0.5))
                            Text("\(targetValue)")
                                .foregroundColor(Color(white: 0.5))
                        }
                        .font(.system(size: isCompact ? 20 : 24, design: .monospaced))
                        
                        Text("\(array[l]) + \(array[r]) = \(sum). Target is \(targetValue).")
                            .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                            .foregroundColor(Color(white: 0.6))
                            .padding(.top, -8)
                            .padding(.bottom, 8)
                        
                        Text("Sum \(sum) \(relation) \(targetValue). Which pointer should move?")
                            .font(.system(size: isCompact ? 16 : 18, weight: .medium))
                            .foregroundColor(Color(white: 0.9))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Button(action: { processDecision(movingLeft: true) }) {
                                HStack {
                                    Text(Image(systemName: "chevron.right")).foregroundColor(.cyan)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Move Left")
                                    Text(Image(systemName: "arrow.right")).foregroundColor(.cyan)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.11, green: 0.18, blue: 0.25)) // Dark cyan-ish
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                            }
                            
                            Button(action: { processDecision(movingLeft: false) }) {
                                HStack {
                                    Text(Image(systemName: "arrow.left")).foregroundColor(.pink)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Move Right")
                                    Text(Image(systemName: "chevron.left")).foregroundColor(.pink)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.22, green: 0.12, blue: 0.16)) // Dark pink-ish
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.4), lineWidth: 1))
                            }
                            
                            resetButton
                        }
                        .modifier(ShakeEffect(animatableData: buttonShake))
                    }
                }
                
            case .success:
                VStack(spacing: 20) {
                    Text("\(array[leftIndex ?? 0]) + \(array[rightIndex ?? 0]) = \(targetValue). Target found!")
                        .font(.system(size: isCompact ? 18 : 22, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "trophy")
                        Text("Pair found in \(stepCount) steps")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.3), lineWidth: 1))
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("POINTER MOVES")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                            Text("\(stepCount)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(.cyan)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().background(Color(white: 0.3)).frame(height: 40)
                        
                        VStack(spacing: 8) {
                            Text("TIME COMPLEXITY")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                            Text("O(n)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(.cyan)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().background(Color(white: 0.3)).frame(height: 40)
                        
                        VStack(spacing: 8) {
                            Text("VS BINARY SEARCH")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                            Text("O(log n)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(Color(red: 0.6, green: 0.3, blue: 1.0))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                    
                    // Convergence History
                    VStack(spacing: 8) {
                        Text("POINTER CONVERGENCE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.6))
                            .padding(.bottom, 4)
                        
                        ForEach(Array(pointerHistory.enumerated()), id: \.offset) { i, bounds in
                            historyBar(left: bounds.0, right: bounds.1)
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
                
            case .noSolution:
                VStack(spacing: 20) {
                    Text("Pointers crossed! No pair sums to \(targetValue).")
                        .font(.system(size: isCompact ? 18 : 22, weight: .medium))
                        .foregroundColor(.pink)
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
    
    // Helper view for Pointer Convergence history visualization
    private func historyBar(left: Int, right: Int) -> some View {
        let maxIndices = array.count - 1
        let totalWidth: CGFloat = 200
        let leftRatio = CGFloat(left) / CGFloat(maxIndices)
        let rightRatio = CGFloat(right) / CGFloat(maxIndices)
        let activeWidth = max(20, (rightRatio - leftRatio) * totalWidth) // prevent 0-width
        let offset = leftRatio * totalWidth
        
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color(white: 0.15))
                .frame(width: totalWidth, height: 20)
            
            ZStack {
                Capsule()
                    .fill(LinearGradient(colors: [.cyan.opacity(0.6), .pink.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                
                Text("[\(left)..\(right)]")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: activeWidth, height: 20)
            .offset(x: offset)
        }
        .frame(width: totalWidth)
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
            
            Text("Two pointers reduces an O(n²) brute-force search to O(n) by intelligently eliminating impossible pairs at each step. Each pointer moves at most n times.")
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
    
    private func handleTap(_ index: Int) {
        if phase == .setupLeft {
            if index == 0 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    leftIndex = 0
                    phase = .setupRight
                }
            } else {
                withAnimation(.default) {
                    shakeTriggers[index, default: 0] += 1
                }
            }
        } else if phase == .setupRight {
            if index == array.count - 1 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    rightIndex = array.count - 1
                    pointerHistory.append((0, array.count - 1))
                    phase = .evaluate
                }
            } else {
                withAnimation(.default) {
                    shakeTriggers[index, default: 0] += 1
                }
            }
        }
    }
    
    // Removed triggerShake helper
    
    private func processDecision(movingLeft: Bool) {
        guard let l = leftIndex, let r = rightIndex else { return }
        
        let sum = array[l] + array[r]
        let shouldMoveLeft = sum < targetValue
        let shouldMoveRight = sum > targetValue
        
        if (movingLeft && shouldMoveLeft) || (!movingLeft && shouldMoveRight) {
            // Correct choice
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                stepCount += 1
                if movingLeft {
                    leftIndex = min(array.count - 1, l + 1)
                } else {
                    rightIndex = max(0, r - 1)
                }
                
                // Record the new state location in the convergence history
                if let newL = leftIndex, let newR = rightIndex {
                    pointerHistory.append((newL, newR))
                }
                
                checkTerminalState()
            }
        } else {
            // Incorrect choice
            withAnimation(.default) {
                buttonShake += 1
            }
        }
    }
    
    private func checkTerminalState() {
        guard let l = leftIndex, let r = rightIndex else { return }
        
        if l >= r {
            phase = .noSolution
        } else if array[l] + array[r] == targetValue {
            phase = .success
        }
    }
    
    private func resetAll() {
        withAnimation(.easeInOut) {
            leftIndex = nil
            rightIndex = nil
            stepCount = 0
            pointerHistory = []
            phase = .intro
        }
    }
    
    private func randomizeData() {
        withAnimation(.easeInOut) {
            // Generate 8-14 random sorted unique integers
            let targetCount = Int.random(in: 8...14)
            var newVals = Set<Int>()
            while newVals.count < targetCount {
                newVals.insert(Int.random(in: 1...50))
            }
            array = Array(newVals).sorted()
            
            // Randomly pick a guaranteed valid pair for the Two Pointers target sum
            let idx1 = Int.random(in: 0..<array.count)
            var idx2 = Int.random(in: 0..<array.count)
            while idx1 == idx2 {
                idx2 = Int.random(in: 0..<array.count)
            }
            
            targetValue = array[idx1] + array[idx2]
            
            leftIndex = nil
            rightIndex = nil
            stepCount = 0
            pointerHistory = []
            phase = .intro
        }
    }
}
