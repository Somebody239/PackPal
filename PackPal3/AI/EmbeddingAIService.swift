//
//  EmbeddingAIService.swift
//  PackPal3
//
//  Uses a Core ML MobileBERT-style embedding model to produce embeddings
//  and a heuristic to generate packing lists.
//

import Foundation
import CoreML

/// Service for generating AI-powered packing lists using Core ML MobileBERT model
/// Provides both embedding-based and rule-based packing list generation
final class EmbeddingAIService {

    // MARK: - Singleton
    
    static let shared = EmbeddingAIService()

    // MARK: - Private Properties
    
    private var model: MLModel?
    private let tokenizer = BERTTokenizer.shared
    /// Apple's MobileBERT expects fixed sequence length (commonly 384)
    private let maxLength = 384

    // MARK: - Initialization
    
    private init() {
        loadModel()
    }

    // MARK: - Model Loading
    
    private func loadModel() {
        // Expect a model named "MobileBERT.mlmodelc" packaged by Xcode after you add "MobileBERT.mlmodel"
        // This loader will find it via the compiled model in the bundle
        guard let url = Bundle.main.url(forResource: "MobileBERT", withExtension: "mlmodelc") else {
            print("⚠️ MobileBERT.mlmodel not found in bundle. Add the model to Xcode.")
            model = nil
            return
        }
        do {
            model = try MLModel(contentsOf: url)
            print("✅ Loaded MobileBERT Core ML model")
            if let model = model {
                let inputNames = Array(model.modelDescription.inputDescriptionsByName.keys)
                print("🔍 MobileBERT expected inputs: \(inputNames)")
            }
        } catch {
            print("❌ Failed to load MobileBERT model: \(error)")
            model = nil
        }
    }

    // MARK: - Public API
    
    /// Generates a packing list for the given trip using AI embeddings and heuristics
    /// - Parameters:
    ///   - trip: The trip object containing destination, dates, activities, etc.
    ///   - weather: Optional weather summary for the destination
    ///   - completion: Callback with array of generated packing categories
    func generatePackingList(for trip: Trip, weather: WeatherSummary? = nil, completion: @escaping ([PackingCategory]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let text = self.buildTripDescription(for: trip, weather: weather)
            _ = self.getEmbedding(for: text) // embeddings currently unused for rule-based
            let categories = self.generateFromEmbedding([], trip: trip, weather: weather)
            print("✅ Generated categories (local): \(categories.count)")
            DispatchQueue.main.async { completion(categories) }
        }
    }

    /// Generates a chat response for packing list questions
    /// - Parameters:
    ///   - prompt: The chat prompt including context and user question
    ///   - completion: Callback with AI response text
    func generateChatResponse(prompt: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Simple helpful reply without LLM
            let lower = prompt.lowercased()
            let reply: String
            if lower.contains("add") && lower.contains("item") {
                reply = "Tap '+' in the packing list, pick a category, and enter the item name."
            } else if lower.contains("weather") {
                reply = "Check the weather card in your trip. Consider adding an umbrella, jacket, or sunscreen based on the forecast."
            } else {
                reply = "I can help modify your packing list. Ask about items by category, weather, or activities."
            }
            DispatchQueue.main.async { completion(reply) }
        }
    }

    // MARK: - Private Methods
    
    // MARK: - Embeddings

    private func getEmbedding(for text: String) -> [Float] {
        // If model is unavailable, return zero embedding and rely on heuristic
        guard let model = model else { return Array(repeating: 0, count: 768) }

        let (ids, mask) = tokenizer.encode(text, maxLength: maxLength)
        do {
            let seqLen = NSNumber(value: ids.count)
            let idsArray = try MLMultiArray(shape: [1, seqLen], dataType: .int32)
            let maskArray = try MLMultiArray(shape: [1, seqLen], dataType: .int32)
            let typeIdsArray = try MLMultiArray(shape: [1, seqLen], dataType: .int32)
            for (i, v) in ids.enumerated() { idsArray[i] = NSNumber(value: v) }
            for (i, v) in mask.enumerated() { maskArray[i] = NSNumber(value: v) }
            // tokenTypeIDs all zeros for single sequence inputs
            for i in 0..<ids.count { typeIdsArray[i] = 0 }

            // Build inputs using model's expected names exactly when simple (e.g., ["wordIDs","wordTypes"]) 
            let expected = Array(model.modelDescription.inputDescriptionsByName.keys)
            var dict: [String: MLFeatureValue] = [:]
            if Set(expected) == Set(["wordIDs", "wordTypes"]) {
                dict["wordIDs"] = MLFeatureValue(multiArray: idsArray)
                dict["wordTypes"] = MLFeatureValue(multiArray: typeIdsArray)
            } else {
                // Provide multiple aliases to maximize compatibility
                dict["wordIDs"] = MLFeatureValue(multiArray: idsArray)
                dict["attentionMask"] = MLFeatureValue(multiArray: maskArray)
                dict["tokenTypeIDs"] = MLFeatureValue(multiArray: typeIdsArray)
                dict["wordMask"] = MLFeatureValue(multiArray: maskArray)
                dict["wordTypes"] = MLFeatureValue(multiArray: typeIdsArray)
                dict["attention_mask"] = MLFeatureValue(multiArray: maskArray)
            }
            let inputs = try MLDictionaryFeatureProvider(dictionary: dict)

            let out = try model.prediction(from: inputs)
            
            // Debug: Print available output features
            print("🔍 Available output features: \(out.featureNames)")
            
            // Try different possible output names
            let lastHidden = out.featureValue(for: "last_hidden_state")?.multiArrayValue ?? 
                           out.featureValue(for: "embeddings")?.multiArrayValue ??
                           out.featureValue(for: "sequence_output")?.multiArrayValue ??
                           out.featureValue(for: "output")?.multiArrayValue
            
            guard let hidden = lastHidden else {
                // If no hidden state is exposed (e.g., QA-only model), skip embeddings quietly
                return Array(repeating: 0, count: 768)
            }

            // Take CLS embedding (position 0)
            let hiddenSize = hidden.shape.count >= 3 ? hidden.shape[2].intValue : 768
            var cls: [Float] = []
            cls.reserveCapacity(hiddenSize)
            for i in 0..<hiddenSize {
                let idx: [NSNumber] = [0, 0, NSNumber(value: i)]
                cls.append(hidden[idx].floatValue)
            }
            return cls
        } catch {
            print("❌ Embedding error: \(error)")
            return Array(repeating: 0, count: 768)
        }
    }

    // MARK: - Heuristic Generation
    
    /// Generates packing categories using embedding as weak signal
    private func generateFromEmbedding(_ embedding: [Float], trip: Trip, weather: WeatherSummary?) -> [PackingCategory] {
        // For now, use the robust rule-based generator; embedding can tune thresholds later
        return Trip.suggestedPackingCategories(
            occasion: trip.occasion,
            activities: trip.activities,
            weather: trip.expectedWeather,
            durationDays: max(1, trip.duration)
        )
    }

    /// Builds a text description of the trip for embedding generation
    private func buildTripDescription(for trip: Trip, weather: WeatherSummary?) -> String {
        let duration = max(1, trip.duration)
        let activities = trip.activities.map { $0.rawValue }.joined(separator: ", ")
        let weatherText = weather.map { "Weather: \($0.description), \(Int($0.currentTemp ?? 20))°C" } ?? "Weather: \(trip.expectedWeather.rawValue)"
        return """
        Trip to \(trip.destination) for \(duration) days. Occasion: \(trip.occasion.rawValue). Activities: \(activities.isEmpty ? "general" : activities). \(weatherText).
        """
    }
}


