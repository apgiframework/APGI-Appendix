import SwiftUI

// MARK: - Feature Spotlight
struct FeatureSpotlight: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.1))
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
    }

    @State private var isVisible = false

    func onAppear() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
            isVisible = true
        }
    }
}

// MARK: - Tour Target
enum TourTarget: CaseIterable {
    case sidebar
    case search
    case content
    case toolbar
    case settings
    case simulator
    case timeline
    case bookmarks

    var name: String {
        switch self {
        case .sidebar: return "Sidebar"
        case .search: return "Search"
        case .content: return "Content"
        case .toolbar: return "Toolbar"
        case .settings: return "Settings"
        case .simulator: return "APGI Simulator"
        case .timeline: return "Timeline"
        case .bookmarks: return "Bookmarks"
        }
    }

    var description: String {
        switch self {
        case .sidebar: return "Navigation sidebar for sections"
        case .search: return "Search functionality"
        case .content: return "Main content area"
        case .toolbar: return "Top toolbar with actions"
        case .settings: return "Settings and preferences"
        case .simulator: return "Interactive neural simulator"
        case .timeline: return "Ignition timeline view"
        case .bookmarks: return "Saved bookmarks"
        }
    }

    var icon: String {
        switch self {
        case .sidebar: return "sidebar.left"
        case .search: return "magnifyingglass"
        case .content: return "doc.text"
        case .toolbar: return "toolbar"
        case .settings: return "gear"
        case .simulator: return "chart.line.uptrend.xyaxis"
        case .timeline: return "timeline.selection"
        case .bookmarks: return "bookmark"
        }
    }
}

// MARK: - Tooltip Position
enum TooltipPosition {
    case top
    case bottom
    case leading
    case trailing
    case center
}

// MARK: - Tour Step
struct TourStep: Identifiable {
    let id = UUID()
    let target: TourTarget
    let title: String
    let description: String
    let position: TooltipPosition
    let highlightColor: Color
    let action: (() -> Void)?

    init(
        target: TourTarget,
        title: String,
        description: String,
        position: TooltipPosition,
        highlightColor: Color = .blue,
        action: (() -> Void)? = nil
    ) {
        self.target = target
        self.title = title
        self.description = description
        self.position = position
        self.highlightColor = highlightColor
        self.action = action
    }
}

#Preview {
    VStack(spacing: 20) {
        FeatureSpotlight(
            title: "Enhanced Navigation",
            description: "Quick access to all sections",
            icon: "sidebar.leading",
            color: .blue
        )

        FeatureSpotlight(
            title: "Interactive Simulator",
            description: "Real-time neural modeling",
            icon: "chart.line.uptrend.xyaxis",
            color: .teal
        )
    }
    .padding()
}
