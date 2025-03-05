import Foundation
import ActivityKit
import SwiftUI

/// 貘婆婆签名管理器 - 负责提供随机签名和管理灵动岛陪伴模式
class DreamCompanionManager {
    // 单例模式
    static let shared = DreamCompanionManager()
    
    // 当前活动
    private var currentActivity: Activity<DreamReminderAttributes>?
    
    // 签名列表
    private let signatures = [
        "貘婆婆衔月华织梦，星辉铺就童话路。",
        "枕畔月光永不老，貘婆婆的绒尾扫过千年梦。",
        "貘婆婆掌灯星河渡，每颗星子都是未说完的梦。",
        "晨露凝着昨夜童话，貘婆婆的茶炊正温在梦的转角。",
        "貘婆婆的绒毯盖过春樱冬雪，每个辗转都有月光针脚。",
        "貘婆婆的纺车卷着流云，把心事纺成会飞的绒毛毯。",
        "寄往梦境的明信片，盖着貘婆婆的萤火邮戳。",
        "貘婆婆收集晨露的棱角，折射出七重梦境叠影。",
        "沉入鲸骨化作的梦珊瑚，貘婆婆提着灯笼打捞月光标本。",
        "貘婆婆折的梦纸鹤，正衔着童年星光逆流飞来。",
        "貘婆婆拉开晨雾帷幕，昨夜的梦正在露珠荧幕重播。",
        "当貘婆婆吹散蒲公英，绒毛种子便化作梦的计时沙漏。",
        "貘婆婆把碎梦煅烧成釉，月光在瓷纹里缓缓流动。",
        "貘婆婆在雨霁处煮梦，虹桥那头晾着晒满故事的被褥。",
        "貘婆婆的竹帚扫过星阶，落叶都是闪着微光的未完之梦。",
        "貘婆衔月补梦褶，星梭穿云织忆帘。",
        "貘婆扫尾拾呓语，茶烟袅结昨夜萤。",
        "貘婆砚池写蜃楼，尾卷藏尽鹊桥星。",
        "貘婆银针串时砂，蒲扇摇散雾中剧。",
        "貘婆拾捡前生露，炉烟熏醒忘川萤。",
        "貘婆帚扫星屑屉，绒毯裹紧梦呓匣。",
        "貘婆虹勺舀梦露，锦匣封存未央诗。",
        "貘婆临摹鲛人泪，陶窑烧制童谣星。",
        "貘婆莲灯引迷梦，蛛网黏合碎月痕。",
        "貘婆藤箱压三更，蚌壳孕养半醒虹。",
        "貘婆雾绡裹仙枕，星钥解开云纹谜。",
        "貘婆茧房孵梦鹊，蛛丝拓印将逝霞。",
        "貘婆打捞前世画，竹筛滤净今宵魇。",
        "貘婆冰砚冻蝶影，暖炉焙开枕上书。",
        "貘婆苔枕浸千年，尾扫星河万卷光。"
    ]
    
    // 获取随机签名
    func getRandomSignature() -> String {
        return signatures.randomElement() ?? "貘婆婆与你同在"
    }
    
    // 启动灵动岛陪伴模式
    @available(iOS 16.1, *)
    func startCompanionMode() {
        // 先停止任何现有活动
        stopCompanionMode()
        
        // 确认系统支持Live Activities并可以授权
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("当前设备不支持灵动岛活动或未授权")
            return
        }
        
        // 获取随机签名
        let signature = getRandomSignature()
        print("启动灵动岛陪伴模式，签名: \(signature)")
        
        // 创建内容状态 - 使用特殊时间戳表示这是陪伴模式
        let initialState = ReminderState(reminderTime: Date.distantFuture, message: signature)
        let attributes = DreamReminderAttributes()
        
        do {
            // 使用正确的API调用方式
            let activity = try Activity<DreamReminderAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            currentActivity = activity
            print("成功启动灵动岛陪伴模式，ID: \(activity.id)")
            
            // 设置定时刷新签名
            setupSignatureRefresh()
        } catch {
            print("无法启动灵动岛陪伴模式: \(error.localizedDescription)")
        }
    }
    
    // 设置定时刷新签名
    private func setupSignatureRefresh() {
        // 每30分钟更新一次签名
        Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if #available(iOS 16.1, *) {
                Task {
                    await self.refreshSignature()
                }
            }
        }
    }
    
    // 刷新签名
    @available(iOS 16.1, *)
    private func refreshSignature() async {
        guard !Activity<DreamReminderAttributes>.activities.isEmpty else {
            print("没有活动的灵动岛陪伴模式可更新")
            return
        }
        
        let newSignature = getRandomSignature()
        
        for activity in Activity<DreamReminderAttributes>.activities {
            // 只更新陪伴模式的活动（根据时间戳判断）
            if let state = activity.content.state as? ReminderState,
               state.reminderTime.timeIntervalSince1970 > Date().timeIntervalSince1970 + 365 * 24 * 60 * 60 {
                
                // 更新活动状态
                let updatedState = ReminderState(
                    reminderTime: Date.distantFuture,
                    message: newSignature
                )
                
                do {
                    await activity.update(using: updatedState)
                    print("已更新灵动岛签名: \(activity.id) - \(newSignature)")
                } catch {
                    print("更新灵动岛签名失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 立即更新为新签名
    @available(iOS 16.1, *)
    func updateToNewSignature() {
        Task {
            await refreshSignature()
        }
    }
    
    // 停止灵动岛陪伴模式
    @available(iOS 16.1, *)
    func stopCompanionMode() {
        // 获取所有正在进行的实时活动
        let activities = Activity<DreamReminderAttributes>.activities
        print("检查要停止的灵动岛活动: \(activities.count)个")
        
        // 遍历并结束所有活动
        for activity in activities {
            // 只停止陪伴模式的活动（根据时间戳判断）
            if let state = activity.content.state as? ReminderState,
               state.reminderTime.timeIntervalSince1970 > Date().timeIntervalSince1970 + 365 * 24 * 60 * 60 {
                
                print("正在停止灵动岛活动: \(activity.id)")
                Task {
                    do {
                        await activity.end(dismissalPolicy: .immediate)
                        print("已结束灵动岛陪伴模式: \(activity.id)")
                    } catch {
                        print("结束灵动岛陪伴模式失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // 检查陪伴模式是否激活
    @available(iOS 16.1, *)
    func isCompanionModeActive() -> Bool {
        // 获取所有正在进行的实时活动
        let activities = Activity<DreamReminderAttributes>.activities
        print("当前活动中的灵动岛活动数量: \(activities.count)")
        
        // 检查是否有陪伴模式的活动
        for activity in activities {
            if let state = activity.content.state as? ReminderState,
               state.reminderTime.timeIntervalSince1970 > Date().timeIntervalSince1970 + 365 * 24 * 60 * 60 {
                print("找到活跃的灵动岛陪伴模式: \(activity.id)")
                return true
            }
        }
        
        print("未找到活跃的灵动岛陪伴模式")
        return false
    }
} 