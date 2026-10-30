import SwiftUI

/// Aparência escolhida no app. "Sistema" segue o macOS; as outras forçam.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Sistema"
        case .light: "Claro"
        case .dark: "Escuro"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// Alterna claro ↔ escuro; a partir de "Sistema" vai para o oposto do que está valendo.
    func toggled(systemIsDark: Bool) -> AppAppearance {
        switch self {
        case .light: .dark
        case .dark: .light
        case .system: systemIsDark ? .light : .dark
        }
    }
}
