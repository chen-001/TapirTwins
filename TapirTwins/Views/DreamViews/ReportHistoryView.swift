import SwiftUI
import UIKit

struct ReportHistoryView: View {
    @ObservedObject var viewModel: DreamViewModel
    @State private var selectedReport: DreamReport? = nil
    @State private var showingReportDetail = false
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.reportHistory.isEmpty {
                    Text("暂无历史报告")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets())
                } else {
                    ForEach(viewModel.reportHistory) { report in
                        Button(action: {
                            selectedReport = report
                            showingReportDetail = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: getReportIcon(report.reportType))
                                        .foregroundColor(.green)
                                    
                                    Text(getReportTitle(report.reportType))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Text("基于\(report.dreamsCount)个梦境记录")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("生成时间：\(formatDate(report.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("统计范围：\(report.startDate) - \(report.endDate)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationBarTitle("报告历史", displayMode: .inline)
            .sheet(isPresented: $showingReportDetail) {
                if let report = selectedReport {
                    ReportDetailView(report: report)
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // 如果日期已经是格式化好的字符串，直接返回
        if dateString.contains("-") && dateString.count >= 10 {
            // 只保留 yyyy-MM-dd 部分
            let endIndex = dateString.index(dateString.startIndex, offsetBy: min(10, dateString.count))
            return String(dateString[..<endIndex])
        }
        
        // 尝试解析日期字符串
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        
        return dateString // 如果无法解析，返回原始字符串
    }
    
    private func getReportIcon(_ type: String) -> String {
        switch type {
        case "personality":
            return "person.fill.questionmark"
        case "summary":
            return "chart.bar.doc.horizontal"
        case "weekReport":
            return "calendar.badge.clock"
        case "monthReport":
            return "calendar"
        case "yearReport":
            return "calendar.circle"
        default:
            return "doc.text"
        }
    }
    
    private func getReportTitle(_ type: String) -> String {
        switch type {
        case "personality":
            return "性格分析报告"
        case "summary":
            return "梦境统计报告"
        case "weekReport":
            return "梦境周报"
        case "monthReport":
            return "梦境月报"
        case "yearReport":
            return "梦境年报"
        default:
            return "梦境报告"
        }
    }
}

struct ReportDetailView: View {
    let report: DreamReport
    @Environment(\.presentationMode) var presentationMode
    
    // 用于分享功能的状态变量
    @State private var showingShareOptions = false
    @State private var showingImageShareSheet = false
    @State private var shareImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: getReportIcon(report.reportType))
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        
                        Text(getReportTitle(report.reportType))
                            .font(.title)
                            .bold()
                        
                        Spacer()
                        
                        // 添加分享按钮
                        Button(action: {
                            showingShareOptions = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("基于\(report.dreamsCount)个梦境记录的统计")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("统计时间：\(report.startDate) - \(report.endDate)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // 添加调试信息
                        Text("报告内容长度: \(report.content.count)字符")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 16)
                    
                    if report.content.isEmpty {
                        Text("报告内容为空")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        // 内容预览（调试用）
                        VStack(alignment: .leading) {
                            Text("内容预览（前100字符）:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(report.content.prefix(100) + "...")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.bottom, 8)
                                .lineLimit(3)
                        }
                        
                        // 使用改进后的 MarkdownView 显示内容
                        MarkdownView(markdown: report.content)
                            .padding(.vertical, 8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("报告详情", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
            // 添加分享选项的ActionSheet
            .actionSheet(isPresented: $showingShareOptions) {
                createShareOptionsActionSheet()
            }
            // 添加分享图片的Sheet
            .sheet(isPresented: $showingImageShareSheet) {
                if let image = shareImage {
                    ReportShareImageView(image: image)
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // 如果日期已经是格式化好的字符串，直接返回
        if dateString.contains("-") && dateString.count >= 10 {
            // 只保留 yyyy-MM-dd 部分
            let endIndex = dateString.index(dateString.startIndex, offsetBy: min(10, dateString.count))
            return String(dateString[..<endIndex])
        }
        
        // 尝试解析日期字符串
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        
        return dateString // 如果无法解析，返回原始字符串
    }
    
    private func getReportIcon(_ type: String) -> String {
        switch type {
        case "personality":
            return "person.fill.questionmark"
        case "summary":
            return "chart.bar.doc.horizontal"
        case "weekReport":
            return "calendar.badge.clock"
        case "monthReport":
            return "calendar"
        case "yearReport":
            return "calendar.circle"
        default:
            return "doc.text"
        }
    }
    
    private func getReportTitle(_ type: String) -> String {
        switch type {
        case "personality":
            return "性格分析报告"
        case "summary":
            return "梦境统计报告"
        case "weekReport":
            return "梦境周报"
        case "monthReport":
            return "梦境月报"
        case "yearReport":
            return "梦境年报"
        default:
            return "梦境报告"
        }
    }
    
    // 创建分享选项的ActionSheet
    private func createShareOptionsActionSheet() -> ActionSheet {
        var buttons: [ActionSheet.Button] = []
        
        // 保存到相册
        buttons.append(.default(Text("保存到相册")) {
            createAndSaveImage()
        })
        
        // 分享
        buttons.append(.default(Text("分享")) {
            createAndShareImage()
        })
        
        // 取消按钮
        buttons.append(.cancel())
        
        return ActionSheet(
            title: Text("分享选项"),
            message: Text("选择要执行的操作"),
            buttons: buttons
        )
    }
    
    // 创建并保存图片
    private func createAndSaveImage() {
        print("开始创建报告分享图片")
        let image = createShareImage()
        shareImage = image
        
        if let image = image {
            print("报告图片创建成功，准备保存到相册")
            ViewToImageRenderer.saveToPhotoAlbum(image: image) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("报告图片成功保存到相册")
                        // 显示保存成功的提示
                        let banner = NotificationBanner(title: "保存成功", subtitle: "报告图片已保存到相册", style: .success)
                        banner.show()
                    } else if let error = error {
                        print("保存报告图片失败: \(error.localizedDescription)")
                        // 显示保存失败的提示
                        let banner = NotificationBanner(title: "保存失败", subtitle: error.localizedDescription, style: .danger)
                        banner.show()
                    }
                }
            }
        } else {
            print("报告图片创建失败")
        }
    }
    
    // 创建并分享图片
    private func createAndShareImage() {
        print("开始创建报告分享图片以用于分享")
        let image = createShareImage()
        shareImage = image
        
        if let image = image {
            print("报告图片创建成功，准备显示分享界面")
            showingImageShareSheet = true
        } else {
            print("用于分享的报告图片创建失败")
        }
    }
    
    // 创建分享图片
    private func createShareImage() -> UIImage? {
        print("创建报告'\(getReportTitle(report.reportType))'的分享图片")
        print("报告内容: \(report.content.prefix(100))...")
        
        // 分析报告内容特征
        let contentLength = report.content.count
        let lineBreakCount = report.content.components(separatedBy: "\n").count - 1
        let paragraphCount = report.content.components(separatedBy: "\n\n").count
        let markdownHeaderCount = report.content.components(separatedBy: "#").count - 1
        let listItemCount = report.content.components(separatedBy: "- ").count - 1
        
        print("内容特征: 长度\(contentLength)字符, \(lineBreakCount)个换行, \(paragraphCount)个段落, \(markdownHeaderCount)个标题, \(listItemCount)个列表项")
        
        // 更保守的字体大小计算
        let fontSize: CGFloat
        if contentLength > 5000 {
            fontSize = 12 // 更小的字体适合超长文本
        } else if contentLength > 3000 {
            fontSize = 14
        } else if contentLength > 2000 {
            fontSize = 16
        } else if contentLength > 1000 {
            fontSize = 18
        } else if contentLength > 500 {
            fontSize = 22
        } else {
            fontSize = 24
        }
        
        // 设置适当的渲染宽度 - 使用更保守的宽度
        let renderWidth: CGFloat = 900
        
        // 计算高度 - 使用简化但保守的公式
        // 1. 基础高度: 包含所有UI元素
        let baseHeight: CGFloat = 300
        
        // 2. 计算内容高度: 粗略估计平均每100字符占用的高度
        let heightPer100Chars: CGFloat
        if contentLength > 3000 {
            heightPer100Chars = 40 // 更小的字体，行占用空间更小
        } else if contentLength > 1000 {
            heightPer100Chars = 50
        } else {
            heightPer100Chars = 60
        }
        
        // 最终高度计算 - 使用简单公式避免复杂计算可能的错误
        let contentHeight = ceil(CGFloat(contentLength) / 100.0) * heightPer100Chars
        
        // 添加额外高度用于标题、段落间距等
        let extraHeight = CGFloat(lineBreakCount * 5) + CGFloat(paragraphCount * 10) + CGFloat(markdownHeaderCount * 30)
        
        // 总高度 = 基础高度 + 内容高度 + 额外高度 + 安全边距
        let totalHeight = baseHeight + contentHeight + extraHeight + 100
        
        // 设置保守的最大高度限制
        let maxHeight: CGFloat = 4000 // 更保守的上限
        let finalHeight = min(totalHeight, maxHeight)
        
        print("渲染参数: 宽度\(renderWidth)pt, 高度\(finalHeight)pt (原计算高度: \(totalHeight)pt), 字体\(fontSize)pt")
        print("字符换算: 每100字符高度\(heightPer100Chars)pt, 内容高度\(contentHeight)pt, 额外高度\(extraHeight)pt")
        
        // 创建分享视图
        let shareView = ReportShareCardView(
            reportTitle: getReportTitle(report.reportType),
            reportType: report.reportType,
            startDate: report.startDate,
            endDate: report.endDate,
            dreamsCount: report.dreamsCount,
            content: report.content
        )
        
        // 使用简单直接的渲染方法
        let image = ViewToImageRenderer.renderLongContent(
            view: shareView, 
            width: renderWidth, 
            estimatedHeight: finalHeight
        )
        
        if let image = image {
            print("图片渲染成功: \(image.size.width) x \(image.size.height)")
        } else {
            print("图片渲染失败! 尝试使用备用方式...")
            // 实在不行，尝试更小的尺寸
            return ViewToImageRenderer.renderWithBackground(
                view: shareView,
                size: CGSize(width: renderWidth, height: min(2000, finalHeight))
            )
        }
        
        return image
    }
}

// 用于分享报告图片的视图
struct ReportShareImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                
                Spacer()
                
                Button("分享") {
                    let activityVC = UIActivityViewController(
                        activityItems: [image],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityVC, animated: true)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .padding()
            }
            
            Spacer()
        }
        .background(Color.black.opacity(0.9).edgesIgnoringSafeArea(.all))
    }
}

struct ReportHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ReportHistoryView(viewModel: DreamViewModel())
    }
} 