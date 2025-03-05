//
//  TapirWidgetBundle.swift
//  TapirWidget
//
//  Created by 陈宗伟 on 2025/3/4.
//

import WidgetKit
import SwiftUI

@main
struct TapirWidgetBundle: WidgetBundle {
    var body: some Widget {
        TapirWidget()
        TapirWidgetControl()
        TapirWidgetLiveActivity()
    }
}
