import SwiftUI

/// Escala do texto do app. Numa daily projetada, aumentar a fonte é rotina —
/// aqui isso passa pelo Dynamic Type do próprio SwiftUI, não por tamanhos à mão.
enum TextScale: Int, CaseIterable, Identifiable {
    case padrao = 0, grande, maior, maximo

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .padrao: "Padrão"
        case .grande: "Grande"
        case .maior: "Maior"
        case .maximo: "Máximo"
        }
    }

    /// Multiplicador aplicado a cada fonte. O macOS não escala texto sozinho.
    var factor: CGFloat {
        switch self {
        case .padrao: 1.0
        case .grande: 1.15
        case .maior: 1.3
        case .maximo: 1.5
        }
    }

    var canIncrease: Bool { self != .maximo }
    var canDecrease: Bool { self != .padrao }

    func increased() -> TextScale { TextScale(rawValue: rawValue + 1) ?? self }
    func decreased() -> TextScale { TextScale(rawValue: rawValue - 1) ?? self }
}
