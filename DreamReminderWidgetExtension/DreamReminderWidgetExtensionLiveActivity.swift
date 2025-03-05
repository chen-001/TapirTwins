//
//  DreamReminderWidgetExtensionLiveActivity.swift
//  DreamReminderWidgetExtension
//
//  Created by 陈宗伟 on 2025/3/4.
//

import ActivityKit
import WidgetKit
import SwiftUI

// 删除这里的重复定义，避免与Bundle文件定义冲突
// 使用Bundle中定义的DreamReminderAttributes

// 灵动岛和锁屏小组件
@available(iOS 16.1, *)
struct DreamReminderWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DreamReminderAttributes.self) { context in
            // 锁屏/通知中心版本
            ZStack {
                LinearGradient(
                    colors: [.purple.opacity(0.2), .indigo.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 根据模式选择不同的视图
                if isCompanionMode(context: context) {
                    DreamCompanionLockScreenView(context: context)
                        .padding()
                } else {
                    DreamReminderLockScreenView(context: context)
                        .padding()
                }
            }
            .activityBackgroundTint(.black.opacity(0.2))
            .activitySystemActionForegroundColor(.blue)
            
        } dynamicIsland: { context in
            // 灵动岛版本
            DynamicIsland {
                // 扩展视图
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(.purple.opacity(0.7))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "moon.stars.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 18))
                        }
                        .padding(.leading, 4)
                        .accessibilityLabel("梦境图标")
                        
                        if isCompanionMode(context: context) {
                            Text("貘婆婆")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                                .padding(.leading, 4)
                                .accessibilityHidden(false)
                        } else {
                            Text("记录梦境")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                                .padding(.leading, 4)
                                .accessibilityHidden(false)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        if !isCompanionMode(context: context) {
                            Text(context.state.reminderTime, style: .time)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.trailing, 8)
                                .accessibilityLabel("提醒时间")
                        } else {
                            // 陪伴模式右侧不显示内容
                            EmptyView()
                                .padding(.trailing, 8)
                                .accessibilityHidden(true)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    if isCompanionMode(context: context) {
                        Text("貘婆婆的绒尾日记")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                            .accessibilityLabel("灵动陪伴标题")
                    } else {
                        Text("来和貘婆婆说说你昨夜的梦吧")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                            .accessibilityLabel("记录梦境标题")
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                        .accessibilityLabel(isCompanionMode(context: context) ? "貘婆婆签名" : "梦境提醒消息")
                }
            } compactLeading: {
                // 左侧紧凑视图
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .bold))
                        .accessibilityLabel("梦境图标")
                }
            } compactTrailing: {
                // 右侧紧凑视图
                if isCompanionMode(context: context) {
                    // 陪伴模式显示星星图标
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.yellow)
                        .padding(.trailing, 4)
                        .accessibilityLabel("貘婆婆的星光")
                } else {
                    Text(context.state.reminderTime, style: .time)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.trailing, 4)
                        .accessibilityLabel("提醒时间")
                }
            } minimal: {
                // 最小化视图
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .bold))
                        .accessibilityLabel("梦境图标")
                }
            }
            .widgetURL(isCompanionMode(context: context) ? 
                       nil : 
                       URL(string: "tapirtwins://dreamreminder"))
            .keylineTint(.purple)
        }
    }
    
    // 判断是否是陪伴模式
    private func isCompanionMode(context: ActivityViewContext<DreamReminderAttributes>) -> Bool {
        // 使用时间来区分模式：陪伴模式使用的是遥远的未来时间
        return context.state.reminderTime.timeIntervalSince1970 > Date().timeIntervalSince1970 + 365 * 24 * 60 * 60
    }
}

// 锁屏/通知中心显示的视图 - 梦境提醒模式
@available(iOS 16.1, *)
struct DreamReminderLockScreenView: View {
    let context: ActivityViewContext<DreamReminderAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("记录梦境")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding(.leading, 4)
                
                Spacer()
                
                Text(context.state.reminderTime, style: .time)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 8)
            
            Divider()
                .background(Color.white.opacity(0.5))
                .padding(.vertical, 4)
            
            Text(context.state.message)
                .font(.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
        }
        .padding(.vertical, 8)
    }
}

// 锁屏/通知中心显示的视图 - 陪伴模式
@available(iOS 16.1, *)
struct DreamCompanionLockScreenView: View {
    let context: ActivityViewContext<DreamReminderAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("貘婆婆")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding(.leading, 4)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                    .font(.headline)
            }
            .padding(.horizontal, 8)
            
            Divider()
                .background(Color.white.opacity(0.5))
                .padding(.vertical, 4)
            
            Text(context.state.message)
                .font(.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
        }
        .padding(.vertical, 8)
    }
}

// 为预览创建模拟数据
extension DreamReminderAttributes {
    fileprivate static var preview: DreamReminderAttributes {
        DreamReminderAttributes()
    }
}

extension ReminderState {
    fileprivate static var previewState: ReminderState {
        ReminderState(reminderTime: Date(), message: "测试梦境提醒")
    }
    
    fileprivate static var companionPreviewState: ReminderState {
        ReminderState(reminderTime: Date.distantFuture, message: "貘婆婆衔月华织梦，星辉铺就童话路。")
    }
}

// 使用兼容iOS 17.0+的预览方式
@available(iOS 17.0, *)
#Preview("梦境提醒", as: .content, using: DreamReminderAttributes.preview) {
   DreamReminderWidgetExtensionLiveActivity()
} contentStates: {
    ReminderState.previewState
}

@available(iOS 17.0, *)
#Preview("陪伴模式", as: .content, using: DreamReminderAttributes.preview) {
   DreamReminderWidgetExtensionLiveActivity()
} contentStates: {
    ReminderState.companionPreviewState
}

