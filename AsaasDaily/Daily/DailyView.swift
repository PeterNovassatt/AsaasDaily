import SwiftUI

struct DailyView: View {
    @Bindable var settings: AppSettings
    let daily: DailyModel

    @State private var selection: Participant.ID?
    @Namespace private var stageNamespace
    @Environment(\.colorScheme) private var systemScheme

    private var shown: Participant? {
        daily.participants.first { $0.id == selection } ?? daily.speaker
    }

    var body: some View {
        Group {
            if daily.isPresenting, let participant = daily.speaker ?? shown {
                PresentationStage(daily: daily,
                                  participant: participant,
                                  namespace: stageNamespace,
                                  onExit: { withAnimation(.smooth) { daily.isPresenting = false } })
                    .transition(.opacity)
            } else {
                splitView.transition(.opacity)
            }
        }
        .environment(\.fontScale, settings.textScale.factor)
        .preferredColorScheme(settings.appearance.colorScheme)
        .modifier(FullScreenSync(isPresenting: Binding(
            get: { daily.isPresenting },
            set: { daily.isPresenting = $0 }
        )))
        .sheet(item: $settings.sheet) { destination in
            switch destination {
            case .setup:
                SetupView(settings: settings) { startsDaily in
                    settings.sheet = nil
                    Task {
                        await reload()
                        if startsDaily { advance() }
                    }
                }
            case .guide:
                GuideSheet()
            }
        }
        .task { await loadIfNeeded() }
        .onAppear { if settings.needsSetup { settings.sheet = .setup } }
        .onChange(of: daily.speaker?.id) { _, new in
            withAnimation(.smooth) { selection = new }
        }
    }

    private var splitView: some View {
        NavigationSplitView {
            ParticipantSidebar(daily: daily, selection: $selection)
        } detail: {
            detail
                .navigationTitle(shown?.name ?? "AsaasDaily")
                .navigationSubtitle(subtitle)
                .toolbar { toolbarContent }
        }
    }

    // MARK: Detalhe

    @ViewBuilder
    private var detail: some View {
        if daily.isLoading {
            ContentUnavailableView {
                Label("Carregando a sprint", systemImage: "arrow.triangle.2.circlepath")
            } description: {
                Text(settings.projectKeys.joined(separator: " · "))
            }
        } else if let error = daily.errorMessage {
            ContentUnavailableView {
                Label("Não consegui carregar", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Tentar de novo") { Task { await reload() } }
            }
        } else if !settings.isConfigured {
            ContentUnavailableView {
                Label("Configure o acesso ao Jira", systemImage: "gearshape")
            } description: {
                Text("E-mail, API token, projetos e participantes.")
            } actions: {
                Button("Configurar agora") { settings.sheet = .setup }
                    .buttonStyle(.borderedProminent)
            }
        } else if let participant = shown {
            ParticipantDetail(participant: participant,
                              isSpeaking: participant.id == daily.speaker?.id,
                              mode: settings.cardsViewMode,
                              namespace: stageNamespace,
                              isRefreshing: daily.isRefreshingSpeaker,
                              onRefresh: { Task { await daily.refreshSpeaker() } },
                              onOpen: open)
        } else if daily.isFinished {
            ContentUnavailableView {
                Label("Daily concluída", systemImage: "checkmark.seal")
            } description: {
                Text("Todo mundo falou.")
            } actions: {
                Button("Nova rodada") { Task { await reload() } }
            }
        } else {
            ContentUnavailableView {
                Label("Pronto para começar", systemImage: "person.2.wave.2")
            } description: {
                Text("A ordem prioriza quem tem card em review ou em progresso.")
            } actions: {
                Button("Iniciar") { advance() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var subtitle: String {
        guard daily.totalCount > 0 else { return settings.projectKeys.joined(separator: " · ") }
        return "\(daily.spokenCount) de \(daily.totalCount) · \(daily.codeReviewCount) em review · \(daily.flaggedCount) com flag"
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button {
                withAnimation(.smooth(duration: 0.4)) { daily.previous() }
            } label: {
                Label("Voltar", systemImage: "chevron.backward")
            }
            .disabled(!daily.canGoBack)
            .help("Voltar para quem já falou (←)")

            Button(action: advance) {
                Label(daily.hasStarted ? "Próximo" : "Iniciar", systemImage: "chevron.forward")
            }
            .disabled(daily.participants.isEmpty || daily.isFinished)
            .help("Próximo (→)")
        }

        ToolbarItem(placement: .principal) {
            if daily.totalCount > 0 {
                ProgressRing(spoken: daily.spokenCount, total: daily.totalCount)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Picker("Visualização", selection: $settings.cardsViewMode) {
                ForEach(CardsViewMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelStyle(.iconOnly)
            .help("Alternar entre lista e quadro")
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                withAnimation(.smooth(duration: 0.4)) { daily.skip() }
            } label: {
                Label("Pular", systemImage: "forward.end")
            }
            .disabled(daily.speaker == nil)
            .help("Manda para o fim da fila (⌘K)")

            Button {
                Task { await reload() }
            } label: {
                Label("Nova rodada", systemImage: "arrow.clockwise")
            }
            .help("Nova rodada (⇧⌘R)")

            Menu {
                Button("Aumentar", systemImage: "textformat.size.larger") {
                    settings.textScale = settings.textScale.increased()
                }
                .disabled(!settings.textScale.canIncrease)
                .keyboardShortcut("+", modifiers: .command)

                Button("Diminuir", systemImage: "textformat.size.smaller") {
                    settings.textScale = settings.textScale.decreased()
                }
                .disabled(!settings.textScale.canDecrease)
                .keyboardShortcut("-", modifiers: .command)

                Divider()

                Picker("Tamanho", selection: $settings.textScale) {
                    ForEach(TextScale.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                Label("Tamanho do texto", systemImage: "textformat.size")
            }
            .help("Tamanho do texto: \(settings.textScale.label)")

            Button {
                withAnimation(.smooth(duration: 0.5)) { daily.isPresenting = true }
            } label: {
                Label("Apresentar", systemImage: "play.rectangle")
            }
            .disabled(daily.speaker == nil)
            .help("Modo apresentação (⇧⌘P)")

            Button {
                withAnimation(.smooth) {
                    settings.appearance = settings.appearance.toggled(systemIsDark: systemScheme == .dark)
                }
            } label: {
                Label(settings.appearance.label, systemImage: settings.appearance.symbol)
                    .contentTransition(.symbolEffect(.replace))
            }
            .help("Aparência: \(settings.appearance.label)")
        }
    }

    // MARK: Ações

    private func advance() {
        withAnimation(.smooth(duration: 0.4)) { daily.next() }
    }

    private func loadIfNeeded() async {
        guard daily.participants.isEmpty, settings.isConfigured else { return }
        await reload()
    }

    private func reload() async {
        await daily.reset(credentials: settings.credentials,
                          projectKeys: settings.projectKeys,
                          people: settings.people)
    }

    private func open(_ issue: JiraIssue) {
        NSWorkspace.shared.open(settings.credentials.site.appending(path: "browse/\(issue.key)"))
    }
}
