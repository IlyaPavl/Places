//
//  MapViewController.swift
//  Pods
//
//  Created by Ilya Pavlov on 03.08.2023.
//

import UIKit
import MapKit
import CoreLocation // для определения местоположения пользователя

protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    
    var mapViewContorllerDelegate: MapViewControllerDelegate?
    
    var place = Place()
    
    var annotationIdentifier = "annotationIdentifier" // идентификатор аннотации
    let locationManager = CLLocationManager()         // отвечает за настройку и управление геолокациями
    let regionInMeters = 2000.00                      // отвечает за величину zoomout на карте
    var incomeSegueIdentifier = ""
    var placeCoordinate: CLLocationCoordinate2D?      // свойство для хранения координат заведения
    var previousLocation: CLLocation? {               // хранение предыдущего местоположения пользователя
        didSet {                                      // добавим наблюдателя, чтобы отслеживать изменения геопозиции (для этого также прописываем условия, при которых метод будет вызываться)
            startTrackingUserLocation()
        }
    }
    var directionsArray: [MKDirections] = []
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var mapPinimage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var navButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        setUpMapView()
        setUpViewElements()
        checkLocationServices()
        
        addressLabel.layer.shadowColor = UIColor.black.cgColor
        addressLabel.layer.shadowOpacity = 0.5
        addressLabel.layer.shadowOffset = CGSize(width: 4, height: 4)
        addressLabel.layer.shadowRadius = 10
        
    }
    
    @IBAction func closeMapVc() {
        dismiss(animated: true)
    }
    @IBAction func doneButtonPressed() {
        
        mapViewContorllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
        
    }
    
    @IBAction func navButtonPressed() {
        getDirections()
    }
    
    @IBAction func centerViewUserLocation() {
        showUserLocation()
    }
    
    private func setUpMapView() {
        
        navButton.isHidden = true
        
        if incomeSegueIdentifier == "showPlace" {
            setupPlacemark()
            mapPinimage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            navButton.isHidden = false
        }
    }
    
    private func resetMapview(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel()}
        directionsArray.removeAll()
    }
    
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
    private func setupPlacemark() {
        
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
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    private func setUpViewElements() {
        exitButton.layer.shadowColor = UIColor.black.cgColor
        exitButton.layer.shadowOpacity = 0.5
        exitButton.layer.shadowOffset = CGSize(width: 4, height: 4)
        exitButton.layer.shadowRadius = 10
        
        addressLabel.layer.shadowColor = UIColor.black.cgColor
        addressLabel.layer.shadowOpacity = 0.5
        addressLabel.layer.shadowOffset = CGSize(width: 4, height: 4)
        addressLabel.layer.shadowRadius = 10
        
    }
    
    // проверяем, включена ли геолокация
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setUpLocationManager()
            checkLocationAuth()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Location Services are disabled",
                               message: "To enable it go: Settings -> Privacy -> Location Services and turn On")
            }
        }
    }
    
    // метод для конфгурации первоналаьчных свойств locationManager
    private func setUpLocationManager() {
        locationManager.delegate = self
        // выбираем точность локации
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // метод для проверки статуса для разрешения использования геопозиции
    private func checkLocationAuth() {
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
            if incomeSegueIdentifier == "getAddress" { showUserLocation() }
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    // метод для отображения локации пользователя
    private func showUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // метод для выбора условий, при которых метод showUserLocation() будет вызываться
    private func startTrackingUserLocation() {
        guard let previousLocation = previousLocation else {return}
        
        // определяем координаты центра отображаемой области
        let center = getCenterLocation(for: mapView)
        
        // далее бдуем обновлять маршрут каждые 50 метров и отображать это
        guard center.distance(from: previousLocation) > 50 else {return}
        self.previousLocation = center
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }
    }
    
    // метод для извлечение координат центра карты
    private func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func getDirections() {
        
        // определим координаты местоположения пользователя
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not available")
            return}
        
        // включаем метод для отслеживания местоположения
        locationManager.startUpdatingLocation()
        // подставляем значения координат в свойство previousLocation
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.latitude)
        
        // запрос на прокладку маршрута
        guard let request = createDirectionRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return }
        
        // создаем свойство для построения маршрута
        let directions = MKDirections(request: request)
        resetMapview(withNew: directions)
        
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
                self.mapView.addOverlay(route.polyline)                                             // свойство отображующее всю геометрию маршрута
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                                
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = (route.expectedTravelTime / 60)
                
                print("Расстояние до места: \(distance) км.")
                print("Время в пути составит: \(timeInterval) мин.")
            }
        }
    }
    
    // метод для настройки запроса для построения маршрута
    private func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}


// MARK: - Подпишемся под протокол MKViewDelegate, что бы более тонко настроить вид карты, в частности сделать отображении аннотации более презентабельным

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {return nil}
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    
    // метод, который вызывается каждый раз при смене отображаемого региона
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.showUserLocation()
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { placemarks, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else {return}
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare          // забираем адрес с карты
            let buildingNumber = placemark?.subThoroughfare   // забираем номер дома
            
            DispatchQueue.main.async {
                if streetName != nil && buildingNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildingNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    
    // создаем метод для отрисовки линии маршрута
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .systemBlue

        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuth()
    }
}
