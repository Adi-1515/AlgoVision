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

struct InteractiveSlidingWindowView: View {
    let pattern: AlgoPattern
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    
    enum Phase {
        case intro
        case anchor
        case expand
        case slide
        case success
    }
    
    @State private var phase: Phase = .intro
    @State private var array = [2, 1, 5, 1, 3, 2, 3, 5, 1, 4]
    @State private var k = 3
    
    @State private var windowStart: Int? = nil
    @State private var windowEnd: Int? = nil
    @State private var bestSum: Int = 0
    @State private var shakeTriggers: [Int: CGFloat] = [:]
    
    private var maxValue: Int { array.max() ?? 5 }
    
    private let darkBg = Color(red: 0.08, green: 0.07, blue: 0.12)
    private let boxBg = Color(red: 0.13, green: 0.13, blue: 0.17)
    
    private var barWidth: CGFloat { isCompact ? 44 : 64 }
    private var barSpacing: CGFloat { isCompact ? 6 : 12 }
    
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
                    
                    equationArea
                    
                    Spacer()
                        .frame(minHeight: 20)
                    
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
                Text("MAX SUM OF \(k)")
                    .font(.system(size: isCompact ? 14 : 16, weight: .bold, design: .monospaced))
                    .tracking(2.0)
                    .foregroundColor(Color(white: 0.6))
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(pattern.accent.opacity(0.15))
                        .shadow(color: pattern.accent.opacity(0.4), radius: 12, y: 0)
                    
                    Text("k=\(k)")
                        .font(.system(size: isCompact ? 20 : 26, weight: .bold))
                        .foregroundColor(pattern.accentSecondary)
                }
                .frame(width: isCompact ? 68 : 88, height: isCompact ? 40 : 54)
            }
            if phase != .intro, let start = windowStart, let end = windowEnd {
                let sum = currentWindowSum()
                HStack(spacing: 12) {
                    Text("Window [\(start)-\(end)]").foregroundColor(.cyan).fontWeight(.bold)
                    Text("•").foregroundColor(Color(white: 0.4))
                    Text("Sum: \(sum)").foregroundColor(Color(white: 0.8))
                    if phase == .slide || phase == .success {
                        Text("•").foregroundColor(Color(white: 0.4))
                        Text("Best: \(bestSum)").foregroundColor(.orange).fontWeight(.bold)
                    }
                }
                .font(.system(size: isCompact ? 12 : 14, weight: .bold, design: .monospaced))
            } else {
                Text("Window [0-0] • Sum: 0 • Best: 0")
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.clear)
            }
        }
    }
    
    @ViewBuilder
    private var equationArea: some View {
        if let start = windowStart, let end = windowEnd {
            let slice = array[start...end]
            let sum = slice.reduce(0, +)
            
            HStack(spacing: 8) {
                ForEach(start...end, id: \.self) { i in
                    Text("\(array[i])")
                        .foregroundColor(pattern.accentSecondary)
                    if i < end {
                        Text("+")
                            .foregroundColor(Color(white: 0.5))
                    }
                }
                Text("=")
                    .foregroundColor(Color(white: 0.5))
                    .padding(.horizontal, 4)
                Text("\(sum)")
                    .foregroundColor(.white)
            }
            .font(.system(size: isCompact ? 20 : 24, weight: .bold, design: .monospaced))
            .frame(height: 30)
        } else {
            Text("").frame(height: 30)
        }
    }
    
    private var visualizationArea: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let barSpacing = isCompact ? 6.0 : 12.0
            let totalSpacing = barSpacing * CGFloat(max(0, array.count - 1))
            let barWidth = max(20, min(isCompact ? 44.0 : 64.0, (availableWidth - totalSpacing) / CGFloat(max(1, array.count))))
            let totalCellWidth = barWidth + barSpacing
            
            VStack(spacing: 8) {
                // Window range indicator bar above logs
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.15))
                        .opacity(phase == .intro ? 0 : 1)
                        .frame(height: 6)
                    
                    if let start = windowStart, let end = windowEnd {
                        let activeWidth = CGFloat(end - start) * totalCellWidth + barWidth
                        let startOffset = CGFloat(start) * totalCellWidth
                        
                        Capsule()
                            .fill(pattern.accentSecondary)
                            .frame(width: max(activeWidth, 0), height: 6)
                            .offset(x: startOffset)
                            .shadow(color: pattern.accentSecondary.opacity(0.4), radius: 6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: start)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: end)
                    }
                }
                .frame(maxWidth: CGFloat(array.count) * totalCellWidth - barSpacing, alignment: .center)
                .frame(maxWidth: .infinity)
                .frame(height: 6)
                
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
        .frame(height: isCompact ? 214 : 274)
    }
    
    private func logView(for index: Int, barWidth: CGFloat) -> some View {
        let val = array[index]
        let heightRatio = CGFloat(val) / CGFloat(maxValue)
        let totalHeight: CGFloat = isCompact ? 170 : 230
        let minHeight: CGFloat = isCompact ? 60 : 80
        let calculatedHeight = minHeight + (heightRatio * (totalHeight - minHeight))
        
        let inWindow = index >= (windowStart ?? -1) && index <= (windowEnd ?? -1)
        let isNextTarget = phase == .expand && index == (windowEnd ?? -1) + 1
        
        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(inWindow ? pattern.accentSecondary : boxBg)
                    .shadow(color: inWindow ? pattern.accentSecondary.opacity(0.6) : .clear, radius: 12)
                
                if !inWindow {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(pattern.accentSecondary.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .opacity(isNextTarget ? 1 : 0)
                }
                
                Text("\(val)")
                    .font(.system(size: isCompact ? 18 : 24, weight: .heavy))
                    .foregroundColor(inWindow ? .white : Color(white: 0.8))
            }
            .frame(width: barWidth, height: calculatedHeight)
            .overlay(alignment: .top) {
                if index == windowStart {
                    Text("L")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.08, green: 0.07, blue: 0.12))
                        .frame(width: 20, height: 20)
                        .background(pattern.accent)
                        .clipShape(Circle())
                        .offset(y: -28)
                }
            }
            .overlay(alignment: .top) {
                if index == windowEnd && windowStart != windowEnd {
                    Text("R")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.08, green: 0.07, blue: 0.12))
                        .frame(width: 20, height: 20)
                        .background(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .clipShape(Circle())
                        .offset(y: -28)
                }
            }
            .modifier(ShakeEffect(animatableData: shakeTriggers[index] ?? 0))
            .onTapGesture { handleTap(index) }
            
            // Index Label (always shown to match spacing)
            Text("[\(index)]")
                .font(.system(size: isCompact ? 9 : 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(white: 0.3))
        }
    }
    
    @State private var previousStartVal: Int? = nil
    @State private var nextEndVal: Int? = nil
    @State private var windowHistory: [(start: Int, end: Int, sum: Int, isBest: Bool)] = []
    @State private var isNewBest: Bool = false
    
    // MARK: - Control Area
    @ViewBuilder
    private var controlArea: some View {
        VStack(spacing: 24) {
            switch phase {
            case .intro:
                Text("Observe the array. Each bar's height represents its value. Tap \"Start\" when ready.")
                    .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation { phase = .anchor }
                    }) {
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
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(pattern.accent.opacity(0.3), lineWidth: 1))
                    }
                }
                
            case .anchor:
                Text("Where should the window start? Tap the first element.")
                    .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                    .foregroundColor(Color(white: 0.9))
                    .multilineTextAlignment(.center)
                
                resetButton
                
            case .expand:
                let sum = currentWindowSum()
                let size = (windowEnd ?? 0) - (windowStart ?? 0) + 1
                
                if size == 1 {
                    Text("Window anchored at [\(windowStart ?? 0)]. Value = \(sum). Tap next element to expand.")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                } else if size < k {
                    Text("Added \(array[windowEnd ?? 0]). Running sum = \(sum). Tap next to expand.")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Sum = \(sum). Best = \(bestSum). Slide again?")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Button(action: slideRight) {
                            HStack {
                                Text("Slide Right")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                pattern.accentSecondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        resetButton
                    }
                }
                if size < k { resetButton }
                
            case .slide:
                if let prev = previousStartVal, let next = nextEndVal {
                    HStack(spacing: 8) {
                        Text("-\(prev) + \(next) -> Sum = \(currentWindowSum()).")
                            .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        if isNewBest {
                            Text("🏆 New best!")
                                .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .multilineTextAlignment(.center)
                } else {
                    Text("Sum = \(currentWindowSum()). Best = \(bestSum). Slide again?")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 16) {
                    Button(action: slideRight) {
                        HStack {
                            Text("Slide Right")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            pattern.accentSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    resetButton
                }
                
            case .success:
                VStack(spacing: 24) {
                    Text("All positions checked! Best sum = \(bestSum).")
                        .font(.system(size: isCompact ? 18 : 22, weight: .medium))
                        .foregroundColor(.white)
                    
                    if let bestWindow = windowHistory.first(where: { $0.isBest }) {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy")
                            Text("Best sum = \(bestSum) at [\(bestWindow.start)-\(bestWindow.end)]")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.3), lineWidth: 1))
                    }
                    
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            Text("WINDOWS CHECKED")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                            Text("\(windowHistory.count)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(pattern.accentSecondary)
                        }
                        
                        Divider().background(Color(white: 0.3)).frame(height: 40)
                        
                        VStack(spacing: 8) {
                            Text("TIME COMPLEXITY")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                            Text("O(n)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(pattern.accentSecondary)
                        }
                        
                        Divider().background(Color(white: 0.3)).frame(height: 40)
                        
                        VStack(spacing: 8) {
                            Text("VS BRUTE FORCE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.6))
                            Text("O(n·k)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(pattern.accent)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("WINDOW POSITIONS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.5))
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 4) {
                            ForEach(0..<windowHistory.count, id: \.self) { i in
                                let hist = windowHistory[i]
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Capsule()
                                            .fill(Color(white: 0.15))
                                            .frame(width: 250, height: 20)
                                        
                                        HStack {
                                            if hist.start > 0 { Spacer().frame(width: CGFloat(hist.start) * (250.0 / CGFloat(array.count))) }
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: hist.isBest ? [.orange.opacity(0.8), .yellow.opacity(0.8)] : [pattern.accentSecondary.opacity(0.6), pattern.accent.opacity(0.6)],
                                                        startPoint: .leading, endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: CGFloat(k) * (250.0 / CGFloat(array.count)), height: 20)
                                            Spacer()
                                        }
                                        .frame(width: 250)
                                        
                                        Text("sum=\(hist.sum) \(hist.isBest ? "★" : "")")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color(white: 0.8))
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    
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
                    .padding(.top, 16)
                }
            }
        }
    }
    
    private var resetButton: some View {
        Button(action: resetAll) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(white: 0.7))
                .frame(width: 56, height: 56)
                .background(boxBg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Key Insight Area
    private var keyInsightArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.pages")
                Text("KEY INSIGHT")
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .tracking(1.5)
            .foregroundColor(Color(white: 0.6))
            
            Text("Instead of recalculating the sum of \(k) elements from scratch every time (which takes O(k * n) time), we simply subtract the element leaving the window and add the element entering it. This reduces time complexity to O(n).")
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
    
    // MARK: - Logic
    
    private func currentWindowSum() -> Int {
        guard let s = windowStart, let e = windowEnd else { return 0 }
        return array[s...e].reduce(0, +)
    }
    
    private func handleTap(_ index: Int) {
        if phase == .anchor {
            if index == 0 {
                withAnimation(.spring()) {
                    windowStart = 0
                    windowEnd = 0
                    bestSum = currentWindowSum()
                    phase = .expand
                }
            } else {
                withAnimation(.default) {
                    shakeTriggers[index, default: 0] += 1
                }
            }
        } else if phase == .expand {
            let expectedNext = (windowEnd ?? 0) + 1
            if index == expectedNext {
                withAnimation(.spring()) {
                    windowEnd = index
                    let len = (windowEnd ?? 0) - (windowStart ?? 0) + 1
                    if len == k {
                        bestSum = currentWindowSum()
                        windowHistory.append((start: windowStart ?? 0, end: windowEnd ?? 0, sum: bestSum, isBest: true))
                        phase = .slide
                    }
                }
            } else {
                withAnimation(.default) {
                    shakeTriggers[index, default: 0] += 1
                }
            }
        }
    }
    
    private func slideRight() {
        guard let s = windowStart, let e = windowEnd else { return }
        
        let nextStart = s + 1
        let nextEnd = e + 1
        
        if nextEnd < array.count {
            previousStartVal = array[s]
            nextEndVal = array[nextEnd]
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                windowStart = nextStart
                windowEnd = nextEnd
                let newSum = currentWindowSum()
                
                isNewBest = newSum > bestSum
                if isNewBest {
                    bestSum = newSum
                    // Mark previous history as not best
                    for i in 0..<windowHistory.count {
                        windowHistory[i].isBest = false
                    }
                }
                
                windowHistory.append((start: nextStart, end: nextEnd, sum: newSum, isBest: isNewBest))
            }
        } else {
            withAnimation {
                phase = .success
            }
        }
    }
    
    // triggerShake removed
    
    private func resetAll() {
        withAnimation(.easeInOut) {
            windowStart = nil
            windowEnd = nil
            bestSum = 0
            previousStartVal = nil
            nextEndVal = nil
            windowHistory.removeAll()
            isNewBest = false
            phase = .intro
        }
    }
    
    private func randomizeData() {
        withAnimation(.easeInOut) {
            // Generate 8-16 array
            let targetCount = Int.random(in: 8...16)
            array = (0..<targetCount).map { _ in Int.random(in: 1...10) }
            
            // Randomize fixed window K guaranteed to fit
            k = Int.random(in: 2...min(4, array.count)) // Ensure k fits within the new array
            
            // Reset all state variables to initial state for the new array
            windowStart = nil
            windowEnd = nil
            bestSum = 0
            previousStartVal = nil
            nextEndVal = nil
            windowHistory.removeAll()
            isNewBest = false
            phase = .intro
        }
    }
}
