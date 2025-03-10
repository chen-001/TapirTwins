//
//  DreamReminderWidgetExtensionBundle.swift
//  DreamReminderWidgetExtension
//
//  Created by 陈宗伟 on 2025/3/4.
//

import WidgetKit
import SwiftUI
import ActivityKit

// 梦境提醒活动的属性
public struct DreamReminderAttributes: ActivityAttributes {
    // 活动属性结构体
    public typealias ContentState = ReminderState
    
    // 添加空的初始化方法
    public init() {}
}

// ContentState定义
public struct ReminderState: Codable, Hashable {
    // 使用基本类型存储时间戳，避免Date的编解码问题
    public var reminderTimeInterval: TimeInterval
    public var message: String
    
    // 计算属性，用于获取Date对象
    public var reminderTime: Date {
        return Date(timeIntervalSince1970: reminderTimeInterval)
    }
    
    // 简单的初始化方法，接受Date参数
    public init(reminderTime: Date, message: String = "记录你的梦境") {
        self.reminderTimeInterval = reminderTime.timeIntervalSince1970
        self.message = message
    }
}

@main
struct DreamReminderWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        DreamReminderWidgetExtension()
        
        if #available(iOS 16.1, *) {
            DreamReminderWidgetExtensionLiveActivity()
        }
    }
}
