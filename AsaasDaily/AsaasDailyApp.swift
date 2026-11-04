import SwiftUI

@main
struct AsaasDailyApp: App {
    @State private var settings = AppSettings()
    @State private var daily = DailyModel()

    var body: some Scene {
        WindowGroup {
            DailyView(settings: settings, daily: daily)
        }
        .defaultSize(width: 1440, height: 900)
        // Sem .hiddenTitleBar: ele troca o botão verde de tela cheia por "zoom",
        // e o modo apresentação depende de tela cheia de verdade.
        .windowResizability(.contentMinSize)
        .commands { DailyCommands(daily: daily, settings: settings) }

        Settings {
            SettingsView(settings: settings)
        }
    }
}

/// Atalhos na barra de menus — é onde o macOS espera que eles vivam e,
/// de quebra, onde o time descobre que existem.
struct DailyCommands: Commands {
    let daily: DailyModel
    @Bindable var settings: AppSettings

    var body: some Commands {
        CommandMenu("Daily") {
            Button(daily.hasStarted ? "Próximo" : "Iniciar") {
                withAnimation(.smooth(duration: 0.45)) { daily.next() }
            }
            .keyboardShortcut(.rightArrow, modifiers: [])
            .disabled(daily.participants.isEmpty)

            Button("Voltar para quem já falou") {
                withAnimation(.smooth(duration: 0.45)) { daily.previous() }
            }
            .keyboardShortcut(.leftArrow, modifiers: [])
            .disabled(!daily.canGoBack)

            Button("Pular (vai para o fim da fila)") {
                withAnimation(.smooth(duration: 0.45)) { daily.skip() }
            }
            .keyboardShortcut("k", modifiers: .command)
            .disabled(daily.speaker == nil)

            Divider()

            Button("Atualizar cards de quem está falando") {
                Task { await daily.refreshSpeaker() }
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(daily.speaker == nil)

            Button(daily.isPresenting ? "Sair da apresentação" : "Apresentar") {
                withAnimation(.smooth(duration: 0.5)) { daily.isPresenting.toggle() }
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(daily.speaker == nil && !daily.isPresenting)

            Divider()

            Button("Nova rodada") {
                Task {
                    await daily.reset(credentials: settings.credentials,
                                      projectKeys: settings.projectKeys,
                                      people: settings.people)
                }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Toggle("Mostrar épico ou tarefa-pai", isOn: $settings.showsParent)
                .keyboardShortcut("e", modifiers: .command)

            Divider()

            // ⌘+ exige shift no teclado, então o sistema enxerga ⌘⇧=; registrar os
            // dois jeitos é o que faz o atalho responder como o usuário espera.
            Button("Aumentar fonte") { settings.textScale = settings.textScale.increased() }
                .keyboardShortcut("=", modifiers: .command)
                .disabled(!settings.textScale.canIncrease)

            Button("Aumentar fonte ") { settings.textScale = settings.textScale.increased() }
                .keyboardShortcut("+", modifiers: [.command, .shift])
                .disabled(!settings.textScale.canIncrease)

            Button("Diminuir fonte") { settings.textScale = settings.textScale.decreased() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(!settings.textScale.canDecrease)

            Button("Tamanho padrão") { settings.textScale = .padrao }
                .keyboardShortcut("0", modifiers: .command)
        }

        // O guia continua disponível depois do primeiro uso: é onde o macOS
        // manda procurar quando alguém não sabe o que um atalho faz.
        CommandGroup(replacing: .help) {
            Button("Guia do AsaasDaily") { settings.sheet = .guide }
                .keyboardShortcut("?", modifiers: .command)

            Button("Refazer configuração…") { settings.sheet = .setup }

            Divider()

            Button("Abrir o Jira") {
                NSWorkspace.shared.open(settings.credentials.site)
            }
        }
    }
}
