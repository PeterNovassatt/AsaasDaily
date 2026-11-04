import SwiftUI

/// Preferências no padrão do sistema: abas, ⌘, para abrir.
struct SettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        TabView {
            AccountSettings(settings: settings)
                .tabItem { Label("Conta", systemImage: "person.crop.circle") }

            ProjectPicker(settings: settings)
                .tabItem { Label("Projetos", systemImage: "square.grid.2x2") }

            TeamPicker(settings: settings)
                .tabItem { Label("Time", systemImage: "person.3") }
        }
        .frame(width: 560, height: 460)
    }
}

// MARK: - Conta

private struct AccountSettings: View {
    @Bindable var settings: AppSettings
    @State private var status: String?
    @State private var isTesting = false

    var body: some View {
        Form {
            Section {
                TextField("E-mail", text: $settings.credentials.email,
                          prompt: Text("nome@asaas.com.br"))
                SecureField("API token", text: $settings.credentials.apiToken,
                            prompt: Text("Token gerado em id.atlassian.com"))
            } footer: {
                Text("O token fica no Keychain, não nas preferências.")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Button("Testar conexão") { Task { await test() } }
                        .disabled(!settings.credentials.isComplete || isTesting)
                    if isTesting { ProgressView().controlSize(.small) }
                    if let status {
                        Text(status).scaledFont(.callout).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: settings.credentials.email) { _, _ in settings.save() }
        .onChange(of: settings.credentials.apiToken) { _, _ in settings.save() }
    }

    private func test() async {
        isTesting = true
        defer { isTesting = false }

        status = await JiraClient(credentials: settings.credentials).verify().message
    }
}
