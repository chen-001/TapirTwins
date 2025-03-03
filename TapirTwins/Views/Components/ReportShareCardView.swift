import SwiftUI

/// 用于报告分享的卡片视图
struct ReportShareCardView: View {
    let reportTitle: String
    let reportType: String
    let startDate: String?
    let endDate: String?
    let dreamsCount: Int?
    let content: String
    let appName: String = "TapirTwins貘貘梦境日记"
    
    // 日期格式化器
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    // 处理内容，将Markdown转为纯文本
    private var processedContent: String {
        return processMarkdown(content)
    }
    
    // 根据内容长度计算适当的字体大小
    private var contentFontSize: CGFloat {
        let contentLength = content.count
        if contentLength > 2000 {
            return 18 // 超长内容
        } else if contentLength > 1000 {
            return 20 // 非常长的内容
        } else if contentLength > 500 {
            return 22 // 长内容
        } else if contentLength > 300 {
            return 24 // 中等内容
        } else {
            return 26 // 短内容
        }
    }
    
    // 根据标题长度计算适当的字体大小
    private var titleFontSize: CGFloat {
        let titleLength = reportTitle.count
        if titleLength > 20 {
            return 36 // 长标题
        } else if titleLength > 10 {
            return 42 // 中等标题
        } else {
            return 48 // 短标题
        }
    }
    
    // 根据报告类型获取图标
    private var reportIcon: String {
        switch reportType.lowercased() {
        case "personality":
            return "person.fill"
        case "summary":
            return "doc.text.fill"
        case "weekreport":
            return "calendar.badge.clock"
        case "monthreport":
            return "chart.bar.fill"
        case "emotions":
            return "heart.fill"
        case "themes":
            return "leaf.fill"
        default:
            return "doc.fill"
        }
    }
    
    // 根据报告类型获取渐变色
    private var gradientColors: [Color] {
        switch reportType.lowercased() {
        case "personality":
            return [Color(red: 0.2, green: 0.3, blue: 0.8).opacity(0.8), Color(red: 0.5, green: 0.2, blue: 0.8).opacity(0.6)]
        case "summary":
            return [Color(red: 0.2, green: 0.6, blue: 0.8).opacity(0.8), Color(red: 0.1, green: 0.5, blue: 0.3).opacity(0.6)]
        case "weekreport", "weekReport":
            return [Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.8), Color(red: 1.0, green: 0.6, blue: 0.3).opacity(0.6)]
        case "monthreport", "monthReport":
            return [Color(red: 0.6, green: 0.2, blue: 0.6).opacity(0.8), Color(red: 0.8, green: 0.3, blue: 0.7).opacity(0.6)]
        case "yearreport", "yearReport":
            return [Color(red: 0.1, green: 0.4, blue: 0.6).opacity(0.8), Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.6)]
        case "emotions":
            return [Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.8), Color(red: 0.7, green: 0.1, blue: 0.4).opacity(0.6)]
        case "themes":
            return [Color(red: 0.3, green: 0.7, blue: 0.4).opacity(0.8), Color(red: 0.5, green: 0.8, blue: 0.2).opacity(0.6)]
        default:
            return [Color(red: 0.3, green: 0.4, blue: 0.7).opacity(0.8), Color(red: 0.5, green: 0.3, blue: 0.7).opacity(0.6)]
        }
    }
    
    // 根据背景色自动选择文本颜色
    private var textColor: Color {
        // 渐变色通常较深，使用白色最安全
        return .white
    }
    
    // 辅助文本颜色
    private var secondaryTextColor: Color {
        return .white.opacity(0.85)
    }
    
    var body: some View {
        ZStack {
            // 梦幻背景
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // 添加星光效果
            ZStack {
                ForEach(0..<20) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                        .frame(width: CGFloat.random(in: 2...6))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                }
            }
            
            // 内容容器
            VStack(spacing: 20) {
                // 顶部区域：标题和信息
                VStack(spacing: 12) {
                    // 标题和图标
                    HStack {
                        Text(reportTitle)
                            .font(.system(size: titleFontSize, weight: .bold))
                            .foregroundColor(textColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 1, y: 1)
                        
                        Spacer()
                        
                        // 报告类型图标
                        Image(systemName: reportIcon)
                            .font(.system(size: 36))
                            .foregroundColor(textColor)
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 1, y: 1)
                    }
                    .padding(.top, 24)
                    
                    // 日期信息
                    HStack {
                        if let startDate = startDate, let endDate = endDate {
                            Text("\(startDate) - \(endDate)")
                                .font(.system(size: 16))
                                .foregroundColor(secondaryTextColor)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        }
                        
                        Spacer()
                        
                        // 梦境数量
                        if let dreamsCount = dreamsCount {
                            Text("梦境数量: \(dreamsCount)")
                                .font(.system(size: 16))
                                .foregroundColor(secondaryTextColor)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                
                // 分隔线
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(height: 2)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                // 内容区域 - 添加半透明背景使文本更易读
                ScrollView {
                    Text(processedContent)
                        .font(.system(size: contentFontSize))
                        .foregroundColor(textColor)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
                .frame(maxHeight: .infinity)
                .background(Color.black.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                // TAPIR TWINS 水印
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("TAPIR TWINS")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(textColor)
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 1, y: 1)
                        
                        Text("AI梦境解析")
                            .font(.system(size: 14))
                            .foregroundColor(secondaryTextColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .padding(.vertical, 12)
        }
    }
    
    // 处理Markdown内容（简化版）
    private func processMarkdown(_ text: String) -> String {
        var result = text
        
        // 处理标题
        let headerPattern = ##"#+\s+(.*)"##
        if let regex = try? NSRegularExpression(pattern: headerPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1:"
            )
        }
        
        // 处理粗体
        let boldPattern = ##"\*\*(.*?)\*\*"##
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1"
            )
        }
        
        // 处理斜体
        let italicPattern = ##"\*(.*?)\*"##
        if let regex = try? NSRegularExpression(pattern: italicPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1"
            )
        }
        
        // 处理列表项
        let listPattern = ##"^\s*-\s+(.*)"##
        if let regex = try? NSRegularExpression(pattern: listPattern, options: .anchorsMatchLines) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "• $1"
            )
        }
        
        return result
    }
}

struct ReportShareCardView_Previews: PreviewProvider {
    static var previews: some View {
        ReportShareCardView(
            reportTitle: "梦境月报",
            reportType: "monthReport",
            startDate: "2023-05-01",
            endDate: "2023-05-31",
            dreamsCount: 15,
            content: """
            ## 梦境月报 - 2023年5月
            
            在过去的一个月里，您记录了15个梦境，这些梦境反映了您的潜意识活动和心理状态。
            
            ### 梦境类型分布
            - 冒险类梦境: 5个 (33%)
            - 日常生活类梦境: 4个 (27%)
            - 焦虑类梦境: 3个 (20%)
            - 奇幻类梦境: 3个 (20%)
            
            ### 情绪状态分析
            您的梦境中主要呈现积极情绪，占比约65%，这表明您的心理状态总体良好。
            
            ### 关键词频率
            飞行、家人、工作、水、动物是出现频率最高的五个关键词。
            
            ### 建议
            多关注与"工作"相关的梦境内容，这可能暗示您的潜意识正在处理工作压力或挑战。
            """
        )
        .previewDisplayName("梦境月报")
        .frame(width: 390, height: 1200) // 展示长内容的高度
    }
} 