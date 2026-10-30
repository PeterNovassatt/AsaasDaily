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


/// Progresso da rodada em 22 pt, para a barra de ferramentas: anel preenchido e o
/// número de quem já falou no centro. Ocupa o espaço de um botão e diz o essencial.
struct ProgressRing: View {
    let spoken: Int
    let total: Int

    private var fraction: Double { total == 0 ? 0 : Double(spoken) / Double(total) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: fraction)
            Text("\(spoken)")
                .font(.system(size: 9, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(width: 22, height: 22)
        .help("\(spoken) de \(total) já falaram")
    }
}
