//
//  MainViewController.swift
//  Places
//
//  Created by Ilya Pavlov on 20.07.2023.
//

import UIKit
import RealmSwift


class MainViewController: UITableViewController {

    //необходимо выполнить запрос к базе, чтобы отобразить находящиеся в ней данные. Для этого пишем results - аналог массива в realm - автообновляемый тип контейнера и в качестве типа указываем наш Place

    var places: Results<Place>!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Избранные места"
        self.tableView.separatorInset.left = 95
        
        // чтобы отобразить все заведения на экране, необходимо инициализировать объект places. Подставляем Place.self, так как нам нужно обратиться не к модели данных, а к типу
        places = realm.objects(Place.self)

    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.isEmpty ? 0 : places.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        /*
        конфигурация базовой (некастомной) ячейки (новый способ, который пришел с iOS 14)
        var cellConfig = UIListContentConfiguration.cell()
        cellConfig.text = restaurantNames[indexPath.row]
        cellConfig.image = UIImage(named: restaurantNames[indexPath.row])
        cellConfig.imageProperties.cornerRadius = cell.frame.size.height / 2
        cell.contentConfiguration = cellConfig
         */
         
        /*
         данное условие было создано тогда6 когда у нас еще не было модели данных
        if place.image == nil {
            cell.placeImage.image = UIImage(named: place.restaurantImage!)
        } else {
            cell.placeImage.image = place.image
        }
         */

        let place = places[indexPath.row]
    
        
        cell.nameOfPlace.text = place.name
        cell.locationOfPlace.text = place.location
        cell.typeOfPlace.text = place.type
        cell.placeImage.image = UIImage(data: place.imageData!)
        cell.placeImage.layer.cornerRadius = cell.placeImage.frame.size.height / 2

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
    
    /* данный метод удаляет элементы из списка и базы. Однако он подходит для того, когда у нас несколько действий для одного свайпа
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let place = places[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
     */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard segue.identifier == "showDetail" else { return }
        guard let indexPath = tableView.indexPathForSelectedRow else {return}
        
        let place = places[indexPath.row]
        
        let navigVC = segue.destination as! UINavigationController
        let editVC = navigVC.topViewController as! NewPlaceTableViewController
        editVC.currentPlace = place
    }
    
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        guard let newPlaceVC = segue.source as? NewPlaceTableViewController else { return }
                
        newPlaceVC.savePlace()
        
//        данная строка использовалась, чтобы передавать данные между VC. Когда у нас есть база - это не нужно
//      places.append(newPlaceVC.newPlace!)
        tableView.reloadData()
    }

}
