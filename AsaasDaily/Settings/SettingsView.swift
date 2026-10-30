import SwiftUI

/// Preferências no padrão do sistema: abas, ⌘, para abrir.
struct SettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        TabView {
            AccountSettings(settings: settings)
                .tabItem { Label("Conta", systemImage: "person.crop.circle") }

            ProjectSettings(settings: settings)
                .tabItem { Label("Projetos", systemImage: "square.grid.2x2") }

            TeamSettings(settings: settings)
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Button("Testar conexão") { Task { await test() } }
                        .disabled(!settings.credentials.isComplete || isTesting)
                    if isTesting { ProgressView().controlSize(.small) }
                    if let status {
                        Text(status).font(.callout).foregroundStyle(.secondary)
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

        let client = JiraClient(credentials: settings.credentials)
        let found = await client.projects()
        status = found.isEmpty ? "Não consegui autenticar." : "Conectado · \(found.count) projetos"
    }
}

// MARK: - Projetos

private struct ProjectSettings: View {
    @Bindable var settings: AppSettings
    @State private var projects: [JiraProject] = []
    @State private var search = ""
    @State private var isLoading = false

    private var filtered: [JiraProject] {
        guard !search.isEmpty else { return projects }
        return projects.filter {
            $0.key.localizedCaseInsensitiveContains(search)
                || $0.name.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(filtered) { project in
                    Toggle(isOn: binding(for: project)) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(project.key).font(.body.weight(.medium))
                            Text(project.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .searchable(text: $search, placement: .sidebar, prompt: "Buscar projeto")
            .overlay {
                if isLoading { ProgressView() }
                else if projects.isEmpty {
                    ContentUnavailableView("Nenhum projeto", systemImage: "square.grid.2x2",
                                           description: Text("Verifique as credenciais na aba Conta."))
                }
            }

            Divider()

            HStack {
                Text("\(settings.projectKeys.count) selecionados")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Recarregar") { Task { await load() } }
            }
            .padding(10)
        }
        .task { await load() }
    }

    private func binding(for project: JiraProject) -> Binding<Bool> {
        Binding(
            get: { settings.projectKeys.contains(project.key) },
            set: { isOn in
                if isOn { settings.projectKeys.append(project.key) }
                else { settings.projectKeys.removeAll { $0 == project.key } }
                settings.save()
            }
        )
    }

    private func load() async {
        guard settings.credentials.isComplete, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        projects = await JiraClient(credentials: settings.credentials).projects()
    }
}

// MARK: - Time

private struct TeamSettings: View {
    @Bindable var settings: AppSettings
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach($settings.people) { $person in
                    HStack(spacing: 10) {
                        Toggle(isOn: $person.isSelected) { EmptyView() }
                            .labelsHidden()

                        Avatar(person: person, size: 26)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(person.name).lineLimit(1)
                            TextField("Apelido", text: Binding(
                                get: { person.nickname ?? "" },
                                set: { person.nickname = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if isLoading { ProgressView() }
                else if settings.people.isEmpty {
                    ContentUnavailableView("Nenhum participante", systemImage: "person.3",
                                           description: Text("Carregue a partir dos projetos selecionados."))
                }
            }

            Divider()

            HStack {
                Text("\(settings.selectedPeople.count) na daily")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Buscar do Jira") { Task { await load() } }
                    .disabled(settings.projectKeys.isEmpty || isLoading)
            }
            .padding(10)
        }
        .onChange(of: settings.people) { _, _ in settings.save() }
    }

    /// Busca quem tem card em aberto, preservando apelidos e marcações já feitas.
    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let client = JiraClient(credentials: settings.credentials)
        let boards = await client.boards(projectKeys: settings.projectKeys)
        let found = await client.assignees(boards: boards)

        let existing = Dictionary(uniqueKeysWithValues: settings.people.map { ($0.id, $0) })
        settings.people = found.map { person in
            var merged = person
            if let old = existing[person.id] {
                merged.nickname = old.nickname
                merged.isSelected = old.isSelected
            }
            return merged
        }
        settings.save()
    }
}
