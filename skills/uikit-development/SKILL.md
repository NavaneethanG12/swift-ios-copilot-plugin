---
name: uikit-development
description: >
  Build iOS UIs with UIKit — UIViewController lifecycle, programmatic
  Auto Layout, UITableView, UICollectionView (compositional + diffable),
  UINavigationController, and common UIKit patterns.
argument-hint: "[view controller, UIKit component, or layout issue]"
user-invocable: true
---

# UIKit Development

## UIViewController Lifecycle

```
init → loadView → viewDidLoad → viewWillAppear → viewIsAppearing → viewDidAppear
                                 viewWillDisappear → viewDidDisappear → deinit
```

| Method | Do here | Don't do here |
|---|---|---|
| `viewDidLoad` | One-time setup: add subviews, constraints, configure data sources | Start animations, read frame/bounds (not final yet) |
| `viewIsAppearing` | Update content with final geometry, trait collections | Heavy work (called once per appearance) |
| `viewWillAppear` | Refresh data, start observers | Read final layout (geometry not final) |
| `viewDidAppear` | Start animations, analytics tracking, timers | Modify constraints (causes visual jump) |
| `viewWillDisappear` | Stop timers, save state | — |
| `viewDidDisappear` | Release heavy resources, cancel requests | — |
| `deinit` | Invalidate timers, remove observers, cancel subscriptions | — |

### Template
```swift
import UIKit

final class ItemListViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var dataSource: UITableViewDiffableDataSource<Section, Item>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Items"
        view.backgroundColor = .systemBackground
        setupTableView()
        configureDataSource()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        loadData()
    }
}
```

---

## Programmatic Auto Layout

### The Pattern
```swift
// 1. Create view
let label = UILabel()
label.translatesAutoresizingMaskIntoConstraints = false  // ALWAYS set this
view.addSubview(label)

// 2. Activate constraints
NSLayoutConstraint.activate([
    label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
    label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
    label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
])
```

### Common Patterns
```swift
// Pin to all edges (with insets)
NSLayoutConstraint.activate([
    child.topAnchor.constraint(equalTo: parent.topAnchor, constant: 16),
    child.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 16),
    child.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -16),
    child.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -16)
])

// Center in parent
NSLayoutConstraint.activate([
    child.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
    child.centerYAnchor.constraint(equalTo: parent.centerYAnchor)
])

// Fixed size
NSLayoutConstraint.activate([
    button.widthAnchor.constraint(equalToConstant: 200),
    button.heightAnchor.constraint(equalToConstant: 44)  // minimum 44pt tap target
])

// Aspect ratio
imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0/16.0)

// Priority
let bottom = label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
bottom.priority = .defaultLow  // 250
bottom.isActive = true
```

### UIStackView
```swift
let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, button])
stack.axis = .vertical
stack.spacing = 8
stack.alignment = .leading     // .fill, .leading, .center, .trailing
stack.distribution = .fill     // .fillEqually, .fillProportionally, .equalSpacing
stack.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(stack)
```

### Common Mistakes

| Mistake | Result | Fix |
|---|---|---|
| Forgot `translatesAutoresizingMaskIntoConstraints = false` | Constraints conflict with autoresizing | Always set to `false` for manual constraints |
| Missing constraint (ambiguous layout) | View at origin or wrong size | Ensure X + Y + width + height are all defined |
| Conflicting constraints | Runtime warning, unpredictable layout | Check priorities, remove duplicates |
| Hardcoded frame in `viewDidLoad` | Wrong on different devices | Use Auto Layout, never `frame =` |
| Not using `safeAreaLayoutGuide` | Content behind notch/home indicator | Pin to `view.safeAreaLayoutGuide` not `view` |

---

## UITableView (Diffable Data Source)

```swift
enum Section: Hashable { case main }

private func setupTableView() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.topAnchor),
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
}

private func configureDataSource() {
    dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) {
        tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.image = UIImage(systemName: item.icon)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

private func applySnapshot(items: [Item], animating: Bool = true) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    snapshot.appendSections([.main])
    snapshot.appendItems(items)
    dataSource.apply(snapshot, animatingDifferences: animating)
}
```

---

## UICollectionView (Compositional Layout + Diffable)

### List Layout (modern replacement for UITableView)
```swift
var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
config.trailingSwipeActionsConfigurationProvider = { indexPath in
    let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
        // delete item
        completion(true)
    }
    return UISwipeActionsConfiguration(actions: [delete])
}
let layout = UICollectionViewCompositionalLayout.list(using: config)
let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
```

### Grid Layout
```swift
let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                          heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                           heightDimension: .absolute(200))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8)
    return section
}
```

### Cell Registration (iOS 14+)
```swift
let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
    cell, indexPath, item in
    var content = cell.defaultContentConfiguration()
    content.text = item.title
    content.image = UIImage(systemName: item.icon)
    cell.contentConfiguration = content
}

dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
    collectionView, indexPath, item in
    collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
}
```

---

## Navigation

```swift
// Push (inside UINavigationController)
let detail = DetailViewController(item: item)
navigationController?.pushViewController(detail, animated: true)

// Present modally
let vc = SettingsViewController()
vc.modalPresentationStyle = .pageSheet  // .fullScreen, .formSheet, .automatic
if let sheet = vc.sheetPresentationController {
    sheet.detents = [.medium(), .large()]
    sheet.prefersGrabberVisible = true
}
present(vc, animated: true)

// Dismiss
dismiss(animated: true)
navigationController?.popViewController(animated: true)
navigationController?.popToRootViewController(animated: true)
```

---

## Common UI Components

```swift
// Button (iOS 15+ configuration API)
var config = UIButton.Configuration.filled()
config.title = "Save"
config.image = UIImage(systemName: "checkmark")
config.imagePadding = 8
let button = UIButton(configuration: config)
button.addAction(UIAction { _ in save() }, for: .touchUpInside)

// TextField
let textField = UITextField()
textField.borderStyle = .roundedRect
textField.placeholder = "Enter name"
textField.font = .preferredFont(forTextStyle: .body)
textField.adjustsFontForContentSizeCategory = true  // Dynamic Type

// ImageView
let imageView = UIImageView()
imageView.contentMode = .scaleAspectFill
imageView.clipsToBounds = true
imageView.layer.cornerRadius = 8

// Activity Indicator
let spinner = UIActivityIndicatorView(style: .medium)
spinner.startAnimating()
```

---

## Dynamic Type in UIKit

```swift
label.font = .preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true
label.numberOfLines = 0  // allow wrapping

// Custom font with Dynamic Type scaling
label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: "CustomFont", size: 17)!)
label.adjustsFontForContentSizeCategory = true
```

---

## Passing Data Between ViewControllers

```swift
// Forward: set properties before push/present
let detail = DetailViewController()
detail.item = selectedItem
navigationController?.pushViewController(detail, animated: true)

// Backward: delegate pattern
protocol DetailDelegate: AnyObject {
    func detailDidUpdate(_ item: Item)
}

class DetailViewController: UIViewController {
    weak var delegate: DetailDelegate?  // MUST be weak
    func save() { delegate?.detailDidUpdate(item) }
}

// Or: closure (watch for retain cycles)
detail.onSave = { [weak self] updatedItem in
    self?.handleUpdate(updatedItem)
}
```

---

## Do / Don't

**Do**: Use `UICollectionView` with compositional layout over `UITableView` for new code.
Use diffable data sources. Use `UIButton.Configuration`. Support Dynamic Type.
Pin to `safeAreaLayoutGuide`. Use `[weak self]` in closures. Use `UIAction` over target-action.

**Don't**: Use `cellForRow(at:)` data source pattern (use diffable). Use `frame =` for layout.
Hardcode font sizes (use `preferredFont(forTextStyle:)`). Make delegates strong. Put
heavy work in `viewDidLoad`. Forget `translatesAutoresizingMaskIntoConstraints = false`.
