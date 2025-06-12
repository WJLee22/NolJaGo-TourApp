//
//  SavedPlacesViewController.swift
//  NolJaGo-TourApp
//
//  Created by wjlee on 5/31/25.
//

import UIKit
import MapKit

class SavedPlacesViewController: UIViewController {
    
    @IBOutlet weak var cityTableView: UITableView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var favoritePlaces: [FavoritePlace] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // 테이블뷰 설정
        cityTableView.register(FavoritePlaceCell.self, forCellReuseIdentifier: "FavoritePlaceCell")
        cityTableView.dataSource = self
        cityTableView.delegate = self
        
        // 초기 메시지
        descriptionLabel.text = "찜한 장소를 선택하면 상세 정보가 표시됩니다."
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면이 나타날 때마다 즐겨찾기 목록 새로고침
        loadFavoritePlaces()
    }
    
    private func setupUI() {
        // 테이블뷰 스타일 설정
        cityTableView.layer.cornerRadius = 10
        cityTableView.separatorStyle = .none
        cityTableView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        
        // 설명 레이블 스타일 설정
        descriptionLabel.layer.cornerRadius = 15
        descriptionLabel.clipsToBounds = true
        descriptionLabel.backgroundColor = UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
    }
    
    private func loadFavoritePlaces() {
        if let savedData = UserDefaults.standard.data(forKey: "favoritePlaces"),
           let decoded = try? JSONDecoder().decode([FavoritePlace].self, from: savedData) {
            // 최신 저장 항목이 위에 오도록 정렬
            favoritePlaces = decoded.sorted { $0.savedDate > $1.savedDate }
            cityTableView.reloadData()
            
            if favoritePlaces.isEmpty {
                descriptionLabel.text = "아직 찜한 장소가 없습니다. 지도 화면에서 장소를 찜해보세요!"
            }
        } else {
            favoritePlaces = []
            descriptionLabel.text = "아직 찜한 장소가 없습니다. 지도 화면에서 장소를 찜해보세요!"
            cityTableView.reloadData()
        }
    }
    
    @IBAction func editingTableViewRow(_ sender: UIBarButtonItem) {
        if cityTableView.isEditing {
            sender.title = "편집"
            cityTableView.isEditing = false
        } else {
            sender.title = "완료"
            cityTableView.isEditing = true
        }
    }
    
    // 선택한 장소의 상세 정보 표시
    private func updateDetailView(for place: FavoritePlace) {
        // 카드 형태의 정보 표시 (HTML 스타일)
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, 'SF Pro Display', 'AppleSDGothicNeo-Regular', 'Malgun Gothic', sans-serif;
                    margin: 15px;
                    color: #333;
                }
                .title {
                    font-size: 18px;
                    font-weight: bold;
                    color: #333;
                    margin-bottom: 10px;
                }
                .info {
                    font-size: 14px;
                    margin: 5px 0;
                    color: #555;
                }
                .category {
                    display: inline-block;
                    background-color: #f0f0f0;
                    padding: 4px 8px;
                    border-radius: 12px;
                    font-size: 12px;
                    margin-bottom: 10px;
                }
                .address {
                    margin-top: 10px;
                    font-size: 14px;
                }
            </style>
        </head>
        <body>
            <div class="category">\(place.category)</div>
            <div class="title">📍 \(place.title)</div>
            <div class="address">주소: \(place.address)</div>
            <div class="info">위도: \(place.latitude), 경도: \(place.longitude)</div>
            <div class="info">저장 날짜: \(formattedDate(place.savedDate))</div>
        </body>
        </html>
        """
        
        if let htmlData = htmlContent.data(using: .utf8) {
            do {
                let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ]
                
                let attributedString = try NSAttributedString(
                    data: htmlData,
                    options: options,
                    documentAttributes: nil
                )
                
                // 메인 스레드에서 UI 업데이트
                DispatchQueue.main.async {
                    self.descriptionLabel.attributedText = attributedString
                }
            } catch {
                print("HTML 변환 에러: \(error)")
                // 실패 시 일반 텍스트로 표시
                descriptionLabel.text = "📍 \(place.title)\n\n카테고리: \(place.category)\n주소: \(place.address)\n저장 날짜: \(formattedDate(place.savedDate))"
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: date)
    }
}

extension SavedPlacesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
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

extension SavedPlacesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateDetailView(for: favoritePlaces[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
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
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if favoritePlaces.isEmpty {
                descriptionLabel.text = "아직 찜한 장소가 없습니다. 지도 화면에서 장소를 찜해보세요!"
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
}

// 커스텀 테이블뷰 셀
class FavoritePlaceCell: UITableViewCell {
    private let cardView = UIView()
    private let placeImageView = UIImageView()
    private let titleLabel = UILabel()
    private let categoryLabel = UILabel()
    private let addressLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // 카드 뷰 설정
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 10
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 3
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        // 이미지 뷰 설정
        placeImageView.contentMode = .scaleAspectFill
        placeImageView.clipsToBounds = true
        placeImageView.layer.cornerRadius = 8
        placeImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(placeImageView)
        
        // 카테고리 레이블 설정
        categoryLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        categoryLabel.textColor = .white
        categoryLabel.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        categoryLabel.textAlignment = .center
        categoryLabel.layer.cornerRadius = 8
        categoryLabel.clipsToBounds = true
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(categoryLabel)
        
        // 제목 레이블 설정
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        titleLabel.textColor = .darkText
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        // 주소 레이블 설정
        addressLabel.font = UIFont.systemFont(ofSize: 12)
        addressLabel.textColor = .darkGray
        addressLabel.numberOfLines = 1
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(addressLabel)
        
        // 오토레이아웃 설정
        NSLayoutConstraint.activate([
            // 카드 뷰
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // 이미지 뷰
            placeImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            placeImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            placeImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            placeImageView.widthAnchor.constraint(equalToConstant: 80),
            
            // 카테고리 레이블
            categoryLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            categoryLabel.leadingAnchor.constraint(equalTo: placeImageView.trailingAnchor, constant: 10),
            categoryLabel.heightAnchor.constraint(equalToConstant: 16),
            categoryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            // 제목 레이블
            titleLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: placeImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            
            // 주소 레이블
            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            addressLabel.leadingAnchor.constraint(equalTo: placeImageView.trailingAnchor, constant: 10),
            addressLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            addressLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -10)
        ])
        
        // 배경색 및 선택 스타일 설정
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    func configure(with place: FavoritePlace) {
        titleLabel.text = place.title
        categoryLabel.text = place.category
        addressLabel.text = place.address
        
        // 이미지 로드
        if !place.imageUrl.isEmpty, let url = URL(string: place.imageUrl) {
            placeImageView.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
            
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.placeImageView.image = image
                    }
                }
            }.resume()
        } else {
            placeImageView.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
            placeImageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        }
    }
}
