import SwiftUI
import ActivityKit
import WidgetKit
import Foundation
import UIKit

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
        
        // 确认系统支持Live Activities并可以授权
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("当前设备不支持灵动岛活动或未授权")
            return
        }
        
        print("准备启动灵动岛活动，时间: \(reminderTime)")
        
        // 创建内容状态
        let initialState = ReminderState(reminderTime: reminderTime, message: message)
        let attributes = DreamReminderAttributes()
        
        do {
            // 使用正确的API调用方式
            let activity = try Activity<DreamReminderAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            currentActivity = activity
            print("成功启动梦境提醒活动，ID: \(activity.id)")
            
            // 添加延迟更新，确保状态刷新
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Task {
                    await self.updateActivity(message: message)
                    print("已更新初始状态")
                }
            }
        } catch {
            print("无法启动梦境提醒活动: \(error.localizedDescription)")
            print("详细错误信息: \(error)")
        }
    }
    
    // 更新活动状态
    @available(iOS 16.1, *)
    func updateActivity(message: String) {
        // 获取当前活动中的第一个
        guard !Activity<DreamReminderAttributes>.activities.isEmpty else {
            print("没有活动的梦境提醒活动可更新")
            return
        }
        
        for activity in Activity<DreamReminderAttributes>.activities {
            // 更新活动状态
            let updatedState = ReminderState(
                reminderTime: Date(), 
                message: message
            )
            
            Task {
                do {
                    await activity.update(using: updatedState)
                    print("已更新梦境提醒活动: \(activity.id)")
                } catch {
                    print("更新梦境提醒活动失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 停止梦境提醒活动
    @available(iOS 16.1, *)
    func stopDreamReminderActivity() {
        // 获取所有正在进行的实时活动
        let activities = Activity<DreamReminderAttributes>.activities
        
        // 遍历并结束所有活动
        for activity in activities {
            Task {
                do {
                    await activity.end(dismissalPolicy: .immediate)
                    print("已结束梦境提醒活动: \(activity.id)")
                } catch {
                    print("结束梦境提醒活动失败: \(error.localizedDescription)")
                }
            }
        }
    }
}
