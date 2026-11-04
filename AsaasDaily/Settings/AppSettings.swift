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

    /// Marcado quando a pessoa termina o setup inicial. Quem já usava o app entra
    /// configurado e nunca vê a folha.
    var setupCompleted: Bool {
        didSet { UserDefaults.standard.set(setupCompleted, forKey: Self.setupKey) }
    }

    /// Uma folha de cada vez. Duas `.sheet` irmãs no mesmo view fazem o SwiftUI
    /// reapresentar a segunda quando a primeira fecha — por isso um destino só.
    var sheet: OnboardingSheet?

    private static let projectsKey = "jira.projectKeys"
    private static let peopleKey = "jira.people"
    private static let speechKey = "daily.speechEnabled"
    private static let importedKey = "daily.didImportLegacy"
    private static let appearanceKey = "daily.appearance"
    private static let viewModeKey = "daily.cardsViewMode"
    private static let textScaleKey = "daily.textScale"
    private static let setupKey = "daily.setupCompleted"

    var isConfigured: Bool {
        credentials.isComplete && !projectKeys.isEmpty && people.contains(where: \.isSelected)
    }

    var selectedPeople: [JiraPerson] { people.filter { $0.isActive && $0.isSelected } }

    /// O setup aparece só para quem nunca configurou nada: quem já tem credencial e
    /// time (inclusive vindo do app anterior) começa direto na daily.
    var needsSetup: Bool { !setupCompleted && !isConfigured }

    init() {
        let defaults = UserDefaults.standard
        credentials = CredentialsStore.load()
        projectKeys = defaults.stringArray(forKey: Self.projectsKey) ?? []
        speechEnabled = defaults.bool(forKey: Self.speechKey)
        textScale = TextScale(rawValue: defaults.integer(forKey: Self.textScaleKey)) ?? .padrao
        cardsViewMode = (defaults.string(forKey: Self.viewModeKey))
            .flatMap(CardsViewMode.init(rawValue:)) ?? .list
        setupCompleted = defaults.bool(forKey: Self.setupKey)
        appearance = (defaults.string(forKey: Self.appearanceKey))
            .flatMap(AppAppearance.init(rawValue:)) ?? .dark
        people = (defaults.data(forKey: Self.peopleKey))
            .flatMap { try? JSONDecoder().decode([JiraPerson].self, from: $0) } ?? []

        if !defaults.bool(forKey: Self.importedKey) { importLegacyIfNeeded() }
        if !setupCompleted && isConfigured { setupCompleted = true }
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
