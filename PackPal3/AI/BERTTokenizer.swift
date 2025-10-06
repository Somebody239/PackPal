//
//  BERTTokenizer.swift
//  PackPal3
//
//  Minimal WordPiece tokenizer for BERT-compatible vocab.txt
//

import Foundation

/// Minimal WordPiece tokenizer for BERT-compatible vocabulary
/// Handles tokenization for Core ML MobileBERT model
final class BERTTokenizer {

    // MARK: - Singleton
    
    static let shared = BERTTokenizer()

    // MARK: - Private Properties
    
    private var tokenToId: [String: Int] = [:]
    private var idToToken: [Int: String] = [:]

    /// Common special tokens for BERT tokenization
    private let cls = "[CLS]"
    private let sep = "[SEP]"
    private let pad = "[PAD]"
    private let unk = "[UNK]"

    // MARK: - Initialization
    
    private init() {
        loadVocab()
    }

    // MARK: - Private Methods
    
    /// Loads vocabulary from vocab.txt file in the bundle
    private func loadVocab() {
        // Try root first
        var url = Bundle.main.url(forResource: "vocab", withExtension: "txt")
        // Fallback: common subdirectory name used in this project
        if url == nil {
            url = Bundle.main.url(forResource: "vocab", withExtension: "txt", subdirectory: "tokenizer_distilbert")
        }
        guard let vocabURL = url else {
            print("⚠️ Missing vocab.txt in bundle (tried root and tokenizer_distilbert/")
            return
        }
        do {
            let data = try Data(contentsOf: vocabURL)
            guard let text = String(data: data, encoding: .utf8) else { return }
            var index = 0
            text.split(separator: "\n").forEach { line in
                let token = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !token.isEmpty else { return }
                tokenToId[token] = index
                idToToken[index] = token
                index += 1
            }
            print("✅ Loaded BERT vocab with \(tokenToId.count) tokens")
        } catch {
            print("⚠️ Failed to load vocab.txt: \(error)")
        }
    }

    // MARK: - Public Methods
    
    /// Encodes text into BERT-compatible token IDs and attention mask
    /// - Parameters:
    ///   - text: Input text to tokenize
    ///   - maxLength: Maximum sequence length (default: 64)
    /// - Returns: Tuple of token IDs and attention mask
    func encode(_ text: String, maxLength: Int = 64) -> (ids: [Int32], mask: [Int32]) {
        // Basic whitespace tokenization, lowercasing
        let cleaned = text.lowercased()
        let words = cleaned.split(whereSeparator: { $0.isWhitespace })

        var ids: [Int32] = []
        var mask: [Int32] = []

        func id(for token: String) -> Int32 {
            if let i = tokenToId[token] { return Int32(i) }
            return Int32(tokenToId[unk] ?? 100)
        }

        // [CLS]
        ids.append(id(for: cls))
        mask.append(1)

        for word in words {
            // Very simplified WordPiece: try full token, else unk
            let token = String(word)
            ids.append(id(for: token))
            mask.append(1)
            if ids.count >= maxLength - 1 { break }
        }

        // [SEP]
        ids.append(id(for: sep))
        mask.append(1)

        // Pad
        while ids.count < maxLength {
            ids.append(id(for: pad))
            mask.append(0)
        }

        return (ids, mask)
    }
}


