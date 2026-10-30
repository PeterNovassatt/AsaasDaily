import Foundation
import Observation

@MainActor
@Observable
final class DailyModel {

    // MARK: Estado

    private(set) var participants: [Participant] = []
    private(set) var speaker: Participant?
    private(set) var unassigned: [JiraIssue] = []

    /// Modo apresentação: esconde o chrome e joga o foco em quem está falando.
    /// É estado de sessão — não faz sentido o app abrir já apresentando.
    var isPresenting = false

    private(set) var isLoading = false
    private(set) var isRefreshingSpeaker = false
    private(set) var errorMessage: String?

    /// Totais do board (não só de quem está na rodada).
    private(set) var codeReviewCount = 0
    private(set) var inProgressCount = 0
    private(set) var otherCount = 0
    private(set) var flaggedCount = 0
    private(set) var boardCardCount = 0

    /// Pilha de quem já falou, para voltar uma pessoa por vez.
    private var spokenHistory: [String] = []

    private var client: JiraClient?
    private var boards: [JiraBoard] = []

    // MARK: Derivados

    var nextUp: Participant? {
        participants.first { !$0.hasTalked && $0.id != speaker?.id }
    }

    /// A fila mostrada na lateral: todos menos quem fala agora e o próximo.
    var queue: [Participant] {
        let nextId = nextUp?.id
        return participants.filter { $0.id != speaker?.id && $0.id != nextId }
    }

    var spokenCount: Int { participants.filter(\.hasTalked).count }
    var totalCount: Int { participants.count }
    var progress: Double { totalCount == 0 ? 0 : Double(spokenCount) / Double(totalCount) }
    var canGoBack: Bool { !spokenHistory.isEmpty }
    var isFinished: Bool { totalCount > 0 && spokenCount == totalCount && speaker == nil }
    var hasStarted: Bool { speaker != nil || spokenCount > 0 }

    // MARK: Carga

    func load(credentials: JiraCredentials, projectKeys: [String], people: [JiraPerson]) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let client = JiraClient(credentials: credentials)
        self.client = client

        boards = await client.boards(projectKeys: projectKeys)
        guard !boards.isEmpty else {
            errorMessage = "Nenhum board encontrado para \(projectKeys.joined(separator: ", "))."
            return
        }

        let issues = await client.issues(boards: boards)
        guard !issues.isEmpty else {
            errorMessage = "Nenhum card em aberto nos boards selecionados."
            return
        }

        buildRound(issues: issues, people: people.filter { $0.isActive && $0.isSelected })
        refreshBoardCounters(from: issues)
    }

    /// Ordem de fala: quem tem card em Code Review entra primeiro, depois In Progress,
    /// e o restante do time entra sorteado. O card que puxou a pessoa fica marcado.
    private func buildRound(issues: [JiraIssue], people: [JiraPerson]) {
        let byAssignee = Dictionary(grouping: issues.filter { $0.assigneeId != nil },
                                    by: { $0.assigneeId! })

        func cards(for person: JiraPerson) -> [JiraIssue] { byAssignee[person.id] ?? [] }

        var ordered: [Participant] = []
        var added = Set<String>()

        func pull(from pool: [JiraIssue]) {
            for issue in pool {
                guard let assigneeId = issue.assigneeId, !added.contains(assigneeId),
                      let person = people.first(where: { $0.id == assigneeId })
                else { continue }

                var participant = Participant(person: person, cards: cards(for: person))
                participant.markTrigger(issue.key)
                ordered.append(participant)
                added.insert(assigneeId)
            }
        }

        let active = issues.filter { !$0.isEpic }
        pull(from: active.filter { $0.status.caseInsensitiveCompare("code review") == .orderedSame })
        pull(from: active.filter { $0.status.caseInsensitiveCompare("in progress") == .orderedSame })

        for person in people where !added.contains(person.id) {
            ordered.append(Participant(person: person, cards: cards(for: person)))
        }

        // Quem não foi puxado por um card entra em ordem aleatória, para a daily
        // não começar sempre pelas mesmas pessoas.
        let pulled = ordered.prefix(added.count)
        let rest = ordered.dropFirst(added.count).shuffled()

        participants = Array(pulled) + Array(rest)
        speaker = nil
        spokenHistory = []
        unassigned = active.filter {
            $0.assigneeId == nil
                && ($0.status.caseInsensitiveCompare("code review") == .orderedSame
                    || $0.status.caseInsensitiveCompare("in progress") == .orderedSame)
        }
        relabelQueue()
    }

    private func refreshBoardCounters(from issues: [JiraIssue]) {
        let cards = issues.filter { !$0.isEpic }
        codeReviewCount = cards.count { $0.status.caseInsensitiveCompare("code review") == .orderedSame }
        inProgressCount = cards.count { $0.status.caseInsensitiveCompare("in progress") == .orderedSame }
        flaggedCount = cards.count(where: \.isFlagged)
        boardCardCount = cards.count
        otherCount = boardCardCount - codeReviewCount - inProgressCount
    }

    // MARK: Condução da rodada

    func next() {
        if var current = speaker, let index = participants.firstIndex(where: { $0.id == current.id }) {
            current.hasTalked = true
            participants[index] = current
            spokenHistory.append(current.id)
        }
        speaker = participants.first { !$0.hasTalked }
        relabelQueue()
    }

    /// Pular manda a pessoa para o fim da fila — sem isso ela voltaria a ser
    /// escolhida no clique seguinte, já que a busca é sempre pelo primeiro pendente.
    func skip() {
        guard let current = speaker,
              participants.contains(where: { !$0.hasTalked && $0.id != current.id })
        else { return }

        if let index = participants.firstIndex(where: { $0.id == current.id }) {
            let moved = participants.remove(at: index)
            participants.append(moved)
        }
        speaker = participants.first { !$0.hasTalked && $0.id != current.id }
        relabelQueue()
    }

    /// Volta para a última pessoa que falou: ela reassume e deixa de contar como
    /// "já falou"; quem estava falando volta para a fila.
    func previous() {
        guard let previousId = spokenHistory.popLast(),
              let index = participants.firstIndex(where: { $0.id == previousId })
        else { return }

        participants[index].hasTalked = false
        speaker = participants[index]
        relabelQueue()
    }

    func remove(_ participant: Participant) {
        participants.removeAll { $0.id == participant.id }
        spokenHistory.removeAll { $0 == participant.id }
        if speaker?.id == participant.id { speaker = participants.first { !$0.hasTalked } }
        relabelQueue()
    }

    func reset(credentials: JiraCredentials, projectKeys: [String], people: [JiraPerson]) async {
        speaker = nil
        spokenHistory = []
        await load(credentials: credentials, projectKeys: projectKeys, people: people)
    }

    /// Numeração da fila: o próximo é 1, então os pendentes começam em 2.
    private func relabelQueue() {
        let nextId = nextUp?.id
        var position = 2
        for index in participants.indices {
            let participant = participants[index]
            guard participant.id != speaker?.id, participant.id != nextId else { continue }
            participants[index].queueLabel = participant.hasTalked ? "✓" : "\(position)"
            if !participant.hasTalked { position += 1 }
        }
    }

    // MARK: Atualizar só quem está falando

    /// Recarrega os cards da pessoa que está falando sem remontar a rodada, e ajusta
    /// os totais por diferença — recalcular do zero exigiria buscar o board inteiro.
    func refreshSpeaker() async {
        guard let client, let current = speaker, !isRefreshingSpeaker else { return }
        isRefreshingSpeaker = true
        defer { isRefreshingSpeaker = false }

        let fresh = await client.issues(boards: boards, assigneeId: current.person.id)
        guard let index = participants.firstIndex(where: { $0.id == current.id }) else { return }

        let triggers = Set(participants[index].cards.filter(\.isTriggerCard).map(\.key))
        let before = snapshot(of: participants[index])

        participants[index].update(cards: fresh)
        for key in triggers { participants[index].markTrigger(key) }

        let after = snapshot(of: participants[index])
        codeReviewCount += after.codeReview - before.codeReview
        inProgressCount += after.inProgress - before.inProgress
        otherCount += after.other - before.other
        flaggedCount += after.flagged - before.flagged
        boardCardCount += after.total - before.total

        speaker = participants[index]
    }

    private func snapshot(of participant: Participant)
        -> (codeReview: Int, inProgress: Int, other: Int, flagged: Int, total: Int) {
        (participant.codeReviewCards.count,
         participant.inProgressCards.count,
         participant.otherCards.count,
         participant.flaggedCards.count,
         participant.cards.count { !$0.isEpic })
    }
}
