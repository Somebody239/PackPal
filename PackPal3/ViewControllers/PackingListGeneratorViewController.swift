//
//  PackingListGeneratorViewController.swift
//  PackPal2
//
//  Created by AI Assistant on 2025-10-02.
//

import UIKit

/// Loading screen that shows packing list generation progress
final class PackingListGeneratorViewController: UIViewController {
    
    var onComplete: (([PackingCategory]) -> Void)?
    private let trip: Trip
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let iconImageView = UIImageView()
    private let statusLabel = UILabel()
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startGeneration()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Icon
        iconImageView.image = UIImage(systemName: "suitcase.fill")
        iconImageView.tintColor = .systemOrange
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.text = "Generating Packing List"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtitle
        subtitleLabel.text = "Analyzing your trip details..."
        subtitleLabel.font = .systemFont(ofSize: 17)
        subtitleLabel.textColor = UIColor(white: 0.7, alpha: 1.0)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress bar
        progressView.progressTintColor = .systemOrange
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.2)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status label
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            progressView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func startGeneration() {
        let steps = [
            ("Analyzing destination weather", 0.2),
            ("Reviewing activities", 0.4),
            ("Calculating trip duration", 0.6),
            ("Generating AI recommendations", 0.8),
            ("Finalizing packing list", 1.0)
        ]
        
        var currentStep = 0
        var generatedCategories: [PackingCategory]?
        
        // Start AI generation in parallel (MobileBERT embeddings + heuristic)
        EmbeddingAIService.shared.generatePackingList(for: trip) { [weak self] (categories: [PackingCategory]) in
            DispatchQueue.main.async {
                generatedCategories = categories
                print("✅ AI packing list generated with \(categories.count) categories")
                print("🧳 Categories passed to UI: \(categories.map { $0.name })")
            }
        }
        
        func performNextStep() {
            guard currentStep < steps.count else {
                // Wait for AI if not ready yet
                if generatedCategories == nil {
                    statusLabel.text = "Waiting for AI..."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        performNextStep()
                    }
                } else {
                    complete(with: generatedCategories ?? [])
                }
                return
            }
            
            let (status, progress) = steps[currentStep]
            statusLabel.text = status
            
            UIView.animate(withDuration: 0.3) {
                self.progressView.setProgress(Float(progress), animated: true)
            }
            
            currentStep += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                performNextStep()
            }
        }
        
        performNextStep()
    }
    
    private func complete(with categories: [PackingCategory]) {
        print("🎯 complete() called with \(categories.count) categories")
        print("🎯 Category names: \(categories.map { $0.name })")
        
        // Add a checkmark animation
        UIView.animate(withDuration: 0.3, animations: {
            self.iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
            self.iconImageView.tintColor = .systemGreen
            self.titleLabel.text = "Packing List Ready!"
            self.subtitleLabel.text = "Your trip is all set"
            self.statusLabel.text = ""
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                print("🎯 Calling onComplete with \(categories.count) categories")
                self.onComplete?(categories)
                self.dismiss(animated: true)
            }
        }
    }
}


