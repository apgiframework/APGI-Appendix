import SwiftUI

/// Standardized SF Symbols for consistent UI across the app
enum SFSymbols {
    // MARK: - Navigation & Actions

    static let search = "magnifyingglass"
    static let bookmark = "bookmark"
    static let bookmarkFill = "bookmark.fill"
    static let back = "chevron.left"
    static let forward = "chevron.right"
    static let close = "xmark"
    static let closeCircleFill = "xmark.circle.fill"
    static let add = "plus"
    static let remove = "minus"
    static let edit = "pencil"
    static let delete = "trash"
    static let share = "square.and.arrow.up"
    static let copy = "doc.on.doc"
    static let export = "arrow.up.doc"
    static let `import` = "arrow.down.doc"

    // MARK: - Content & Display

    static let focus = "eye"
    static let focusOff = "eye.slash"
    static let focusMode = "arrow.up.left.and.arrow.down.right"
    static let zoomIn = "plus.magnifyingglass"
    static let zoomOut = "minus.magnifyingglass"
    static let fontSize = "textformat.size"
    static let theme = "circle.lefthalf.filled"
    static let appearance = "paintpalette"
    static let accessibility = "figure.walk"

    // MARK: - Media & Playback

    static let play = "play.fill"
    static let pause = "pause.fill"
    static let stop = "stop.fill"
    static let replay = "arrow.counterclockwise"
    static let speed = "speedometer"
    static let timeline = "timeline.selection"

    // MARK: - Status & Connection

    static let online = "wifi"
    static let offline = "wifi.slash"
    static let connected = "checkmark.circle.fill"
    static let disconnected = "xmark.circle.fill"
    static let loading = "circle.grid.3x3.fill"
    static let refresh = "arrow.clockwise"

    // MARK: - Content Types

    static let document = "doc"
    static let text = "text.book.closed"
    static let image = "photo"
    static let video = "video"
    static let audio = "waveform"
    static let code = "chevron.left.slash.chevron.right"
    static let table = "tablecells"
    static let chart = "chart.bar"
    static let graph = "point.3.connected.trianglepath.dotted"

    // MARK: - Categories & Sections

    static let methodology = "brain.head.profile"
    static let biological = "leaf"
    static let theoretical = "atom"
    static let applications = "cross.case"
    static let glossary = "character.book.closed"
    static let bibliography = "books.vertical"
    static let simulator = "cpu"

    // MARK: - UI Controls

    static let menu = "line.horizontal.3"
    static let sidebar = "sidebar.left"
    static let sidebarRight = "sidebar.right"
    static let inspector = "sidebar.squares.left"
    static let settings = "gear"
    static let help = "questionmark.circle"
    static let info = "info.circle"
    static let warning = "exclamationmark.triangle"
    static let error = "exclamationmark.octagon"

    // MARK: - Semantic Actions

    static let confirm = "checkmark"
    static let cancel = "xmark"
    static let accept = "checkmark.circle"
    static let decline = "xmark.circle"
    static let favorite = "heart"
    static let favoriteFill = "heart.fill"
    static let star = "star"
    static let starFill = "star.fill"

    // MARK: - System Integration

    static let notifications = "bell"
    static let notificationsOff = "bell.slash"
    static let keyboard = "keyboard"
    static let mouse = "cursorarrow"
    static let touch = "hand.point.up.left"
    static let voice = "mic"
    static let haptic = "waveform"
}

// MARK: - Accessibility Helpers

extension Image {
    /// Create an SF Symbol image with standardized accessibility
    static func sfSymbol(
        _ symbol: String,
        label: String? = nil,
        hint: String? = nil
    ) -> some View {
        Image(systemName: symbol)
            .accessibilityLabel(label ?? symbol.replacingOccurrences(of: ".", with: " "))
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Semantic Symbol Groups

extension SFSymbols {
    /// Symbols for different content states
    enum ContentState {
        case loading, empty, error, success

        var symbol: String {
            switch self {
            case .loading: return SFSymbols.loading
            case .empty: return "tray"
            case .error: return SFSymbols.error
            case .success: return "checkmark.circle"
            }
        }

        var defaultLabel: String {
            switch self {
            case .loading: return "Loading"
            case .empty: return "No content"
            case .error: return "Error occurred"
            case .success: return "Success"
            }
        }
    }

    /// Symbols for navigation actions
    enum Navigation {
        case back, forward, up, down, home

        var symbol: String {
            switch self {
            case .back: return SFSymbols.back
            case .forward: return SFSymbols.forward
            case .up: return "chevron.up"
            case .down: return "chevron.down"
            case .home: return "house"
            }
        }
    }

    /// Symbols for user actions
    enum Action {
        case create, read, update, delete, share, bookmark, favorite

        var symbol: String {
            switch self {
            case .create: return SFSymbols.add
            case .read: return "eye"
            case .update: return SFSymbols.edit
            case .delete: return SFSymbols.delete
            case .share: return SFSymbols.share
            case .bookmark: return SFSymbols.bookmark
            case .favorite: return SFSymbols.favorite
            }
        }
    }
}

// MARK: - Usage Examples (for documentation)

/*
 // Instead of inconsistent usage like:
 Image(systemName: "magnifyingglass") // in one place
 Image(systemName: "search") // in another place

 // Use standardized symbols:
 Image(systemName: SFSymbols.search)

 // With accessibility:
 Image.sfSymbol(SFSymbols.search, label: "Search content", hint: "Find information in the app")

 // Semantic usage:
 let stateSymbol = SFSymbols.ContentState.loading.symbol
 let navSymbol = SFSymbols.Navigation.back.symbol
 let actionSymbol = SFSymbols.Action.bookmark.symbol
 */
