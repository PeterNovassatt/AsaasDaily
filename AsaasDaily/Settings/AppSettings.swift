import Foundation
import Observation

/// Configuração do app: credenciais, projetos e time. O token mora no Keychain;
/// o resto em UserDefaults.
@MainActor
@Observable
final class AppSettings {

    var credentials: JiraCredentials
    var projectKeys: [String]
    var people: [JiraPerson]
    var speechEnabled: Bool
    var textScale: TextScale {
        didSet { UserDefaults.standard.set(textScale.rawValue, forKey: Self.textScaleKey) }
    }
    var cardsViewMode: CardsViewMode {
        didSet { UserDefaults.standard.set(cardsViewMode.rawValue, forKey: Self.viewModeKey) }
    }
    var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceKey) }
    }

    private static let projectsKey = "jira.projectKeys"
    private static let peopleKey = "jira.people"
    private static let speechKey = "daily.speechEnabled"
    private static let importedKey = "daily.didImportLegacy"
    private static let appearanceKey = "daily.appearance"
    private static let viewModeKey = "daily.cardsViewMode"
    private static let textScaleKey = "daily.textScale"

    var isConfigured: Bool {
        credentials.isComplete && !projectKeys.isEmpty && people.contains(where: \.isSelected)
    }

    var selectedPeople: [JiraPerson] { people.filter { $0.isActive && $0.isSelected } }

    init() {
        let defaults = UserDefaults.standard
        credentials = CredentialsStore.load()
        projectKeys = defaults.stringArray(forKey: Self.projectsKey) ?? []
        speechEnabled = defaults.bool(forKey: Self.speechKey)
        textScale = TextScale(rawValue: defaults.integer(forKey: Self.textScaleKey)) ?? .padrao
        cardsViewMode = (defaults.string(forKey: Self.viewModeKey))
            .flatMap(CardsViewMode.init(rawValue:)) ?? .list
        appearance = (defaults.string(forKey: Self.appearanceKey))
            .flatMap(AppAppearance.init(rawValue:)) ?? .dark
        people = (defaults.data(forKey: Self.peopleKey))
            .flatMap { try? JSONDecoder().decode([JiraPerson].self, from: $0) } ?? []

        if !defaults.bool(forKey: Self.importedKey) { importLegacyIfNeeded() }
    }

    func save() {
        let defaults = UserDefaults.standard
        CredentialsStore.save(credentials)
        defaults.set(projectKeys, forKey: Self.projectsKey)
        defaults.set(speechEnabled, forKey: Self.speechKey)
        if let data = try? JSONEncoder().encode(people) {
            defaults.set(data, forKey: Self.peopleKey)
        }
    }

    /// Uma única vez: puxa o que já estava configurado no app anterior.
    private func importLegacyIfNeeded() {
        guard LegacyImport.isAvailable, let payload = LegacyImport.read() else { return }

        if !credentials.isComplete, let imported = payload.credentials { credentials = imported }
        if projectKeys.isEmpty { projectKeys = payload.projectKeys }
        if people.isEmpty { people = payload.people }
        speechEnabled = payload.speechEnabled

        if let fieldId = payload.flaggedFieldId {
            UserDefaults.standard.set(fieldId, forKey: "jira.flaggedFieldId")
        }

        UserDefaults.standard.set(true, forKey: Self.importedKey)
        save()
    }
}
