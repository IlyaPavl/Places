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
        addressLabel.layer.shadowOpacity = 0.5
        addressLabel.layer.shadowOffset = CGSize(width: 4, height: 4)
        addressLabel.layer.shadowRadius = 10
        
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
