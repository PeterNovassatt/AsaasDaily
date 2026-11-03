import SwiftUI

/// Progresso da rodada como uma pílula por pessoa: quem já falou fica cheia, quem
/// está falando fica maior. Lê-se de relance e de longe — melhor que uma barra
/// linear, que só diz "mais ou menos no meio".
struct ProgressPips: View {
    let participants: [Participant]
    let currentId: Participant.ID?
    var height: CGFloat = 5
    var width: CGFloat = 22
    var spacing: CGFloat = 5

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(participants) { person in
                Capsule()
                    .fill(fill(for: person))
                    .frame(width: person.id == currentId ? width * 1.5 : width, height: height)
                    .animation(.smooth, value: person.hasTalked)
                    .animation(.smooth, value: currentId)
            }
        }
        .padding(.horizontal, 4)
        .help(summary)
    }

    private func fill(for person: Participant) -> Color {
        if person.hasTalked { return Color.accentColor }
        if person.id == currentId { return Color.accentColor }
        return .secondary.opacity(0.25)
    }

    private var summary: String {
        let spoken = participants.filter(\.hasTalked).count
        return "\(spoken) de \(participants.count) já falaram"
    }
}


/// Progresso da rodada para a barra de ferramentas. O item da toolbar desenha um
/// fundo em pílula, feito para conteúdo horizontal — um círculo sozinho lá dentro
/// sobra espaço dos dois lados. Daí anel e contagem lado a lado.
struct ProgressRing: View {
    let spoken: Int
    let total: Int

    private var fraction: Double { total == 0 ? 0 : Double(spoken) / Double(total) }

    var body: some View {
        HStack(spacing: 7) {
            ring
            Text("\(spoken) de \(total)")
                .scaledFont(.caption, weight: .medium)
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(.secondary)
        }
        // O fundo do item é desenhado em volta do conteúdo: sem esta folga o anel
        // e o número encostam na borda da pílula.
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .help("\(spoken) de \(total) já falaram")
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: fraction)
        }
        .frame(width: 16, height: 16)
    }
}
