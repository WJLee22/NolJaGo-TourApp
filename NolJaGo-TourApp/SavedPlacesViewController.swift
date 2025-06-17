//
//  SavedPlacesViewController.swift
//  NolJaGo-TourApp
//
//  Created by wjlee on 5/31/25.
//

import UIKit
import MapKit
import SafariServices

class SavedPlacesViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var favoriteTableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateImageView: UIImageView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    // MARK: - Properties
    var favoritePlaces: [FavoritePlace] = []
    private var selectedPlace: FavoritePlace?
    private var detailCardView: UIView?
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        setupEmptyState()
        setupRefreshControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavoritePlaces()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        // 네비게이션 바 스타일 설정
        title = "찜한 장소"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UITheme.primaryTextDark,
            .font: UIFont.systemFont(ofSize: 30, weight: .bold)
        ]
        
        // 편집 버튼 스타일 설정
        let editButton = UIBarButtonItem(title: "편집", style: .plain, target: self, action: #selector(editingTableViewRow(_:)))
        editButton.tintColor = UITheme.primaryOrange
        navigationItem.rightBarButtonItem = editButton
    }
    
    private func setupTableView() {
        // 테이블뷰 등록 및 설정
        favoriteTableView.register(FavoritePlaceCell.self, forCellReuseIdentifier: "FavoritePlaceCell")
        favoriteTableView.dataSource = self
        favoriteTableView.delegate = self
        
        // 테이블뷰 스타일 설정
        favoriteTableView.separatorStyle = .none
        favoriteTableView.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        favoriteTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        favoriteTableView.showsVerticalScrollIndicator = false
        favoriteTableView.rowHeight = UITableView.automaticDimension
        favoriteTableView.estimatedRowHeight = 150
    }
    
    private func setupEmptyState() {
        // 빈 상태 뷰 설정
        emptyStateView.isHidden = true
        emptyStateView.backgroundColor = .clear
        
        // 이미지 설정
        if let heartImage = UIImage(systemName: "heart.slash") {
            emptyStateImageView.image = heartImage
            emptyStateImageView.tintColor = UITheme.primaryOrange.withAlphaComponent(0.7)
            emptyStateImageView.contentMode = .scaleAspectFit
        }
        
        // 텍스트 설정
        emptyStateLabel.text = "아직 찜한 장소가 없어요\n지도 화면에서 마음에 드는 장소를 찜해보세요!"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textColor = UITheme.secondaryTextGray
        emptyStateLabel.numberOfLines = 0
    }
    
    private func setupRefreshControl() {
        refreshControl.tintColor = UITheme.primaryOrange
        refreshControl.attributedTitle = NSAttributedString(string: "당겨서 새로고침")
        refreshControl.addTarget(self, action: #selector(refreshFavorites), for: .valueChanged)
        favoriteTableView.refreshControl = refreshControl
    }
    
    // MARK: - Data Loading
    private func loadFavoritePlaces() {
        if let savedData = UserDefaults.standard.data(forKey: "favoritePlaces"),
           let decoded = try? JSONDecoder().decode([FavoritePlace].self, from: savedData) {
            // 최신 저장 항목이 위에 오도록 정렬
            favoritePlaces = decoded.sorted { $0.savedDate > $1.savedDate }
            favoriteTableView.reloadData()
            
            // 빈 상태 처리
            updateEmptyState()
        } else {
            favoritePlaces = []
            updateEmptyState()
        }
    }
    
    private func updateEmptyState() {
        if favoritePlaces.isEmpty {
            favoriteTableView.isHidden = true
            emptyStateView.isHidden = false
            
            // 애니메이션 효과
            emptyStateView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.emptyStateView.alpha = 1
            }
        } else {
            favoriteTableView.isHidden = false
            emptyStateView.isHidden = true
        }
    }
    
    // MARK: - Actions
    @objc private func refreshFavorites() {
        loadFavoritePlaces()
        
        // 애니메이션 효과로 완료 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl.endRefreshing()
        }
    }
    
    @IBAction func editingTableViewRow(_ sender: UIBarButtonItem) {
        if favoriteTableView.isEditing {
            sender.title = "편집"
            favoriteTableView.isEditing = false
        } else {
            sender.title = "완료"
            favoriteTableView.isEditing = true
        }
    }
    
    // MARK: - Detail View Methods
    private func showDetailView(for place: FavoritePlace) {
        // 이전 상세 카드가 있으면 제거
        hideDetailView()
        
        // 새 상세 카드 생성
        selectedPlace = place
        
        // 상세 카드 생성
        let cardView = createDetailCardView(for: place)
        view.addSubview(cardView)
        detailCardView = cardView
        
        // 애니메이션으로 표시
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            cardView.alpha = 1
            cardView.transform = CGAffineTransform.identity
        })
    }
    
    private func hideDetailView() {
        guard let cardView = detailCardView else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            cardView.alpha = 0
            cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            cardView.removeFromSuperview()
            self.detailCardView = nil
        })
    }
    
    private func createDetailCardView(for place: FavoritePlace) -> UIView {
        // 카드 컨테이너 생성
        let cardHeight: CGFloat = 280
        let cardView = UIView(frame: CGRect(x: 20, y: view.bounds.height - cardHeight - 100, 
                                            width: view.bounds.width - 40, height: cardHeight))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 20
        UITheme.applyShadow(to: cardView, opacity: 0.2, radius: 8)
        
        // 상단 이미지 영역
        let imageHeight: CGFloat = 140
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cardView.bounds.width, height: imageHeight))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        // 이미지 로딩
        if !place.imageUrl.isEmpty, let url = URL(string: place.imageUrl) {
            let placeholderImage = UIImage(systemName: "photo")
            imageView.image = placeholderImage
            imageView.tintColor = UIColor.gray.withAlphaComponent(0.5)
            
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                            imageView.image = image
                        })
                    }
                }
            }.resume()
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = UIColor.gray.withAlphaComponent(0.5)
        }
        cardView.addSubview(imageView)
        
        // 카테고리 태그
        let categoryTag = UILabel(frame: CGRect(x: 15, y: 15, width: 0, height: 26))
        categoryTag.text = " \(place.category) "
        categoryTag.font = UITheme.tagFont
        categoryTag.textColor = .white
        categoryTag.backgroundColor = getCategoryColor(place.category)
        categoryTag.layer.cornerRadius = 13
        categoryTag.clipsToBounds = true
        categoryTag.sizeToFit()
        categoryTag.frame.size.width += 20
        categoryTag.textAlignment = .center
        imageView.addSubview(categoryTag)
        
        // 제목
        let titleLabel = UILabel(frame: CGRect(x: 20, y: imageHeight + 15, width: cardView.bounds.width - 40, height: 25))
        titleLabel.text = place.title
        titleLabel.font = UITheme.titleFont
        titleLabel.textColor = UITheme.primaryTextDark
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        cardView.addSubview(titleLabel)
        
        // 주소
        let addressIcon = UILabel(frame: CGRect(x: 20, y: imageHeight + 45, width: 20, height: 20))
        addressIcon.text = "📍"
        cardView.addSubview(addressIcon)
        
        let addressLabel = UILabel(frame: CGRect(x: 45, y: imageHeight + 45, width: cardView.bounds.width - 65, height: 20))
        addressLabel.text = place.address
        addressLabel.font = UITheme.bodyFont
        addressLabel.textColor = UITheme.secondaryTextGray
        addressLabel.numberOfLines = 1
        addressLabel.lineBreakMode = .byTruncatingTail
        cardView.addSubview(addressLabel)
        
        // 저장 날짜
        let dateIcon = UILabel(frame: CGRect(x: 20, y: imageHeight + 70, width: 20, height: 20))
        dateIcon.text = "🕒"
        cardView.addSubview(dateIcon)
        
        let dateLabel = UILabel(frame: CGRect(x: 45, y: imageHeight + 70, width: cardView.bounds.width - 65, height: 20))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateLabel.text = "저장: " + dateFormatter.string(from: place.savedDate)
        dateLabel.font = UITheme.captionFont
        dateLabel.textColor = UITheme.secondaryTextGray
        cardView.addSubview(dateLabel)
        
        // 버튼 컨테이너
        let buttonContainer = UIView(frame: CGRect(x: 15, y: imageHeight + 100, width: cardView.bounds.width - 30, height: 50))
        cardView.addSubview(buttonContainer)
        
        // 액션 버튼들
        let buttonWidth = (buttonContainer.bounds.width - 20) / 3
        
        // 1. 지도에서 보기 버튼
        let mapButton = createActionButton(
            frame: CGRect(x: 0, y: 0, width: buttonWidth, height: 40),
            title: "지도에서 보기",
            icon: "map.fill",
            color: UITheme.tourismBlue
        )
        mapButton.addTarget(self, action: #selector(openInMap), for: .touchUpInside)
        buttonContainer.addSubview(mapButton)
        
        // 2. 길찾기 버튼
        let directionsButton = createActionButton(
            frame: CGRect(x: buttonWidth + 10, y: 0, width: buttonWidth, height: 40),
            title: "길찾기",
            icon: "location.fill",
            color: UITheme.festivalGreen
        )
        directionsButton.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        buttonContainer.addSubview(directionsButton)
        
        // 3. 공유하기 버튼
        let shareButton = createActionButton(
            frame: CGRect(x: (buttonWidth + 10) * 2, y: 0, width: buttonWidth, height: 40),
            title: "공유하기",
            icon: "square.and.arrow.up.fill",
            color: UITheme.primaryOrange
        )
        shareButton.addTarget(self, action: #selector(sharePlace), for: .touchUpInside)
        buttonContainer.addSubview(shareButton)
        
        // 닫기 버튼
        let closeButton = UIButton(frame: CGRect(x: cardView.bounds.width - 50, y: 10, width: 40, height: 40))
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeDetailView), for: .touchUpInside)
        imageView.addSubview(closeButton)
        
        return cardView
    }
    
    private func createActionButton(frame: CGRect, title: String, icon: String, color: UIColor) -> UIButton {
        let button = UIButton(frame: frame)
        
        // 아이콘 이미지 설정
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let image = UIImage(systemName: icon, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        
        // 타이틀 설정
        button.setTitle(" " + title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        
        // 스타일 설정
        button.backgroundColor = color
        button.layer.cornerRadius = 20
        UITheme.applyShadow(to: button, opacity: 0.2, radius: 4)
        
        return button
    }
    
    private func getCategoryColor(_ category: String) -> UIColor {
        switch category {
        case "관광지": return UITheme.tourismBlue
        case "숙박": return UITheme.accommodationPurple
        case "음식점": return UITheme.restaurantRed
        case "축제/행사": return UITheme.festivalGreen
        default: return UITheme.primaryOrange
        }
    }
    
    // MARK: - Button Actions
    @objc private func closeDetailView() {
        hideDetailView()
    }
    
    @objc private func openInMap() {
        guard let place = selectedPlace else { return }
        
        // 탭바에서 맵 화면으로 이동
        if let tabBarController = self.tabBarController,
           tabBarController.viewControllers?.count ?? 0 > 1 {
            tabBarController.selectedIndex = 1 // 맵 탭 인덱스
            
            // 해당 장소 위치로 이동하는 알림 전송
            NotificationCenter.default.post(name: NSNotification.Name("ShowLocationOnMap"), 
                                           object: nil, 
                                           userInfo: ["latitude": place.latitude, 
                                                     "longitude": place.longitude,
                                                     "title": place.title])
        }
    }
    
    @objc private func getDirections() {
        guard let place = selectedPlace else { return }
        
        let latitude = place.latitude
        let longitude = place.longitude
        
        // 애플 지도 앱으로 길찾기
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
        mapItem.name = place.title
        
        // 현재 위치에서 목적지까지의 경로
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    @objc private func sharePlace() {
        guard let place = selectedPlace else { return }
        
        // 공유할 텍스트 생성
        let shareText = "[\(place.category)] \(place.title)\n주소: \(place.address)\n\n🗺 NolJaGo 앱에서 확인해보세요!"
        
        // 공유 시트 표시
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SavedPlacesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoritePlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoritePlaceCell", for: indexPath) as! FavoritePlaceCell
        
        let place = favoritePlaces[indexPath.row]
        cell.configure(with: place)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SavedPlacesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = favoritePlaces[indexPath.row]
        showDetailView(for: place)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // UserDefaults에서도 삭제
            let placeToDelete = favoritePlaces[indexPath.row]
            favoritePlaces.remove(at: indexPath.row)
            
            if let savedData = UserDefaults.standard.data(forKey: "favoritePlaces"),
               let decoded = try? JSONDecoder().decode([FavoritePlace].self, from: savedData) {
                let updatedPlaces = decoded.filter { $0.id != placeToDelete.id }
                if let encoded = try? JSONEncoder().encode(updatedPlaces) {
                    UserDefaults.standard.set(encoded, forKey: "favoritePlaces")
                }
            }
            
            // 애니메이션과 함께 셀 삭제
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // 빈 상태 체크
            updateEmptyState()
            
            // 상세 카드가 표시 중이고 삭제한 항목이면 카드도 닫기
            if let selectedPlace = selectedPlace, selectedPlace.id == placeToDelete.id {
                hideDetailView()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedPlace = favoritePlaces.remove(at: sourceIndexPath.row)
        favoritePlaces.insert(movedPlace, at: destinationIndexPath.row)
        
        // UserDefaults에 변경된 순서 저장
        if let encoded = try? JSONEncoder().encode(favoritePlaces) {
            UserDefaults.standard.set(encoded, forKey: "favoritePlaces")
        }
    }
    
    // 스와이프 액션 추가
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 삭제 액션
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { (_, _, completion) in
            // 기존 삭제 로직 활용
            self.tableView(tableView, commit: .delete, forRowAt: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        // 공유 액션
        let shareAction = UIContextualAction(style: .normal, title: "공유") { (_, _, completion) in
            let place = self.favoritePlaces[indexPath.row]
            let shareText = "[\(place.category)] \(place.title)\n주소: \(place.address)\n\n🗺 NolJaGo 앱에서 확인해보세요!"
            
            let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            self.present(activityViewController, animated: true)
            completion(true)
        }
        shareAction.backgroundColor = UITheme.primaryOrange
        
        // 액션 설정
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
        return configuration
    }
}

// MARK: - FavoritePlaceCell
class FavoritePlaceCell: UITableViewCell {
    private let cardView = UIView()
    private let placeImageView = UIImageView()
    private let titleLabel = UILabel()
    private let categoryLabel = UILabel()
    private let addressLabel = UILabel()
    private let dateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // 셀 설정
        backgroundColor = .clear
        selectionStyle = .none
        
        // 카드 뷰 설정
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        UITheme.applyShadow(to: cardView, opacity: 0.1, radius: 5)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        // 이미지 뷰 설정
        placeImageView.contentMode = .scaleAspectFill
        placeImageView.clipsToBounds = true
        placeImageView.layer.cornerRadius = 14
        placeImageView.translatesAutoresizingMaskIntoConstraints = false
        placeImageView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        cardView.addSubview(placeImageView)
        
        // 카테고리 레이블 설정
        categoryLabel.font = UITheme.tagFont
        categoryLabel.textColor = .white
        categoryLabel.textAlignment = .center
        categoryLabel.layer.cornerRadius = 12
        categoryLabel.clipsToBounds = true
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(categoryLabel)
        
        // 제목 레이블 설정
        titleLabel.font = UITheme.subtitleFont
        titleLabel.textColor = UITheme.primaryTextDark
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        // 주소 레이블 설정
        addressLabel.font = UITheme.bodyFont
        addressLabel.textColor = UITheme.secondaryTextGray
        addressLabel.numberOfLines = 1
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(addressLabel)
        
        // 날짜 레이블 설정
        dateLabel.font = UITheme.captionFont
        dateLabel.textColor = UITheme.secondaryTextGray.withAlphaComponent(0.8)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dateLabel)
        
        // 오토레이아웃 설정
        NSLayoutConstraint.activate([
            // 카드 뷰
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // 이미지 뷰
            placeImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            placeImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            placeImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            placeImageView.widthAnchor.constraint(equalToConstant: 120),
            
            // 카테고리 레이블
            categoryLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            categoryLabel.leadingAnchor.constraint(equalTo: placeImageView.trailingAnchor, constant: 12),
            categoryLabel.heightAnchor.constraint(equalToConstant: 24),
            
            // 제목 레이블
            titleLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: placeImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            
            // 주소 레이블
            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            addressLabel.leadingAnchor.constraint(equalTo: placeImageView.trailingAnchor, constant: 12),
            addressLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            
            // 날짜 레이블
            dateLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            dateLabel.leadingAnchor.constraint(equalTo: placeImageView.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
        ])
    }
    
    func configure(with place: FavoritePlace) {
        titleLabel.text = place.title
        
        // 카테고리 설정
        categoryLabel.text = " \(place.category) "
        categoryLabel.sizeToFit()
        let categoryWidth = categoryLabel.frame.width + 16
        categoryLabel.widthAnchor.constraint(equalToConstant: categoryWidth).isActive = true
        
        // 카테고리별 색상 설정
        switch place.category {
        case "관광지":
            categoryLabel.backgroundColor = UITheme.tourismBlue
        case "숙박":
            categoryLabel.backgroundColor = UITheme.accommodationPurple
        case "음식점":
            categoryLabel.backgroundColor = UITheme.restaurantRed
        case "축제/행사":
            categoryLabel.backgroundColor = UITheme.festivalGreen
        default:
            categoryLabel.backgroundColor = UITheme.primaryOrange
        }
        
        // 주소 설정
        addressLabel.text = "📍 \(place.address)"
        
        // 날짜 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateLabel.text = "저장일: \(dateFormatter.string(from: place.savedDate))"
        
        // 이미지 로딩
        if !place.imageUrl.isEmpty, let url = URL(string: place.imageUrl) {
            placeImageView.image = UIImage(systemName: "photo")
            placeImageView.tintColor = UIColor.gray.withAlphaComponent(0.5)
            
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        UIView.transition(with: self?.placeImageView ?? UIImageView(), 
                                         duration: 0.3, 
                                         options: .transitionCrossDissolve, 
                                         animations: {
                            self?.placeImageView.image = image
                        })
                    }
                }
            }.resume()
        } else {
            placeImageView.image = UIImage(systemName: "photo")
            placeImageView.tintColor = UIColor.gray.withAlphaComponent(0.5)
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.1) {
            self.cardView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            self.cardView.alpha = highlighted ? 0.9 : 1.0
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        placeImageView.image = nil
        titleLabel.text = nil
        categoryLabel.text = nil
        addressLabel.text = nil
        dateLabel.text = nil
    }
}