import SwiftUI

enum SectionCategory: String, CaseIterable, Hashable {
  case navigation = "Demonstrations"
  case theoretical = "Theoretical Foundation"
  case mathematical = "Mathematical Framework"
  case biological = "Biological Implementation"
  case cognitive = "Cognitive Integration"
  case applications = "Applications & Extensions"
  case reference = "Reference Materials"
}

extension SectionCategory {
  var icon: String {
    switch self {
    case .navigation: return "location"
    case .theoretical: return "lightbulb.fill"
    case .mathematical: return "function"
    case .biological: return "brain.head.profile"
    case .cognitive: return "brain"
    case .applications: return "stethoscope"
    case .reference: return "books.vertical.fill"
    }
  }

  var color: Color {
    switch self {
    case .navigation: return .workspacePurple
    case .theoretical: return .thresholdBlue
    case .mathematical: return .errorYellow
    case .biological: return .neuromodGreen
    case .cognitive: return .inactiveSlate
    case .applications: return .precisionRed
    case .reference: return .secondary
    }
  }

  var sections: [Tab] {
    Tab.allCases.filter { $0.category == self }
  }
}
