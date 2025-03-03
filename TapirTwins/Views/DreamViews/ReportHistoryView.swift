import SwiftUI

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
        default:
            return "梦境报告"
        }
    }
}

struct ReportDetailView: View {
    let report: DreamReport
    @Environment(\.presentationMode) var presentationMode
    
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
        default:
            return "梦境报告"
        }
    }
}

struct ReportHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ReportHistoryView(viewModel: DreamViewModel())
    }
} 