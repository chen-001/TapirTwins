import SwiftUI

enum NotificationBannerStyle {
    case success
    case warning
    case danger
    case info
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return Color.green
        case .warning:
            return Color.orange
        case .danger:
            return Color.red
        case .info:
            return Color.blue
        }
    }
    
    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .danger:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

class NotificationBanner: ObservableObject {
    static let shared = NotificationBanner()
    
    @Published var isVisible = false
    @Published var title: String = ""
    @Published var subtitle: String = ""
    @Published var style: NotificationBannerStyle = .info
    
    private var workItem: DispatchWorkItem?
    
    init(title: String = "", subtitle: String = "", style: NotificationBannerStyle = .info) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }
    
    func show(duration: TimeInterval = 3.0) {
        // 确保在主线程执行UI更新
        DispatchQueue.main.async {
            // 取消之前的隐藏任务
            self.workItem?.cancel()
            
            // 显示通知
            NotificationBanner.shared.title = self.title
            NotificationBanner.shared.subtitle = self.subtitle
            NotificationBanner.shared.style = self.style
            NotificationBanner.shared.isVisible = true
            
            // 创建新的延迟任务用于隐藏通知
            let workItem = DispatchWorkItem {
                NotificationBanner.shared.isVisible = false
            }
            self.workItem = workItem
            
            // 延迟执行隐藏任务
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
        }
    }
}

struct NotificationBannerView: View {
    @ObservedObject private var banner = NotificationBanner.shared
    
    var body: some View {
        if banner.isVisible {
            VStack {
                // 通知横幅始终显示在顶部
                HStack(spacing: 16) {
                    Image(systemName: banner.style.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(banner.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if !banner.subtitle.isEmpty {
                            Text(banner.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        banner.isVisible = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(banner.style.backgroundColor)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: banner.isVisible)
                
                Spacer()
            }
            .zIndex(999) // 确保显示在最上层
        }
    }
} 