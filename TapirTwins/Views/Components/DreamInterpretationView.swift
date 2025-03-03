import SwiftUI

struct DreamInterpretationView: View {
    let interpretation: DreamInterpretation
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和折叠/展开按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: iconForStyle(interpretation.style))
                        .foregroundColor(colorForStyle(interpretation.style))
                        .font(.system(size: 20))
                    
                    Text(titleForStyle(interpretation.style))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatDate(interpretation.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14))
                        .padding(.leading, 4)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                // 分隔线
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, colorForStyle(interpretation.style).opacity(0.5), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                // 内容 - 支持Markdown
                markdownContentView
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
                    .padding(.bottom, 10)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.3),
                            backgroundColorForStyle(interpretation.style).opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(colorForStyle(interpretation.style).opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
    
    // 创建Markdown内容视图
    @ViewBuilder
    private var markdownContentView: some View {
        if #available(iOS 15.0, *) {
            markdownText
        } else {
            Text(interpretation.content)
        }
    }
    
    // 处理Markdown转换
    @available(iOS 15.0, *)
    private var markdownText: Text {
        do {
            let attributedString = try AttributedString(markdown: interpretation.content)
            return Text(attributedString)
        } catch {
            return Text(interpretation.content)
        }
    }
    
    private func iconForStyle(_ style: String) -> String {
        switch style {
        case "mystic":
            return "sparkles.square.filled.on.square"
        case "scientific":
            return "brain.head.profile"
        case "humorous":
            return "face.smiling"
        default:
            return "star"
        }
    }
    
    private func titleForStyle(_ style: String) -> String {
        switch style {
        case "mystic":
            return "玄学解梦"
        case "scientific":
            return "科学解析"
        case "humorous":
            return "幽默解读"
        default:
            return "梦境解析"
        }
    }
    
    private func colorForStyle(_ style: String) -> Color {
        switch style {
        case "mystic":
            return Color.purple
        case "scientific":
            return Color.blue
        case "humorous":
            return Color.orange
        default:
            return Color.gray
        }
    }
    
    private func backgroundColorForStyle(_ style: String) -> Color {
        switch style {
        case "mystic":
            return Color.purple
        case "scientific":
            return Color.blue
        case "humorous":
            return Color.orange
        default:
            return Color.gray
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM-dd HH:mm"
        return outputFormatter.string(from: date)
    }
}

struct DreamInterpretationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                DreamInterpretationView(
                    interpretation: DreamInterpretation(
                        id: "1",
                        dreamId: "1",
                        style: "mystic",
                        content: "这个梦境暗示着你正在经历一段转变期，飞翔象征着自由和超越现实限制的渴望。俯瞰大地代表你希望获得更广阔的视野和洞察力。这个梦境预示着即将到来的积极变化和个人成长。",
                        createdAt: "2023-02-28T12:00:00Z"
                    )
                )
                
                DreamInterpretationView(
                    interpretation: DreamInterpretation(
                        id: "2",
                        dreamId: "1",
                        style: "scientific",
                        content: "从心理学角度来看，飞行梦通常反映了潜意识中对自由和掌控感的渴望。研究表明，当我们面临生活压力或寻求突破现状时，大脑会创造这种超越物理限制的场景。你的梦境可能表明你正在寻找生活中的新视角或解决方案。",
                        createdAt: "2023-02-28T12:05:00Z"
                    )
                )
                
                DreamInterpretationView(
                    interpretation: DreamInterpretation(
                        id: "3",
                        dreamId: "1",
                        style: "humorous",
                        content: "看来你梦里是把自己当超人了！不用花钱买机票就能环游世界，省了不少机票钱啊！不过要小心，下次梦游的时候别真的以为自己会飞，从床上跳下去可就不好玩了。也许这个梦是在暗示你应该减肥，这样才能像梦中一样轻盈自由？",
                        createdAt: "2023-02-28T12:10:00Z"
                    )
                )
            }
            .padding()
        }
    }
} 