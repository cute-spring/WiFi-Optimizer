import SwiftUI

// Lightweight design system for consistent spacing, card surfaces, and status chips
struct AppTheme {
    static let cornerRadius: CGFloat = 12
    static let smallCorner: CGFloat = 8
    static let cardPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 16
    static let shadowRadius: CGFloat = 4
}

struct SectionCard<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let t = title { Text(t).font(.headline).bold() }
            content
        }
        .padding(AppTheme.cardPadding)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: AppTheme.shadowRadius, x: 0, y: 1)
    }
}

struct StatusChip: View {
    let title: String
    let systemImage: String?
    let color: Color

    init(_ title: String, systemImage: String? = nil, color: Color) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        HStack(spacing: 6) {
            if let image = systemImage {
                Image(systemName: image)
                    .font(.caption)
                    .foregroundColor(color)
            }
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}