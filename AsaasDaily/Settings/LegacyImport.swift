import Foundation

/// Importa a configuração do app MAUI anterior (bundle com.companyname.dailydriver),
/// para não ser preciso reconfigurar credenciais, projetos e apelidos do time.
enum LegacyImport {

    private static let plistURL = FileManager.default
        .homeDirectoryForCurrentUser
        .appending(path: "Library/Preferences/com.companyname.dailydriver.plist")

    struct Payload {
        var credentials: JiraCredentials?
        var projectKeys: [String] = []
        var people: [JiraPerson] = []
        var flaggedFieldId: String?
        var speechEnabled = false
    }

    static var isAvailable: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func read() -> Payload? {
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let root = plist as? [String: Any]
        else { return nil }

        var payload = Payload()

        // Os valores são strings JSON gravadas pelo app antigo.
        func json<T: Decodable>(_ key: String, as type: T.Type) -> T? {
            guard let raw = root[key] as? String, let data = raw.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(type, from: data)
        }

        if let config = json("new-configuration", as: LegacyConfiguration.self) {
            payload.projectKeys = config.project?
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty } ?? []

            if let email = config.email, let token = config.apiToken, !email.isEmpty, !token.isEmpty {
                payload.credentials = JiraCredentials(email: email,
                                                      apiToken: token,
                                                      site: CredentialsStore.defaultSite)
            }
        }

        if let people = json("persons", as: [LegacyPerson].self) {
            payload.people = people.map {
                JiraPerson(id: $0.id,
                           name: $0.name ?? "",
                           avatarURL: $0.avatarUrl.flatMap(URL.init(string:)),
                           nickname: $0.nickname,
                           isActive: $0.active ?? true,
                           isSelected: $0.isChecked ?? false)
            }
        }

        payload.flaggedFieldId = root["flagged-field-id"] as? String
        payload.speechEnabled = root["speech-enabled"] as? Bool ?? false
        return payload
    }

    // MARK: Formato do app antigo (PascalCase do C#)

    private struct LegacyConfiguration: Decodable {
        let email: String?
        let apiToken: String?
        let project: String?

        enum CodingKeys: String, CodingKey {
            case email = "Email", apiToken = "ApiToken", project = "Project"
        }
    }

    private struct LegacyPerson: Decodable {
        let id: String
        let name: String?
        let avatarUrl: String?
        let nickname: String?
        let active: Bool?
        let isChecked: Bool?

        enum CodingKeys: String, CodingKey {
            case id = "Id", name = "Name", avatarUrl = "AvatarUrl"
            case nickname = "Nickname", active = "Active", isChecked = "IsChecked"
        }
    }
}
