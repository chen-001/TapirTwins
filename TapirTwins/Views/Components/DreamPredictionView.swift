import SwiftUI

struct DreamPredictionView: View {
    let prediction: DreamPrediction
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
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.system(size: 20))
                    
                    Text("梦境预言")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatDate(prediction.createdAt))
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
                            gradient: Gradient(colors: [.clear, Color.purple.opacity(0.5), .clear]),
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
                            Color.purple.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
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
            Text(prediction.content)
        }
    }
    
    // 处理Markdown转换
    @available(iOS 15.0, *)
    private var markdownText: Text {
        do {
            let attributedString = try AttributedString(markdown: prediction.content)
            return Text(attributedString)
        } catch {
            return Text(prediction.content)
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

struct DreamPredictionView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            
            DreamPredictionView(
                prediction: DreamPrediction(
                    id: "1",
                    dreamId: "1",
                    content: "根据你的梦境内容，我预测你未来24小时可能会遇到以下情况：\n\n1. 工作或学习方面：你今天可能会收到一个意外的好消息，或许是一个新的机会或项目。你的创造力将特别活跃，是完成创意工作的好时机。\n\n2. 人际关系：可能会与一位久未联系的朋友意外重逢，这次相遇将给你带来新的见解或视角。\n\n3. 情绪状态：你今天的情绪会较为平稳，但下午可能会有短暂的焦虑，建议找时间进行15分钟的冥想或深呼吸。\n\n4. 健康提醒：注意保持充足的水分摄入，今天你可能会感到比平时更加口渴。\n\n建议：今天尝试从新的角度看待问题，就像你在梦中能够从高处俯瞰一样。当面临选择时，选择能给你带来更多自由感的选项。",
                    createdAt: "2023-02-28T12:00:00Z"
                )
            )
            .padding()
        }
    }
} 