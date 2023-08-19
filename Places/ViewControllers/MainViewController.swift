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
    
    //необходимо выполнить запрос к базе, чтобы отобразить находящиеся в ней данные. Для этого пишем results - аналог массива в realm - автообновляемый тип контейнера - и в качестве типа указываем наш Place
    private var places: Results<Place>!
    
    // массив, в котором будут хранится результаты поиска
    private var filteredPlaces: Results<Place>!
    
    // проверка пустой ли searchBar
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else {return false}
        
        return text.isEmpty
    }
    // свойства, чтобы активировать searchBar
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    private var topMenu = UIMenu()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorInset.left = 95
        
        
        // чтобы отобразить все заведения на экране, необходимо инициализировать объект places. Подставляем Place.self, так как нам нужно обратиться не к модели данных, а к типу
        places = realm.objects(Place.self)
        
        // настройка NavigationBar
        setUpMenu()
        setUpNavBar()
        
        // настройка поиска
        searchController.searchResultsUpdater = self // сообщаем, что получателем текста в поисковой строке будет наш класс
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
        navigationItem.searchController = searchController
        searchController.definesPresentationContext = true
        
    }
    
    // MARK: - Navigation Bar Set up
    
    // настройка сортировки
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
        
        /*
         конфигурация базовой (некастомной) ячейки (новый способ, который пришел с iOS 14)
         var cellConfig = UIListContentConfiguration.cell()
         cellConfig.text = restaurantNames[indexPath.row]
         cellConfig.image = UIImage(named: restaurantNames[indexPath.row])
         cellConfig.imageProperties.cornerRadius = cell.frame.size.height / 2
         cell.contentConfiguration = cellConfig
         */
        
        /*
         данное условие было создано тогда, когда у нас еще не было модели данных
         if place.image == nil {
         cell.placeImage.image = UIImage(named: place.restaurantImage!)
         } else {
         cell.placeImage.image = place.image
         }
         */
        
        return cell
    }
    
    // MARK: - Table view data delegate
    
    // конфигурация действия удалить
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
    
    /*
     1. override func prepare(for segue: UIStoryboardSegue, sender: Any?) {: Это переопределение функции prepare(for:sender:), которая вызывается перед переходом на другой экран с помощью segue (перехода между экранами в iOS). Это дает вам возможность подготовить данные для следующего экрана.
     2. super.prepare(for: segue, sender: sender): Вызывает родительскую реализацию этой функции, чтобы она также выполнила свои задачи (если таковые есть). Это важно для правильной работы встроенной логики переходов.
     3. guard segue.identifier == "showDetail" else { return }: Здесь происходит проверка идентификатора segue. Эта строка говорит: “Если идентификатор segue не равен ‘showDetail’, то просто верни управление и не выполняй ниже указанный код”.
     4. guard let indexPath = tableView.indexPathForSelectedRow else { return }: В данной строке мы получаем индекс пути выбранной ячейки таблицы. Если ячейка не выбрана (например, если функция была вызвана не через выбор ячейки, а по другому триггеру), то выполняется return, и функция завершается.
     5. let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]: В данной строке определяется объект “place”, который будет передан на следующий экран. Если в данный момент включен поиск (переменная isFiltering равна true), то берется объект из отфильтрованного списка filteredPlaces, иначе из основного списка places, исходя из выбранного индекса пути.
     6. let navigVC = segue.destination as! UINavigationController: Эта строка извлекает навигационный контроллер (UINavigationController), который будет использован для перехода. Обратите внимание, что предполагается, что переход ведет к UINavigationController.
     7. let editVC = navigVC.topViewController as! NewPlaceTableViewController: Здесь мы получаем верхний (текущий) контроллер в навигационной иерархии, который предполагается использовать для редактирования информации о месте. Важно, чтобы этот контроллер был типа NewPlaceTableViewController.
     8. editVC.currentPlace = place: Эта строка устанавливает свойство currentPlace контроллера, который будет использоваться для редактирования. Это свойство будет содержать информацию о выбранном месте и передаст ее на следующий экран для отображения или редактирования.
     */
    
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

/*
 1. extension MainViewController: UISearchResultsUpdating {: Эта строка начинает расширение (extension) класса MainViewController и указывает, что класс будет реализовывать протокол UISearchResultsUpdating. Протокол UISearchResultsUpdating используется для обработки обновлений поисковых результатов для контроллера поиска.
 2. func updateSearchResults(for searchController: UISearchController) {: Это функция, требуемая протоколом UISearchResultsUpdating, и она вызывается при обновлении результатов поиска. Она принимает в качестве параметра объект UISearchController, который содержит информацию о состоянии поиска.
 3. filterContentForSearchText(searchController.searchBar.text!): Здесь вызывается функция filterContentForSearchText, передавая ей текст из строки поиска в searchBar контроллера поиска. searchController.searchBar.text! означает, что мы передаем текст из строки поиска, добавив “!” для извлечения фактического текста.
 4. private func filterContentForSearchText(_ searchText: String) {: Это приватная функция, которая фильтрует содержимое массива places в соответствии с заданным текстом поиска.
 5. filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@ OR type CONTAINS[c] %@", searchText, searchText, searchText): В этой строке мы фильтруем массив places, используя метод filter с форматированным запросом. Мы ищем объекты, в которых поле “name” (имя), “location” (местоположение) или “type” (тип) содержат (case-insensitive, указанное [c]) заданный текст поиска. Результат фильтрации сохраняется в массиве filteredPlaces.
 6. tableView.reloadData(): После того как массив filteredPlaces обновлен, вызывается метод перезагрузки таблицы reloadData(), чтобы обновить отображение данных в таблице.
 */

extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        
        filteredPlaces = places.filter("name CONTAINS %@ OR location CONTAINS %@ OR type CONTAINS %@", searchText, searchText, searchText)
        tableView.reloadData()
    }
    
}
