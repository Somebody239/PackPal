//
//  HuggingFaceService.swift
//  PackPal3
//
//  Created by AI Assistant on 2025-10-03.
//  Service for generating AI-powered packing lists using Hugging Face API
//

import Foundation

/// Service for generating AI-powered packing lists using Hugging Face API
/// Provides both packing list generation and chat responses using Mistral-7B model
class HuggingFaceService {
    
    // MARK: - Constants
    
    private static let HF_API_TOKEN = "YOUR_HUGGING_FACE_API_TOKEN_HERE"
    /// Updated model URL - using a more reliable model endpoint
    private static let HF_MODEL_URL = "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2"
    
    // MARK: - Singleton
    
    static let shared = HuggingFaceService()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Generates a packing list based on trip details and weather
    /// - Parameters:
    ///   - trip: The trip object containing destination, dates, activities, etc.
    ///   - weather: Weather summary for the destination
    ///   - completion: Callback with array of generated packing categories
    func generatePackingList(for trip: Trip, weather: WeatherSummary? = nil, completion: @escaping ([PackingCategory]) -> Void) {
        guard let url = URL(string: HuggingFaceService.HF_MODEL_URL) else {
            print("❌ Invalid Hugging Face URL")
            completion(HuggingFaceService.fallbackPackingList(for: trip))
            return
        }
        
        // Build prompt
        let prompt = buildPrompt(for: trip)
        
        // Setup request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(HuggingFaceService.HF_API_TOKEN)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "inputs": prompt,
            "parameters": [
                "max_new_tokens": 500,
                "temperature": 0.7,
                "top_p": 0.95,
                "do_sample": true,
                "return_full_text": false
            ],
            "options": [
                "use_cache": false,
                "wait_for_model": true
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Failed to encode request body: \(error)")
            completion(HuggingFaceService.fallbackPackingList(for: trip))
            return
        }
        
        // Make API call
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let service = self else {
                DispatchQueue.main.async {
                    completion(HuggingFaceService.fallbackPackingList(for: trip))
                }
                return
            }

            // Handle network errors
            if let error = error {
                print("❌ Hugging Face Network Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(HuggingFaceService.fallbackPackingList(for: trip))
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received from Hugging Face")
                DispatchQueue.main.async {
                    completion(HuggingFaceService.fallbackPackingList(for: trip))
                }
                return
            }
            
            // Check HTTP status code BEFORE parsing
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                print("📡 HF HTTP Status: \(statusCode)")
                
                // Log raw response for debugging
                let rawResponse = String(data: data, encoding: .utf8) ?? "[binary data]"
                let preview = rawResponse.prefix(500)
                print("🔍 HF Response (\(data.count) bytes): \(preview)")
                
                // Check for error status codes
                if statusCode != 200 {
                    print("❌ HF API Error - Status \(statusCode)")
                    print("❌ Error Body: \(rawResponse)")
                    
                    // Provide specific error messages
                    switch statusCode {
                    case 401, 403:
                        print("🔐 Authentication failed. Check your HF_API_TOKEN.")
                    case 404:
                        print("🔍 Model not found. Verify model path: \(HuggingFaceService.HF_MODEL_URL)")
                    case 429:
                        print("⏱️ Rate limited. Too many requests.")
                    case 500...599:
                        print("🔥 HF server error. Try again later.")
                    default:
                        print("❓ Unexpected status code.")
                    }
                    
                    DispatchQueue.main.async {
                        completion(HuggingFaceService.fallbackPackingList(for: trip))
                    }
                    return
                }
            }
            
            // Parse JSON response
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    print("❌ Response is not an array of objects")
                    DispatchQueue.main.async {
                        completion(HuggingFaceService.fallbackPackingList(for: trip))
                    }
                    return
                }
                
                guard let firstResult = json.first else {
                    print("❌ Empty response array")
                    DispatchQueue.main.async {
                        completion(HuggingFaceService.fallbackPackingList(for: trip))
                    }
                    return
                }
                
                guard let generatedText = firstResult["generated_text"] as? String else {
                    print("❌ No 'generated_text' field in response")
                    print("🔍 Available keys: \(firstResult.keys.joined(separator: ", "))")
                    DispatchQueue.main.async {
                        completion(HuggingFaceService.fallbackPackingList(for: trip))
                    }
                    return
                }
                
                print("✅ Generated text received (\(generatedText.count) chars)")
                let categories = service.parseGeneratedText(generatedText)
                
                if categories.isEmpty {
                    print("⚠️ No categories parsed from text, using fallback")
                    DispatchQueue.main.async {
                        completion(HuggingFaceService.fallbackPackingList(for: trip))
                    }
                } else {
                    print("✅ Parsed \(categories.count) categories with \(categories.flatMap { $0.items }.count) total items")
                    DispatchQueue.main.async {
                        completion(categories)
                    }
                }
                
            } catch let jsonError {
                let rawText = String(data: data, encoding: .utf8) ?? "[decode failed]"
                print("❌ JSON Parse Error: \(jsonError)")
                print("❌ Raw response was: \(rawText.prefix(200))...")
                DispatchQueue.main.async {
                    completion(HuggingFaceService.fallbackPackingList(for: trip))
                }
            }
        }.resume()
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(for trip: Trip, weather: WeatherSummary? = nil) -> String {
        let duration = max(1, trip.duration)
        let activities = trip.activities.map { $0.rawValue }.joined(separator: ", ")
        let activitiesText = activities.isEmpty ? "general activities" : activities

        // Use real weather if available, otherwise fall back to expected weather
        let weatherText = if let weather = weather {
            "Current weather: \(weather.description), temperature around \(Int(weather.currentTemp ?? 20))°C"
        } else {
            "Expected weather: \(trip.expectedWeather.rawValue)"
        }

        let prompt = """
        Create a detailed packing list for a \(duration)-day trip to \(trip.destination) from \(formatDate(trip.startDate)) to \(formatDate(trip.endDate)).

        Trip Details:
        - Trip Type: \(trip.tripType.rawValue)
        - Occasion: \(trip.occasion.rawValue)
        - Activities: \(activitiesText)
        - \(weatherText)

        Consider the destination, dates, activities, and weather conditions when suggesting items.

        Organize the packing list into these categories with specific items for each:
        1. Essentials (documents, money, phone, etc.)
        2. Clothing (appropriate for weather and activities)
        3. Toiletries (personal care items)
        4. Electronics (chargers, adapters, etc.)
        5. Activities (gear specific to planned activities)
        6. Health & Safety (medications, first aid, etc.)

        Format each category as:
        CATEGORY_NAME:
        - item 1
        - item 2
        - item 3

        Be specific about quantities and consider the trip duration and weather conditions.
        """

        return prompt
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func parseGeneratedText(_ text: String) -> [PackingCategory] {
        var categories: [PackingCategory] = []
        var currentCategory: String?
        var currentItems: [PackingItem] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }
            
            // Check if line is a category header (ends with :)
            if trimmed.hasSuffix(":") {
                // Save previous category if exists
                if let categoryName = currentCategory, !currentItems.isEmpty {
                    categories.append(PackingCategory(
                        name: categoryName,
                        items: currentItems
                    ))
                }
                
                // Start new category
                currentCategory = trimmed.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
                currentItems = []
            }
            // Check if line is an item (starts with - or •)
            else if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") {
                let itemName = trimmed
                    .replacingOccurrences(of: "^[-•*]\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                
                if !itemName.isEmpty {
                    currentItems.append(PackingItem(name: itemName))
                }
            }
            // If we have a current category and line doesn't look like a header, treat as item
            else if currentCategory != nil && !trimmed.contains(":") {
                currentItems.append(PackingItem(name: trimmed))
            }
        }
        
        // Save last category
        if let categoryName = currentCategory, !currentItems.isEmpty {
            categories.append(PackingCategory(
                name: categoryName,
                items: currentItems
            ))
        }
        
        return categories
    }
    
    /// Generate a chat response for packing list questions
    /// - Parameters:
    ///   - prompt: The chat prompt including context and user question
    ///   - completion: Callback with AI response text
    func generateChatResponse(prompt: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: HuggingFaceService.HF_MODEL_URL) else {
            print("❌ Invalid Hugging Face URL")
            completion("Sorry, I'm having trouble connecting right now. Please try again later.")
            return
        }

        // Setup request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(HuggingFaceService.HF_API_TOKEN)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "inputs": prompt,
            "parameters": [
                "max_new_tokens": 200,
                "temperature": 0.7,
                "top_p": 0.95,
                "do_sample": true,
                "return_full_text": false
            ],
            "options": [
                "use_cache": false,
                "wait_for_model": true
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Failed to encode chat request body: \(error)")
            completion("Sorry, I encountered an error processing your request.")
            return
        }

        // Make API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                print("❌ Chat Network Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion("Sorry, I'm having trouble connecting right now. Please check your internet connection.")
                }
                return
            }

            guard let data = data else {
                print("❌ No chat response data received")
                DispatchQueue.main.async {
                    completion("I didn't receive a response. Please try again.")
                }
                return
            }

            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                print("📡 Chat HTTP Status: \(statusCode)")
                
                if statusCode != 200 {
                    let rawResponse = String(data: data, encoding: .utf8) ?? "[no text]"
                    print("❌ Chat API Error - Status \(statusCode): \(rawResponse)")
                    
                    DispatchQueue.main.async {
                        completion("Sorry, I'm having trouble responding right now. Please try again later.")
                    }
                    return
                }
            }

            // Parse JSON
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                      let firstResult = json.first,
                      let generatedText = firstResult["generated_text"] as? String else {
                    print("❌ Unexpected chat response format")
                    DispatchQueue.main.async {
                        completion("I'm not sure how to respond to that. Could you rephrase your question?")
                    }
                    return
                }

                // Clean up the response
                let cleanResponse = generatedText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: prompt, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                DispatchQueue.main.async {
                    if cleanResponse.isEmpty {
                        completion("I'd be happy to help! Could you please rephrase your question?")
                    } else {
                        completion(cleanResponse)
                    }
                }
                
            } catch let jsonError {
                let rawText = String(data: data, encoding: .utf8) ?? "[decode failed]"
                print("❌ Chat JSON Parse Error: \(jsonError)")
                print("❌ Raw: \(rawText.prefix(200))")
                DispatchQueue.main.async {
                    completion("Sorry, I had trouble understanding the response. Please try again.")
                }
            }
        }.resume()
    }

    /// Fallback to rule-based packing list if AI fails
    private static func fallbackPackingList(for trip: Trip) -> [PackingCategory] {
        print("⚠️ Using fallback packing list generation")
        return Trip.suggestedPackingCategories(
            occasion: trip.occasion,
            activities: trip.activities,
            weather: trip.expectedWeather,
            durationDays: max(1, trip.duration)
        )
    }
}



