import UIKit
import SwiftUI

// MARK: - SettingsViewController

/// Main settings view controller that displays app preferences and configuration options
/// Features a modern glass-morphism design with organized sections for different setting categories
final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - UI Components
    
    // Main container and layout
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let containerView = UIView()
    private let headerView = UIView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private var closeContainer: UIView?
    
    // Settings controls
    private let flagsSwitch = UISwitch()
    private let hapticsSwitch = UISwitch()
    private let notificationsSwitch = UISwitch()
    private let temperatureSegmentedControl = UISegmentedControl(items: ["°C", "°F"])
    private let distanceSegmentedControl = UISegmentedControl(items: ["km", "mi"])

    // MARK: - Settings Data
    
    /// Configuration for settings sections and their actions
    private lazy var sections: [[(title: String, icon: String, action: () -> Void)]] = [
        // Features section
        [("Custom Categories", "slider.horizontal.3", { [weak self] in self?.showCustomCategories() }),
         ("Pending Invites", "bell", { [weak self] in self?.showPendingInvites() }),
         ("Forwarded Emails", "envelope", { [weak self] in self?.showForwardedEmails() })],
        // About section
        [("Add Reservations via Email", "arrow.right.square", { [weak self] in self?.showReservationsHelp() }),
         ("Export Data", "square.and.arrow.up", { [weak self] in self?.showExportData() }),
         ("Privacy Policy", "hand.raised", { [weak self] in self?.showPrivacyPolicy() }),
         ("About", "info.circle", { [weak self] in self?.showAbout() })]
    ]
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupSettings()
    }
    
    private func setupUI() {
        // Background with black
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Container with Liquid Glass effect
        containerView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 20
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        
        // Add blur effect for Liquid Glass appearance
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(blurEffectView)
        
        // Header setup
        setupHeader()
        
        // Table view setup
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.allowsSelection = true
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        // Add views
        view.addSubview(containerView)
        containerView.addSubview(blurEffectView)
        containerView.addSubview(headerView)
        containerView.addSubview(tableView)
        
        // Setup blur constraints
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupHeader() {
        // Title
        titleLabel.text = "Settings"
        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        
        // Close button matching trip creation exactly
        if #available(iOS 18.0, *) {
            let hosting = UIHostingController(rootView: GlassCloseButton(action: { [weak self] in
                self?.closeTapped()
            }))
            addChild(hosting)
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            hosting.view.backgroundColor = UIColor.clear
            hosting.didMove(toParent: self)
            closeContainer = hosting.view
        } else {
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
            blur.layer.cornerRadius = 22
            blur.clipsToBounds = true
            blur.translatesAutoresizingMaskIntoConstraints = false

            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            closeButton.tintColor = .white
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            closeButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
            closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            blur.contentView.addSubview(closeButton)

            NSLayoutConstraint.activate([
                closeButton.centerXAnchor.constraint(equalTo: blur.centerXAnchor),
                closeButton.centerYAnchor.constraint(equalTo: blur.centerYAnchor)
            ])
            closeContainer = blur
        }
        
        headerView.addSubview(titleLabel)
        if let closeContainer = closeContainer {
            headerView.addSubview(closeContainer)
            closeContainer.translatesAutoresizingMaskIntoConstraints = false
        }
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container constraints
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            
            // Header constraints
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 50),
            
            // Title constraints
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        // Close button constraints
        if let closeContainer = closeContainer {
            closeContainer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                closeContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                closeContainer.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                closeContainer.widthAnchor.constraint(equalToConstant: 44),
                closeContainer.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }
    
    private func setupSettings() {
        // Configure switches
        flagsSwitch.isOn = SettingsManager.showCountryFlags
        flagsSwitch.onTintColor = .systemOrange
        flagsSwitch.addTarget(self, action: #selector(flagsChanged), for: .valueChanged)
        
        hapticsSwitch.isOn = SettingsManager.hapticsEnabled
        hapticsSwitch.onTintColor = .systemOrange
        hapticsSwitch.addTarget(self, action: #selector(hapticsChanged), for: .valueChanged)
        
        notificationsSwitch.isOn = SettingsManager.notificationsEnabled
        notificationsSwitch.onTintColor = .systemOrange
        notificationsSwitch.addTarget(self, action: #selector(notificationsChanged), for: .valueChanged)
        
        // Configure segmented controls
        temperatureSegmentedControl.selectedSegmentIndex = SettingsManager.temperatureUnit == "c" ? 0 : 1
        temperatureSegmentedControl.selectedSegmentTintColor = .systemOrange
        temperatureSegmentedControl.addTarget(self, action: #selector(temperatureChanged), for: .valueChanged)
        
        distanceSegmentedControl.selectedSegmentIndex = SettingsManager.distanceUnit == "km" ? 0 : 1
        distanceSegmentedControl.selectedSegmentTintColor = .systemOrange
        distanceSegmentedControl.addTarget(self, action: #selector(distanceChanged), for: .valueChanged)
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Settings Actions
    
    @objc private func flagsChanged() {
        SettingsManager.showCountryFlags = flagsSwitch.isOn
    }
    
    @objc private func hapticsChanged() {
        SettingsManager.hapticsEnabled = hapticsSwitch.isOn
    }
    
    @objc private func notificationsChanged() {
        SettingsManager.notificationsEnabled = notificationsSwitch.isOn
    }
    
    @objc private func temperatureChanged() {
        SettingsManager.temperatureUnit = temperatureSegmentedControl.selectedSegmentIndex == 0 ? "c" : "f"
    }
    
    @objc private func distanceChanged() {
        SettingsManager.distanceUnit = distanceSegmentedControl.selectedSegmentIndex == 0 ? "km" : "mi"
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int { 
        return 4 // General, Units, Features, About
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 
        switch section {
        case 0: return 2 // Country Flags, Haptics
        case 1: return 2 // Temperature Unit, Distance Unit
        case 2: return sections[0].count // Custom Categories, Pending Invites, etc.
        case 3: return sections[1].count // Add Reservations, Export Data, etc.
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "General"
        case 1: return "Units"
        case 2: return "Features"
        case 3: return "About"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsTableViewCell
        
        switch indexPath.section {
        case 0: // General settings
            if indexPath.row == 0 {
                cell.configure(title: "Show Country Flags", icon: "flag.fill", control: flagsSwitch)
            } else {
                cell.configure(title: "Haptic Feedback", icon: "iphone.radiowaves.left.and.right", control: hapticsSwitch)
            }
        case 1: // Unit settings
            if indexPath.row == 0 {
                cell.configure(title: "Temperature Unit", icon: "thermometer", control: temperatureSegmentedControl)
            } else {
                cell.configure(title: "Distance Unit", icon: "ruler", control: distanceSegmentedControl)
            }
        case 2: // Features
            let item = sections[0][indexPath.row]
            cell.configure(title: item.title, icon: item.icon, action: item.action)
        case 3: // About
            let item = sections[1][indexPath.row]
            cell.configure(title: item.title, icon: item.icon, action: item.action)
        default:
            break
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Only handle taps for action items (sections 2 and 3)
        if indexPath.section >= 2 {
            let item = sections[indexPath.section - 2][indexPath.row]
            item.action()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: - Settings Action Handlers

    private func showCustomCategories() {
        let alert = UIAlertController(title: "Custom Categories", message: "Create your own packing categories to organize items your way.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showPendingInvites() {
        let alert = UIAlertController(title: "Pending Invites", message: "No pending invites at this time.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showForwardedEmails() {
        let alert = UIAlertController(title: "Forwarded Emails", message: "Manage emails forwarded to your trip organizer.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showReservationsHelp() {
        let alert = UIAlertController(title: "Reservations via Email", message: "Forward confirmation emails to add reservations automatically to your trips.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showExportData() {
        let alert = UIAlertController(title: "Export Data", message: "Export your trips and packing lists to share or backup your data.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Export", style: .default) { _ in
            // TODO: Implement data export functionality
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showPrivacyPolicy() {
        let alert = UIAlertController(title: "Privacy Policy", message: "Your data is stored locally on your device. We don't collect or share your personal information.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showNotifications() {
        let alert = UIAlertController(title: "Notifications", message: "Manage trip reminders and packing alerts.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAbout() {
        let alert = UIAlertController(title: "About PackPal", message: "Version 1.0\n\nYour smart travel companion for organizing trips and packing efficiently.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SettingsTableViewCell

class SettingsTableViewCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let controlContainer = UIView()
    
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
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemOrange
        
        // Title
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label
        
        // Control container
        controlContainer.backgroundColor = .clear
        
        // Add subviews
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(controlContainer)
        
        // Setup constraints
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        controlContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Icon constraints
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Title constraints
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Control container constraints
            controlContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            controlContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            controlContainer.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
    }
    
    func configure(title: String, icon: String, control: UIView? = nil, action: (() -> Void)? = nil) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: icon)
        
        // Remove existing controls
        controlContainer.subviews.forEach { $0.removeFromSuperview() }
        
        if let control = control {
            controlContainer.addSubview(control)
            control.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                control.topAnchor.constraint(equalTo: controlContainer.topAnchor),
                control.leadingAnchor.constraint(equalTo: controlContainer.leadingAnchor),
                control.trailingAnchor.constraint(equalTo: controlContainer.trailingAnchor),
                control.bottomAnchor.constraint(equalTo: controlContainer.bottomAnchor)
            ])
        } else if let action = action {
            // Add disclosure indicator for action items
            let disclosureImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
            disclosureImageView.tintColor = .systemGray3
            controlContainer.addSubview(disclosureImageView)
            disclosureImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                disclosureImageView.centerYAnchor.constraint(equalTo: controlContainer.centerYAnchor),
                disclosureImageView.trailingAnchor.constraint(equalTo: controlContainer.trailingAnchor),
                disclosureImageView.widthAnchor.constraint(equalToConstant: 12),
                disclosureImageView.heightAnchor.constraint(equalToConstant: 12)
            ])
        }
    }
}


