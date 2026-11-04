import SwiftUI

/// Seleção de projetos e de participantes. São os mesmos controles nas preferências e no
/// setup inicial — quem já passou pelo setup reencontra a tela que conhece em ⌘,.

struct ProjectPicker: View {
    @Bindable var settings: AppSettings

    @State private var projects: [JiraProject] = []
    @State private var search = ""
    @State private var isLoading = false

    /// Com algumas centenas de projetos, quem já está marcado precisa ficar à vista —
    /// senão a pessoa não consegue conferir o que escolheu sem rolar a lista inteira.
    private var filtered: [JiraProject] {
        let matching = search.isEmpty ? projects : projects.filter {
            $0.key.localizedCaseInsensitiveContains(search)
                || $0.name.localizedCaseInsensitiveContains(search)
        }
        let selected = Set(settings.projectKeys)
        return matching.sorted { lhs, rhs in
            let left = selected.contains(lhs.key), right = selected.contains(rhs.key)
            return left == right ? lhs.key < rhs.key : left
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Buscar projeto", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)

            Divider()

            List {
                ForEach(filtered) { project in
                    Toggle(isOn: binding(for: project)) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(project.key).scaledFont(.body, weight: .medium)
                            Text(project.name)
                                .scaledFont(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .overlay {
                if isLoading { ProgressView() }
                else if projects.isEmpty {
                    ContentUnavailableView("Nenhum projeto", systemImage: "square.grid.2x2",
                                           description: Text("Confira o e-mail e o token do Jira."))
                }
            }

            Divider()

            HStack {
                Text("\(settings.projectKeys.count) selecionados")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Recarregar") { Task { await load() } }
                    .disabled(isLoading)
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

struct TeamPicker: View {
    @Bindable var settings: AppSettings

    /// No setup a lista começa vazia e buscar é o passo seguinte; nas preferências o
    /// time já está salvo e buscar de novo é opcional.
    var loadsAutomatically = false

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
                            .scaledFont(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if isLoading { ProgressView() }
                else if settings.people.isEmpty {
                    ContentUnavailableView("Nenhum participante", systemImage: "person.3",
                                           description: Text("A busca traz quem está como responsável por um card em aberto nos projetos selecionados. Se a lista vier vazia, nenhum card desses projetos tem responsável atribuído."))
                }
            }

            Divider()

            HStack {
                Text("\(settings.selectedPeople.count) na daily")
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if isLoading { ProgressView().controlSize(.small) }
                Button("Buscar do Jira") { Task { await load() } }
                    .disabled(settings.projectKeys.isEmpty || isLoading)
            }
            .padding(10)
        }
        .onChange(of: settings.people) { _, _ in settings.save() }
        .task {
            guard loadsAutomatically, settings.people.isEmpty else { return }
            await load()
        }
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
