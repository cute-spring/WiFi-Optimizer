import SwiftUI
import WiFi_Optimizer

struct CombinedAnalysisView: View {
    @EnvironmentObject var model: ScannerModel
    @EnvironmentObject var prefs: UserPreferences

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                // 当前网络分析
                if let analysis = model.networkAnalysis {
                    CurrentNetworkAnalysisView(analysis: analysis)
                } else {
                    SectionCard(title: "当前网络分析") {
                        Text("未连接到WiFi网络")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                // 质量参考（直接嵌入原有视图以复用逻辑和样式）
                SectionCard(title: "质量参考") {
                    QualityReferenceView()
                        .environmentObject(model)
                        .environmentObject(prefs)
                }
            }
            .padding([.horizontal, .bottom], 12)
        }
    }
}