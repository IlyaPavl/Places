//
//  MainViewController.swift
//  Places
//
//  Created by Ilya Pavlov on 20.07.2023.
//

import UIKit


class MainViewController: UITableViewController {


    
    var places = Place.getPlaces()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Избранные места"
        self.tableView.separatorInset.left = 95

    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell

// конфигурация базовой (некастомной) ячейки (новый способ, который пришел с iOS 14)
//        var cellConfig = UIListContentConfiguration.cell()
//        cellConfig.text = restaurantNames[indexPath.row]
//        cellConfig.image = UIImage(named: restaurantNames[indexPath.row])
//        cellConfig.imageProperties.cornerRadius = cell.frame.size.height / 2
//        cell.contentConfiguration = cellConfig
        
        let place = places[indexPath.row]
        
        if place.image == nil {
            cell.placeImage.image = UIImage(named: place.restaurantImage!)
        } else {
            cell.placeImage.image = place.image
        }
        
        cell.placeImage.layer.cornerRadius = cell.placeImage.frame.size.height / 2
        cell.nameOfPlace.text = place.name
        cell.locationOfPlace.text = place.location
        cell.typeOfPlace.text = place.type

        return cell
    }
    
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        guard let newPlaceVC = segue.source as? NewPlaceTableViewController else { return }
                
        newPlaceVC.saveNewPlace()
        places.append(newPlaceVC.newPlace!)
        tableView.reloadData()
    }

}
