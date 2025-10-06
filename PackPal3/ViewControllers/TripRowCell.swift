//
//  TripRowCell.swift
//  PackPal3
//
//  Created by AI Assistant on 2025-10-02.
//  Custom table view cell for displaying trip information
//

import UIKit

// MARK: - TripRowCell

/// Custom table view cell for displaying trip information
final class TripRowCell: UITableViewCell {
    // MARK: - Properties
    
    // Image URLs for random selection
    private let tripImages: [String] = [
        "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=3135&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "https://images.unsplash.com/photo-1473625247510-8ceb1760943f?q=80&w=2222&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1287&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "https://images.unsplash.com/photo-1573097637683-58e6462d2902?q=80&w=1287&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "https://images.unsplash.com/photo-1613744696511-fd64320d6c7b?q=80&w=2148&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "https://images.unsplash.com/photo-1446768500601-ac47e5ec3719?q=80&w=2292&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "https://images.unsplash.com/photo-1535866658354-f97cfb9d889b?q=80&w=927&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
    ]
    
    // UI Components
    private let containerView = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let agoLabel = UILabel()
    
    // Formatters
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        setupContainer()
        setupIcon()
        setupLabels()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Setup Methods
    
    private func setupContainer() {
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
    }
    
    private func setupIcon() {
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = DesignSystem.Radius.md
        iconView.alpha = 0.7 // Slight transparency
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)
    }
    
    private func setupLabels() {
        // Configure labels
        nameLabel.font = DesignSystem.Font.title(20)
        nameLabel.textColor = DesignSystem.Color.textPrimary
        nameLabel.numberOfLines = 1
        
        dateLabel.font = DesignSystem.Font.body(14)
        dateLabel.textColor = DesignSystem.Color.textSecondary
        
        agoLabel.font = DesignSystem.Font.caption(12)
        agoLabel.textColor = DesignSystem.Color.textTertiary
        
        // Add labels to container
        containerView.addSubview(nameLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(agoLabel)
        
        // Ensure labels are configured for auto layout
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        agoLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container fills content view
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSystem.Spacing.sm),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.sm),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignSystem.Spacing.sm),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DesignSystem.Spacing.sm),
            
            // Icon on the left, takes up vertical space
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
            
            // Labels vertically centered with icon, to the right of the icon
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: DesignSystem.Spacing.md),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DesignSystem.Spacing.sm),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: DesignSystem.Spacing.md),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DesignSystem.Spacing.sm),
            
            agoLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            agoLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: DesignSystem.Spacing.md),
            agoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DesignSystem.Spacing.sm)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(with trip: Trip) {
        // Set text
        nameLabel.text = trip.name
        dateLabel.text = "\(formatter.string(from: trip.startDate)) → \(formatter.string(from: trip.endDate))"
        agoLabel.text = relative(from: trip.endDate)
        
        // Randomly select and load image
        loadRandomTripImage()
    }
    
    // MARK: - Private Methods
    
    private func loadRandomTripImage() {
        // Randomly select an image URL
        guard let imageUrlString = tripImages.randomElement(),
              let imageUrl = URL(string: imageUrlString) else {
            return
        }
        
        // Download and set image
        URLSession.shared.dataTask(with: imageUrl) { [weak self] (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.iconView.image = image
            }
        }.resume()
    }
    
    private func relative(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

