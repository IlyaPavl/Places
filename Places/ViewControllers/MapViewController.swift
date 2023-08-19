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
    
    let mapManager = MapManager()
    var mapViewContorllerDelegate: MapViewControllerDelegate?
    
    var place = Place()
    
    var annotationIdentifier = "annotationIdentifier" // идентификатор аннотации
    
    var incomeSegueIdentifier = ""
    var previousLocation: CLLocation? {               // хранение предыдущего местоположения пользователя
        didSet {                                      // добавим наблюдателя, чтобы отслеживать изменения геопозиции (для этого также прописываем условия, при которых метод будет вызываться)
            mapManager.startTrackingUserLocation(for: mapView,
                                                 and: previousLocation) { currentLocation in
                self.previousLocation = currentLocation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)
                }
            }
        }
    }
    
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
    }
    
    @IBAction func closeMapVc() {
        dismiss(animated: true)
    }
    @IBAction func doneButtonPressed() {
        
        mapViewContorllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
        
    }
    
    @IBAction func navButtonPressed() {
        mapManager.getDirections(for: mapView) { location in
            self.previousLocation = location
        }
    }
    
    @IBAction func centerViewUserLocation() {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    private func setUpMapView() {
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        navButton.isHidden = true
        
        if incomeSegueIdentifier == "showPlace" {
            mapManager.setupPlacemark(place: place, mapView: mapView)
            mapPinimage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            navButton.isHidden = false
        }
    }
    
    private func setUpViewElements() {
        exitButton.layer.shadowColor = UIColor.black.cgColor
        exitButton.layer.shadowOpacity = 0.5
        exitButton.layer.shadowOffset = CGSize(width: 4, height: 4)
        exitButton.layer.shadowRadius = 10
        
        addressLabel.layer.shadowColor = UIColor.black.cgColor
        addressLabel.layer.shadowOpacity = 0.3
        addressLabel.layer.shadowOffset = CGSize(width: 4, height: 4)
        addressLabel.layer.shadowRadius = 10
        
    }
    
    
}


// MARK: - Подпишемся под протокол MKViewDelegate, что бы более тонко настроить вид карты, в частности сделать отображении аннотации более презентабельным

extension MapViewController: MKMapViewDelegate {
    
    /*
     Эта функция - часть делегата MKMapViewDelegate, которая отвечает за предоставление пользовательских видов для аннотаций (маркеров) на карте. Вот что делает каждый шаг этой функции:
     
     1. Проверка на пользовательскую локацию: Сначала функция проверяет, не является ли переданная аннотация экземпляром MKUserLocation (местоположение пользователя). Если это так, то возвращается nil, потому что в данном случае не нужно создавать вид аннотации.
     2. Попытка переиспользования аннотации: Функция пытается переиспользовать аннотационный вид с помощью метода dequeueReusableAnnotationView(withIdentifier:). Если такой вид не найден (например, при первом создании), то создается новый MKMarkerAnnotationView.
     3. Настройка внешнего вида аннотации: Далее производится настройка внешнего вида аннотации. Устанавливается свойство canShowCallout в true, чтобы при клике на аннотацию появлялся балун с дополнительной информацией.
     4. Добавление изображения: Если у места (Place) есть imageData (данные изображения), то создается UIImageView с соответствующим изображением. Добавляется закругление углов и обрезание для создания скругленного вида. Созданный UIImageView устанавливается как правое дополнительное представление (Accessory View) для балуна аннотации.
     5. Возвращение аннотационного вида: Наконец, функция возвращает настроенный аннотационный вид, который будет отображаться на карте вместо стандартной аннотации. Этот вид будет содержать изображение, а также возможность показа дополнительной информации при клике.
     */
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
    
    /* метод, который вызывается каждый раз при смене отображаемого региона
     Данная функция - это часть делегата MKMapViewDelegate, которая срабатывает при изменении области (региона) отображаемой на карте. Вот пошаговое описание того, что делает каждый этап этой функции:
     1. Получение центральной точки области: Функция начинает с получения центральной координаты области, которая сейчас отображается на карте. Для этого используется метод getCenterLocation(for:), который передается объект mapView.
     2. Проверка и отображение текущей локации: Если текущий переход (incomeSegueIdentifier) - это “showPlace” (показ места) и previousLocation (предыдущее местоположение) не равно nil, то через 10 секунд после изменения области запланировано отображение местоположения пользователя. Это сделано, чтобы показать местоположение пользователя на карте, после того как пользователь перешел на экран отдельного места.
     3. Отмена геокодирования: Здесь вызывается метод cancelGeocode() для отмены всех активных запросов геокодирования. Это может быть полезно, если пользователь быстро меняет область на карте и нужно обработать только последний запрос на обратное геокодирование.
     4. Обратное геокодирование и обновление адреса: Затем идет обратное геокодирование - получение адреса на основе координаты центральной точки области. Результаты геокодирования - местоположения в виде “меток” (placemarks) - проверяются. Если есть ошибки или нет результатов, то дальнейшее выполнение прекращается.
     5. Извлечение адреса из геокодирования: Если есть результат геокодирования (хотя бы одна “метка” или placemark), то извлекаются название улицы (thoroughfare) и номер дома (subThoroughfare) из этой метки.
     6. Обновление метки с адресом на главном потоке: После извлечения данных из геокодирования, они используются для обновления метки с адресом (addressLabel) на пользовательском интерфейсе. Если есть и название улицы и номер дома, то адрес образуется в формате “улица, номер дома”. Если есть только название улицы, выводится только улица. Если данных нет вообще, метка адреса очищается.
     */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.mapManager.showUserLocation(mapView: self.mapView)
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
        mapManager.checkLocationAuth(mapView: mapView, segueIdentifier: incomeSegueIdentifier)
    }
}
