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
        case .navigation: return .accentColor
        case .theoretical: return .apgiBlue
        case .mathematical: return .apgiPurple
        case .biological: return .apgiGreen
        case .cognitive: return .apgiOrange
        case .applications: return .apgiRed
        case .reference: return .gray
        }
    }
    
    var sections: [Tab] {
        NavigationSection.allCases.first { $0.tabs.contains(where: { $0.category == self }) }?.tabs ?? []
    }
}
