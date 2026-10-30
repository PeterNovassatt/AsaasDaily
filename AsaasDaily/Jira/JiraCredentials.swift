import Foundation
import Security

/// Credenciais do Jira. O e-mail fica em UserDefaults; o token vai para o Keychain
/// (o app anterior guardava o token em texto plano nas preferências).
struct JiraCredentials: Sendable {
    var email: String
    var apiToken: String
    var site: URL

    var isComplete: Bool { !email.isEmpty && !apiToken.isEmpty }

    var authorizationHeader: String {
        let raw = "\(email):\(apiToken)"
        return "Basic \(Data(raw.utf8).base64EncodedString())"
    }
}

enum CredentialsStore {
    private static let emailKey = "jira.email"
    private static let siteKey = "jira.site"
    private static let keychainAccount = "jira.apiToken"
    private static let keychainService = "com.asaas.AsaasDaily"

    static let defaultSite = URL(string: "https://asaasdev.atlassian.net")!

    static func load() -> JiraCredentials {
        let defaults = UserDefaults.standard
        let site = (defaults.string(forKey: siteKey)).flatMap(URL.init(string:)) ?? defaultSite
        return JiraCredentials(email: defaults.string(forKey: emailKey) ?? "",
                               apiToken: readToken() ?? "",
                               site: site)
    }

    static func save(_ credentials: JiraCredentials) {
        let defaults = UserDefaults.standard
        defaults.set(credentials.email, forKey: emailKey)
        defaults.set(credentials.site.absoluteString, forKey: siteKey)
        writeToken(credentials.apiToken)
    }

    // MARK: Keychain

    private static func baseQuery() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: keychainService,
         kSecAttrAccount as String: keychainAccount]
    }

    static func readToken() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func writeToken(_ token: String) {
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)

        guard !token.isEmpty else { return }
        var insert = query
        insert[kSecValueData as String] = Data(token.utf8)
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(insert as CFDictionary, nil)
    }
}
