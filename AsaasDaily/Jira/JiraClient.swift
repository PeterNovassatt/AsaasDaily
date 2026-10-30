import Foundation

enum JiraError: LocalizedError {
    case notConfigured
    case http(status: Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Configure o e-mail e o API token do Jira."
        case .http(let status): "O Jira respondeu \(status)."
        }
    }
}

/// Acesso à API do Jira. Duas lições do app anterior estão embutidas aqui:
/// o id do campo "Flagged" é descoberto pelo nome (varia por instância) e as
/// consultas de issue são paginadas — a API trunca em maxResults e um board
/// com 253 cards devolvia só 200, perdendo o resto em silêncio.
actor JiraClient {
    private let credentials: JiraCredentials
    private let session: URLSession
    private var flaggedFieldIdTask: Task<String, Never>?

    private static let pageSize = 200
    private static let flaggedFieldFallback = "customfield_10023"
    private static let flaggedFieldDefaultsKey = "jira.flaggedFieldId"

    init(credentials: JiraCredentials, session: URLSession = .shared) {
        self.credentials = credentials
        self.session = session
    }

    // MARK: - Requisições

    private func get(_ path: String, query: [URLQueryItem] = []) async throws -> Data {
        guard credentials.isComplete else { throw JiraError.notConfigured }

        var components = URLComponents(url: credentials.site.appending(path: path),
                                       resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }

        var request = URLRequest(url: components.url!)
        request.setValue(credentials.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw JiraError.http(status: http.statusCode)
        }
        return data
    }

    private func decoder(flaggedFieldId: String) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.flaggedFieldId] = flaggedFieldId
        return decoder
    }

    // MARK: - Campo Flagged

    /// Resolvido pelo nome do campo e memoizado: os boards são consultados em
    /// paralelo e, sem isso, cada um dispararia a mesma descoberta.
    func flaggedFieldId() async -> String {
        if let existing = flaggedFieldIdTask { return await existing.value }

        let task = Task<String, Never> { [self] in
            if let cached = UserDefaults.standard.string(forKey: Self.flaggedFieldDefaultsKey),
               !cached.isEmpty {
                return cached
            }
            struct Field: Decodable { let id: String; let name: String }
            guard let data = try? await get("/rest/api/3/field"),
                  let fields = try? JSONDecoder().decode([Field].self, from: data),
                  let flagged = fields.first(where: { $0.name.caseInsensitiveCompare("Flagged") == .orderedSame })
            else { return Self.flaggedFieldFallback }

            UserDefaults.standard.set(flagged.id, forKey: Self.flaggedFieldDefaultsKey)
            return flagged.id
        }
        flaggedFieldIdTask = task
        return await task.value
    }

    // MARK: - Boards

    func boards(projectKey: String) async throws -> [JiraBoard] {
        struct Response: Decodable { let values: [JiraBoard] }
        let data = try await get("/rest/agile/1.0/board", query: [
            .init(name: "projectLocation", value: projectKey),
            .init(name: "maxResults", value: "15"),
            .init(name: "orderBy", value: "name"),
            .init(name: "overrideFilterPermissions", value: "true"),
            .init(name: "startAt", value: "0")
        ])
        return try JSONDecoder().decode(Response.self, from: data).values
    }

    func boards(projectKeys: [String]) async -> [JiraBoard] {
        await withTaskGroup(of: [JiraBoard].self) { group in
            for key in projectKeys {
                group.addTask { (try? await self.boards(projectKey: key)) ?? [] }
            }
            var all: [JiraBoard] = []
            for await boards in group { all.append(contentsOf: boards) }
            return all
        }
    }

    // MARK: - Issues

    /// `assigneeId` entra na própria JQL: o board segue sendo o escopo, então o
    /// resultado é o mesmo subconjunto que a carga completa traria para a pessoa.
    func issues(boardId: Int, assigneeId: String? = nil) async throws -> [JiraIssue] {
        let fieldId = await flaggedFieldId()
        let jql = assigneeId.map { "statusCategory != Done AND assignee = \"\($0)\"" }
            ?? "statusCategory != Done"
        let fields = "assignee,status,summary,\(fieldId),issuetype,parent"

        func page(startAt: Int) async throws -> JiraIssuePage {
            let data = try await get("/rest/agile/1.0/board/\(boardId)/issue", query: [
                .init(name: "jql", value: jql),
                .init(name: "fields", value: fields),
                .init(name: "orderBy", value: "rank"),
                .init(name: "startAt", value: String(startAt)),
                .init(name: "maxResults", value: String(Self.pageSize))
            ])
            return try decoder(flaggedFieldId: fieldId).decode(JiraIssuePage.self, from: data)
        }

        let first = try await page(startAt: 0)
        guard first.total > Self.pageSize else { return first.issues }

        let remaining = await withTaskGroup(of: [JiraIssue].self) { group in
            for index in 1...((first.total - 1) / Self.pageSize) {
                group.addTask {
                    (try? await page(startAt: index * Self.pageSize))?.issues ?? []
                }
            }
            var collected: [JiraIssue] = []
            for await issues in group { collected.append(contentsOf: issues) }
            return collected
        }
        return first.issues + remaining
    }

    /// Issues de todos os boards informados, deduplicadas: um card pode aparecer
    /// em mais de um board do mesmo projeto.
    func issues(boards: [JiraBoard], assigneeId: String? = nil) async -> [JiraIssue] {
        let collected = await withTaskGroup(of: [JiraIssue].self) { group in
            for board in boards {
                group.addTask {
                    (try? await self.issues(boardId: board.id, assigneeId: assigneeId)) ?? []
                }
            }
            var all: [JiraIssue] = []
            for await issues in group { all.append(contentsOf: issues) }
            return all
        }

        var seen = Set<String>()
        return collected.filter { seen.insert($0.key).inserted }
    }
}

// MARK: - Dados para as preferências

extension JiraClient {

    /// Projetos a que a conta tem acesso, paginados.
    func projects() async -> [JiraProject] {
        struct Page: Decodable {
            let values: [Entry]
            let isLast: Bool
            struct Entry: Decodable {
                let key: String
                let name: String
                let projectCategory: Category?
                struct Category: Decodable { let name: String }
            }
        }

        var collected: [JiraProject] = []
        var startAt = 0

        while true {
            guard let data = try? await get("/rest/api/3/project/search", query: [
                .init(name: "startAt", value: String(startAt)),
                .init(name: "maxResults", value: "100"),
                .init(name: "orderBy", value: "name")
            ]), let page = try? JSONDecoder().decode(Page.self, from: data) else { break }

            collected += page.values.map {
                JiraProject(key: $0.key, name: $0.name, category: $0.projectCategory?.name)
            }

            if page.isLast || page.values.isEmpty { break }
            startAt += page.values.count
        }
        return collected
    }

    /// Quem tem card em aberto nos boards — a lista de onde sai o time da daily.
    func assignees(boards: [JiraBoard]) async -> [JiraPerson] {
        let issues = await issues(boards: boards)

        var people: [String: JiraPerson] = [:]
        for issue in issues {
            guard let id = issue.assigneeId, people[id] == nil else { continue }
            people[id] = JiraPerson(id: id,
                                    name: issue.assigneeName ?? id,
                                    avatarURL: issue.assigneeAvatarURL)
        }
        return people.values.sorted { $0.name < $1.name }
    }
}
