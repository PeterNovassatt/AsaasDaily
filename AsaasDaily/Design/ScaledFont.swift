import SwiftUI

/// O macOS não tem Dynamic Type — `.dynamicTypeSize` existe na API porque ela é
/// multiplataforma, mas não muda nada aqui. Para o app poder aumentar o texto numa
/// daily projetada, a escala viaja pelo ambiente e cada fonte é calculada a partir
/// do tamanho nominal do estilo.
private struct FontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var fontScale: CGFloat {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }
}

struct ScaledFont: ViewModifier {
    @Environment(\.fontScale) private var scale

    var style: Font.TextStyle?
    var size: CGFloat?
    var weight: Font.Weight?
    var design: Font.Design?

    /// Tamanhos nominais dos estilos no macOS.
    private static let sizes: [Font.TextStyle: CGFloat] = [
        .largeTitle: 26, .title: 22, .title2: 17, .title3: 15, .headline: 13,
        .body: 13, .callout: 12, .subheadline: 11, .footnote: 10,
        .caption: 10, .caption2: 10
    ]

    func body(content: Content) -> some View {
        let base = size ?? style.flatMap { Self.sizes[$0] } ?? 13
        return content.font(.system(size: base * scale, weight: weight, design: design))
    }
}

extension View {
    func scaledFont(_ style: Font.TextStyle,
                    weight: Font.Weight? = nil,
                    design: Font.Design? = nil) -> some View {
        modifier(ScaledFont(style: style, weight: weight, design: design))
    }

    func scaledFont(size: CGFloat,
                    weight: Font.Weight? = nil,
                    design: Font.Design? = nil) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design))
    }
}
