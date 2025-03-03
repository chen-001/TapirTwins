import SwiftUI

struct DreamContinuationView: View {
    let continuation: DreamContinuation
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
                    Image(systemName: iconForStyle(continuation.style))
                        .foregroundColor(colorForStyle(continuation.style))
                        .font(.system(size: 20))
                    
                    Text(titleForStyle(continuation.style))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatDate(continuation.createdAt))
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
                            gradient: Gradient(colors: [.clear, colorForStyle(continuation.style).opacity(0.5), .clear]),
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
                            backgroundColorForStyle(continuation.style).opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(colorForStyle(continuation.style).opacity(0.3), lineWidth: 1)
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
            Text(continuation.content)
        }
    }
    
    // 处理Markdown转换
    @available(iOS 15.0, *)
    private var markdownText: Text {
        do {
            let attributedString = try AttributedString(markdown: continuation.content)
            return Text(attributedString)
        } catch {
            return Text(continuation.content)
        }
    }
    
    private func iconForStyle(_ style: String) -> String {
        switch style {
        case "comedy":
            return "theatermasks.fill"
        case "tragedy":
            return "cloud.heavyrain.fill"
        case "mystery":
            return "magnifyingglass.circle.fill"
        case "scifi":
            return "airplane.circle.fill"
        case "ethical":
            return "books.vertical.fill"
        default:
            return "book.fill"
        }
    }
    
    private func titleForStyle(_ style: String) -> String {
        switch style {
        case "comedy":
            return "喜剧续写"
        case "tragedy":
            return "悲剧续写"
        case "mystery":
            return "悬疑续写"
        case "scifi":
            return "科幻续写"
        case "ethical":
            return "伦理续写"
        default:
            return "梦境续写"
        }
    }
    
    private func colorForStyle(_ style: String) -> Color {
        switch style {
        case "comedy":
            return Color.yellow
        case "tragedy":
            return Color.indigo
        case "mystery":
            return Color.green
        case "scifi":
            return Color.cyan
        case "ethical":
            return Color.mint
        default:
            return Color.gray
        }
    }
    
    private func backgroundColorForStyle(_ style: String) -> Color {
        switch style {
        case "comedy":
            return Color.yellow
        case "tragedy":
            return Color.indigo
        case "mystery":
            return Color.green
        case "scifi":
            return Color.cyan
        case "ethical":
            return Color.mint
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

struct DreamContinuationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                DreamContinuationView(
                    continuation: DreamContinuation(
                        id: "1",
                        dreamId: "1",
                        style: "comedy",
                        content: "你在天空中飞翔，突然发现有个人影在你旁边。转头一看，是你的邻居老王，他一脸惊恐地问：\"你怎么在这里？\"你淡定地说：\"天气不错，出来溜达溜达\"。老王结结巴巴地说：\"可...可是这是33层的高空啊！\"你笑着说：\"这就是我不搭电梯的原因。\"说完，你看了看手表，\"糟糕，约会要迟到了\"，加速飞走，只留下老王在风中凌乱。",
                        createdAt: "2023-02-28T12:00:00Z"
                    )
                )
                
                DreamContinuationView(
                    continuation: DreamContinuation(
                        id: "2",
                        dreamId: "1",
                        style: "scifi",
                        content: "你在天空飞翔时，忽然感觉到异常的气流波动。空气中开始出现微妙的蓝色粒子，你意识到这不是普通的飞行体验。突然，一道光束从云层中射出，将你笼罩。你的身体开始变得轻盈透明，周围的景象也变得模糊。当一切再次清晰时，你发现自己置身于一个巨大的透明飞行器内，周围站着数个身形修长的灰色生物，他们用一种你从未听过却能理解的语言说：\"测试成功，记忆植入完整。\"",
                        createdAt: "2023-02-28T12:05:00Z"
                    )
                )
            }
            .padding()
        }
    }
} 