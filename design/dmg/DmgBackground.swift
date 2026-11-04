// Fundo da janela do instalador (.dmg): o app à esquerda, a pasta Aplicativos à direita e a seta
// entre eles. Mesma paleta do ícone (scripts/make-icon.swift).
// Uso: swift design/dmg/DmgBackground.swift <pasta-de-saída>  (o build-dmg.sh roda isto e junta 1x e 2x num .tiff)
import AppKit
import SwiftUI

let navyDeep = Color(red: 0, green: 23 / 255, blue: 80 / 255)   // #001750
let brand = Color(red: 0, green: 56 / 255, blue: 229 / 255)     // #0038E5, o azul do Atlas
let brandLit = Color(red: 46 / 255, green: 107 / 255, blue: 1)  // #2E6BFF

/// Tamanho da janela e posição dos ícones; o build-dmg.sh usa os mesmos números no Finder.
enum Layout {
    static let size = CGSize(width: 660, height: 400)
    static let appCenter = CGPoint(x: 170, y: 220)
    static let applicationsCenter = CGPoint(x: 490, y: 220)
    static let iconSize: CGFloat = 128
}

/// A roda do ícone — oito pessoas em círculo, a de cima com o anel de quem está falando —
/// em marca d'água no canto.
struct WheelWatermark: View {
    private static let count = 8

    var body: some View {
        ZStack {
            ForEach(0..<Self.count, id: \.self) { index in
                let angle = Angle.degrees(Double(index) / Double(Self.count) * 360 - 90)
                let isSpeaking = index == 0
                let point = CGPoint(x: cos(angle.radians) * 46, y: sin(angle.radians) * 46)

                Circle()
                    .fill(.white.opacity(isSpeaking ? 0.14 : 0.07))
                    .frame(width: 14, height: 14)
                    .overlay {
                        if isSpeaking {
                            Circle().stroke(.white.opacity(0.15), lineWidth: 3).frame(width: 24, height: 24)
                        }
                    }
                    .offset(x: point.x, y: point.y)
            }
        }
        // Canto superior direito: o único espaço livre da janela, longe dos ícones e do rodapé.
        .position(x: 566, y: 86)
    }
}

/// Conexão entre o app e a pasta: pontos que crescem e clareiam até a ponta.
struct InstallArrow: View {
    private static let dotCount = 7

    var body: some View {
        let startX = Layout.appCenter.x + 96
        let endX = Layout.applicationsCenter.x - 104
        let y = Layout.appCenter.y
        let step = (endX - startX) / CGFloat(Self.dotCount)

        ZStack {
            ForEach(0..<Self.dotCount, id: \.self) { index in
                let progress = CGFloat(index) / CGFloat(Self.dotCount - 1)
                Circle()
                    .fill(brandLit.opacity(0.35 + 0.65 * progress))
                    .frame(width: 6 + 4 * progress, height: 6 + 4 * progress)
                    .position(x: startX + step * CGFloat(index), y: y)
            }

            Path { path in
                path.move(to: CGPoint(x: endX - 6, y: y - 14))
                path.addLine(to: CGPoint(x: endX + 8, y: y))
                path.addLine(to: CGPoint(x: endX - 6, y: y + 14))
            }
            .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }
    }
}

/// Plaquinha clara sob cada ícone: o Finder escreve o nome em preto, ilegível direto no fundo escuro.
struct LabelPlate: View {
    var center: CGPoint

    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .frame(width: 132, height: 24)
            .position(x: center.x, y: center.y + Layout.iconSize / 2 + 20)
    }
}

struct DmgBackground: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [navyDeep, Color(red: 0, green: 10 / 255, blue: 46 / 255)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            RadialGradient(colors: [brand.opacity(0.5), .clear],
                           center: .init(x: 0.5, y: 0.62), startRadius: 10, endRadius: 330)

            WheelWatermark()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text("Asaas").font(.system(size: 34, weight: .heavy, design: .rounded))
                    Text(" Daily").font(.system(size: 34, weight: .regular, design: .rounded))
                }
                .foregroundStyle(.white)
                Text("A daily do time, com os cards do Jira na tela · Asaas")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(brandLit)
            }
            .padding(.leading, 40)
            .padding(.top, 30)

            InstallArrow()

            LabelPlate(center: Layout.appCenter)
            LabelPlate(center: Layout.applicationsCenter)

            Text("Arraste o AsaasDaily para a pasta Aplicativos")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: Layout.size.width)
                .position(x: Layout.size.width / 2, y: Layout.size.height - 22)
        }
        .frame(width: Layout.size.width, height: Layout.size.height)
    }
}

@MainActor
func render(scale: CGFloat, to url: URL) throws {
    let renderer = ImageRenderer(content: DmgBackground().environment(\.colorScheme, .dark))
    renderer.scale = scale
    guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
    let bitmap = NSBitmapImageRep(cgImage: image)
    bitmap.size = Layout.size
    guard let data = bitmap.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
    try data.write(to: url)
}

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
try MainActor.assumeIsolated {
    try render(scale: 1, to: output.appendingPathComponent("background.png"))
    try render(scale: 2, to: output.appendingPathComponent("background@2x.png"))
}
print(output.path)
