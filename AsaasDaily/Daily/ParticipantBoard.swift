import SwiftUI

/// Os cards da pessoa em quadro, espelhando o board do Jira. Só colunas com card
/// aparecem — nove colunas vazias não ajudam ninguém numa daily de dois minutos.
struct ParticipantBoard: View {
    let columns: [KanbanColumn]
    var onOpen: (JiraIssue) -> Void = { _ in }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(columns) { column in
                    Column(column: column, onOpen: onOpen)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.visible)
    }

    private struct Column: View {
        let column: KanbanColumn
        let onOpen: (JiraIssue) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Image(systemName: column.symbol)
                        .font(.caption)
                        .foregroundStyle(column.accent)
                    Text(column.status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(column.accent)
                    Text("\(column.count)")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(column.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(column.accent.opacity(0.15), in: .capsule)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 2)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(column.cards) { issue in
                            IssueCard(issue: issue)
                                .onTapGesture(count: 2) { onOpen(issue) }
                                .contextMenu {
                                    Button("Abrir no Jira", systemImage: "arrow.up.forward.square") {
                                        onOpen(issue)
                                    }
                                }
                                .scrollTransition(.animated(.smooth)) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0.4)
                                        .scaleEffect(phase.isIdentity ? 1 : 0.97)
                                }
                        }
                    }
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.never)
            }
            .frame(width: 280)
        }
    }
}

/// Card do quadro: o que a pessoa precisa dizer sobre ele cabe em três linhas.
struct IssueCard: View {
    let issue: JiraIssue

    @State private var isHovering = false

    private var accentBorder: Color? {
        if issue.isFlagged { return Color.red }
        if issue.isTriggerCard { return Color.orange }
        if issue.isEpic { return Color.purple }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if issue.hasParent {
                Label(issue.parentLabel, systemImage: "arrow.turn.down.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(issue.summary)
                .font(.callout)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                Text(issue.key)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                if issue.isTriggerCard {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.orange)
                }
                if issue.isFlagged {
                    Image(systemName: "flag.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.red)
                        .symbolEffect(.pulse, options: .repeating)
                }
            }
        }
        .padding(11)
        .background(.quaternary.opacity(isHovering ? 0.5 : 0.3), in: .rect(cornerRadius: 10))
        .overlay {
            if let accentBorder {
                RoundedRectangle(cornerRadius: 10).strokeBorder(accentBorder, lineWidth: 1)
            }
        }
        .animation(.snappy(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
    }
}
