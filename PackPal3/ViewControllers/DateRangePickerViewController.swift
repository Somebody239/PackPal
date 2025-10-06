import UIKit

/// Liquid Glass popup calendar for selecting date ranges
final class DateRangePickerViewController: UIViewController {
    var onApply: ((Date, Date) -> Void)?
    var initialStartDate: Date = Date()
    var initialEndDate: Date = Date()

    // UI components
    private let containerView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    // Calendar view
    private let calendarView = UICalendarView()
    private var selection: UICalendarSelectionSingleDate!

    // Range display
    private let rangeDisplayCard = UIView()
    private let startDateLabel = UILabel()
    private let endDateLabel = UILabel()
    private let rangeLabel = UILabel()

    // Action buttons
    private let buttonStack = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private let applyButton = UIButton(type: .system)

    // State
    private var selectedStartDate: Date?
    private var selectedEndDate: Date?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupModalPresentation()
        setupUI()
        setupConstraints()
        setupCalendar()
        updateDateDisplay()
    }

    // Provide a constraints setup method (content is configured inside setupUI)
    private func setupConstraints() {}

    private func setupModalPresentation() {
        // Configure as sheet presentation for Liquid Glass effect
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        // Add blur background for Liquid Glass effect
        view.backgroundColor = .clear

        // Semi-transparent overlay
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.alpha = 0

        view.insertSubview(overlayView, at: 0)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Fade in overlay
        UIView.animate(withDuration: 0.3) {
            overlayView.alpha = 1
        }
    }

    private func setupUI() {
        // Main container with Liquid Glass styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1.0)
        containerView.layer.cornerRadius = 24
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true

        // Enhanced glass effect
        let blurEffect = UIBlurEffect(style: .systemThickMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        containerView.insertSubview(blurView, at: 0)

        // Subtle tint overlay
        let tintView = UIView()
        tintView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.02)
        tintView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(tintView)

        // Header
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .clear

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Select Trip Dates"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor(white: 0.7, alpha: 1.0)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // Calendar
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.backgroundColor = .clear
        calendarView.tintColor = .systemOrange

        // Use modern single date selection for now, we'll handle range logic
        selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection

        // Range display card
        rangeDisplayCard.translatesAutoresizingMaskIntoConstraints = false
        rangeDisplayCard.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        rangeDisplayCard.layer.cornerRadius = 12

        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        startDateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        startDateLabel.textColor = .white

        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        endDateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        endDateLabel.textColor = .white

        rangeLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        rangeLabel.textColor = UIColor(white: 0.7, alpha: 1.0)
        rangeLabel.textAlignment = .center

        // Buttons
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.baseForegroundColor = UIColor(white: 0.7, alpha: 1.0)
        cancelConfig.title = "Cancel"
        cancelConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 16, weight: .medium)
            return outgoing
        }
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        var applyConfig = UIButton.Configuration.filled()
        applyConfig.baseBackgroundColor = .systemOrange
        applyConfig.baseForegroundColor = .white
        applyConfig.title = "Apply"
        applyConfig.cornerStyle = .capsule
        applyConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 16, weight: .semibold)
            return outgoing
        }
        applyConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        applyButton.configuration = applyConfig
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)

        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually

        // Build hierarchy
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)

        let rangeStack = UIStackView(arrangedSubviews: [startDateLabel, rangeLabel, endDateLabel])
        rangeStack.axis = .horizontal
        rangeStack.spacing = 8
        rangeStack.alignment = .center
        rangeStack.translatesAutoresizingMaskIntoConstraints = false

        rangeDisplayCard.addSubview(rangeStack)
        containerView.addSubview(headerView)
        containerView.addSubview(calendarView)
        containerView.addSubview(rangeDisplayCard)
        containerView.addSubview(buttonStack)

        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(applyButton)

        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            // Blur view
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Tint overlay
            tintView.topAnchor.constraint(equalTo: blurView.topAnchor),
            tintView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),

            // Container
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Header
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            // Calendar
            calendarView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            calendarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            calendarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            calendarView.heightAnchor.constraint(equalToConstant: 320),

            // Range display
            rangeDisplayCard.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 20),
            rangeDisplayCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            rangeDisplayCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            rangeDisplayCard.heightAnchor.constraint(equalToConstant: 60),

            rangeStack.topAnchor.constraint(equalTo: rangeDisplayCard.topAnchor, constant: 12),
            rangeStack.leadingAnchor.constraint(equalTo: rangeDisplayCard.leadingAnchor, constant: 16),
            rangeStack.trailingAnchor.constraint(equalTo: rangeDisplayCard.trailingAnchor, constant: -16),
            rangeStack.bottomAnchor.constraint(equalTo: rangeDisplayCard.bottomAnchor, constant: -12),

            // Buttons
            buttonStack.topAnchor.constraint(equalTo: rangeDisplayCard.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func applyTapped() {
        // Return selected range; if only one selected, treat as single day
        if let start = selectedStartDate, let end = selectedEndDate {
            onApply?(start, end < start ? start : end)
            dismiss(animated: true)
            return
        }
        if let startOnly = selectedStartDate {
            onApply?(startOnly, startOnly)
            dismiss(animated: true)
            return
        }
        let today = Date()
        onApply?(today, today)
        dismiss(animated: true)
    }
    
    private func setupCalendar() {
        // Configure calendar for current locale
        var calendar = Calendar.current
        calendar.locale = Locale.current

        // Set initial visible month to initialStartDate's month
        let visibleMonth = Calendar.current.dateComponents([.year, .month], from: initialStartDate)
        calendarView.visibleDateComponents = visibleMonth

        // Set initial selection to start date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: initialStartDate)
        selection.setSelected(dateComponents, animated: false)

        // Set available date range (min = today)
        let todayComps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        if let minDate = Calendar.current.date(from: todayComps) {
            calendarView.availableDateRange = DateInterval(start: minDate, end: .distantFuture)
        }
    }

    private func updateDateDisplay() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if let startDate = selectedStartDate {
            startDateLabel.text = formatter.string(from: startDate)
        } else {
            startDateLabel.text = "Start"
        }

        if let endDate = selectedEndDate {
            endDateLabel.text = formatter.string(from: endDate)
        } else {
            endDateLabel.text = "End"
        }

        if selectedStartDate != nil && selectedEndDate != nil {
            let duration = Calendar.current.dateComponents([.day], from: selectedStartDate!, to: selectedEndDate!)
            let days = max(1, duration.day ?? 0)
            rangeLabel.text = "\(days) day\(days == 1 ? "" : "s")"
        } else {
            rangeLabel.text = "→"
        }
    }
    
    
}

// MARK: - UICalendarSelectionSingleDateDelegate

extension DateRangePickerViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }

        Haptics.tap()

        // Handle range selection logic
        if selectedStartDate == nil {
            // First selection - set as start date
            selectedStartDate = date
        } else if selectedEndDate == nil {
            // Second selection - determine if it's start or end based on order
            if date < selectedStartDate! {
                selectedEndDate = selectedStartDate
                selectedStartDate = date
            } else {
                selectedEndDate = date
            }
        } else {
            // Both dates selected, start over with new selection as start
            selectedStartDate = date
            selectedEndDate = nil
        }

        updateDateDisplay()
    }

    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        // Only allow future dates
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return false }

        return date >= Date()
    }
}

