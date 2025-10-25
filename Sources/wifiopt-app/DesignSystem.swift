import SwiftUI

// Lightweight design system for consistent spacing, card surfaces, and status chips
struct AppTheme {
    static let cornerRadius: CGFloat = 12
    static let smallCorner: CGFloat = 8
    static let cardPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 16
    static let shadowRadius: CGFloat = 4
    
    // Brand palette for quality levels (centralized)
    static let qualityVeryPoor: Color = Color(red: 0.90, green: 0.22, blue: 0.22) // red
    static let qualityPoor: Color = Color(red: 0.96, green: 0.62, blue: 0.18)     // orange
    static let qualityFair: Color = Color(red: 0.96, green: 0.86, blue: 0.24)     // yellow
    static let qualityGood: Color = Color(red: 0.28, green: 0.63, blue: 0.99)     // blue
    static let qualityExcellent: Color = Color(red: 0.22, green: 0.78, blue: 0.38) // green
    static let muted: Color = Color.gray
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