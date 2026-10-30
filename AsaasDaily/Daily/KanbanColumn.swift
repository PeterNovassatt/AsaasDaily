import SwiftUI

/// Uma coluna do quadro, espelhando um status do board do Jira.
struct KanbanColumn: Identifiable, Hashable {
    let status: String
    let cards: [JiraIssue]

    var id: String { status }
    var accent: Color { StatusPalette.accent(status) }
    var symbol: String { StatusPalette.symbol(status) }
    var title: String { status.uppercased() }
    var count: Int { cards.count }

    /// Numa lista vertical a ordem do board não serve: o Backlog é a maior coluna e
    /// empurraria para baixo justamente o que se discute na daily. Aqui manda a
    /// relevância — review e progresso primeiro, backlog por último.
    private static let order = [
        "code review", "product review", "in progress", "rollout",
        "to do", "prioritized", "in preparation", "in refinement", "backlog"
    ]

    /// Colunas que entram recolhidas: informação de contexto, não pauta.
    static let collapsedByDefault: Set<String> = ["backlog", "in refinement"]

    var startsCollapsed: Bool {
        Self.collapsedByDefault.contains(status.lowercased())
    }

    /// No quadro vale a ordem do board do Jira, que o time já tem na cabeça.
    private static let boardOrder = [
        "backlog", "in refinement", "in preparation", "prioritized",
        "to do", "in progress", "code review", "product review", "rollout"
    ]

    static func build(from cards: [JiraIssue], mode: CardsViewMode = .list) -> [KanbanColumn] {
        let sequence = mode == .board ? boardOrder : order
        return Dictionary(grouping: cards, by: \.status)
            .map { KanbanColumn(status: $0.key, cards: $0.value) }
            .sorted { lhs, rhs in
                let left = index(of: lhs.status, in: sequence)
                let right = index(of: rhs.status, in: sequence)
                return left == right ? lhs.status < rhs.status : left < right
            }
    }

    private static func index(of status: String, in sequence: [String]) -> Int {
        sequence.firstIndex(of: status.lowercased()) ?? sequence.count
    }
}
