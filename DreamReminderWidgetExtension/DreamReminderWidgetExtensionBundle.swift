//
//  DreamReminderWidgetExtensionBundle.swift
//  DreamReminderWidgetExtension
//
//  Created by 陈宗伟 on 2025/3/4.
//

import WidgetKit
import SwiftUI

@main
struct DreamReminderWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        DreamReminderWidgetExtension()
        DreamReminderWidgetExtensionControl()
        DreamReminderWidgetExtensionLiveActivity()
    }
}
