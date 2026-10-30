import SwiftUI

/// Barra lateral no padrão do sistema: quem fala agora, quem vem depois e quem já
/// falou. A seleção é livre — dá para espiar os cards de qualquer pessoa sem mexer
/// na rodada.
struct ParticipantSidebar: View {
    let daily: DailyModel
    @Binding var selection: Participant.ID?

    var body: some View {
        List(selection: $selection) {
            if let speaker = daily.speaker {
                Section("Falando agora") {
                    Row(participant: speaker, isSpeaking: true)
                }
            }

            if !upcoming.isEmpty {
                Section("A seguir") {
                    ForEach(upcoming) { Row(participant: $0) }
                }
            }

            if !finished.isEmpty {
                Section("Já falaram") {
                    ForEach(finished) { Row(participant: $0) }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 232, max: 300)
    }

    private var upcoming: [Participant] {
        daily.participants.filter { !$0.hasTalked && $0.id != daily.speaker?.id }
    }

    private var finished: [Participant] {
        daily.participants.filter { $0.hasTalked && $0.id != daily.speaker?.id }
    }

    private struct Row: View {
        let participant: Participant
        var isSpeaking = false

        var body: some View {
            HStack(spacing: 8) {
                Avatar(person: participant.person, size: 22)

                Text(participant.name)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if participant.hasTalked {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Counter(value: participant.flaggedCards.count, color: Color.red)
                    Counter(value: participant.codeReviewCards.count,
                            color: StatusPalette.accent("code review"))
                    Counter(value: participant.inProgressCards.count,
                            color: StatusPalette.accent("in progress"))
                }
            }
            .tag(participant.id)
            .badge(isSpeaking ? Text("") : nil)
        }

        private struct Counter: View {
            let value: Int
            let color: Color

            var body: some View {
                if value > 0 {
                    Text("\(value)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(color)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
        }
    }
}
