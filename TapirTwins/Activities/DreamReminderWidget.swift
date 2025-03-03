import WidgetKit
import SwiftUI
import ActivityKit

// 注意：如果您的应用中有多个Widget，应该添加到同一个WidgetBundle中
// 如果这是一个独立的Widget Extension，保持@main注解
//@main
struct DreamReminderWidgets: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            DreamReminderLiveActivityWidget()
        }
    }
}

// 灵动岛和锁屏小组件
@available(iOS 16.1, *)
struct DreamReminderLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DreamReminderAttributes.self) { context in
            // 锁屏/通知中心版本
            DreamReminderLockScreenView(context: context)
                .activityBackgroundTint(Color.gray.opacity(0.2))
                .activitySystemActionForegroundColor(Color.blue)
        } dynamicIsland: { context in
            // 灵动岛版本
            DynamicIsland {
                // 扩展视图
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                        .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.reminderTime, style: .time)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text("记录梦境")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 2)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.message)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            } compactLeading: {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.7))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
            } compactTrailing: {
                Text(context.state.reminderTime, style: .time)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            } minimal: {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.7))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .widgetURL(URL(string: "tapirtwins://dreamreminder"))
            .keylineTint(Color.purple)
        }
    }
}

// 锁屏/通知中心显示的视图
@available(iOS 16.1, *)
struct DreamReminderLockScreenView: View {
    let context: ActivityViewContext<DreamReminderAttributes>
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("记录梦境")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.leading, 4)
                
                Spacer()
                
                Text(context.state.reminderTime, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            
            Divider()
                .padding(.vertical, 4)
            
            Text(context.state.message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .activityBackgroundTint(Color.gray.opacity(0.2))
        .activitySystemActionForegroundColor(Color.blue)
    }
} 