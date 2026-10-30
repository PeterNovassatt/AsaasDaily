import Foundation

/// Um card do board. O campo "Flagged" é um custom field cujo id varia por instância
/// do Jira, então ele é resolvido em runtime e chega ao decoder via userInfo.
struct JiraIssue: Identifiable, Hashable, Sendable {
    let key: String
    let summary: String
    let status: String
    let issueType: String
    let assigneeId: String?
    let assigneeName: String?
    let assigneeAvatarURL: URL?
    let parentKey: String?
    let parentSummary: String?
    let isFlagged: Bool

    /// Marca o card que trouxe a pessoa para a rodada (a "estrela" na daily).
    var isTriggerCard: Bool = false

    var id: String { key }

    /// "Epic" e "Technical Epic" convivem no board da Asaas.
    var isEpic: Bool { issueType.localizedCaseInsensitiveContains("epic") }

    var hasParent: Bool { parentKey?.isEmpty == false }

    var parentLabel: String {
        guard let parentKey, let parentSummary else { return "" }
        return "\(parentKey) · \(parentSummary)"
    }
}

struct JiraBoard: Identifiable, Hashable, Codable, Sendable {
    let id: Int
    let name: String
}

struct JiraPerson: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var name: String
    var avatarURL: URL?
    var nickname: String?
    var isActive: Bool = true
    var isSelected: Bool = false

    var displayName: String { nickname ?? name }
}

struct JiraProject: Identifiable, Hashable, Codable, Sendable {
    let key: String
    let name: String
    let category: String?

    var id: String { key }
}

// MARK: - Decodificação

extension CodingUserInfoKey {
    static let flaggedFieldId = CodingUserInfoKey(rawValue: "flaggedFieldId")!
}

/// Chave dinâmica: o id do campo Flagged só é conhecido em runtime.
private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
    init(_ name: String) { self.stringValue = name }
}

struct JiraIssuePage: Decodable {
    let issues: [JiraIssue]
    let total: Int
}

extension JiraIssue: Decodable {
    private enum RootKeys: String, CodingKey { case key, fields }
    private enum FieldKeys: String, CodingKey {
        case summary, status, assignee, issuetype, parent
    }
    private enum NamedKeys: String, CodingKey { case name }
    private enum AssigneeKeys: String, CodingKey { case accountId, displayName, avatarUrls }
    private enum ParentKeys: String, CodingKey { case key, fields }
    private enum ParentFieldKeys: String, CodingKey { case summary }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)
        key = try root.decode(String.self, forKey: .key)

        let fields = try root.nestedContainer(keyedBy: FieldKeys.self, forKey: .fields)
        summary = (try? fields.decode(String.self, forKey: .summary)) ?? ""

        let statusBox = try? fields.nestedContainer(keyedBy: NamedKeys.self, forKey: .status)
        status = (try? statusBox?.decode(String.self, forKey: .name)) ?? ""

        let typeBox = try? fields.nestedContainer(keyedBy: NamedKeys.self, forKey: .issuetype)
        issueType = (try? typeBox?.decode(String.self, forKey: .name)) ?? ""

        let assignee = try? fields.nestedContainer(keyedBy: AssigneeKeys.self, forKey: .assignee)
        assigneeId = try? assignee?.decode(String.self, forKey: .accountId)
        assigneeName = try? assignee?.decode(String.self, forKey: .displayName)
        let avatars = try? assignee?.decode([String: String].self, forKey: .avatarUrls)
        assigneeAvatarURL = (avatars?["48x48"]).flatMap(URL.init(string:))

        // parent cobre os dois níveis no Jira: subtask → task e task → épico.
        let parent = try? fields.nestedContainer(keyedBy: ParentKeys.self, forKey: .parent)
        parentKey = try? parent?.decode(String.self, forKey: .key)
        let parentFields = try? parent?.nestedContainer(keyedBy: ParentFieldKeys.self, forKey: .fields)
        parentSummary = try? parentFields?.decode(String.self, forKey: .summary)

        // Flagged chega como array de opções; vazio ou ausente significa sem flag.
        if let fieldId = decoder.userInfo[.flaggedFieldId] as? String,
           let dynamic = try? decoder.container(keyedBy: RootKeys.self)
               .nestedContainer(keyedBy: DynamicKey.self, forKey: .fields),
           let options = try? dynamic.decodeIfPresent([FlagOption].self, forKey: DynamicKey(fieldId)) {
            isFlagged = !options.isEmpty
        } else {
            isFlagged = false
        }
    }

    private struct FlagOption: Decodable { let value: String? }
}
