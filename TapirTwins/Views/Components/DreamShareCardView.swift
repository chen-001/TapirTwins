import SwiftUI

/// 用于分享的梦境内容类型
enum DreamShareContentType {
    case dream                 // 原始梦境
    case interpretation        // 解梦内容
    case continuation          // 续写内容
    case prediction            // 预言内容
    
    var title: String {
        switch self {
        case .dream: return "梦境记录"
        case .interpretation: return "梦境解析"
        case .continuation: return "梦境续写"
        case .prediction: return "梦境预言"
        }
    }
    
    var iconName: String {
        switch self {
        case .dream: return "moon.stars"
        case .interpretation: return "wand.and.stars"
        case .continuation: return "text.book.closed"
        case .prediction: return "sparkles"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .dream: 
            return [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.5)]
        case .interpretation: 
            return [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]
        case .continuation: 
            return [Color.cyan.opacity(0.8), Color.green.opacity(0.8)]
        case .prediction: 
            return [Color.orange.opacity(0.8), Color.red.opacity(0.8)]
        }
    }
}

struct DreamShareCardView: View {
    let dreamTitle: String
    let dreamDate: String
    let content: String
    let contentType: DreamShareContentType
    let style: String?
    let appName: String = "TapirTwins貘貘梦境日记"
    
    // 根据内容长度计算适当的字体大小 - 整体增大字号
    private var contentFontSize: CGFloat {
        let length = content.count
        if length > 500 {
            return 22 // 非常长的内容 (原16)
        } else if length > 300 {
            return 34 // 长内容 (原18)
        } else if length > 150 {
            return 46 // 中等内容 (原20)
        } else {
            return 48 // 短内容 (原22)
        }
    }
    
    // 根据标题长度计算适当的字体大小 - 整体增大字号
    private var titleFontSize: CGFloat {
        let length = dreamTitle.count
        if length > 20 {
            return 48 // 长标题 (原22)
        } else if length > 10 {
            return 52 // 中等标题 (原26)
        } else {
            return 56 // 短标题 (原30)
        }
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: contentType.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 星星背景效果（仅在梦境类型时显示）
            if contentType == .dream {
                StarsView()
                    .opacity(0.5)
            }
            
            // 内容卡片
            VStack(alignment: .leading, spacing: 40) { // 减小间距，使内容更紧凑
                // 顶部标题栏
                HStack {
                    Image(systemName: contentType.iconName)
                        .font(.system(size: 58)) // 增大图标尺寸
                        .foregroundColor(.white)
                    
                    Text(contentType.title)
                        .font(.system(size: 58, weight: .bold)) // 增大标题尺寸
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 显示风格（如果有）
                    if let style = style {
                        Text(styleDisplayName(style))
                            .font(.system(size: 48, weight: .medium)) // 略微增大
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(30)
                    }
                }
                
                // 梦境标题
                Text(dreamTitle)
                    .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                
                // 日期
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.white.opacity(0.8))
                    Text(formattedDate(dreamDate))
                        .font(.system(size: 38)) // 增大日期文字
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 35)
                
                // 分隔线
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.vertical, 35)
                
                // 主要内容 - 移除ScrollView，让内容直接显示，并增加空间占比
                Text(content)
                    .font(.system(size: contentFontSize))
                    .foregroundColor(.white)
                    .lineSpacing(contentFontSize * 0.4) // 根据字体大小调整行间距
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxHeight: .infinity, alignment: .top) // 使用最大高度，但内容顶部对齐
                
                // 占位Spacer，控制底部30%的空白
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.25) // 保留约25%的底部空间
                
                // 底部应用名称水印
                HStack {
                    Spacer()
                    Text(appName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 30)
            }
            .padding(25)
            .padding(.vertical, 30) // 增加垂直内边距
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.2))
                    .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
            )
            .padding(20)
        }
    }
    
    // 格式化日期
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy年MM月dd日"
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // 风格名称映射
    private func styleDisplayName(_ style: String) -> String {
        switch style {
        // 解梦风格
        case "mystic": return "玄学解梦"
        case "scientific": return "科学解析"
        case "humorous": return "幽默解读"
        case "zhenHuan1": return "甄嬛解梦"
            
        // 续写风格
        case "comedy": return "喜剧风格"
        case "tragedy": return "悲剧风格"
        case "mystery": return "悬疑风格"
        case "scifi": return "科幻风格"
        case "ethical": return "伦理风格"
        case "zhenHuan2": return "甄嬛续写"
            
        // 预言时间范围
        case "predictToday": return "今日预言"
        case "predictMonth": return "月预言"
        case "predictYear": return "年预言"
        case "predictFiveYears": return "五年预言"
        case "zhenHuan3": return "甄嬛预言"
            
        default: return style
        }
    }
}

struct DreamShareCardView_Previews: PreviewProvider {
    static var previews: some View {
        DreamShareCardView(
            dreamTitle: "飞翔在天空中",
            dreamDate: "2023-03-01",
            content: "我梦见自己在高空飞行，俯瞰整个城市。感觉非常自由，风吹过我的脸庞，我能控制自己飞行的方向和高度。城市的灯光在夜晚闪烁，像是星星落在了地面上。",
            contentType: .dream,
            style: nil
        )
        .previewDisplayName("梦境记录")
        .frame(width: 390, height: 844) // iPhone 14尺寸
        
        DreamShareCardView(
            dreamTitle: "飞翔在天空中",
            dreamDate: "2023-03-01",
            content: "这个梦境暗示着你正在经历一段转变期，飞翔象征着自由和超越现实限制的渴望。俯瞰大地代表你希望获得更广阔的视野和洞察力。这个梦境预示着即将到来的积极变化和个人成长。",
            contentType: .interpretation,
            style: "mystic"
        )
        .previewDisplayName("解梦内容")
        .frame(width: 390, height: 844) // iPhone 14尺寸
    }
} 