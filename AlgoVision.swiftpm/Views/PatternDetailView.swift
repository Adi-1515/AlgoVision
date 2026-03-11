import SwiftUI

struct PatternDetailView: View {
    let pattern: AlgoPattern
    var animation: Namespace.ID
    @Binding var selectedPattern: AlgoPattern?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0 // 0 for Overview, 1 for Interactive
    @Namespace private var tabAnimation
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    private var isPad: Bool { !isCompact }
    
    var body: some View {
        ZStack {
            // Background Layer uses the exact same `BackgroundView` as HomeView
            BackgroundView()
                .matchedGeometryEffect(id: "bg-\(pattern.id)", in: animation)
            
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 16) {

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(pattern.accent.opacity(0.18))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: pattern.icon)
                            .font(.system(size: isPad ? 23 : 20, weight: .semibold))
                            .foregroundColor(pattern.accent)
                    }
                    .matchedGeometryEffect(id: "icon-\(pattern.id)", in: animation)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PATTERN")
                            .font(.system(size: isPad ? 14 : 11, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.5))
                        
                        Text(pattern.title)
                            .font(.system(size: isPad ? 32 : 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 80)
                .padding(.top, isPad ? 24 : 60)
                
                HStack(spacing: 8) {
                    TabButton(title: "Overview", index: 0, selectedTab: $selectedTab, namespace: tabAnimation)
                    TabButton(title: "Interactive", index: 1, selectedTab: $selectedTab, namespace: tabAnimation)
                }
                .padding(6)
                .background(Color(white: 0.1))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
                .padding(.horizontal, isPad ? 120 : 24)
                .padding(.vertical, 24)
                
                if selectedTab == 0 {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            InfoCard(title: "DESCRIPTION", icon: "doc.text", content: pattern.description, pattern: pattern)
                            InfoCard(title: "CORE IDEA", icon: "lightbulb", content: pattern.coreIdea, pattern: pattern)
                            InfoCard(title: "WHEN TO USE", icon: "target", content: pattern.whenToUse, pattern: pattern)
                            
                            if isCompact {
                                VStack(spacing: 16) {
                                    InfoCard(title: "TIME COMPLEXITY", icon: "clock", content: pattern.timeComplexity, pattern: pattern)
                                    InfoCard(title: "SPACE COMPLEXITY", icon: "memorychip", content: pattern.spaceComplexity, pattern: pattern)
                                }
                            } else {
                                HStack(spacing: 16) {
                                    InfoCard(title: "TIME COMPLEXITY", icon: "clock", content: pattern.timeComplexity, pattern: pattern)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    InfoCard(title: "SPACE COMPLEXITY", icon: "memorychip", content: pattern.spaceComplexity, pattern: pattern)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    interactiveContent(for: pattern)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
                    hapticFeedback.prepare()
                    hapticFeedback.impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedPattern = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(pattern.accent)
                }
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width > 100 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedPattern = nil
                        dismiss()
                    }
                }
            }
        )
    }
    
    @ViewBuilder
    private func interactiveContent(for pattern: AlgoPattern) -> some View {
        switch pattern.type {
        case .binarySearch:
            InteractiveBinarySearchView(pattern: pattern)
        case .twoPointers:
            InteractiveTwoPointersView(pattern: pattern)
        case .slidingWindow:
            InteractiveSlidingWindowView(pattern: pattern)
        case .bfs:
            InteractiveBFSView(pattern: pattern)
        }
    }
}


struct InfoCard: View {
    let title: String
    let icon: String // SF Symbol
    let content: String
    let pattern: AlgoPattern
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    private var isPad: Bool { !isCompact }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: isPad ? 19 : 16, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
                Text(title)
                    .font(.system(size: isPad ? 16 : 13, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(Color(white: 0.5))
            }
            
            Text(content)
                .font(.system(size: isPad ? 20 : 17, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(white: 0.08).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            pattern.accent.opacity(0.7),
                            pattern.accentSecondary.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
    }
}

struct TabButton: View {
    let title: String
    let index: Int
    @Binding var selectedTab: Int
    var namespace: Namespace.ID
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedTab = index
            }
        }) {
            Text(title)
                .font(.system(size: 15, weight: selectedTab == index ? .bold : .medium))
                .foregroundColor(selectedTab == index ? .white : Color(white: 0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if selectedTab == index {
                            Capsule()
                                .fill(Color(white: 0.25))
                                .matchedGeometryEffect(id: "TabBackground", in: namespace)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PatternDetailView_Previews: PreviewProvider {
    @Namespace static var animation
    
    static var previews: some View {
        let sample = AlgoPattern(
            type: .binarySearch,
            title: "Binary Search",
            subtitle: "Divide & Conquer in O(log n)",
            icon: "magnifyingglass",
            accent: Color(red: 0.6, green: 0.3, blue: 1.0),
            accentSecondary: Color(red: 0.8, green: 0.4, blue: 1.0),
            description: "Binary Search is a classic divide-and-conquer algorithm that efficiently locates a target value within a sorted array. By repeatedly halving the search space, it dramatically reduces the number of comparisons needed.",
            coreIdea: "Compare the target with the middle element. If it matches, you're done. If the target is smaller, search the left half. If larger, search the right half. Repeat until found.",
            whenToUse: "Use when searching in a sorted collection. If the data is ordered, you can eliminate half the remaining elements in a single comparison.",
            timeComplexity: "O(log n) – halves the search space each step. ~30 steps for 1 billion items.",
            spaceComplexity: "O(1) iterative, O(log n) recursive – only pointers needed, no extra data structures."
        )
        PatternDetailView(pattern: sample, animation: animation, selectedPattern: .constant(sample))
    }
}
