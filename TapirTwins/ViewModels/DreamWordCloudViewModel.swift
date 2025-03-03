import Foundation
import SwiftUI
import NaturalLanguage

// 导入项目中已有的模型
// 这里不需要显式导入，因为Swift会自动导入同一模块中的其他文件

class DreamWordCloudViewModel: ObservableObject {
    @Published var dreams: [Dream] = []
    @Published var wordFrequencies: [(String, Double)] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analyzedDreamsCount: Int = 0
    
    private let apiService = APIService.shared
    
    // 停用词列表（常见但对分析无意义的词）
    private let stopWords: Set<String> = ["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好", "自己", "这", "那", "这个", "那个", "来", "没", "被", "吧", "给"]
    
    func fetchDreams() {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchDreams { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let personalDreams):
                    self.dreams = personalDreams
                    
                    // 检查是否有默认空间，如果有，则获取该空间的梦境
                    let settings = UserSettings.load()
                    if let defaultSpaceId = settings.defaultShareSpaceId {
                        self.fetchSpaceDreamsAndMerge(spaceId: defaultSpaceId)
                    } else {
                        // 没有默认空间，所以只使用个人梦境
                        self.dreams.sort(by: { $0.date > $1.date })
                        self.isLoading = false
                        self.generateWordCloud(dreams: self.dreams)
                    }
                    
                case .failure(let error):
                    self.handleError(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchSpaceDreamsAndMerge(spaceId: String) {
        apiService.fetchSpaceDreams(spaceId: spaceId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let spaceDreams):
                    // 将空间梦境添加到dreams数组，但需要避免重复
                    var uniqueDreams = self.dreams
                    
                    // 遍历空间梦境，只添加不重复的梦境
                    for spaceDream in spaceDreams {
                        // 检查是否已经存在相同内容的梦境（比较标题和日期）
                        let isDuplicate = uniqueDreams.contains { existingDream in
                            // 认为标题相同且日期相同的梦境是重复的
                            return existingDream.title == spaceDream.title && 
                                   existingDream.date == spaceDream.date
                        }
                        
                        // 如果不是重复的，则添加到列表
                        if !isDuplicate {
                            uniqueDreams.append(spaceDream)
                        }
                    }
                    
                    // 按日期排序
                    self.dreams = uniqueDreams.sorted(by: { $0.date > $1.date })
                    self.generateWordCloud(dreams: self.dreams)
                    
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func generateWordCloud(dreams: [Dream]) {
        guard !dreams.isEmpty else {
            self.wordFrequencies = []
            self.analyzedDreamsCount = 0
            return
        }
        
        self.analyzedDreamsCount = dreams.count
        
        // 合并所有梦境内容
        let allContent = dreams.map { $0.title + " " + $0.content }.joined(separator: " ")
        
        // 使用NaturalLanguage框架进行分词
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = allContent
        
        var wordCounts: [String: Int] = [:]
        
        tokenizer.enumerateTokens(in: allContent.startIndex..<allContent.endIndex) { tokenRange, _ in
            let word = String(allContent[tokenRange]).lowercased()
            
            // 过滤掉停用词和短词
            if word.count >= 2 && !self.stopWords.contains(word) {
                wordCounts[word, default: 0] += 1
            }
            
            return true
        }
        
        // 过滤掉出现次数少于2次的词
        let filteredWords = wordCounts.filter { $0.value >= 2 }
        
        // 找出最大频率，用于归一化
        let maxCount = filteredWords.values.max() ?? 1
        
        // 计算归一化的词频
        let normalizedFrequencies = filteredWords.map { (word, count) in
            (word, Double(count) / Double(maxCount))
        }
        
        // 按频率排序并取前50个词
        let sortedFrequencies = normalizedFrequencies.sorted { $0.1 > $1.1 }.prefix(50)
        
        DispatchQueue.main.async {
            self.wordFrequencies = Array(sortedFrequencies)
        }
    }
    
    func filterDreamsByDateRange(startDate: Date, endDate: Date) -> [Dream] {
        return dreams.filter { dream in
            if let dreamDate = formatDateToDate(dream.date) {
                // 确保日期在范围内（包括开始和结束日期）
                return dreamDate >= startDate.startOfDay && dreamDate <= endDate.endOfDay
            }
            return false
        }
    }
    
    private func formatDateToDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: dateString)
    }
    
    private func handleError(_ error: APIError) {
        switch error {
        case .serverError(let message):
            errorMessage = message
        case .requestFailed(let error):
            errorMessage = "请求失败: \(error.localizedDescription)"
        case .decodingFailed(let error):
            errorMessage = "数据解析失败: \(error.localizedDescription)"
        case .invalidURL:
            errorMessage = "无效的URL"
        case .invalidResponse:
            errorMessage = "服务器响应无效"
        case .unknown:
            errorMessage = "发生未知错误"
        case .unauthorized:
            errorMessage = "未授权，请重新登录"
        case .noData:
            errorMessage = "服务器未返回数据"
        }
    }
}

// 扩展Date以获取一天的开始和结束
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}