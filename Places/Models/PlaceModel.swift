//
//  PlaceModel.swift
//  Places
//
//  Created by Ilya Pavlov on 22.07.2023.
//

import RealmSwift

class Place: Object {
    
    @Persisted var name = ""
    @Persisted var location: String?
    @Persisted var type: String?
    @Persisted var imageData: Data?
    @Persisted var date = Date()
    @Persisted var rating = 0.0
    
    convenience init(name: String , location: String?, type: String?, imageData: Data?, rating: Double) {
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
    /* создаем данный метод для того, чтобы занести наши предустановленные

    let restaurantNames = ["Burger Heroes", "Kitchen", "Bonsai", "Дастархан", "Индокитай", "X.O", "Балкан Гриль", "Sherlock Holmes", "Speak Easy", "Morris Pub", "Вкусные истории", "Классик", "Love&Life", "Шок", "Бочка"]
    
    func savePlaces() {
        
        for place in restaurantNames {
            let image = UIImage(named: place)
            let newPlace = Place()
            
            guard let imageData = image?.pngData() else {return}
            
            newPlace.name = place
            newPlace.location = "Москва"
            newPlace.type = "Ресторан"
            newPlace.imageData = imageData
            
            // вызываем метод, который сохраняет данные в базу
            StorageManager.saveObject(newPlace)
        }
    }
     */
}
