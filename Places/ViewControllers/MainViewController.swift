//
//  MainViewController.swift
//  Places
//
//  Created by Ilya Pavlov on 20.07.2023.
//

import UIKit
import RealmSwift


class MainViewController: UITableViewController {
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var places: Results<Place>!
    
    private var filteredPlaces: Results<Place>!
    
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else {return false}
        
        return text.isEmpty
    }

    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    private var topMenu = UIMenu()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorInset.left = 95
        
        
        places = realm.objects(Place.self)
        
        setUpMenu()
        setUpNavBar()
        
        searchController.searchResultsUpdater = self // сообщаем, что получателем текста в поисковой строке будет наш класс
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
        navigationItem.searchController = searchController
        searchController.definesPresentationContext = true
        
    }
    
    // MARK: - Navigation Bar Set up
    
    private func setUpMenu() {
        
        func createSortingAction(title: String, keyPath: String, ascending: Bool) -> UIAction {
            return UIAction(title: title, image: UIImage(systemName: ascending ? "chevron.up" : "chevron.down")) { _ in
                self.places = self.places.sorted(byKeyPath: keyPath, ascending: ascending)
                self.tableView.reloadData()
            }
        }
        
        let subMenuDate = UIMenu(title: "Дата", image: UIImage(systemName: "calendar"), children: [
            createSortingAction(title: "По убыванию", keyPath: "date", ascending: false),
            createSortingAction(title: "По возрастанию", keyPath: "date", ascending: true)
        ])
        
        let subMenuName = UIMenu(title: "Имя", image: UIImage(systemName: "character.cursor.ibeam"), children: [
            createSortingAction(title: "По убыванию", keyPath: "name", ascending: false),
            createSortingAction(title: "По возрастанию", keyPath: "name", ascending: true)
        ])
        
        let subMenuRate = UIMenu(title: "Рейтинг", image: UIImage(systemName: "star.leadinghalf.filled"), children: [
            createSortingAction(title: "По убыванию", keyPath: "rating", ascending: false),
            createSortingAction(title: "По возрастанию", keyPath: "rating", ascending: true)
        ])
        
        topMenu = UIMenu(title: "Cортировка", children: [subMenuDate, subMenuName, subMenuRate])
    }
    
    private func setUpNavBar() {
        let barButtonLeft = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), menu: topMenu)
        navigationItem.leftBarButtonItem = barButtonLeft
        navigationItem.title = "Избранные места"
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isFiltering {
            return filteredPlaces.count
        }
        return places.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        
        cell.nameOfPlace.text = place.name
        cell.locationOfPlace.text = place.location
        cell.typeOfPlace.text = place.type
        cell.placeImage.image = UIImage(data: place.imageData!)
        cell.starsView.rating = Int(place.rating)
        
        return cell
    }
    
    // MARK: - Table view data delegate
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let place = places[indexPath.row]
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard segue.identifier == "showDetail" else { return }
        guard let indexPath = tableView.indexPathForSelectedRow else {return}
        
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        
        let navigVC = segue.destination as! UINavigationController
        let editVC = navigVC.topViewController as! NewPlaceTableViewController
        editVC.currentPlace = place
    }
    
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        guard let newPlaceVC = segue.source as? NewPlaceTableViewController else { return }
        
        newPlaceVC.savePlace()
        
        //      данная строка использовалась, чтобы передавать данные между VC. Когда у нас есть база - это не нужно
        //      places.append(newPlaceVC.newPlace!)
        tableView.reloadData()
    }
    
}

extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        
        filteredPlaces = places.filter("name CONTAINS %@ OR location CONTAINS %@ OR type CONTAINS %@", searchText, searchText, searchText)
        tableView.reloadData()
    }
    
}
