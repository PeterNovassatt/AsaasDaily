import SwiftUI

/// Como os cards da pessoa aparecem. Lista rende mais em densidade; quadro espelha
/// o board do Jira. Cada um serve um momento da daily, então o usuário escolhe.
enum CardsViewMode: String, CaseIterable, Identifiable {
    case list, board

    var id: String { rawValue }

    var label: String {
        switch self {
        case .list: "Lista"
        case .board: "Quadro"
        }
    }

    var symbol: String {
        switch self {
        case .list: "list.bullet"
        case .board: "rectangle.split.3x1"
        }
    }
}
