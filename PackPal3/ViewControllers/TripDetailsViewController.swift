//
//  TripDetailsViewController.swift
//  PackPal2
//
//  Created by Kishan Joshi on 2025-10-01.
//

import UIKit

// MARK: - TripDetailsDelegate

protocol TripDetailsDelegate: AnyObject {
    func tripDetailsViewControllerDidUpdateTrip(_ controller: TripDetailsViewController, trip: Trip)
    func tripDetailsViewControllerDidDeleteTrip(_ controller: TripDetailsViewController, trip: Trip)
}

// MARK: - TripDetailsViewController

/// Swipeable modal packing list view - main focus on checklist with compact header
final class TripDetailsViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: TripDetailsDelegate?
    var trip: Trip {
        didSet {
            updateUI()
        }
    }

    // MARK: - UI Components

    private let handleBar = UIView()
    private let headerContainer = UIView()
    private let tripTitleLabel = UILabel()
    private let dateLabel = UILabel()
    private let weatherIconView = UIImageView()
    private let weatherTempLabel = UILabel()
    private let weatherDescLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    private let packingTableView = UITableView(frame: .zero, style: .grouped)
    private let bottomToolbar = UIToolbar()

    // MARK: - Data

    private var packingCategories: [PackingCategory] = []
    private var currentWeather: WeatherSummary?

    // MARK: - Initialization

    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        updateUI()
        loadWeatherData()

        // Prevent sheet from dismissing when tapping content
        if let presentation = presentationController as? UISheetPresentationController {
            presentation.delegate = self
        }
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        // Close button (top left)
        let closeItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), 
                                       style: .plain, 
                                       target: self, 
                                       action: #selector(closeTapped))
        closeItem.tintColor = DesignSystem.Color.textPrimary
        navigationItem.leftBarButtonItem = closeItem
        
        // Edit button (top right)
        let editItem = UIBarButtonItem(image: UIImage(systemName: "pencil"), 
                                      style: .plain, 
                                      target: self, 
                                      action: #selector(editTapped))
        editItem.tintColor = DesignSystem.Color.primary
        navigationItem.rightBarButtonItem = editItem
    }

    private func setupUI() {
        // Liquid Glass modal background
        view.backgroundColor = DesignSystem.Color.background
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        
        // Swipe handle bar
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        handleBar.backgroundColor = DesignSystem.Color.textTertiary.withAlphaComponent(0.3)
        handleBar.layer.cornerRadius = 2.5
        
        // Header container (transparent, inline layout)
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.backgroundColor = .clear
        
        // Trip title
        tripTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tripTitleLabel.font = DesignSystem.Font.title(24)
        tripTitleLabel.textColor = DesignSystem.Color.textPrimary
        tripTitleLabel.numberOfLines = 1
        
        // Date label (smaller, below title)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = DesignSystem.Font.body(14)
        dateLabel.textColor = DesignSystem.Color.textSecondary
        
        // Weather icon (SF Symbol) - smaller for inline layout
        weatherIconView.translatesAutoresizingMaskIntoConstraints = false
        weatherIconView.contentMode = .scaleAspectFit
        weatherIconView.tintColor = DesignSystem.Color.primary
        weatherIconView.image = UIImage(systemName: "cloud.sun.fill") // Default icon
        
        // Configure image to use smaller size for inline layout
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium, scale: .default)
        weatherIconView.preferredSymbolConfiguration = config
        
        // Weather temperature label (smaller, inline)
        weatherTempLabel.translatesAutoresizingMaskIntoConstraints = false
        weatherTempLabel.font = .systemFont(ofSize: 14, weight: .medium)
        weatherTempLabel.textColor = DesignSystem.Color.textPrimary
        weatherTempLabel.textAlignment = .right
        weatherTempLabel.text = "--°"
        
        // Weather description label (very small, inline)
        weatherDescLabel.translatesAutoresizingMaskIntoConstraints = false
        weatherDescLabel.font = DesignSystem.Font.body(10)
        weatherDescLabel.textColor = DesignSystem.Color.textTertiary
        weatherDescLabel.textAlignment = .right
        weatherDescLabel.numberOfLines = 1
        weatherDescLabel.text = "Loading..."
        
        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = DesignSystem.Color.primary
        progressBar.trackTintColor = DesignSystem.Color.surfaceBorder
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.progress = 0.0
        
        // Progress label
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = DesignSystem.Font.body(12)
        progressLabel.textColor = DesignSystem.Color.textTertiary
        progressLabel.text = "0% packed"
        
        // Packing list table view - this is the main scrollable container
        packingTableView.translatesAutoresizingMaskIntoConstraints = false
        packingTableView.backgroundColor = DesignSystem.Color.background
        packingTableView.separatorStyle = .singleLine
        packingTableView.separatorColor = DesignSystem.Color.surfaceBorder.withAlphaComponent(0.3)
        packingTableView.delegate = self
        packingTableView.dataSource = self
        packingTableView.register(PackingItemCell.self, forCellReuseIdentifier: "ItemCell")
        packingTableView.estimatedRowHeight = 44
        packingTableView.rowHeight = UITableView.automaticDimension
        packingTableView.estimatedSectionHeaderHeight = 36
        packingTableView.sectionHeaderHeight = UITableView.automaticDimension
        packingTableView.contentInsetAdjustmentBehavior = .never
        packingTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        packingTableView.tableHeaderView = headerContainer // Set header as table header
        packingTableView.tableHeaderView?.frame.size.height = 120 // Initial height, will adjust
        
        // Bottom toolbar with glass effect
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.barStyle = .black
        bottomToolbar.isTranslucent = true
        bottomToolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        bottomToolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        // Regenerate button
        let regenerateItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), 
                                             style: .plain, 
                                             target: self, 
                                             action: #selector(regenerateTapped))
        regenerateItem.tintColor = DesignSystem.Color.primary
        
        // Chat button
        let chatItem = UIBarButtonItem(image: UIImage(systemName: "bubble.left.and.bubble.right.fill"), 
                                       style: .plain, 
                                       target: self, 
                                       action: #selector(chatTapped))
        chatItem.tintColor = DesignSystem.Color.textPrimary
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bottomToolbar.items = [flexSpace, regenerateItem, flexSpace, chatItem, flexSpace]
        
        // Add subviews to header
        headerContainer.addSubview(tripTitleLabel)
        headerContainer.addSubview(dateLabel)
        headerContainer.addSubview(weatherIconView)
        headerContainer.addSubview(weatherTempLabel)
        headerContainer.addSubview(weatherDescLabel)
        headerContainer.addSubview(progressBar)
        headerContainer.addSubview(progressLabel)
        
        // Add main views
        view.addSubview(handleBar)
        view.addSubview(packingTableView)
        view.addSubview(bottomToolbar)
    }
    
    private func setupConstraints() {
        // Setup header container constraints
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerContainer.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 40),
            
            // Trip title (left side, with weather inline)
            tripTitleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
            tripTitleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
            tripTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: weatherIconView.leadingAnchor, constant: -12),
            
            // Date label (below title)
            dateLabel.topAnchor.constraint(equalTo: tripTitleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: tripTitleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: weatherIconView.leadingAnchor, constant: -12),
            
            // Weather icon (right side, top line with title)
            weatherIconView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
            weatherIconView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),
            weatherIconView.widthAnchor.constraint(equalToConstant: 16),
            weatherIconView.heightAnchor.constraint(equalToConstant: 16),
            
            // Weather temperature (beside icon, same line as title)
            weatherTempLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
            weatherTempLabel.trailingAnchor.constraint(equalTo: weatherIconView.leadingAnchor, constant: -4),
            weatherTempLabel.leadingAnchor.constraint(greaterThanOrEqualTo: tripTitleLabel.trailingAnchor, constant: 12),
            
            // Weather description (below temperature, same line as date)
            weatherDescLabel.topAnchor.constraint(equalTo: dateLabel.topAnchor),
            weatherDescLabel.trailingAnchor.constraint(equalTo: weatherIconView.leadingAnchor, constant: -4),
            weatherDescLabel.leadingAnchor.constraint(greaterThanOrEqualTo: dateLabel.trailingAnchor, constant: 12),
            
            // Progress bar
            progressBar.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 24), // Increased spacing
            progressBar.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
            
            // Progress label
            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 6),
            progressLabel.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -16),
            
            // Handle bar
            handleBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            handleBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 5),
            
            // Table view - fills space between handle and toolbar
            packingTableView.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 12),
            packingTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            packingTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            packingTableView.bottomAnchor.constraint(equalTo: bottomToolbar.topAnchor),
            
            // Bottom toolbar
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 49)
        ])
        
        // Update header size after layout
        headerContainer.layoutIfNeeded()
        let headerSize = headerContainer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        headerContainer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: headerSize.height)
        packingTableView.tableHeaderView = headerContainer
    }
    
    // MARK: - UI Update

    private func updateUI() {
        print("🔍 updateUI() called - trip has \(trip.packingCategories.count) categories")

        // Update header
        tripTitleLabel.text = trip.destination

        // Format date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: trip.startDate)
        dateLabel.text = "\(dateStr) • \(trip.duration) days"

        // Update packing list - always use fallback if empty
        if trip.packingCategories.isEmpty {
            print("⚠️ No categories, generating fallback")
            packingCategories = Trip.suggestedPackingCategories(
                occasion: trip.occasion,
                activities: trip.activities,
                weather: trip.expectedWeather,
                durationDays: max(1, trip.duration)
            )
            // Save fallback to trip
            trip.packingCategories = packingCategories
            TripManager.shared.saveTrip(trip)
        } else {
            packingCategories = trip.packingCategories
        }

        print("📋 Displaying \(packingCategories.count) categories with \(packingCategories.flatMap { $0.items }.count) total items")

        // Update progress
        updateProgress()

        // Reload table
        packingTableView.reloadData()

        print("✅ updateUI() complete")
    }

    private func updateProgress() {
        let allItems = packingCategories.flatMap { $0.items }
        let packedItems = allItems.filter { $0.isPacked }
        let progress = allItems.isEmpty ? 0.0 : Float(packedItems.count) / Float(allItems.count)

        progressBar.progress = progress
        progressLabel.text = "\(Int(progress * 100))% packed (\(packedItems.count)/\(allItems.count) items)"
    }

    // MARK: - Weather
    
    private func loadWeatherData() {
        WeatherService.fetchSummary(
            for: trip.destination,
            start: trip.startDate,
            end: trip.endDate
        ) { [weak self] (summary: WeatherSummary) in
            guard let self = self else { return }
            self.currentWeather = summary
            
            DispatchQueue.main.async {
                // Set weather icon with smaller configuration for inline layout
                let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium, scale: .default)
                self.weatherIconView.image = UIImage(systemName: summary.icon, withConfiguration: config)
                self.weatherIconView.tintColor = DesignSystem.Color.primary
                
                // Set temperature
                let temp = summary.currentTemp ?? summary.maxTemp ?? 0
                self.weatherTempLabel.text = "\(Int(temp))°C"
                
                // Set description
                self.weatherDescLabel.text = summary.description
            }
        }
    }
    

    // MARK: - Actions

    @objc private func regenerateTapped() {
        print("🔄 Regenerate tapped - checking trip details, weather, and dates")
        
        // Show loading in toolbar
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.color = DesignSystem.Color.primary
        let spinnerItem = UIBarButtonItem(customView: spinner)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bottomToolbar.items = [flexSpace, spinnerItem, flexSpace]
        
        // Reload weather first, then regenerate
        WeatherService.fetchSummary(
            for: trip.destination,
            start: trip.startDate,
            end: trip.endDate
        ) { [weak self] (weather: WeatherSummary) in
            guard let self = self else { return }
            self.currentWeather = weather
            
            // Generate new packing list with updated weather
            EmbeddingAIService.shared.generatePackingList(
                for: self.trip,
                weather: weather
            ) { categories in
                DispatchQueue.main.async {
                    // Update trip with new categories
                    self.trip.packingCategories = categories
                    TripManager.shared.saveTrip(self.trip)
                    self.delegate?.tripDetailsViewControllerDidUpdateTrip(self, trip: self.trip)
                    
                    // Restore toolbar and update UI
                    self.restoreToolbar()
                    self.updateUI()
                    Haptics.confirm()
                }
            }
        }
    }
    
    private func restoreToolbar() {
        // Regenerate button
        let regenerateItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), 
                                             style: .plain, 
                                             target: self, 
                                             action: #selector(regenerateTapped))
        regenerateItem.tintColor = DesignSystem.Color.primary
        
        // Chat button
        let chatItem = UIBarButtonItem(image: UIImage(systemName: "bubble.left.and.bubble.right.fill"), 
                                       style: .plain, 
                                       target: self, 
                                       action: #selector(chatTapped))
        chatItem.tintColor = DesignSystem.Color.textPrimary
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bottomToolbar.items = [flexSpace, regenerateItem, flexSpace, chatItem, flexSpace]
    }
    
    @objc private func closeTapped() {
        print("❌ Close tapped - dismissing sheet")
        dismiss(animated: true)
    }
    
    @objc private func editTapped() {
        print("✏️ Edit tapped - opening trip edit screen")
        
        // Create trip creation controller in edit mode
        let editVC = TripCreationViewController()
        editVC.prefillTrip = trip
        editVC.delegate = self
        editVC.modalPresentationStyle = .overFullScreen
        editVC.modalTransitionStyle = .coverVertical
        present(editVC, animated: true)
    }
    
    @objc private func chatTapped() {
        print("💬 Chat tapped - opening AI chat screen")
        let chatVC = AIChatViewController(trip: trip)
        chatVC.modalPresentationStyle = .pageSheet
        if let sheet = chatVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(chatVC, animated: true)
    }
    
}

// MARK: - TableView

extension TripDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        let count = packingCategories.isEmpty ? 1 : packingCategories.count
        print("📊 TableView sections: \(count)")
        return count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if packingCategories.isEmpty {
            print("📊 Section \(section): 1 row (empty state)")
            return 1 // Show empty state
        }
        let rowCount = packingCategories[section].items.count
        print("📊 Section \(section) (\(packingCategories[section].name)): \(rowCount) rows")
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! PackingItemCell
        
        if packingCategories.isEmpty {
            cell.configureEmpty()
        } else {
            let item = packingCategories[indexPath.section].items[indexPath.row]
            let categoryId = packingCategories[indexPath.section].id
            cell.configure(item: item, categoryId: categoryId)
            cell.onToggle = { [weak self] categoryId, itemId, isPacked in
                self?.toggleItem(categoryId: categoryId, itemId: itemId, isPacked: isPacked)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if packingCategories.isEmpty {
            return nil
        }
        
        let headerView = UIView()
        headerView.backgroundColor = DesignSystem.Color.background
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = packingCategories[section].name.uppercased()
        label.font = DesignSystem.Font.subtitle(14)
        label.textColor = DesignSystem.Color.textSecondary
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        // Add add button per category
        let addButton = UIButton(type: .system)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = DesignSystem.Color.primary
        addButton.tag = section
        addButton.addTarget(self, action: #selector(addItemTapped(_:)), for: .touchUpInside)
        headerView.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])

        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return packingCategories.isEmpty ? 0 : 36
    }
    
    private func toggleItem(categoryId: UUID, itemId: UUID, isPacked: Bool) {
        // Find and update item
        if let categoryIndex = trip.packingCategories.firstIndex(where: { $0.id == categoryId }),
           let itemIndex = trip.packingCategories[categoryIndex].items.firstIndex(where: { $0.id == itemId }) {
            trip.packingCategories[categoryIndex].items[itemIndex].isPacked = isPacked
            TripManager.shared.saveTrip(trip)
            delegate?.tripDetailsViewControllerDidUpdateTrip(self, trip: trip)
            updateProgress()
            Haptics.tap()
        }
    }

    @objc private func addItemTapped(_ sender: UIButton) {
        let section = sender.tag
        guard section < packingCategories.count else { return }
        
        let alert = UIAlertController(title: "Add Item",
                                      message: "Enter a new item for \(packingCategories[section].name)",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Item name"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let self = self, let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let newItem = PackingItem(name: name)
            self.trip.packingCategories[section].items.append(newItem)
            TripManager.shared.saveTrip(self.trip)
            self.packingCategories = self.trip.packingCategories
            self.packingTableView.reloadSections(IndexSet(integer: section), with: .automatic)
            self.updateProgress()
        }))
        present(alert, animated: true)
    }
}

// MARK: - PackingItemCell

private class PackingItemCell: UITableViewCell {
    private let checkbox = UIButton(type: .system)
    private let itemLabel = UILabel()
    private var categoryId: UUID?
    private var itemId: UUID?
    
    var onToggle: ((UUID, UUID, Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        
        itemLabel.translatesAutoresizingMaskIntoConstraints = false
        itemLabel.font = DesignSystem.Font.body(16)
        itemLabel.textColor = DesignSystem.Color.textPrimary
        itemLabel.numberOfLines = 0
        
        contentView.addSubview(checkbox)
        contentView.addSubview(itemLabel)

        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            checkbox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkbox.widthAnchor.constraint(equalToConstant: 28),
            checkbox.heightAnchor.constraint(equalToConstant: 28),
            
            itemLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 12),
            itemLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            itemLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            itemLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(item: PackingItem, categoryId: UUID) {
        self.categoryId = categoryId
        self.itemId = item.id
        itemLabel.text = item.name
        
        let imageName = item.isPacked ? "checkmark.circle.fill" : "circle"
        checkbox.setImage(UIImage(systemName: imageName), for: .normal)
        checkbox.tintColor = item.isPacked ? DesignSystem.Color.primary : DesignSystem.Color.textTertiary
    }
    
    func configureEmpty() {
        categoryId = nil
        itemId = nil
        checkbox.isHidden = true
        itemLabel.text = "No packing items yet. Tap 'Regenerate' to create a list."
        itemLabel.textColor = DesignSystem.Color.textTertiary
        itemLabel.textAlignment = .center
    }
    
    @objc private func checkboxTapped() {
        guard let categoryId = categoryId, let itemId = itemId else { return }
        
        let currentlyPacked = checkbox.currentImage == UIImage(systemName: "checkmark.circle.fill")
        let newPacked = !currentlyPacked
        
        let imageName = newPacked ? "checkmark.circle.fill" : "circle"
        checkbox.setImage(UIImage(systemName: imageName), for: .normal)
        checkbox.tintColor = newPacked ? DesignSystem.Color.primary : DesignSystem.Color.textTertiary
        
        onToggle?(categoryId, itemId, newPacked)
    }
}

// MARK: - AIChatViewController

private class AIChatViewController: UIViewController {
    private let trip: Trip
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputContainer = UIView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var messages: [(String, Bool)] = [] // (text, isUser)
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // Add initial AI greeting
        messages.append(("Hi! I'm your packing assistant. Ask me anything about what to pack for \(trip.destination)!", false))
        tableView.reloadData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background
        title = "💬 Chat with AI"
        
        // Table view for messages
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        // Input container
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.backgroundColor = DesignSystem.Color.surface
        
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.placeholder = "Ask about packing..."
        inputField.backgroundColor = DesignSystem.Color.surfaceBorder
        inputField.textColor = DesignSystem.Color.textPrimary
        inputField.layer.cornerRadius = 20
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        inputField.leftViewMode = .always
        inputField.delegate = self
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = DesignSystem.Color.primary
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)
        view.addSubview(tableView)
        view.addSubview(inputContainer)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),
            
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    // MARK: - Actions

    @objc private func sendTapped() {
        guard let text = inputField.text, !text.isEmpty else { return }

        // Add user message
        messages.append((text, true))
        inputField.text = ""
        tableView.reloadData()
        scrollToBottom()

        // Get AI response
        let prompt = "User asked about trip to \(trip.destination): \(text)"
        EmbeddingAIService.shared.generateChatResponse(
            prompt: prompt
        ) { [weak self] response in
            DispatchQueue.main.async {
                self?.messages.append((response, false))
                self?.tableView.reloadData()
                self?.scrollToBottom()
            }
        }
    }
    
    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

extension AIChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! ChatMessageCell
        let (text, isUser) = messages[indexPath.row]
        cell.configure(text: text, isUser: isUser)
        return cell
    }
}

extension AIChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}

// MARK: - ChatMessageCell

private class ChatMessageCell: UITableViewCell {
    private let bubble = UIView()
    private let messageLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 16
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = DesignSystem.Font.body(15)
        messageLabel.numberOfLines = 0
        
        bubble.addSubview(messageLabel)
        contentView.addSubview(bubble)
    }
    
    func configure(text: String, isUser: Bool) {
        messageLabel.text = text
        
        if isUser {
            bubble.backgroundColor = DesignSystem.Color.primary
            messageLabel.textColor = .white
        } else {
            bubble.backgroundColor = DesignSystem.Color.surface
            messageLabel.textColor = DesignSystem.Color.textPrimary
        }
        
        // Remove old constraints
        NSLayoutConstraint.deactivate(bubble.constraints)
        NSLayoutConstraint.deactivate(contentView.constraints)
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -12),
            
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])
        
        if isUser {
            NSLayoutConstraint.activate([
                bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
        } else {
            NSLayoutConstraint.activate([
                bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            ])
        }
    }
}

// MARK: - TripCreationDelegate

extension TripDetailsViewController: TripCreationDelegate {
    func tripCreationViewController(_ controller: TripCreationViewController, didCreateTrip trip: Trip) {
        print("✏️ Trip updated - regenerating packing list")
        
        // Update the trip
        self.trip = trip
        TripManager.shared.saveTrip(trip)
        delegate?.tripDetailsViewControllerDidUpdateTrip(self, trip: trip)
        
        // Regenerate packing list with new trip details
        regeneratePackingListForUpdatedTrip()
        
        // Dismiss the edit controller
        controller.dismiss(animated: true)
    }
    
    func tripCreationViewControllerDidCancel(_ controller: TripCreationViewController) {
        print("✏️ Trip edit cancelled")
        controller.dismiss(animated: true)
    }
    
    private func regeneratePackingListForUpdatedTrip() {
        print("🔄 Regenerating packing list for updated trip")
        
        // Show loading in toolbar
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.color = DesignSystem.Color.primary
        let spinnerItem = UIBarButtonItem(customView: spinner)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bottomToolbar.items = [flexSpace, spinnerItem, flexSpace]
        
        // Reload weather first, then regenerate
        WeatherService.fetchSummary(
            for: trip.destination,
            start: trip.startDate,
            end: trip.endDate
        ) { [weak self] (weather: WeatherSummary) in
            guard let self = self else { return }
            self.currentWeather = weather
            
            // Generate new packing list with updated weather and trip details
            EmbeddingAIService.shared.generatePackingList(
                for: self.trip,
                weather: weather
            ) { categories in
                DispatchQueue.main.async {
                    // Update trip with new categories
                    self.trip.packingCategories = categories
                    TripManager.shared.saveTrip(self.trip)
                    self.delegate?.tripDetailsViewControllerDidUpdateTrip(self, trip: self.trip)
                    
                    // Restore toolbar and update UI
                    self.restoreToolbar()
                    self.updateUI()
                    Haptics.confirm()
                }
            }
        }
    }
}

// MARK: - UISheetPresentationControllerDelegate

extension TripDetailsViewController: UISheetPresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Allow dismissal only by explicit swipe down, not by taps
        return true
    }
}
