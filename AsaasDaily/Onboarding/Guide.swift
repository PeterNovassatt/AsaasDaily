import SwiftUI

/// As duas telas de onboarding, apresentadas pela mesma folha.
enum OnboardingSheet: String, Identifiable {
    case setup, guide
    var id: String { rawValue }
}

/// Desenho que acompanha cada passo do guia, montado com as mesmas peças que a pessoa
/// vai reencontrar no app — não é screenshot, é o componente de verdade.
enum GuideIllustration: Equatable {
    case queue
    case cards
    case shortcuts
}

struct GuideStep: Identifiable, Equatable {
    let title: String
    let body: String
    let symbol: String
    let illustration: GuideIllustration

    var id: String { title }
}

/// Guia de três passos: aparece no fim do setup e de novo pelo menu Ajuda.
enum Guide {
    static let steps: [GuideStep] = [
        GuideStep(
            title: "A fila se monta sozinha",
            body: "Quem tem card em code review fala primeiro, depois quem está com algo em progresso; o resto entra sorteado. Ninguém precisa lembrar de quem é a vez.",
            symbol: "person.2.wave.2",
            illustration: .queue
        ),
        GuideStep(
            title: "Os cards vêm do Jira na hora",
            body: "Cada pessoa aparece com o que tem em aberto, em lista ou em quadro. A bandeira vermelha é impedimento marcado no Jira; a estrela é o card que trouxe a pessoa para esta posição na fila.",
            symbol: "rectangle.stack",
            illustration: .cards
        ),
        GuideStep(
            title: "Conduza sem soltar o teclado",
            body: "As setas avançam e voltam, ⌘K manda para o fim da fila e ⇧⌘P abre a apresentação em tela cheia — a tela para espelhar na reunião, com o texto grande.",
            symbol: "keyboard",
            illustration: .shortcuts
        ),
    ]
}

// MARK: - Ilustrações

struct GuideIllustrationView: View {
    let illustration: GuideIllustration

    var body: some View {
        switch illustration {
        case .queue: QueueIllustration()
        case .cards: CardsIllustration()
        case .shortcuts: ShortcutsIllustration()
        }
    }
}

/// A fila do sidebar: quem fala agora em destaque, os próximos abaixo.
private struct QueueIllustration: View {
    @State private var isSpeaking = false

    private let rows: [(initials: String, reason: String, status: String)] = [
        ("MR", "Em code review", "code review"),
        ("TL", "Em progresso", "in progress"),
        ("CF", "Sorteado", "to do"),
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(.quaternary)
                        Text(row.initials)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 28, height: 28)
                    .overlay {
                        if index == 0 {
                            Circle().strokeBorder(Color.accentColor, lineWidth: 2)
                                .scaleEffect(isSpeaking ? 1.18 : 1)
                                .opacity(isSpeaking ? 0 : 1)
                        }
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(index == 0 ? "Falando agora" : "Na fila")
                            .font(.system(size: 12, weight: .medium))
                        Label(row.reason, systemImage: StatusPalette.symbol(row.status))
                            .font(.system(size: 10))
                            .foregroundStyle(StatusPalette.accent(row.status))
                    }

                    Spacer()

                    if index == 0 {
                        Image(systemName: "waveform")
                            .foregroundStyle(Color.accentColor)
                            .symbolEffect(.variableColor.iterative, options: .repeating)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    index == 0 ? AnyShapeStyle(Color.accentColor.opacity(0.12)) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            }
        }
        .padding(.horizontal, 48)
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { isSpeaking = true }
        }
    }
}

/// Três linhas de card com os sinais que a daily lê: status, impedimento e card de origem.
private struct CardsIllustration: View {
    var body: some View {
        VStack(spacing: 6) {
            row(symbol: "flag.fill", tint: .red, title: "Integração do webhook parada",
                status: "in progress", pulses: true)
            row(symbol: "star.fill", tint: .orange, title: "Ajuste no extrato de cobranças",
                status: "code review", pulses: false)
            row(symbol: "circle.fill", tint: .secondary, title: "Revisar textos da tela de pix",
                status: "to do", pulses: false)
        }
        .padding(.horizontal, 36)
    }

    private func row(symbol: String, tint: Color, title: String, status: String, pulses: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(symbol == "circle.fill" ? .system(size: 6) : .body)
                .foregroundStyle(tint)
                .symbolEffect(.pulse, options: .repeating, isActive: pulses)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 12))
                .lineLimit(1)

            Spacer()

            Label(status.uppercased(), systemImage: StatusPalette.symbol(status))
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(StatusPalette.accent(status))
                .labelStyle(.titleAndIcon)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// As teclas que conduzem a rodada, desenhadas como teclas.
private struct ShortcutsIllustration: View {
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                key("←", caption: "Voltar")
                key("→", caption: "Próximo")
            }
            HStack(spacing: 10) {
                key("⌘K", caption: "Pular")
                key("⇧⌘P", caption: "Apresentar")
                key("⌘R", caption: "Atualizar")
            }
        }
    }

    private func key(_ label: String, caption: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .frame(minWidth: 46, minHeight: 36)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.quaternary)
                }
            Text(caption)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}
