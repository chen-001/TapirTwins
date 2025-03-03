import SwiftUI
import ActivityKit
import WidgetKit
import Foundation
import UIKit

// 梦境提醒活动的属性
struct DreamReminderAttributes: ActivityAttributes {
    // 活动属性结构体为空
    public typealias ContentState = ReminderState
    
    // 添加空的初始化方法
    public init() {}
}

// 将ContentState移出为独立的结构体
struct ReminderState: Codable, Hashable {
    // 使用基本类型存储时间戳，避免Date的编解码问题
    var reminderTimeInterval: TimeInterval
    var message: String
    
    // 计算属性，用于获取Date对象
    var reminderTime: Date {
        return Date(timeIntervalSince1970: reminderTimeInterval)
    }
    
    // 简单的初始化方法，接受Date参数
    init(reminderTime: Date, message: String = "记录你的梦境") {
        self.reminderTimeInterval = reminderTime.timeIntervalSince1970
        self.message = message
    }
}

// 灵动岛活动视图
@available(iOS 16.1, *)
struct DreamReminderLiveActivityView: View {
    let context: ActivityViewContext<DreamReminderAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("记录梦境")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.leading, 4)
                
                Spacer()
                
                Text(context.state.reminderTime, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            
            Divider()
                .padding(.vertical, 2)
            
            Text(context.state.message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}

// 梦境提醒活动管理器
class DreamReminderActivityManager {
    static let shared = DreamReminderActivityManager()
    
    private var currentActivity: Activity<DreamReminderAttributes>?
    
    private init() {}
    
    // 开始梦境提醒活动
    @available(iOS 16.1, *)
    func startDreamReminderActivity(reminderTime: Date, message: String = "点击记录昨晚的梦境") {
        // 先停止现有活动
        stopDreamReminderActivity()
        
        // 如果系统支持Live Activities
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("当前设备不支持灵动岛活动")
            return
        }
        
        // 创建内容状态
        let initialState = ReminderState(reminderTime: reminderTime, message: message)
        let attributes = DreamReminderAttributes()
        
        do {
            // 使用正确的API调用方式
            let activity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            currentActivity = activity
            print("成功启动梦境提醒活动，ID: \(activity.id)")
            
            // 添加延迟更新，确保状态刷新
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Task {
                    await activity.update(using: initialState)
                    print("已更新初始状态")
                }
            }
        } catch {
            print("无法启动梦境提醒活动: \(error.localizedDescription)")
        }
    }
    
    // 更新活动状态
    @available(iOS 16.1, *)
    func updateActivity(message: String) {
        guard let currentActivity = Activity<DreamReminderAttributes>.activities.first else {
            print("没有活动的梦境提醒活动可更新")
            return
        }
        
        // 更新活动状态
        let updatedState = ReminderState(
            reminderTime: Date(), 
            message: message
        )
        
        Task.init {
            await currentActivity.update(using: updatedState)
            print("已更新梦境提醒活动")
        }
    }
    
    // 停止梦境提醒活动
    @available(iOS 16.1, *)
    func stopDreamReminderActivity() {
        // 获取所有正在进行的实时活动
        let activities = Activity<DreamReminderAttributes>.activities
        
        // 遍历并结束所有活动
        for activity in activities {
            Task.init {
                await activity.end(dismissalPolicy: .immediate)
                print("已结束梦境提醒活动")
            }
        }
    }
}
