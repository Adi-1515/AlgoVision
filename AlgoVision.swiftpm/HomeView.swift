import SwiftUI

struct HomeView: View {

    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var isCompact: Bool { hSizeClass == .compact }

    private var columns: [GridItem] {
        isCompact
            ? [GridItem(.flexible(), spacing: 20)]
            : [GridItem(.flexible(), spacing: 40), GridItem(.flexible(), spacing: 40)]
    }

    @State private var selectedPattern: AlgoPattern?
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompact ? 40 : 52) {
                        HeaderSection(isCompact: isCompact)
                            .frame(maxWidth: .infinity)

                        LazyVGrid(columns: columns, spacing: 40) {
                            ForEach(patterns) { pattern in
                                PatternCard(pattern: pattern, isCompact: isCompact, animation: animation)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            selectedPattern = pattern
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, isCompact ? 20 : 40)
                    .padding(.top, isCompact ? 72 : 88)
                    .padding(.bottom, 80)
                    .frame(maxWidth: 1100, alignment: .center)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedPattern != nil },
                set: { if !$0 { selectedPattern = nil } }
            )) {
                if let pattern = selectedPattern {
                    PatternDetailView(pattern: pattern, animation: animation, selectedPattern: $selectedPattern)
                        .navigationBarBackButtonHidden(true)
                }
            }
            .selectionHapticIfAvailable(trigger: selectedPattern)
        }
    }
}

struct HeaderSection: View {
    let isCompact: Bool

    @State private var glowPulse = false

    var body: some View {
        VStack(alignment: .center, spacing: isCompact ? 16 : 20) {
            HStack(spacing: 10) {
                Text("✦")
                    .font(.system(size: isCompact ? 10 : 15, weight: .thin, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.75))
                Text("INTERACTIVE LEARNING LAB")
                    .font(.system(size: isCompact ? 10 : 15, weight: .thin, design: .monospaced))
                    .tracking(isCompact ? 3 : 5)
                    .foregroundColor(.cyan.opacity(0.75))
                Text("✦")
                    .font(.system(size: isCompact ? 10 : 15, weight: .thin, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.75))
            }
            
            Text("VisionAlgo")
                .font(.system(size: isCompact ? 48 : 72, weight: .bold, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.65, green: 0.25, blue: 1.0),
                            Color(red: 1.0, green: 0.35, blue: 0.75)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color(red: 0.65, green: 0.25, blue: 1.0).opacity(glowPulse ? 0.55 : 0.3), radius: glowPulse ? 22 : 14)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }
                }
            
            Text("Master algorithm patterns through animated walkthroughs.\nNo code, just intuition.")
                .font(.system(size: isCompact ? 15 : 21, weight: .regular))
                .foregroundColor(Color(white: 0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
        }
        .padding(.horizontal, isCompact ? 8 : 0)
    }
}

struct PatternCard: View {
    let pattern: AlgoPattern
    let isCompact: Bool
    var animation: Namespace.ID

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            pattern.accent.opacity(0.13),
                            Color(red: 0.04, green: 0.05, blue: 0.10).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .matchedGeometryEffect(id: "bg-\(pattern.id)", in: animation)
            
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            pattern.accent.opacity(0.9),
                            pattern.accentSecondary.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )

            // Glow shadow layer
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(pattern.accent.opacity(0.35), lineWidth: 6)
                .blur(radius: 8)

            // Card content
            VStack(alignment: .leading, spacing: 0) {

                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(pattern.accent.opacity(0.18))
                        .frame(width: 58, height: 58)
                        .shadow(color: pattern.accent.opacity(0.5), radius: 12, x: 0, y: 4)

                    Image(systemName: pattern.icon)
                        .font(.system(size: isCompact ? 22 : 25, weight: .semibold))
                        .foregroundColor(pattern.accent)
                        .shadow(color: pattern.accent.opacity(0.8), radius: 6)
                }
                .matchedGeometryEffect(id: "icon-\(pattern.id)", in: animation)

                Spacer(minLength: isCompact ? 18 : 24)

                // Title
                Text(pattern.title)
                    .font(.system(size: isCompact ? 20 : 25, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 6)

                // Subtitle
                Text(pattern.subtitle)
                    .font(.system(size: isCompact ? 13 : 17, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: isCompact ? 20 : 26)

                // Explore CTA
                HStack(spacing: 5) {
                    Text("EXPLORE")
                        .font(.headline) // Using dynamic type
                        .foregroundColor(pattern.accent.opacity(1.0)) // Max opacity for better contrast

                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(pattern.accent.opacity(1.0)) // Max opacity for better contrast
                }
            }
            .padding(isCompact ? 24 : 32)
        }
        .frame(height: isCompact ? 210 : 240)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .shadow(color: pattern.accent.opacity(isPressed ? 0.45 : 0.15), radius: isPressed ? 24 : 12, x: 0, y: isPressed ? 12 : 6)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .contentShape(RoundedRectangle(cornerRadius: 28))
        .impactHapticIfAvailable(trigger: isPressed)
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: 50,
            pressing: { pressing in isPressed = pressing },
            perform: {}
        )
        .accessibilityLabel("\(pattern.title): \(pattern.subtitle)")
        .accessibilityHint("Explore this algorithm pattern")
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.13),
                    Color(red: 0.02, green: 0.02, blue: 0.07)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            GridOverlay()
            
            RadialGradient(
                colors: [
                    Color(red: 0.45, green: 0.15, blue: 0.85).opacity(0.28),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 520
            )
            
            RadialGradient(
                colors: [
                    Color(red: 0.0, green: 0.75, blue: 0.65).opacity(0.2),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 480
            )
        }
        .ignoresSafeArea()
    }
}

struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 56
                var x: CGFloat = 0
                while x <= geo.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y <= geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += spacing
                }
            }
            .stroke(Color.white.opacity(0.032), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}


extension View {
    @ViewBuilder
    func selectionHapticIfAvailable<T: Equatable>(trigger: T) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.selection, trigger: trigger)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func impactHapticIfAvailable<T: Equatable>(trigger: T) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.impact(flexibility: .solid, intensity: 0.8), trigger: trigger)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func successHapticIfAvailable<T: Equatable>(trigger: T) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.success, trigger: trigger)
        } else {
            self
        }
    }
}
