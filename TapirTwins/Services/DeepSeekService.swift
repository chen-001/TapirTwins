import Foundation

enum DeepSeekStyle: String {
    // 解梦风格
    case mystic = "mystic"      // 玄学版
    case scientific = "scientific"  // 科学版
    case humorous = "humorous"  // 幽默版
    case zhenHuan1 = "zhenhuanDream"  // 甄嬛风解梦
    
    // 续写风格
    case comedy = "comedy"      // 喜剧
    case tragedy = "tragedy"    // 悲剧
    case mystery = "mystery"    // 悬疑
    case scifi = "scifi"        // 科幻
    case ethical = "ethical"    // 伦理
    case zhenHuan2 = "zhenhuanStory"  // 甄嬛风续写
    
    // 预言时间范围
    case predictToday = "today"           // 预言今天
    case predictMonth = "month"           // 预言未来一个月
    case predictYear = "year"             // 预言未来一年
    case predictFiveYears = "fiveYears"   // 预言未来五年
    case zhenHuan3 = "zhenhuanPrediction" // 甄嬛风预言
    
    // 新增：梦境报告风格
    case reportWeek = "weekReport"    // 周报
    case reportMonth = "monthReport"  // 月报
    case reportYear = "yearReport"    // 年报
    
    // 新增：人物志
    case characterStory = "character"  // 人物志
}

class DeepSeekService {
    static let shared = DeepSeekService()
    
    private let apiKey = "sk-af0934a7b1644306be5e4390556f7249" // 注意：通常不应将API密钥硬编码
    private let baseURL = "https://api.deepseek.com/v1"
    
    private init() {}
    
    // 处理解梦请求
    func interpretDream(content: String, style: DeepSeekStyle, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = generateInterpretationPrompt(content: content, style: style)
        callDeepSeekAPI(prompt: prompt, completion: completion)
    }
    
    // 处理续写请求
    func continueDream(content: String, style: DeepSeekStyle, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = generateContinuationPrompt(content: content, style: style)
        callDeepSeekAPI(prompt: prompt, completion: completion)
    }
    
    // 处理预言请求
    func predictFromDream(content: String, style: DeepSeekStyle = .predictToday, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = generatePredictionPrompt(content: content, style: style)
        callDeepSeekAPI(prompt: prompt, completion: completion)
    }
    
    // 新增：处理人物志请求
    func generateCharacterStory(dreams: [Dream], characterName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = generateCharacterStoryPrompt(dreams: dreams, characterName: characterName)
        callDeepSeekAPI(prompt: prompt, completion: completion)
    }
    
    // 新增：处理梦境报告请求
    func generateDreamReport(dreams: [Dream], reportStyle: ReportTimeRange, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = generateDreamReportPrompt(dreams: dreams, reportStyle: reportStyle)
        callDeepSeekAPI(prompt: prompt, completion: completion)
    }
    
    // 调用DeepSeek API
    private func callDeepSeekAPI(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("DeepSeek服务: 开始调用DeepSeek API...")
        print("DeepSeek服务: 提示词: \(prompt)")
        
        // 创建请求URL
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(NSError(domain: "DeepSeekServiceError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        // 创建请求体
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        // 转换为JSON数据
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(NSError(domain: "DeepSeekServiceError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "请求数据序列化失败"])))
            return
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 发送请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            // 检查错误
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 检查响应状态
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "DeepSeekServiceError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "API请求失败，状态码：\(statusCode)"])))
                }
                return
            }
            
            // 检查数据
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "DeepSeekServiceError", code: 1004, userInfo: [NSLocalizedDescriptionKey: "API未返回数据"])))
                }
                return
            }
            
            // 解析响应
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        completion(.success(content))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "DeepSeekServiceError", code: 1005, userInfo: [NSLocalizedDescriptionKey: "API响应格式不正确"])))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // 生成解梦的提示词
    private func generateInterpretationPrompt(content: String, style: DeepSeekStyle) -> String {
        let styleDescription: String
        let userSettings = UserSettings.load()
        let wordCount = userSettings.interpretationLength
        
        switch style {
        case .mystic:
            styleDescription = "请以玄学角度分析这个梦境，包括可能的预示、象征意义和命运暗示。使用神秘、玄学的语言风格。"
        case .scientific:
            styleDescription = "请以科学和心理学的角度分析这个梦境，解释可能的心理状态、潜意识因素和大脑活动。使用客观、专业的语言风格。"
        case .humorous:
            styleDescription = "请以幽默诙谐的方式解析这个梦境，添加有趣的比喻和调侃，但不失对梦境的基本解析。使用轻松、幽默的语言风格。"
        case .zhenHuan1:
            styleDescription = "请以《甄嬛传》的风格解析这个梦境，将梦境内容比作宫廷中的人事斗争和命运转折。使用《甄嬛传》中的人物（如甄嬛、皇上、华妃、果郡王等）、经典台词和隐喻来解读梦境的含义。分析方式要似是而非、意味深长，带有宫斗的机锋和权谋。使用华丽典雅的语言，夹杂文言文和《甄嬛传》中的经典用语。"
        default:
            styleDescription = "请解析这个梦境的含义。"
        }
        
        return """
        你是一位专业的梦境解析师，擅长分析梦境的象征意义和潜在含义。
        
        以下是一位用户记录的梦境内容：
        "\(content)"
        
        \(styleDescription)
        
        请提供约\(wordCount)字的分析。
        """
    }
    
    // 生成续写的提示词
    private func generateContinuationPrompt(content: String, style: DeepSeekStyle) -> String {
        let styleDescription: String
        let userSettings = UserSettings.load()
        let wordCount = userSettings.continuationLength
        
        switch style {
        case .comedy:
            styleDescription = "以喜剧风格续写，加入幽默、轻松的元素，情节发展应该充满欢乐和意外的转折。"
        case .tragedy:
            styleDescription = "以悲剧风格续写，情节发展应该带有悲伤、遗憾或失落的元素，表达人生的无常和情感的深度。"
        case .mystery:
            styleDescription = "以悬疑风格续写，加入谜团和线索，情节发展应该充满紧张感和未知，引导读者思考隐藏的真相。"
        case .scifi:
            styleDescription = "以科幻风格续写，加入未来技术、异世界或超自然元素，展现想象力和对未知的探索。"
        case .ethical:
            styleDescription = "以伦理风格续写，探讨道德困境和价值选择，情节发展应该引发读者对人性和社会规范的思考。"
        case .zhenHuan2:
            styleDescription = "以《甄嬛传》的风格续写这个梦境，将梦境内容转化为宫廷故事。使用《甄嬛传》中的人物关系、宫廷背景和权谋斗争作为故事框架。描写要精致华美，角色对话要带有含蓄机锋，情节要有宫斗剧的张力和转折。可以使用《甄嬛传》中的经典台词和场景，语言风格要典雅古风，融入恰当的文言表达。"
        default:
            styleDescription = "请根据梦境内容自然续写后续情节。"
        }
        
        return """
        你是一位专业的创意小说家，擅长根据梦境内容创作有趣的续写故事。
        
        以下是一位用户记录的梦境内容：
        "\(content)"
        
        请为这个梦境续写一段故事，\(styleDescription)
        
        请提供约\(wordCount)字的续写内容，确保文风流畅自然，有故事情节和场景描写。
        """
    }
    
    // 生成预言的提示词
    private func generatePredictionPrompt(content: String, style: DeepSeekStyle = .predictToday) -> String {
        let timeRange: String
        let detailLevel: String
        let userSettings = UserSettings.load()
        let wordCount = userSettings.predictionLength
        
        switch style {
        case .predictToday:
            timeRange = "未来24小时内"
            detailLevel = "非常具体的预测，包括可能发生的小事、情绪变化和社交互动"
        case .predictMonth:
            timeRange = "未来一个月内"
            detailLevel = "相对具体的预测，包括可能发生的重要事件、关系变化和机遇挑战"
        case .predictYear:
            timeRange = "未来一年内"
            detailLevel = "宏观的预测，包括生活方向、事业发展、重要决策和潜在转折点"
        case .predictFiveYears:
            timeRange = "未来五年内"
            detailLevel = "人生规划层面的预测，包括长期发展趋势、人生目标实现和重大生活转变"
        case .zhenHuan3:
            timeRange = "命运走向"
            detailLevel = "以《甄嬛传》的风格预测命运走向。将用户比作宫廷中的某个角色，用宫廷隐喻和权谋比拟现实生活中可能发生的事件。预测应包含《甄嬛传》中的经典台词改编、角色类比和情节暗示。语言要典雅含蓄，充满机锋和双关，如'宫墙高墙广，不知皇上此刻在何处'这样的表达方式。"
        default:
            timeRange = "未来24小时内"
            detailLevel = "具体的预测，包括可能发生的事件和情绪变化"
        }
        
        return """
        你是一位擅长解读梦境预兆的预言师，可以从梦境中提取象征意义，预测未来可能发生的事件。
        
        以下是一位用户记录的梦境内容：
        "\(content)"
        
        请基于这个梦境内容，对用户\(timeRange)可能遇到的事件进行预测。你的预测应该：
        1. 包含3-5个\(detailLevel)
        2. 既有积极的预测，也有需要注意的提醒
        3. 语言风格应神秘而专业，但不要过于迷信
        4. 提供一些实用的建议，帮助用户应对未来可能的挑战
        
        请提供约\(wordCount)字的预言内容。
        """
    }
    
    // 新增：生成人物志的提示词
    private func generateCharacterStoryPrompt(dreams: [Dream], characterName: String) -> String {
        var dreamsText = ""
        
        // 将梦境内容合并成文本
        for (index, dream) in dreams.enumerated() {
            dreamsText += "梦境\(index + 1)（\(dream.date)）：\n\(dream.content)\n\n"
        }
        
        return """
        你是一位专业的梦境分析师，擅长从梦境中提取特定人物的信息并构建故事。你的风格轻松幽默，善于调侃，有时搞怪腹黑，喜欢用毒舌但不失温情的方式描述人物。
        
        我有一系列梦境记录，我想了解在这些梦境中关于"\(characterName)"的所有故事和情节。请帮我完成以下任务：
        
        1. 仔细阅读所有梦境记录，找出所有与"\(characterName)"相关的片段和情节。
        2. 分析"\(characterName)"在梦中出现的场景、言行、特点和与梦者的关系。
        3. 提取与"\(characterName)"相关的所有情节，按时间顺序整理。
        4. 基于提取的情节，创作一个连贯的"\(characterName)"人物故事，展现这个人物在梦境中的形象和意义。
        5. 分析"\(characterName)"在梦中可能代表的心理象征和潜意识含义。
        
        以下是我的梦境记录：
        
        \(dreamsText)
        
        请以Markdown格式输出，包含以下部分：
        1. **人物概述**：以幽默调侃的方式描述"\(characterName)"在梦中的整体形象
        2. **出场记录**：用轻松诙谐的语气列举"\(characterName)"在各个梦境中的出场情况
        3. **人物故事**：将所有与"\(characterName)"相关的情节串联成一个完整的故事，加入一些搞怪的元素和腹黑的评论
        4. **心理解析**：用略带调侃但不失专业的口吻分析"\(characterName)"在梦中可能代表的心理含义
        5. **关系分析**：用毒舌但不伤人的方式描述"\(characterName)"与梦者或其他梦中人物的关系
        
        整体风格要保持幽默、轻松、调侃，可以适当添加一些搞笑的比喻和俏皮的评论，让读者在阅读时能会心一笑。但请确保不会过度嘲讽或贬低人物，保持一定的温度和善意。
        
        如果在梦境中没有找到"\(characterName)"，请明确指出并分析可能的原因，同时根据梦境内容创作一个可能的"\(characterName)"故事，标注为"虚构故事"，并尽量使这个虚构故事充满幽默感和娱乐性。
        """
    }
    
    // 新增：生成梦境报告的提示词
    private func generateDreamReportPrompt(dreams: [Dream], reportStyle: ReportTimeRange) -> String {
        // 将梦境内容组合成文本
        var dreamsText = ""
        for (index, dream) in dreams.enumerated() {
            dreamsText += "梦境\(index + 1)（\(formatDate(dream.date))）：\n标题：\(dream.title)\n内容：\(dream.content)\n\n"
        }
        
        let reportTitle: String
        switch reportStyle {
        case .week:
            reportTitle = "梦境周报"
        case .month:
            reportTitle = "梦境月报"
        case .year:
            reportTitle = "梦境年报"
        }
        
        // 获取用户设置的报告长度
        let settings = UserSettings.load()
        let wordCount = settings.dreamReportLength.wordCount
        
        return """
        你是一位创意数据分析师，擅长为用户生成个性化的数据报告。
        
        请为用户创建一份"\(reportTitle)"，类似于音乐APP或旅行APP的年度总结报告风格。以下是用户在这段时间内记录的\(dreams.count)个梦境：
        
        \(dreamsText)
        
        请基于这些梦境内容，创建一份生动有趣、图文并茂的报告。报告应包含：
        
        1. 引人注目的标题和个性化开场白
        2. 梦境数据统计（如梦境总数、平均长度、记录频率等）
        3. 梦境主题分类和比例（如冒险类、焦虑类、日常类等）
        4. 梦境中出现的关键元素或人物分析
        5. 有趣的梦境洞察（如"你是XX%的人中梦到过飞行的一员"）
        6. 梦境情绪分析（如正面/负面情绪比例）
        7. 专属梦境个性标签（如"夜间哲学家"、"奇幻冒险家"等）
        8. 对未来梦境的有趣预测或建议
        9. 温馨结语
        
        **重要：请使用Markdown格式编写报告，确保包含以下元素：**
        
        - 使用 # 和 ## 等表示标题层级
        - 使用 **加粗** 和 *斜体* 强调重要内容
        - 使用 - 或 * 创建列表项
        - 使用 > 引用突出重要见解
        - 适当使用段落分隔，保证可读性
        
        请使用创意、活泼的语言风格，像是在讲述一个有趣的故事。可以添加一些虚构的视觉元素描述（如"这里有一张你的梦境词云图"、"这是你的梦境情绪波动曲线"等）。报告长度约\(wordCount)字。
        
        结构示例：
        ```
        # 梦境报告标题
        
        ## 个性化开场白
        
        > 引人注目的总结或见解
        
        ## 梦境数据统计
        - 统计项1
        - 统计项2
        
        ## 其他章节...
        ```
        """
    }
    
    // 辅助函数：格式化日期显示
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
} 