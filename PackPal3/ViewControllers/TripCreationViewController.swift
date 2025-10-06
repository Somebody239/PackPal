//
//  TripCreationViewController.swift
//  PackPal3
//
//  Created by Kishan Joshi on 2025-10-01.
//  View controller for creating new trips with packing-related questions
//

import UIKit
import MapKit
import SwiftUI

// MARK: - TripCreationDelegate

/// Delegate protocol for trip creation events
protocol TripCreationDelegate: AnyObject {
    func tripCreationViewController(_ controller: TripCreationViewController, didCreateTrip trip: Trip)
    func tripCreationViewControllerDidCancel(_ controller: TripCreationViewController)
}

// MARK: - TripCreationViewController

/// View controller for creating new trips with packing-related questions
final class TripCreationViewController: UIViewController {

    // MARK: - Properties
    
    // Delegate
    weak var delegate: TripCreationDelegate?
    var prefillTrip: Trip?

    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let containerView = UIView()

    // Form fields
    private let tripNameField = UITextField()
    private let destinationField = UITextField()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let occasionButton = UIButton(type: .system)
    private var activitiesButtons: [String: UIButton] = [:]
    private var occasionButtons: [String: UIButton] = [:]
    private let weatherSegmentedControl = UISegmentedControl()
    private var tripTypeButton: UIButton?
    private let notesTextView = UITextView()

    // UI helpers
    private let dateSummaryLabel = UILabel()
    private var dateButton: UIButton?
    private let backgroundButton = UIButton(type: .system)
    private let datePickerContainer = UIStackView()
    private var formStack: UIStackView?

    // Buttons
    private let cancelButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private var saveHosting: UIHostingController<GlassCapsuleButton>?

    // Form state
    private var selectedOccasion: TripOccasion = .vacation
    private var selectedActivities: [TripActivity] = []
    private var selectedWeather: WeatherCondition = .moderate
    private var selectedTripType: TripType = .leisure

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupGestures()
        if let trip = prefillTrip {
            prefillForm(with: trip)
        }
    }
    
    private func prefillForm(with trip: Trip) {
        tripNameField.text = trip.name
        destinationField.text = trip.destination
        startDatePicker.date = trip.startDate
        endDatePicker.date = trip.endDate
        selectedOccasion = trip.occasion
        selectedActivities = trip.activities
        selectedWeather = trip.expectedWeather
        selectedTripType = trip.tripType
        notesTextView.text = trip.notes.isEmpty ? "Add any additional notes about your trip..." : trip.notes
        notesTextView.textColor = trip.notes.isEmpty ? .lightGray : .white
        
        // Update trip type button after it's created
        DispatchQueue.main.async { [weak self] in
            self?.updateTripTypeButton()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        // Rich gradient background matching trip details
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0).cgColor,
            UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Container with enhanced glassmorphism
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = 28
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true

        // Enhanced glass effect
        let blurEffect = UIBlurEffect(style: .systemThickMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        containerView.insertSubview(blurView, at: 0)
        
        // Add subtle tint overlay
        let tintView = UIView()
        tintView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.02)
        tintView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(tintView)
        
        NSLayoutConstraint.activate([
            tintView.topAnchor.constraint(equalTo: blurView.topAnchor),
            tintView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor)
        ])

        // Scroll view setup
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        _ = createFormStack()
        // Ensure default dates to avoid invalid range and improve UX
        startDatePicker.date = Date()
        endDatePicker.date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        scrollView.addSubview(contentView)
        containerView.addSubview(scrollView)

        view.addSubview(containerView)

        // Buttons (Cancel / Save at top like screenshot) with liquid glass for Save
        setupButtons()

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 72),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60)
        ])
    }

    private func setupConstraints() {
        // Additional constraints for dynamic content sizing
        let contentHeight = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        contentHeight.priority = .defaultLow
        contentHeight.isActive = true
    }

    private func setupButtons() {
        // Cancel button (Liquid Glass close control matching Settings page)
        let cancelContainer: UIView
        if #available(iOS 18.0, *) {
            let hosting = UIHostingController(rootView: GlassCloseButton(action: { [weak self] in
                self?.cancelTapped()
            }))
            addChild(hosting)
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            hosting.view.backgroundColor = .clear
            hosting.didMove(toParent: self)
            cancelContainer = hosting.view
        } else {
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
            blur.layer.cornerRadius = 22
            blur.clipsToBounds = true
            blur.translatesAutoresizingMaskIntoConstraints = false

            cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            cancelButton.tintColor = .white
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            cancelButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
            cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            blur.contentView.addSubview(cancelButton)

            NSLayoutConstraint.activate([
                cancelButton.centerXAnchor.constraint(equalTo: blur.centerXAnchor),
                cancelButton.centerYAnchor.constraint(equalTo: blur.centerYAnchor)
            ])
            cancelContainer = blur
        }

        // Save button (Liquid Glass on iOS 18+, UIKit fallback otherwise)
        let trailingControl: UIView
        if #available(iOS 18.0, *) {
            let hosting = UIHostingController(rootView: GlassCapsuleButton(title: "Save", tint: .orange, action: { [weak self] in
                self?.saveTapped()
            }))
            addChild(hosting)
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            hosting.view.backgroundColor = .clear
            hosting.didMove(toParent: self)
            saveHosting = hosting
            trailingControl = hosting.view
        } else {
            var saveConfig = UIButton.Configuration.filled()
            saveConfig.baseBackgroundColor = .systemOrange
            saveConfig.baseForegroundColor = .white
            saveConfig.title = "Save"
            saveConfig.cornerStyle = .capsule
            saveConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 17, weight: .semibold)
                return outgoing
            }
            saveConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24)
            saveButton.configuration = saveConfig
            saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
            trailingControl = saveButton
        }

        // Button container
        let spacer = UIView()
        let buttonStack = UIStackView(arrangedSubviews: [cancelContainer, spacer, trailingControl])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12

        containerView.addSubview(buttonStack)
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            buttonStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            // Ensure 44pt touch target for cancel control
            cancelContainer.widthAnchor.constraint(equalToConstant: 44),
            cancelContainer.heightAnchor.constraint(equalToConstant: 44)
        ])

        if #available(iOS 18.0, *) {
            // Ensure the SwiftUI controls respect height
            trailingControl.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Form Creation

    private func createFormStack() -> UIStackView {
        // Centered stack, large title, and date button modeled after documentation guidance
        let outer = UIStackView()
        outer.axis = .vertical
        outer.alignment = .fill
        outer.spacing = 24
        outer.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 32, right: 0)
        outer.isLayoutMarginsRelativeArrangement = true

        // Title
        tripNameField.placeholder = "Trip name"
        tripNameField.font = .systemFont(ofSize: 34, weight: .bold)
        tripNameField.textColor = .white
        tripNameField.textAlignment = .left
        tripNameField.backgroundColor = .clear
        tripNameField.borderStyle = .none
        tripNameField.autocorrectionType = .no
        tripNameField.autocapitalizationType = .words
        tripNameField.returnKeyType = .done
        tripNameField.enablesReturnKeyAutomatically = true
        tripNameField.clearButtonMode = .whileEditing
        tripNameField.delegate = self
        tripNameField.attributedPlaceholder = NSAttributedString(
            string: "Trip name",
            attributes: [.foregroundColor: UIColor(white: 0.6, alpha: 1.0), .font: UIFont.systemFont(ofSize: 34, weight: .bold)]
        )
        tripNameField.setContentHuggingPriority(.required, for: .vertical)

        // Date button (with icon) -> opens dedicated date selector screen
        let dateBtn = UIButton(type: .system)
        var dateConfig = UIButton.Configuration.plain()
        dateConfig.baseForegroundColor = UIColor(white: 0.85, alpha: 1.0)
        dateConfig.image = UIImage(systemName: "calendar")
        dateConfig.imagePadding = 10
        dateConfig.imagePlacement = .leading
        dateConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        dateConfig.attributedTitle = AttributedString("Select dates", attributes: .init([
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor(white: 0.85, alpha: 1.0)
        ]))
        dateBtn.configuration = dateConfig
        dateBtn.contentHorizontalAlignment = .leading
        dateBtn.addTarget(self, action: #selector(openDateSelector), for: .touchUpInside)
        self.dateButton = dateBtn

        // Destination field, centered style
        let destinationContainer = createTextFieldSection(title: "Destination", placeholder: "City, Country", textField: destinationField)

        // Occasion selector
        let occasionHeader = createSectionHeader("Trip Occasion")
        let occasionSelector = createOccasionSelector()

        // Activities
        let activitiesHeader = createSectionHeader("Activities")
        let activitiesSelector = createActivitiesSelector()
        
        // Trip type selector
        let typeHeader = createSectionHeader("Trip Type")
        let typeSelector = createTripTypeSelector()

        // Notes
        let notesHeader = createSectionHeader("Notes")
        let notes = createNotesSection()

        // Build
        [tripNameField, dateBtn, destinationContainer, occasionHeader, occasionSelector, activitiesHeader, activitiesSelector, typeHeader, typeSelector, notesHeader, notes]
            .forEach { outer.addArrangedSubview($0) }

        formStack = outer
        outer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(outer)
        
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            outer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            outer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        return outer
    }

    private func createSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = UIColor(white: 0.75, alpha: 1.0)
        label.textAlignment = .left
        
        // Add subtle glow effect
        label.layer.shadowColor = UIColor.white.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 0)
        label.layer.shadowOpacity = 0.15
        label.layer.shadowRadius = 2
        
        return label
    }

    private func createTextFieldSection(title: String, placeholder: String, textField: UITextField) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title.uppercased()
        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = UIColor(white: 0.75, alpha: 1.0)

        textField.placeholder = placeholder
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 17, weight: .medium)
        textField.backgroundColor = .clear
        textField.layer.cornerRadius = 14
        textField.layer.borderWidth = 0
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.delegate = self
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.rightViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(white: 0.5, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 17, weight: .regular)
            ]
        )
        
        // Liquid glass background material
        let material = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        material.clipsToBounds = true
        material.layer.cornerRadius = 14
        container.addSubview(material)
        material.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(textField)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 50),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            material.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            material.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            material.topAnchor.constraint(equalTo: textField.topAnchor),
            material.bottomAnchor.constraint(equalTo: textField.bottomAnchor)
        ])

        container.sendSubviewToBack(material)

        return container
    }

    private func createDatePickerSection(title: String, datePicker: UIDatePicker) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .white

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = .systemOrange
        datePicker.minimumDate = Date()

        if datePicker == endDatePicker {
            endDatePicker.minimumDate = startDatePicker.date
        }

        container.addSubview(titleLabel)
        container.addSubview(datePicker)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            datePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            datePicker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createOccasionSelector() -> UIView {
        let container = UIView()
        var rows: [UIStackView] = []
        var currentRow: UIStackView?
        let itemsPerRow = 3

        TripOccasion.allCases.enumerated().forEach { index, occasion in
            if index % itemsPerRow == 0 {
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.spacing = 10
                currentRow?.distribution = .fillEqually
                rows.append(currentRow!)
            }

            let button = createChipButton(
                title: occasion.rawValue,
                isSelected: occasion == selectedOccasion
            )
            button.tag = index
            button.addTarget(self, action: #selector(occasionSelected(_:)), for: .touchUpInside)
            
            // Store reference for later updates
            occasionButtons[occasion.rawValue] = button

            currentRow?.addArrangedSubview(button)
            
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 48)
            ])
        }

        let mainStack = UIStackView(arrangedSubviews: rows)
        mainStack.axis = .vertical
        mainStack.spacing = 10
        container.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }
    
    private func createChipButton(title: String, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        
        // Enhanced glass morphism effect
        button.backgroundColor = isSelected 
            ? UIColor.systemOrange.withAlphaComponent(0.18)
            : UIColor.white.withAlphaComponent(0.08)
        
        // Refined border
        button.layer.cornerRadius = 16
        button.layer.borderWidth = isSelected ? 2.0 : 1.0
        button.layer.borderColor = isSelected 
            ? UIColor.systemOrange.cgColor 
            : UIColor.white.withAlphaComponent(0.12).cgColor
        
        // Enhanced shadow for depth
        button.layer.shadowColor = isSelected ? UIColor.systemOrange.cgColor : UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: isSelected ? 3 : 2)
        button.layer.shadowRadius = isSelected ? 6 : 4
        button.layer.shadowOpacity = isSelected ? 0.3 : 0.1
        
        // Typography
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = isSelected ? .systemOrange : UIColor(white: 0.92, alpha: 1.0)
        config.title = title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: isSelected ? .bold : .medium)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 18)
        
        button.configuration = config
        button.isSelected = isSelected
        
        // Add haptic feedback on press
        button.addAction(UIAction { _ in
            Haptics.tap()
        }, for: .touchDown)
        
        return button
    }

    private func createActivitiesSelector() -> UIView {
        let container = UIView()

        let columns = 2
        var currentRow: UIStackView?

        TripActivity.allCases.forEach { activity in
            if activity == .other { return } // Skip "other" for now
            
            let isSelected = selectedActivities.contains(activity)

            if currentRow == nil || currentRow!.arrangedSubviews.count >= columns {
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.spacing = 10
                currentRow?.distribution = .fillEqually
                container.addSubview(currentRow!)
                currentRow?.translatesAutoresizingMaskIntoConstraints = false
            }

            let button = createChipButton(
                title: activity.rawValue,
                isSelected: isSelected
            )
            button.addTarget(self, action: #selector(activitySelected(_:)), for: .touchUpInside)
            
            // Store reference
            activitiesButtons[activity.rawValue] = button

            currentRow?.addArrangedSubview(button)
            
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 48)
            ])
        }

        // Set up vertical and horizontal constraints for rows
        let rows = container.subviews.compactMap { $0 as? UIStackView }
        for (index, row) in rows.enumerated() {
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
            if index == 0 {
                row.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            } else {
                row.topAnchor.constraint(equalTo: rows[index-1].bottomAnchor, constant: 10).isActive = true
            }
            if index == rows.count - 1 {
                row.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
            }
        }

        return container
    }

    private func createWeatherSelector() -> UIView {
        let container = UIView()

        weatherSegmentedControl.removeAllSegments()
        WeatherCondition.allCases.enumerated().forEach { index, weather in
            weatherSegmentedControl.insertSegment(withTitle: weather.rawValue, at: index, animated: false)
        }
        weatherSegmentedControl.selectedSegmentIndex = 2 // Moderate
        
        // Enhanced styling
        weatherSegmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        weatherSegmentedControl.selectedSegmentTintColor = .systemOrange
        weatherSegmentedControl.layer.cornerRadius = 12
        weatherSegmentedControl.layer.borderWidth = 1
        weatherSegmentedControl.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        
        // Typography
        weatherSegmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor(white: 0.7, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ], for: .normal)
        weatherSegmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .bold)
        ], for: .selected)
        
        weatherSegmentedControl.addTarget(self, action: #selector(weatherSelected), for: .valueChanged)
        
        // Add haptic feedback
        weatherSegmentedControl.addAction(UIAction { _ in
            Haptics.tap()
        }, for: .valueChanged)

        container.addSubview(weatherSegmentedControl)
        weatherSegmentedControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            weatherSegmentedControl.topAnchor.constraint(equalTo: container.topAnchor),
            weatherSegmentedControl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            weatherSegmentedControl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            weatherSegmentedControl.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createTripTypeSelector() -> UIView {
        let container = UIView()

        // Create pull-down menu button (HIG-compliant for 5+ options)
        let button = UIButton(type: .system)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        
        // Create menu actions for each trip type
        var menuActions: [UIAction] = []
        for tripType in TripType.allCases {
            let action = UIAction(
                title: tripType.rawValue,
                state: tripType == selectedTripType ? .on : .off
            ) { [weak self] action in
                Haptics.tap()
                self?.selectedTripType = tripType
                self?.updateTripTypeButton()
            }
            menuActions.append(action)
        }
        
        button.menu = UIMenu(children: menuActions)
        
        // Style the button with enhanced glass effect
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = UIColor(white: 0.92, alpha: 1.0)
        config.background.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        config.background.cornerRadius = 14
        config.background.strokeColor = UIColor.white.withAlphaComponent(0.12)
        config.background.strokeWidth = 1
        config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 18, bottom: 15, trailing: 18)
        
        // Add chevron and title
        config.image = UIImage(systemName: "chevron.up.chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.title = selectedTripType.rawValue
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .medium)
            return outgoing
        }
        
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        
        // Store reference
        tripTypeButton = button
        
        container.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.heightAnchor.constraint(equalToConstant: 52),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }
    
    private func updateTripTypeButton() {
        guard var config = tripTypeButton?.configuration else { return }
        
        // Update button title to show selected type
        config.title = selectedTripType.rawValue
        tripTypeButton?.configuration = config
        
        // Update menu to show checkmark on selected item
        var menuActions: [UIAction] = []
        for tripType in TripType.allCases {
            let action = UIAction(
                title: tripType.rawValue,
                state: tripType == selectedTripType ? .on : .off
            ) { [weak self] action in
                Haptics.tap()
                self?.selectedTripType = tripType
                self?.updateTripTypeButton()
            }
            menuActions.append(action)
        }
        tripTypeButton?.menu = UIMenu(children: menuActions)
    }

    private func createNotesSection() -> UIView {
        let container = UIView()

        notesTextView.text = "Add any additional notes about your trip..."
        notesTextView.textColor = UIColor(white: 0.5, alpha: 1.0)
        notesTextView.font = .systemFont(ofSize: 16, weight: .medium)
        notesTextView.backgroundColor = .clear
        notesTextView.layer.cornerRadius = 14
        notesTextView.layer.borderWidth = 0
        notesTextView.layer.borderColor = UIColor.clear.cgColor
        notesTextView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        notesTextView.delegate = self
        
        // Liquid glass background for notes
        let material = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        material.clipsToBounds = true
        material.layer.cornerRadius = 14
        container.addSubview(material)
        material.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(notesTextView)
        notesTextView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            notesTextView.topAnchor.constraint(equalTo: container.topAnchor),
            notesTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            notesTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            notesTextView.heightAnchor.constraint(equalToConstant: 120),
            notesTextView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            material.leadingAnchor.constraint(equalTo: notesTextView.leadingAnchor),
            material.trailingAnchor.constraint(equalTo: notesTextView.trailingAnchor),
            material.topAnchor.constraint(equalTo: notesTextView.topAnchor),
            material.bottomAnchor.constraint(equalTo: notesTextView.bottomAnchor)
        ])

        container.sendSubviewToBack(material)

        return container
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelTapped() {
        delegate?.tripCreationViewControllerDidCancel(self)
    }

    @objc private func saveTapped() {
        let tripName = tripNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let destination = destinationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var trip = Trip(
            name: tripName,
            destination: destination,
            startDate: startDatePicker.date,
            endDate: endDatePicker.date,
            occasion: selectedOccasion,
            activities: selectedActivities,
            expectedWeather: selectedWeather,
            tripType: selectedTripType,
            notes: notesTextView.text != "Add any additional notes about your trip..." ? notesTextView.text : ""
        )

        // Defaults and validation
        if trip.endDate < trip.startDate { trip.endDate = trip.startDate }

        let errors = trip.validationErrors()
        if errors.isEmpty == false {
            showAlert(title: "Fix the following", message: errors.joined(separator: "\n"))
            return
        }

        // Preserve existing categories if editing, otherwise show loading and generate
        if prefillTrip != nil {
            trip.packingCategories = prefillTrip!.packingCategories
            delegate?.tripCreationViewController(self, didCreateTrip: trip)
        } else {
            // Show packing list generation screen
            showPackingListGeneration(for: trip)
        }
    }
    
    private func showPackingListGeneration(for trip: Trip) {
        var finalTrip = trip
        
        let loadingVC = PackingListGeneratorViewController(trip: trip)
        loadingVC.modalPresentationStyle = .overFullScreen
        loadingVC.modalTransitionStyle = .crossDissolve
        loadingVC.onComplete = { [weak self] categories in
            print("🎯 TripCreation onComplete received \(categories.count) categories")
            print("🎯 Category names: \(categories.map { $0.name })")
            
            // Use AI-generated packing categories
            finalTrip.packingCategories = categories
            
            // Save the trip with categories
            TripManager.shared.saveTrip(finalTrip)
            print("💾 Saved trip with \(finalTrip.packingCategories.count) categories")

            // Also fetch weather for the destination to enhance future packing lists
            WeatherService.fetchSummary(for: finalTrip.destination, start: finalTrip.startDate, end: finalTrip.endDate) { weather in
                // Weather data is now available for future use, but we don't need to wait for it here
                print("✅ Weather fetched for \(finalTrip.destination): \(weather.description)")
            }

            self?.delegate?.tripCreationViewController(self!, didCreateTrip: finalTrip)
        }
        
        present(loadingVC, animated: true)
    }

    @objc private func openDateSelector() {
        Haptics.tap()
        let vc = DateRangePickerViewController(nibName: nil, bundle: nil)
        vc.initialStartDate = startDatePicker.date
        vc.initialEndDate = endDatePicker.date
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        vc.onApply = { [weak self] start, end in
            guard let self = self else { return }
            
            // Update the internal date pickers
            self.startDatePicker.date = start
            self.endDatePicker.date = end
            
            // Update the date button text
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateText = "\(formatter.string(from: start)) → \(formatter.string(from: end))"
            
            // Create new configuration
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = UIColor(white: 0.85, alpha: 1.0)
            config.image = UIImage(systemName: "calendar.badge.checkmark")
            config.imagePadding = 10
            config.imagePlacement = .leading
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
            config.attributedTitle = AttributedString(dateText, attributes: .init([
                .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                .foregroundColor: UIColor(white: 0.85, alpha: 1.0)
            ]))
            
            // Update button configuration
            self.dateButton?.configuration = config
        }
        present(vc, animated: true)
    }

    @objc private func occasionSelected(_ sender: UIButton) {
        guard let attributedTitle = sender.configuration?.attributedTitle else { return }
        let title = String(attributedTitle.characters)
        guard let occasion = TripOccasion(rawValue: title) else { return }
        
        selectedOccasion = occasion
        
        // Update all occasion buttons
        occasionButtons.forEach { key, button in
            let isSelected = key == occasion.rawValue
            updateChipButtonState(button, isSelected: isSelected)
        }
    }

    @objc private func activitySelected(_ sender: UIButton) {
        guard let attributedTitle = sender.configuration?.attributedTitle else { return }
        let title = String(attributedTitle.characters)
        guard let activity = TripActivity(rawValue: title) else { return }
        
        let isCurrentlySelected = selectedActivities.contains(activity)
        
        if isCurrentlySelected {
            selectedActivities.removeAll(where: { $0 == activity })
            updateChipButtonState(sender, isSelected: false)
        } else {
                    selectedActivities.append(activity)
            updateChipButtonState(sender, isSelected: true)
        }
    }
    
    private func updateChipButtonState(_ button: UIButton, isSelected: Bool) {
        // Animate the state change with spring animation
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut], animations: {
            button.backgroundColor = isSelected 
                ? UIColor.systemOrange.withAlphaComponent(0.18)
                : UIColor.white.withAlphaComponent(0.08)
            
            button.layer.borderWidth = isSelected ? 2.0 : 1.0
            button.layer.borderColor = isSelected 
                ? UIColor.systemOrange.cgColor 
                : UIColor.white.withAlphaComponent(0.12).cgColor
            
            button.layer.shadowColor = isSelected ? UIColor.systemOrange.cgColor : UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: isSelected ? 3 : 2)
            button.layer.shadowRadius = isSelected ? 6 : 4
            button.layer.shadowOpacity = isSelected ? 0.3 : 0.1
            
            // Update configuration
            var config = button.configuration
            config?.baseForegroundColor = isSelected ? .systemOrange : UIColor(white: 0.92, alpha: 1.0)
            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 15, weight: isSelected ? .bold : .medium)
                return outgoing
            }
            button.configuration = config
            
            button.isSelected = isSelected
        })
    }

    @objc private func weatherSelected() {
        let index = weatherSegmentedControl.selectedSegmentIndex
        selectedWeather = WeatherCondition.allCases[index]
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension TripCreationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITextViewDelegate

extension TripCreationViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Add any additional notes about your trip..." {
            textView.text = ""
            textView.textColor = .white
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Add any additional notes about your trip..."
            textView.textColor = UIColor(white: 0.5, alpha: 1.0)
        }
    }
}
