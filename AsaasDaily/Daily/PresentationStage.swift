import SwiftUI
import AppKit

/// Modo apresentação: sem barra lateral, sem toolbar, a pessoa ocupando a tela.
/// É o que se projeta na sala — legível a três metros.
struct PresentationStage: View {
    let daily: DailyModel
    let participant: Participant
    let namespace: Namespace.ID
    var onExit: () -> Void = {}

    @State private var showsChrome = false

    private var highlights: [JiraIssue] {
        // O que se discute numa daily: review, progresso e o que estiver travado.
        let relevant = participant.codeReviewCards + participant.inProgressCards
        let flagged = participant.flaggedCards.filter { card in
            !relevant.contains { $0.key == card.key }
        }
        return flagged + relevant
    }

    private var remaining: Int { participant.cards.count - highlights.count }

    var body: some View {
        VStack(spacing: 0) {
            ProgressPips(participants: daily.participants,
                         currentId: participant.id,
                         height: 7, width: 30, spacing: 7)
                .padding(.top, 26)
                .padding(.bottom, 34)

            HStack(spacing: 26) {
                Avatar(person: participant.person, size: 128)
                    .matchedGeometryEffect(id: participant.id, in: namespace)
                    .overlay { Circle().strokeBorder(Color.accentColor, lineWidth: 3) }

                VStack(alignment: .leading, spacing: 8) {
                    Text(participant.name)
                        .scaledFont(size: 64, weight: .bold)
                        .matchedGeometryEffect(id: "name-\(participant.id)", in: namespace)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(participant.cardSummary)
                        .scaledFont(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    Pill(count: participant.codeReviewCards.count, label: "em review",
                         color: StatusPalette.accent("code review"))
                    Pill(count: participant.inProgressCards.count, label: "em progresso",
                         color: StatusPalette.accent("in progress"))
                    Pill(count: participant.flaggedCards.count, label: "com flag",
                         color: Color.red)
                }
            }
            .padding(.horizontal, 56)

            cards
                .padding(.horizontal, 56)
                .padding(.top, 34)

            Spacer(minLength: 0)

            footer
                .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) { exitButton }
        .onHover { showsChrome = $0 }
        .background {
            // Fundo do sistema com um véu da cor de marca: dá profundidade na
            // projeção sem trocar a aparência do app por uma pintura própria.
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                Color.accentColor.opacity(0.22), Color.accentColor.opacity(0.10), Color.accentColor.opacity(0.14),
                Color.accentColor.opacity(0.06), .clear, .clear,
                .clear, .clear, Color.accentColor.opacity(0.08)
            ])
            .background(.background)
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var cards: some View {
        if highlights.isEmpty {
            Text("Sem cards em review ou em progresso")
                .scaledFont(.title3)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320, maximum: 520), spacing: 14)],
                      alignment: .leading, spacing: 14) {
                ForEach(highlights.prefix(6)) { issue in
                    StageCard(issue: issue)
                        .transition(.blurReplace)
                }

                if remaining > 0 || highlights.count > 6 {
                    Text("mais \(participant.cards.count - min(highlights.count, 6)) cards")
                        .scaledFont(.callout)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(.quaternary)
                        }
                }
            }
        }
    }

    /// Esc sai, mas `.onExitCommand` exige foco — este botão registra o atalho na
    /// janela e ainda dá uma saída clicável para quem está com o mouse na mão.
    private var exitButton: some View {
        Button(action: onExit) {
            Label("Sair da apresentação", systemImage: "xmark")
                .labelStyle(.iconOnly)
                .scaledFont(.title3)
                .padding(10)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: .circle)
        .keyboardShortcut(.cancelAction)
        .padding(20)
        .opacity(showsChrome ? 1 : 0.12)
        .animation(.smooth, value: showsChrome)
        .help("Sair da apresentação (esc)")
    }

    private var footer: some View {
        HStack(spacing: 18) {
            Hint(keys: "← →", action: "navegar")
            Hint(keys: "⌘K", action: "pular")
            Hint(keys: "esc", action: "sair da apresentação")
        }
        .foregroundStyle(.tertiary)
    }

    private struct Hint: View {
        let keys: String
        let action: String

        var body: some View {
            HStack(spacing: 6) {
                Text(keys)
                    .scaledFont(.caption, design: .monospaced)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 5))
                Text(action).scaledFont(.caption)
            }
        }
    }

    private struct Pill: View {
        let count: Int
        let label: String
        let color: Color

        var body: some View {
            if count > 0 {
                HStack(spacing: 7) {
                    Text("\(count)")
                        .scaledFont(.title3, weight: .bold)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(label).scaledFont(.callout)
                }
                .foregroundStyle(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(color.opacity(0.15), in: .capsule)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

/// Card em tamanho de projeção: título grande, contexto do pai, sinal de impedimento.
private struct StageCard: View {
    let issue: JiraIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: StatusPalette.symbol(issue.status))
                    .foregroundStyle(StatusPalette.accent(issue.status))
                Text(issue.status.uppercased())
                    .scaledFont(.caption, weight: .semibold)
                    .kerning(0.8)
                    .foregroundStyle(StatusPalette.accent(issue.status))
                Spacer(minLength: 0)
                Text(issue.key)
                    .scaledFont(.caption, design: .monospaced)
                    .foregroundStyle(.secondary)
                if issue.isFlagged {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(Color.red)
                        .symbolEffect(.pulse, options: .repeating)
                }
            }

            Text(issue.summary)
                .scaledFont(.title3, weight: .medium)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if issue.hasParent {
                Label(issue.parentLabel, systemImage: "arrow.turn.down.right")
                    .scaledFont(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(issue.isFlagged ? Color.red : .clear, lineWidth: 1)
        }
    }
}

/// Entra e sai de tela cheia junto com o modo, e desliga o modo se o usuário sair
/// pelo botão verde ou pelo atalho do sistema.
struct FullScreenSync: ViewModifier {
    @Binding var isPresenting: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Sem fullScreenPrimary o botão verde vira zoom e o atalho não funciona.
                (NSApp.keyWindow ?? NSApp.windows.first)?
                    .collectionBehavior.insert(.fullScreenPrimary)
            }
            .onChange(of: isPresenting) { _, presenting in
                guard let window = NSApp.keyWindow ?? NSApp.windows.first else { return }
                let isFullScreen = window.styleMask.contains(.fullScreen)
                if presenting != isFullScreen { window.toggleFullScreen(nil) }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: NSWindow.didExitFullScreenNotification)) { _ in
                if isPresenting { isPresenting = false }
            }
    }
}
