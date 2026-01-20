import SwiftUI

// Bookmark button with feedback for user actions
struct BookmarkButton: View {
    let tab: Tab
    @StateObject private var bookmarkManager = BookmarkManager()
    @State private var showFeedback = false
    @State private var feedbackMessage = ""

    private var isBookmarked: Bool {
        bookmarkManager.isBookmarked(tab)
    }

    var body: some View {
        Button {
            toggleBookmark()
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(isBookmarked ? .accentColor : .primary)
                .scaleEffect(showFeedback ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: showFeedback)
        }
        .overlay(
            // Feedback toast
            VStack {
                if showFeedback {
                    Text(feedbackMessage)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .offset(y: -30)
                }
                Spacer()
            },
            alignment: .top
        )
        .apgiAccessibility(
            label: isBookmarked ? "Remove bookmark" : "Add bookmark",
            hint: "\(tab.shortTitle) section",
            traits: .isButton
        )
    }

    private func toggleBookmark() {
        if isBookmarked {
            bookmarkManager.removeBookmark(tab)
        } else {
            bookmarkManager.addBookmark(tab)
        }

        // Show feedback animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showFeedback = true
            feedbackMessage = bookmarkManager.lastAction?.message ?? ""
        }

        // Hide feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFeedback = false
            }
        }
    }
}
