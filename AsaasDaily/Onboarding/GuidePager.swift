import SwiftUI

/// Os três passos do guia, com ilustração, avanço por botão ou pelas setas e, no fim,
/// a ação que leva direto ao app.
struct GuidePager: View {
    /// Volta do primeiro passo (no setup, para o time); sem ela o botão não aparece.
    var onBackFromFirst: (() -> Void)?
    /// `true` quando a pessoa terminou pelo botão principal e quer começar a daily.
    let onFinish: (Bool) -> Void

    @State private var index = 0
    @State private var forward = true
    @FocusState private var isFocused: Bool

    private var steps: [GuideStep] { Guide.steps }
    private var step: GuideStep { steps[index] }
    private var isLast: Bool { index == steps.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 36)
                .padding(.top, 24)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            footer
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress(.rightArrow) { next(); return .handled }
        .onKeyPress(.leftArrow) { previous(); return .handled }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Como a daily corre", systemImage: "sparkles")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text("\(index + 1) de \(steps.count)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(index)))
            }

            VStack(alignment: .leading, spacing: 18) {
                GuideIllustrationView(illustration: step.illustration)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.quaternary)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Label(step.title, systemImage: step.symbol)
                        .font(.title2.bold())
                    Text(step.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .id(step.id)
            .transition(.asymmetric(
                insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
            ))

            Spacer(minLength: 12)

            // Dentro do setup quem marca o progresso são os pontos do topo; dois
            // conjuntos na mesma tela contariam coisas diferentes lado a lado.
            if onBackFromFirst == nil {
                StepDots(count: steps.count, current: index)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.spring(duration: 0.45), value: index)
    }

    private var footer: some View {
        HStack {
            if index > 0 {
                Button("Voltar", action: previous)
            } else if let onBackFromFirst {
                Button("Voltar", action: onBackFromFirst)
            }
            Spacer()
            if isLast {
                Button("Fechar") { onFinish(false) }
                Button("Começar a daily") { onFinish(true) }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Próximo", action: next)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .controlSize(.large)
    }

    private func next() {
        guard !isLast else { return }
        forward = true
        index += 1
    }

    private func previous() {
        guard index > 0 else { return }
        forward = false
        index -= 1
    }
}

/// Os pontos de progresso: o atual vira cápsula, os outros ficam redondos.
struct StepDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { item in
                Capsule()
                    .fill(item <= current ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary))
                    .frame(width: item == current ? 24 : 8, height: 6)
            }
        }
        .animation(.spring(duration: 0.4), value: current)
    }
}

/// O guia aberto de novo pelo menu Ajuda, sem o setup em volta.
struct GuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GuidePager { _ in dismiss() }
            .frame(width: 620, height: 560)
    }
}
