import Foundation

/// Uma pessoa na rodada, com os cards que ela leva para a daily.
struct Participant: Identifiable, Hashable {
    let person: JiraPerson
    private(set) var cards: [JiraIssue] = []

    var hasTalked = false

    /// Preenchido ao montar a fila: número de ordem, ou ✓ para quem já falou.
    var queueLabel: String = ""

    var id: String { person.id }
    var name: String { person.displayName }

    init(person: JiraPerson, cards: [JiraIssue] = []) {
        self.person = person
        self.update(cards: cards)
    }

    /// Aplica a regra pai/filho e reordena: Code Review → In Progress → resto → épicos.
    mutating func update(cards received: [JiraIssue]) {
        // Se o pai também está na lista da pessoa, ele é redundante: quem conta é a
        // folha. O pai continua visível como contexto dentro do card do filho.
        let parentKeys = Set(received.compactMap(\.parentKey).map { $0.lowercased() })
        let effective = received.filter { !parentKeys.contains($0.key.lowercased()) }

        let codeReview = effective.filter { !$0.isEpic && $0.status.caseInsensitiveCompare("code review") == .orderedSame }
        let inProgress = effective.filter { !$0.isEpic && $0.status.caseInsensitiveCompare("in progress") == .orderedSame }
        let epics = effective.filter(\.isEpic)
        let rest = effective.filter { card in
            !card.isEpic
                && card.status.caseInsensitiveCompare("code review") != .orderedSame
                && card.status.caseInsensitiveCompare("in progress") != .orderedSame
        }

        cards = codeReview + inProgress + rest + epics
    }

    var codeReviewCards: [JiraIssue] { cards.filter { !$0.isEpic && $0.status.caseInsensitiveCompare("code review") == .orderedSame } }
    var inProgressCards: [JiraIssue] { cards.filter { !$0.isEpic && $0.status.caseInsensitiveCompare("in progress") == .orderedSame } }
    var flaggedCards: [JiraIssue] { cards.filter { !$0.isEpic && $0.isFlagged } }
    var otherCards: [JiraIssue] { cards.filter { !$0.isEpic && !codeReviewCards.contains($0) && !inProgressCards.contains($0) } }

    func columns(mode: CardsViewMode = .list) -> [KanbanColumn] {
        KanbanColumn.build(from: cards, mode: mode)
    }

    var cardSummary: String {
        switch cards.count {
        case 0: ""
        case 1: "1 card"
        default: "\(cards.count) cards"
        }
    }

    mutating func markTrigger(_ key: String) {
        guard let index = cards.firstIndex(where: { $0.key == key }) else { return }
        cards[index].isTriggerCard = true
    }
}
