import UIKit

// MARK: - HomeContentDelegate

/// Delegate protocol for home content view controller events
protocol HomeContentDelegate: AnyObject {
    func homeContentViewControllerDidRequestCreateTrip(_ controller: HomeContentViewController)
    func homeContentViewController(_ controller: HomeContentViewController, didSelectTrip trip: Trip)
    func homeContentViewControllerDidRequestOpenSettings(_ controller: HomeContentViewController)
}

// MARK: - HomeContentViewController

/// Main home content view controller displaying trips and create trip functionality
final class HomeContentViewController: UIViewController {

    // MARK: - Properties
    
    // UI Components
    private let headerView = UIView()
    private let myTripsButton = UIButton(type: .system)
    private let settingsGlassContainer = UIView()
    private let settingsButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // Data
    private var trips: [Trip] = []
    private var tripsHidden = false
    
    // Delegate
    weak var delegate: HomeContentDelegate?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTrips()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTrips() // Refresh trips when view appears
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .clear

        // Setup sticky header
        setupStickyHeader()

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(TripRowCell.self, forCellReuseIdentifier: "TripRowCell")
        tableView.register(CreateTripCell.self, forCellReuseIdentifier: "CreateTripCell")
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupStickyHeader() {
        headerView.backgroundColor = .clear
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // My Trips button
        let chevron = UIImage(systemName: "chevron.down")
        var titleConfig = UIButton.Configuration.plain()
        titleConfig.image = chevron
        titleConfig.imagePlacement = .trailing
        titleConfig.imagePadding = 6
        titleConfig.baseForegroundColor = .white
        titleConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        titleConfig.attributedTitle = AttributedString("My Trips",
            attributes: .init([.font: UIFont.boldSystemFont(ofSize: 32), .foregroundColor: UIColor.white]))
        myTripsButton.configuration = titleConfig
        myTripsButton.contentHorizontalAlignment = .leading
        myTripsButton.showsMenuAsPrimaryAction = true
        myTripsButton.menu = UIMenu(title: "", children: [
            UIAction(title: "My Trips", state: .on, handler: { _ in }),
            UIAction(title: "Friends' Trips", handler: { _ in })
        ])
        myTripsButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(myTripsButton)
        
        // Settings button
        settingsGlassContainer.backgroundColor = .clear
        settingsGlassContainer.layer.cornerRadius = 22
        settingsGlassContainer.clipsToBounds = false
        settingsGlassContainer.layer.shadowColor = UIColor.black.cgColor
        settingsGlassContainer.layer.shadowOpacity = 0.3
        settingsGlassContainer.layer.shadowRadius = 8
        settingsGlassContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        settingsGlassContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(settingsGlassContainer)
        
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = .white
        settingsButton.backgroundColor = .systemOrange
        settingsButton.layer.cornerRadius = 22
        settingsButton.clipsToBounds = true
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsGlassContainer.addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 64),
            
            myTripsButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            myTripsButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            myTripsButton.trailingAnchor.constraint(lessThanOrEqualTo: settingsGlassContainer.leadingAnchor, constant: -12),
            
            settingsGlassContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            settingsGlassContainer.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            settingsGlassContainer.widthAnchor.constraint(equalToConstant: 44),
            settingsGlassContainer.heightAnchor.constraint(equalToConstant: 44),
            
            settingsButton.centerXAnchor.constraint(equalTo: settingsGlassContainer.centerXAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: settingsGlassContainer.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Actions

    @objc private func settingsTapped() {
        delegate?.homeContentViewControllerDidRequestOpenSettings(self)
    }

    // MARK: - Data Management

    private func loadTrips() {
        trips = TripManager.shared.loadTrips()
        // Sort trips by start date (upcoming first)
        trips.sort { $0.startDate < $1.startDate }
        tableView.reloadData()
    }

    func refreshTrips() {
        loadTrips()
    }

    func addTrip(_ trip: Trip) {
        TripManager.shared.saveTrip(trip)
        loadTrips()
        // Scroll to top to reveal new trip
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }

    func setTripsHidden(_ hidden: Bool) {
        guard tripsHidden != hidden else { return }
        tripsHidden = hidden

        // Hide entire table view when collapsed
        UIView.animate(withDuration: 0.2) {
            self.tableView.alpha = hidden ? 0 : 1
        }

        // Reload all rows for proper height calculation
        if !hidden {
            var indexPaths: [IndexPath] = []
            for i in 0..<(trips.count + 1) {
                indexPaths.append(IndexPath(row: i, section: 0))
            }

            if !indexPaths.isEmpty {
                tableView.beginUpdates()
                tableView.reloadRows(at: indexPaths, with: .fade)
                tableView.endUpdates()
            }
        }
    }
}

// MARK: - TableView DataSource & Delegate

extension HomeContentViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count + 1 // Trips + create button (no header row)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == trips.count {
            // Last row is always create button
            return tableView.dequeueReusableCell(withIdentifier: "CreateTripCell", for: indexPath) as! CreateTripCell
        } else {
            // Trip rows
            let cell = tableView.dequeueReusableCell(withIdentifier: "TripRowCell", for: indexPath) as! TripRowCell
            cell.configure(with: trips[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == trips.count {
            return tripsHidden ? 0 : 240 // Create card - slightly taller
        } else {
            return tripsHidden ? 0 : 120 // Trip rows height - square aspect ratio
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == trips.count {
            // Create trip button
            delegate?.homeContentViewControllerDidRequestCreateTrip(self)
        } else {
            // Trip row
            delegate?.homeContentViewController(self, didSelectTrip: trips[indexPath.row])
        }
    }
}


// MARK: - CreateTripCell

final class CreateTripCell: UITableViewCell {
    private let container = UIView()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        setupContainer()
        setupIcon()
        setupLabels()
        setupButton()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupContainer() {
        container.backgroundColor = DesignSystem.Color.surface
        container.layer.cornerRadius = DesignSystem.Radius.lg
        container.layer.borderWidth = 1
        container.layer.borderColor = DesignSystem.Color.surfaceBorder.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowOpacity = 0.1
        container.layer.shadowRadius = 8
    }

    private func setupIcon() {
        iconContainer.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        iconContainer.layer.cornerRadius = DesignSystem.Radius.md
        iconContainer.layer.borderWidth = 1
        iconContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconContainer)

        iconView.image = UIImage(systemName: "airplane")
        iconView.tintColor = DesignSystem.Color.primary
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)
    }

    private func setupLabels() {
        titleLabel.text = "Organize a new trip"
        titleLabel.font = DesignSystem.Font.title(22)
        titleLabel.textColor = DesignSystem.Color.textPrimary
        titleLabel.numberOfLines = 1

        subtitleLabel.text = "Create your next trip and plan activities"
        subtitleLabel.font = DesignSystem.Font.body(15)
        subtitleLabel.textColor = DesignSystem.Color.textSecondary
        subtitleLabel.numberOfLines = 2

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
    }

    private func setupButton() {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = DesignSystem.Color.primary
        config.baseForegroundColor = DesignSystem.Color.onPrimary
        config.title = "Create a Trip"
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = DesignSystem.Font.body(16)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 32,
            bottom: 12,
            trailing: 32
        )
        actionButton.configuration = config
        actionButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(actionButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSystem.Spacing.md),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.md),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignSystem.Spacing.md),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DesignSystem.Spacing.md),

            // Icon container - aligned at top
            iconContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            iconContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            iconContainer.widthAnchor.constraint(equalToConstant: 56),
            iconContainer.heightAnchor.constraint(equalToConstant: 56),

            // Icon centered in container
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            // Title - vertically centered with icon
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            titleLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor, constant: -10),

            // Subtitle - right below title with tight spacing
            subtitleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            // Button - centered horizontally at bottom
            actionButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Actions

    @objc private func createTapped() {
        Haptics.tap()
        if let tableView = superview as? UITableView {
            let indexPath = tableView.indexPath(for: self) ?? IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        } else if let tableView = sequence(first: superview, next: { $0?.superview }).first(where: { $0 is UITableView }) as? UITableView {
            let indexPath = tableView.indexPath(for: self) ?? IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }
}