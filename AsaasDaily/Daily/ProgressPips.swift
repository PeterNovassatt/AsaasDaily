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
