import SwiftUI

struct MarkdownView: View {
    let markdown: String
    
    var body: some View {
        if #available(iOS 15.0, *) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStringKey(processedMarkdown))
                        .textSelection(.enabled)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
        } else {
            // iOS 15以下版本的兼容实现
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(plainText)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
        }
    }
    
    // 处理 Markdown 字符串，确保 LocalizedStringKey 能正确解析
    private var processedMarkdown: String {
        var processed = markdown
        
        // 确保段落之间有足够的换行
        processed = processed.replacingOccurrences(of: "\n\n", with: "\n\n\n")
        
        // 替换列表项以确保正确显示
        processed = processed.replacingOccurrences(of: #"- (.*?)(\n|$)"#, with: "• $1$2", options: .regularExpression)
        
        // 处理标题，确保前后有换行
        let headerPattern = #"(^|\n)(#{1,6})\s+(.*?)(\n|$)"#
        if let regex = try? NSRegularExpression(pattern: headerPattern, options: []) {
            let nsString = processed as NSString
            let matches = regex.matches(in: processed, options: [], range: NSRange(location: 0, length: nsString.length))
            
            // 从后向前替换，以避免位置改变
            for match in matches.reversed() {
                if match.numberOfRanges >= 4 {
                    let headerLevel = nsString.substring(with: match.range(at: 2)).count
                    let headerText = nsString.substring(with: match.range(at: 3))
                    
                    // 调整字体大小基于标题级别
                    var fontStyle = ""
                    switch headerLevel {
                    case 1: fontStyle = "**\(headerText)**" // 一级标题用粗体
                    case 2, 3: fontStyle = "*\(headerText)*" // 二三级标题用斜体
                    default: fontStyle = headerText
                    }
                    
                    let replacement = "\n\(fontStyle)\n"
                    processed = (processed as NSString).replacingCharacters(in: match.range, with: replacement)
                }
            }
        }
        
        return processed
    }
    
    private var plainText: String {
        // 简单替换一些基本Markdown语法为纯文本
        var text = markdown
        
        // 替换标题
        let headerPattern = #"#{1,6}\s+(.*?)(\n|$)"#
        if let regex = try? NSRegularExpression(pattern: headerPattern, options: []) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            // 从后向前替换，以避免位置改变
            for match in matches.reversed() {
                if match.numberOfRanges >= 2 {
                    let headerText = nsString.substring(with: match.range(at: 1))
                    text = (text as NSString).replacingCharacters(in: match.range, with: "\(headerText)\n")
                }
            }
        }
        
        // 替换粗体
        text = text.replacingOccurrences(of: #"\*\*(.*?)\*\*"#, with: "$1", options: .regularExpression)
        
        // 替换斜体
        text = text.replacingOccurrences(of: #"\*(.*?)\*"#, with: "$1", options: .regularExpression)
        
        // 替换列表项
        text = text.replacingOccurrences(of: #"- (.*?)(\n|$)"#, with: "• $1$2", options: .regularExpression)
        
        return text
    }
}

struct MarkdownView_Previews: PreviewProvider {
    static var previews: some View {
        MarkdownView(markdown: """
        # 标题1
        
        这是**粗体**文本，这是*斜体*文本。
        
        ## 标题2
        
        - 列表项1
        - 列表项2
        """)
    }
} 