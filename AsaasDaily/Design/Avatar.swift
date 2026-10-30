import SwiftUI

/// Foto da pessoa, com as iniciais como fallback enquanto carrega ou se não houver.
struct Avatar: View {
    let person: JiraPerson
    var size: CGFloat = 28

    private var initials: String {
        person.displayName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var body: some View {
        AsyncImage(url: person.avatarURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Rectangle().fill(.quaternary)
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
    }
}
