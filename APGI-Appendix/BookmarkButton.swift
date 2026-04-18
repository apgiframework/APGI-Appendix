import SwiftUI

/// Bookmark button with feedback for user actions
struct BookmarkButton: View {
  let tab: Tab
  @EnvironmentObject private var bookmarkManager: BookmarkManager
  @State private var showFeedback = false
  @State private var feedbackMessage = ""

  private var isBookmarked: Bool {
    self.bookmarkManager.isBookmarked(self.tab)
  }

  var body: some View {
    Button {
      self.toggleBookmark()
    } label: {
      Image(systemName: self.isBookmarked ? "bookmark.fill" : "bookmark")
        .foregroundColor(self.isBookmarked ? .accentColor : .primary)
        .scaleEffect(self.showFeedback ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: self.showFeedback)
    }
    .overlay(
      // Feedback toast
      VStack {
        if self.showFeedback {
          Text(self.feedbackMessage)
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
    .contextMenu {
      if self.isBookmarked {
        Button("Remove Bookmark") {
          self.bookmarkManager.removeBookmark(self.tab)
          // Show feedback animation
          withAnimation(.easeInOut(duration: 0.3)) {
            self.feedbackMessage = "Bookmark removed"
            self.showFeedback = true
          }

          // Hide feedback after delay
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
              self.showFeedback = false
            }
          }
        }
      }
    }
    .apgiAccessibility(
      label: self.isBookmarked ? "Remove bookmark" : "Add bookmark",
      hint: "\(self.tab.shortTitle) section",
      traits: .isButton
    )
  }

  private func toggleBookmark() {
    if self.isBookmarked {
      self.bookmarkManager.removeBookmark(self.tab)
    } else {
      self.bookmarkManager.addBookmark(self.tab)
    }

    // Show feedback animation
    withAnimation(.easeInOut(duration: 0.3)) {
      self.showFeedback = true
      self.feedbackMessage = self.bookmarkManager.lastAction?.message ?? ""
    }

    // Hide feedback after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      withAnimation(.easeInOut(duration: 0.3)) {
        self.showFeedback = false
      }
    }
  }
}
