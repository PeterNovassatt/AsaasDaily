import SwiftUI

/// Primeira abertura: conecta o Jira, escolhe os projetos e o time, e termina no guia.
/// Cada passo só libera o seguinte quando tem o que o app precisa para funcionar —
/// é o que evita a tela vazia de "configure o acesso" logo depois de instalar.
struct SetupView: View {
    @Bindable var settings: AppSettings
    /// Chamado no fim com `true` quando a pessoa quer começar a daily na hora.
    let onFinish: (Bool) -> Void

    private enum Step: Int, CaseIterable {
        case account, projects, team, guide
    }

    private enum CheckStatus: Equatable {
        case idle, checking, connected(Int), failed
    }

    @State private var step = Step.account
    @State private var status = CheckStatus.idle
    @State private var forward = true

    private static let tokenURL = URL(string: "https://id.atlassian.com/manage-profile/security/api-tokens")!

    var body: some View {
        VStack(spacing: 0) {
            StepDots(count: Step.allCases.count, current: step.rawValue)
                .padding(.top, 22)

            if step == .guide {
                // O guia traz os próprios botões e o último deles conclui o setup.
                GuidePager(onBackFromFirst: { go(to: .team) }, onFinish: finish)
                    .transition(transition)
            } else {
                Group {
                    switch step {
                    case .account: accountStep
                    case .projects: projectsStep
                    default: teamStep
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 22)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(transition)
                .id(step)

                Divider()
                footer
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
            }
        }
        .frame(width: 620, height: 560)
        .interactiveDismissDisabled()
        .animation(.spring(duration: 0.4), value: step)
        .onChange(of: settings.credentials.email) { status = .idle }
        .onChange(of: settings.credentials.apiToken) { status = .idle }
    }

    private var transition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    // MARK: - Conta

    private var accountStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.accentColor)
                    .padding(.bottom, 4)
                Text("Boas-vindas ao AsaasDaily").font(.largeTitle.bold())
                Text("O app conduz a daily do time: monta a fila, mostra os cards de cada pessoa direto do Jira e projeta tudo na tela da reunião. Começa conectando a sua conta.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Form {
                Section {
                    TextField("E-mail", text: $settings.credentials.email,
                              prompt: Text("nome@asaas.com.br"))
                    SecureField("API token", text: $settings.credentials.apiToken,
                                prompt: Text("Token gerado em id.atlassian.com"))
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("O token fica no Keychain do seu Mac, nunca nas preferências.")
                            .foregroundStyle(.secondary)
                        Link("Criar um API token no Atlassian", destination: Self.tokenURL)
                    }
                    .font(.callout)
                    .padding(.top, 2)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 170)

            statusLine
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        switch status {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Conferindo o acesso…").foregroundStyle(.secondary)
            }
        case .connected(let count):
            Label("Conectado · \(count) projetos visíveis", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Label("Não consegui autenticar. Confira o e-mail e gere um token novo.",
                  systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Projetos

    private var projectsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            header("Quais projetos entram na daily?",
                   "Os cards vêm dos boards destes projetos. Dá para mudar depois em Preferências.",
                   symbol: "square.grid.2x2")

            ProjectPicker(settings: settings)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.quaternary)
                }
        }
    }

    // MARK: - Time

    private var teamStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            header("Quem participa?",
                   "Busquei quem tem card em aberto nos projetos escolhidos. Marque quem fala na daily — o apelido é o nome que aparece na tela.",
                   symbol: "person.3")

            TeamPicker(settings: settings, loadsAutomatically: true)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.quaternary)
                }
        }
    }

    private func header(_ title: String, _ subtitle: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol).font(.title2.bold())
            Text(subtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Rodapé

    private var footer: some View {
        HStack {
            if step != .account {
                Button("Voltar") { go(to: Step(rawValue: step.rawValue - 1) ?? .account) }
            }
            Spacer()
            if let hint = blockingHint {
                Text(hint).font(.callout).foregroundStyle(.secondary)
            }
            Button("Continuar", action: advance)
                .keyboardShortcut(.defaultAction)
                .disabled(!canAdvance)
        }
        .controlSize(.large)
    }

    private var canAdvance: Bool {
        switch step {
        case .account: settings.credentials.isComplete && status != .checking
        case .projects: !settings.projectKeys.isEmpty
        case .team: settings.people.contains(where: \.isSelected)
        case .guide: true
        }
    }

    /// Diz o que falta em vez de deixar o botão apagado sem explicação.
    private var blockingHint: String? {
        switch step {
        case .account: settings.credentials.isComplete ? nil : "Preencha o e-mail e o token"
        case .projects: settings.projectKeys.isEmpty ? "Escolha ao menos um projeto" : nil
        case .team: settings.people.contains(where: \.isSelected) ? nil : "Marque quem participa"
        case .guide: nil
        }
    }

    // MARK: - Navegação

    private func advance() {
        switch step {
        case .account: Task { await checkAndContinue() }
        case .projects: go(to: .team)
        case .team: go(to: .guide)
        case .guide: finish(true)
        }
    }

    /// O passo da conta só avança com credencial que o Jira aceitou: errar aqui
    /// deixaria as duas telas seguintes vazias sem dizer por quê.
    private func checkAndContinue() async {
        settings.save()
        status = .checking

        let found = await JiraClient(credentials: settings.credentials).projects()
        guard !found.isEmpty else {
            status = .failed
            return
        }
        status = .connected(found.count)
        go(to: .projects)
    }

    private func go(to next: Step) {
        forward = next.rawValue > step.rawValue
        step = next
    }

    private func finish(_ startsDaily: Bool) {
        settings.save()
        settings.setupCompleted = true
        onFinish(startsDaily)
    }
}
