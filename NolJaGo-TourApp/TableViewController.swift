//
//  ViewController.swift
//  TableViewCollectionView
//
//  Created by wjlee on 5/31/25.
//

import UIKit

class TableViewController: UIViewController {
    
    @IBOutlet weak var cityTableView: UITableView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var cities: [City] = NolJaGo_TourApp.load("cityData.json")
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cityTableView.register(UITableViewCell.self, forCellReuseIdentifier: "wjlee")
        cityTableView.dataSource = self
        cityTableView.delegate = self
        
        cityTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
        descriptionLabel.text = cities[0].description
    }
    
    @IBAction func editingTableViewRow(_ sender: UIBarButtonItem) {
        if cityTableView.isEditing == true{
            sender.title = "Edit"
            cityTableView.isEditing = false
        }else{
            sender.title = "Done"
            cityTableView.isEditing = true
        }
    }
}

extension TableViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // 1의 섹션만 한다.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wjlee") as! UITableViewCell
        
        cell.textLabel?.text = cities[indexPath.row].name
        cell.detailTextLabel?.text = cities[indexPath.row].country
        
        cell.imageView?.image = cities[indexPath.row].uiImage(size: CGSize(width: 200, height: 150))
        cell.textLabel?.textAlignment = .right
        return cell
    }
}

extension TableViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        descriptionLabel.text = cities[indexPath.row].description
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete{
            cities.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {

        let city = cities.remove(at: sourceIndexPath.row)
        cities.insert(city, at: destinationIndexPath.row)
        tableView.reloadData()
    }
}
