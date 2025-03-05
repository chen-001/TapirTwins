//
//  DreamReminderWidgetExtension.swift
//  DreamReminderWidgetExtension
//
//  Created by 陈宗伟 on 2025/3/4.
//

import WidgetKit
import SwiftUI

// 主要的Widget实现（非LiveActivity部分）
struct DreamReminderWidgetExtension: Widget {
    let kind: String = "DreamReminderWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DreamReminderWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("梦境记录")
        .description("帮助你记录梦境的小组件")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// 数据提供者
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), message: "记录梦境")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), message: "点击记录昨晚的梦境")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, message: "记录梦境")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// Widget入口点数据
struct SimpleEntry: TimelineEntry {
    let date: Date
    let message: String
}

// Widget视图
struct DreamReminderWidgetExtensionEntryView: View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.2), .indigo.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.purple)
                        .font(.title3)
                    
                    Text("梦境记录")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                Text(entry.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding()
        }
    }
}

// 预览支持
struct DreamReminderWidgetExtension_Previews: PreviewProvider {
    static var previews: some View {
        DreamReminderWidgetExtensionEntryView(entry: SimpleEntry(date: Date(), message: "记录梦境"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
