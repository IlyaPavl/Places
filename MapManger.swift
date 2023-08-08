//
//  MapManger.swift
//  Places
//
//  Created by Ilya Pavlov on 08.08.2023.
//

import UIKit
import MapKit

class MapManager {
    let locationManager = CLLocationManager()         // отвечает за настройку и управление геолокациями
    private var placeCoordinate: CLLocationCoordinate2D?      // свойство для хранения координат заведения
    private let regionInMeters = 2000.00                      // отвечает за величину zoomout на карте
    private var directionsArray: [MKDirections] = []          // массив маршрутов
    
    /*
     func setupPlacemark()
     1. `guard let location = place.location else { return }`: Получает местоположение места из свойства `location` объекта `place`, если оно доступно. Если `location` равно `nil`, метод завершается и ничего не делает.
     2. `let geocoder = CLGeocoder()`: Создает объект `geocoder`, который используется для геокодирования (преобразования адреса в координаты или наоборот).
     3. `geocoder.geocodeAddressString(location) { (placemarks, error) in ... }`: Выполняет геокодирование для указанного адреса (`location`). По завершению геокодирования, вызывается замыкание с результатами в параметре `placemarks` (массив объектов `CLPlacemark`) и ошибкой (если есть) в параметре `error`.
     4. `if let error = error { ... }`: Проверяет, есть ли ошибка при геокодировании. Если ошибка есть, выводит ее в консоль и завершает метод.
     5. `guard let placemarks = placemarks else { return }`: Получает первый объект `CLPlacemark` из массива `placemarks`, если массив не пустой. Если массив пустой, метод завершается и ничего не делает.
     6. `let placemark = placemarks.first`: Получает первый объект `CLPlacemark` из массива `placemarks`.
     7. `let annotation = MKPointAnnotation()`: Создает объект `MKPointAnnotation`, который представляет маркер на карте.
     8. `annotation.title = self.place.name`: Задает название маркера, которое берется из свойства `name` объекта `place`.
     9. `annotation.subtitle = self.place.type`: Задает подзаголовок маркера, который берется из свойства `type` объекта `place`.
     10. `guard let placemarkLocation = placemark?.location else { return }`: Получает координаты из объекта `CLPlacemark`, если он существует. Если объект `CLPlacemark` равен `nil`, метод завершается и ничего не делает.
     11. `annotation.coordinate = placemarkLocation.coordinate`: Задает координаты для маркера на основе полученных координат из `CLPlacemark`.
     12. `self.mapView.showAnnotations([annotation], animated: true)`: Добавляет созданный маркер на карту и отображает его на карте.
     13. `self.mapView.selectAnnotation(annotation, animated: true)`: Выделяет маркер на карте, чтобы отобразить его название и подзаголовок.
     */
    func setupPlacemark(place: Place, mapView: MKMapView) {
        
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // проверяем, включена ли геолокация
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuth(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Location Services are disabled",
                               message: "To enable it go: Settings -> Privacy -> Location Services and turn On")
            }
        }
    }
    
    // метод для проверки статуса для разрешения использования геопозиции
     func checkLocationAuth(mapView: MKMapView, segueIdentifier: String) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Your Location is not available",
                               message: "To give permission Go to: Setting -> MyPlaces -> Location")
            }
        case .denied: break
            // cоздать alertController с инструкцией как включить службы геолокацию
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    // метод для отображения локации пользователя
    func showUserLocation(mapView: MKMapView) {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func resetMapview(withNew directions: MKDirections, mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel()}
        directionsArray.removeAll()
    }
    
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        
        // определим координаты местоположения пользователя
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not available")
            return}
        
        // включаем метод для отслеживания местоположения
        locationManager.startUpdatingLocation()
        // подставляем значения координат в свойство previousLocation
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.latitude))
        
        // запрос на прокладку маршрута
        guard let request = createDirectionRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return }
        
        // создаем свойство для построения маршрута
        let directions = MKDirections(request: request)
        resetMapview(withNew: directions, mapView: mapView)
        
        // рассчитываем показатели маршрута
        directions.calculate { response, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlert(title: "Error", message: "Directions are not found")
                return
            }
            
            for route in response.routes{
               
                // создаем наложения на карту
                mapView.addOverlay(route.polyline)                                             // свойство отображующее всю геометрию маршрута
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                                
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = (route.expectedTravelTime / 60)
                
                print("Расстояние до места: \(distance) км.")
                print("Время в пути составит: \(timeInterval) мин.")
            }
        }
    }
    
    // метод для выбора условий, при которых метод showUserLocation() будет вызываться
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        guard let location = location else {return}
        
        // определяем координаты центра отображаемой области
        let center = getCenterLocation(for: mapView)
        
        // далее бдуем обновлять маршрут каждые 50 метров и отображать это
        guard center.distance(from: location) > 50 else {return}
        closure(center)
    }
    
    // метод для извлечение координат центра карты
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // метод для настройки запроса для построения маршрута
    func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinate = placeCoordinate else {return nil}
        
        // свойство для координат стартовой точки
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        // создаем свойства с запросом конечных и начальных точек маршрута
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)     // задаем начальную точку
        request.destination = MKMapItem(placemark: destination)     // задаем конечную точку
        request.transportType = .walking                         // выбираем тип транспорта для маршрута
        // request.requestsAlternateRoutes = true                      // задаем возможность искать альтернативные маршруты
        
        return request
    }
    
    // метод для создания алерта
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true)
    }
}
