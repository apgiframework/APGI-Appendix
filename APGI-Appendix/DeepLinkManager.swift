import Foundation

class DeepLinkManager {
  static let shared = DeepLinkManager()

  private init() {}

  func createURL(for tab: Tab) -> URL? {
    var components = URLComponents()
    components.scheme = "apgi-appendix"
    components.host = "content"
    components.queryItems = [
      URLQueryItem(name: "section", value: tab.rawValue)
    ]
    return components.url
  }

  func parseTab(from url: URL) -> Tab? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme == "apgi-appendix",
      components.host == "content",
      let tabIdentifier = components.queryItems?.first(where: { $0.name == "section" })?.value
    else {
      return nil
    }

    return Tab.allCases.first(where: { $0.rawValue == tabIdentifier })
  }
}
