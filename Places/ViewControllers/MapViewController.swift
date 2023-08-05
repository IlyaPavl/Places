//
//  MapViewController.swift
//  Pods
//
//  Created by Ilya Pavlov on 03.08.2023.
//

import UIKit
import MapKit
import CoreLocation // для определения местоположения пользователя

class MapViewController: UIViewController {
    
    var place = Place()
    var annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager() // отвечает за настройку и управление геолокациями
    let regionInMeters = 5000.00
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var exitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        setupPlacemark()
        setUpExitButton()
        checkLocationServices()
        
    }
    
    @IBAction func closeMapVc() {
        dismiss(animated: true)
    }
    
    @IBAction func centerViewUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
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
            
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    private func setUpExitButton() {
        exitButton.layer.shadowColor = UIColor.black.cgColor
        exitButton.layer.shadowOpacity = 0.5
        exitButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        exitButton.layer.shadowRadius = 4
        exitButton.layer.masksToBounds = false
        
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
            break
        @unknown default:
            print("New case is available")
        }
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
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuth()
    }
}
