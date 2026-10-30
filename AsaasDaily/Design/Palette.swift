import SwiftUI

/// Cor aqui só existe quando carrega informação. Superfícies, textos e separadores
/// ficam com o sistema (`.secondary`, `.quaternary`, materiais), como no AsaasDeck —
/// é o que mantém o app parecido com o resto do macOS em qualquer aparência.
///
/// A cor da marca entra uma vez só, no AccentColor do asset catalog
/// (`#0038E5` do Atlas no claro, `#5B8DFF` no escuro), e daí o sistema a espalha
/// pelos controles sozinho.
enum StatusPalette {

    /// Nove status convivem no board: a cor é o que permite reconhecer a coluna sem
    /// ler. Os tons saem das semânticas do Atlas, afastados entre si o bastante
    /// para não se confundirem.
    private static let colors: [String: Color] = [
        "code review":    .orange,
        "in progress":    .green,
        "to do":          .blue,
        "backlog":        .secondary,
        "in refinement":  .purple,
        "in preparation": .teal,
        "prioritized":    .pink,
        "product review": .indigo,
        "rollout":        .mint
    ]

    static func accent(_ status: String) -> Color {
        colors[status.lowercased()] ?? .secondary
    }

    /// Ícone junto da cor: quem não distingue verde de laranja ainda lê a coluna.
    private static let symbols: [String: String] = [
        "backlog":        "tray.full",
        "in refinement":  "slider.horizontal.3",
        "in preparation": "pencil.and.list.clipboard",
        "prioritized":    "arrow.up.circle",
        "to do":          "circle.dashed",
        "in progress":    "circle.lefthalf.filled",
        "code review":    "chevron.left.forwardslash.chevron.right",
        "product review": "eye.circle",
        "rollout":        "shippingbox"
    ]

    static func symbol(_ status: String) -> String {
        symbols[status.lowercased()] ?? "circle"
    }
}
