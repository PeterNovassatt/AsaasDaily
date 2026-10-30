import SwiftUI

/// Os cards da pessoa, em lista do sistema agrupada por status — na ordem do board.
struct ParticipantDetail: View {
    let participant: Participant
    let isSpeaking: Bool
    var mode: CardsViewMode = .list
    var isRefreshing = false
    var onRefresh: () -> Void = {}
    var onOpen: (JiraIssue) -> Void = { _ in }

    @State private var collapsed: Set<String> = []

    var body: some View {
        Group {
            if mode == .board {
                ParticipantBoard(columns: participant.columns(mode: .board), onOpen: onOpen)
            } else {
                list
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.bar)
        }
        .animation(.smooth, value: participant.id)
        .animation(.smooth, value: mode)
    }

    private var list: some View {
        List {
            ForEach(participant.columns(mode: .list)) { column in
                Section(isExpanded: expansion(for: column)) {
                    ForEach(column.cards) { issue in
                        IssueRow(issue: issue)
                            .contentShape(.rect)
                            .onTapGesture(count: 2) { onOpen(issue) }
                            .contextMenu {
                                Button("Abrir no Jira", systemImage: "arrow.up.forward.square") {
                                    onOpen(issue)
                                }
                            }
                    }
                } header: {
                    Label {
                        HStack(spacing: 6) {
                            Text(column.status)
                            Text("\(column.count)")
                                .foregroundStyle(.tertiary)
                                .monospacedDigit()
                        }
                    } icon: {
                        Image(systemName: column.symbol)
                            .foregroundStyle(column.accent)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .onChange(of: participant.id) { _, _ in resetCollapsed() }
        .onAppear { resetCollapsed() }
    }

    private func resetCollapsed() {
        collapsed = Set(participant.columns(mode: .list).filter(\.startsCollapsed).map(\.status))
    }

    /// Seções grandes de contexto (backlog, refinamento) começam recolhidas para a
    /// pauta da daily aparecer primeiro, mas continuam a um clique.
    private func expansion(for column: KanbanColumn) -> Binding<Bool> {
        Binding(
            get: { !collapsed.contains(column.status) },
            set: { isExpanded in
                if isExpanded { collapsed.remove(column.status) }
                else { collapsed.insert(column.status) }
            }
        )
    }

    private var header: some View {
        HStack(spacing: 14) {
            Avatar(person: participant.person, size: 52)
                .overlay {
                    if isSpeaking {
                        Circle().strokeBorder(Color.accentColor, lineWidth: 2)
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                if isSpeaking {
                    Text("FALANDO AGORA")
                        .font(.caption2.weight(.bold))
                        .kerning(1.2)
                        .foregroundStyle(Color.accentColor)
                }

                Text(participant.name)
                    .font(.system(size: 26, weight: .semibold))
                    .lineLimit(1)

                Text(participant.cardSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if isSpeaking {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .symbolEffect(.rotate, options: .repeating, isActive: isRefreshing)
                }
                .help("Atualizar os cards desta pessoa (⌘R)")
                .disabled(isRefreshing)
            }
        }
    }
}

/// Uma linha de card: ícone do status, título, e os sinais que importam na daily.
struct IssueRow: View {
    let issue: JiraIssue

    var body: some View {
        HStack(spacing: 10) {
            if issue.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(Color.red)
                    .symbolEffect(.pulse, options: .repeating)
                    .help("Impedimento no Jira")
            } else if issue.isTriggerCard {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.orange)
                    .help("Card que trouxe esta pessoa para a rodada")
            } else {
                Image(systemName: issue.isEpic ? "flag.2.crossed" : "circle.fill")
                    .font(issue.isEpic ? .caption : .system(size: 6))
                    .foregroundStyle(issue.isEpic ? AnyShapeStyle(Color.purple) : AnyShapeStyle(.tertiary))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(issue.summary)
                    .lineLimit(1)

                if issue.hasParent {
                    Label(issue.parentLabel, systemImage: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(issue.key)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}
