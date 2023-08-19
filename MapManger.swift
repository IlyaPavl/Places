//
//  MapManger.swift
//  Places
//
//  Created by Ilya Pavlov on 08.08.2023.
//

import UIKit
import MapKit

class MapManager {
    let locationManager = CLLocationManager()                 // отвечает за настройку и управление геолокациями
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
    
    /* проверяем, включена ли геолокация
     1. func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ())
     Этот метод принимает три параметра:
     • mapView: MKMapView: это экземпляр MKMapView, который будет использоваться внутри метода.
     • segueIdentifier: String: строковый идентификатор для перехода, который будет использоваться внутри метода.
     • closure: () -> (): это замыкание (closure), которое будет выполнено после проверок.
     2. if CLLocationManager.locationServicesEnabled()
     Этот блок кода проверяет, включены ли службы геолокации на устройстве.
     3. locationManager.desiredAccuracy = kCLLocationAccuracyBest
     Здесь задается желаемая точность для служб геолокации. В данном случае, kCLLocationAccuracyBest означает максимальную точность.
     4. checkLocationAuth(mapView: mapView, segueIdentifier: segueIdentifier)
     Эта функция вызывается для проверки статуса разрешения на использование геолокации. Она принимает mapView и segueIdentifier, которые будут использованы внутри этой функции.
     5. closure()
     Если службы геолокации включены и статус разрешения определен, замыкание, переданное в метод checkLocationServices, будет выполнено. Это означает, что код внутри замыкания будет выполнен.
     6. else
     Если службы геолокации не включены, код в этом блоке выполнится. Здесь установлена задержка в 1 секунду с помощью DispatchQueue.main.asyncAfter. Затем вызывается метод showAlert, который покажет пользователю предупреждение о том, что службы геолокации отключены и как их можно включить в настройках устройства.
     */
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
    
    /* метод для проверки статуса для разрешения использования геопозиции
     1. func checkLocationAuth(mapView: MKMapView, segueIdentifier: String)
     Этот метод принимает два параметра:
     • mapView: MKMapView: это экземпляр MKMapView, который будет использоваться внутри метода.
     • segueIdentifier: String: строковый идентификатор перехода, который будет использоваться для определения, какой переход нужно выполнить.
     2. switch locationManager.authorizationStatus
     Здесь начинается проверка статуса разрешения на использование служб геолокации.
     3. .notDetermined:
     Если статус разрешения равен .notDetermined, это означает, что пользователь еще не принял решение относительно использования геолокации. В таком случае, метод locationManager.requestWhenInUseAuthorization() вызывается для запроса разрешения на использование геолокации только при активном использовании приложения.
     4. .restricted:
     Если статус разрешения равен .restricted, это означает, что использование геолокации ограничено системными ограничениями (например, для детей). В этом случае, через секунду с помощью DispatchQueue.main.asyncAfter показывается предупреждение пользователю, объясняющее, что геолокация недоступна и как можно предоставить разрешение.
     5. .denied:
     Если статус разрешения равен .denied, это означает, что пользователь отклонил использование геолокации. В этом случае, можно было бы создать UIAlertController с инструкцией о том, как пользователь может включить геолокацию в настройках устройства.
     6. .authorizedAlways:
     Если статус разрешения равен .authorizedAlways, это означает, что приложение имеет доступ к геолокации всегда. Здесь нет дополнительных действий.
     7. .authorizedWhenInUse:
     Если статус разрешения равен .authorizedWhenInUse, это означает, что приложению разрешено использование геолокации только при активном использовании приложения. В этом случае, свойство showsUserLocation устанавливается в true, чтобы показать местоположение пользователя на mapView. Если segueIdentifier равен "getAddress", то выполняется функция showUserLocation, которая, вероятно, выполняет определенное действие в зависимости от этого перехода.
     8. @unknown default:
     Эта часть кода активируется, если какой-либо другой статус разрешения геолокации не был предусмотрен в указанных случаях. В этом случае, просто выводится сообщение в консоль о том, что доступен новый статус.
     */
    func checkLocationAuth(mapView: MKMapView, segueIdentifier: String) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Your Location is not available",
                               message: "To give permission Go to: Setting -> MyPlaces -> Location")
            }
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Your Location is not available",
                               message: "To give permission Go to: Setting -> MyPlaces -> Location")
            }
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
    
    /* метод для отображения локации пользователя
     1. func showUserLocation(mapView: MKMapView)
     Этот метод принимает в качестве параметра экземпляр MKMapView, на которой будет выполнено действие.
     2. if let location = locationManager.location?.coordinate
     Здесь происходит попытка получить текущее местоположение из объекта locationManager. Мы используем опциональную цепочку (?.), чтобы удостовериться, что locationManager.location не nil, иначе блок if не будет выполнен.
     3. let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
     Если удалось получить текущее местоположение, мы используем его координаты location для создания объекта MKCoordinateRegion. Это представляет регион вокруг указанной точки, который будет отображаться на карте. Параметры:
     • center: координаты центра региона, у нас это текущее местоположение.
     • latitudinalMeters: ширина региона в метрах.
     • longitudinalMeters: высота региона в метрах.
     4. mapView.setRegion(region, animated: true)
     Здесь мы устанавливаем созданный регион как текущий регион для mapView. В результате карта будет плавно перемещаться и масштабироваться так, чтобы показать выбранную область вокруг указанной точки. Параметр animated: true говорит о том, что перемещение и масштабирование карты должны быть анимированы.
     */
    func showUserLocation(mapView: MKMapView) {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    /*
     1. private func resetMapview(withNew directions: MKDirections, mapView: MKMapView)
     Это приватный метод, который используется для сброса состояния карты перед добавлением новых маршрутов. Он принимает два параметра:
     • directions: новый объект MKDirections, который представляет маршрут.
     • mapView: экземпляр MKMapView, на которой будут отображены маршруты.
     2. mapView.removeOverlays(mapView.overlays)
     Этот вызов удаляет все текущие наложения (overlays) с карты. В данном случае, наложения представляют собой отображаемые линии маршрутов (polyline) на карте.
     3. directionsArray.append(directions)
     Объект directions добавляется в массив directionsArray. Этот массив, видимо, служит для хранения всех объектов MKDirections.
     4. let _ = directionsArray.map { $0.cancel()}
     Здесь происходит итерация по массиву directionsArray и для каждого объекта MKDirections вызывается метод cancel(). Этот метод отменяет запрос на построение маршрута. Он вызывается, чтобы убедиться, что предыдущие запросы были отменены, если такие были.
     5. directionsArray.removeAll()
     В конце метода, после отмены всех запросов, массив directionsArray очищается, так как старые маршруты были удалены.
     */
    private func resetMapview(withNew directions: MKDirections, mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel()}
        directionsArray.removeAll()
    }
    
    
    /*
     1. func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ())
     Это функция, предназначенная для получения и отображения маршрутов на mapView. Она принимает два параметра:
     • mapView: экземпляр MKMapView, на котором будут отображаться маршруты.
     • previousLocation: замыкание, которое принимает объект типа CLLocation и используется для сохранения предыдущего местоположения.
     2. guard let location = locationManager.location?.coordinate else { ... }
     Здесь определяется текущее местоположение пользователя в виде координат. Если местоположение недоступно, выводится предупреждение и функция завершается.
     3. locationManager.startUpdatingLocation()
     Этот вызов запускает обновление информации о местоположении. Он позволяет локационному менеджеру начать передавать обновления о местоположении.
     4. previousLocation(CLLocation(latitude: location.latitude, longitude: location.latitude))
     Здесь замыкание previousLocation вызывается, и в него передается новое местоположение в виде объекта CLLocation.
     5. guard let request = createDirectionRequest(from: location) else { ... }
     Создается запрос на построение маршрута. Если создание запроса невозможно (например, если местоположение недоступно), выводится предупреждение и функция завершается.
     6. let directions = MKDirections(request: request)
     Создается объект MKDirections с использованием созданного запроса.
     7. resetMapview(withNew: directions, mapView: mapView)
     Вызывается функция resetMapview, которая очищает текущие маршруты на карте.
     8. directions.calculate { response, error in ... }
     Производится рассчет маршрутов с помощью вызова метода calculate на объекте directions. В этом блоке кода будет обработка результата расчета маршрутов.
     9. Внутри блока directions.calculate, для каждого маршрута в response.routes:
     • mapView.addOverlay(route.polyline): Добавляется наложение на карту, представляющее геометрию маршрута в виде линии.
     • mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true): Карта позиционируется так, чтобы весь маршрут был виден.
     • Выводятся данные о расстоянии и времени в пути для каждого маршрута.
     */
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
    
    /* метод для настройки запроса для построения маршрута
     1. func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request?
 Это функция для создания запроса на построение маршрута. Она принимает координату начальной точки маршрута и возвращает объект типа MKDirections.Request или nil, если создание запроса невозможно.
     2. guard let destinationCoordinate = placeCoordinate else {return nil}
 Здесь проверяется, есть ли координата конечной точки маршрута (placeCoordinate). Если ее нет, функция завершается и возвращает nil.
     3. let startingLocation = MKPlacemark(coordinate: coordinate)
 Создается объект MKPlacemark для начальной точки маршрута, используя переданную координату.
     4. let destination = MKPlacemark(coordinate: destinationCoordinate)
 Создается объект MKPlacemark для конечной точки маршрута, используя координату конечной точки.
     5. Создание объекта MKDirections.Request:
     • request.source: Начальная точка маршрута устанавливается с помощью объекта MKMapItem, созданного из startingLocation.
     • request.destination: Конечная точка маршрута устанавливается с помощью объекта MKMapItem, созданного из destination.
     • request.transportType: Выбирается тип транспорта для маршрута (в данном случае - пешком).
     • request.requestsAlternateRoutes: Это свойство отвечает за поиск альтернативных маршрутов. В данной функции оно закомментировано.
     6. Если все шаги выполнены успешно, функция возвращает созданный объект MKDirections.Request. Если координата конечной точки маршрута отсутствует, функция вернет nil.
     */
    func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinate = placeCoordinate else {return nil}
        
        // свойство для координат стартовой точки
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        // создаем свойства с запросом конечных и начальных точек маршрута
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)     // задаем начальную точку
        request.destination = MKMapItem(placemark: destination)     // задаем конечную точку
        request.transportType = .walking                            // выбираем тип транспорта для маршрута
        // request.requestsAlternateRoutes = true                   // задаем возможность искать альтернативные маршруты
        
        return request
    }
    
    /* метод для выбора условий, при которых метод showUserLocation() будет вызываться
     1. Входные параметры метода:
     • mapView: Объект карты, для которой выполняется отслеживание местоположения пользователя.
     • location: Текущее местоположение пользователя в форме CLLocation?. Это опциональное значение, так как местоположение может быть не доступно.
     2. Проверка наличия текущего местоположения:
     • Прежде всего, мы проверяем, что location не является nil с помощью guard let location = location else {return}. Если location равно nil, это означает, что местоположение недоступно, и мы выходим из метода.
     3. Определение координат центра отображаемой области:
     • Мы вызываем метод getCenterLocation(for:), передавая ему mapView. Этот метод вычисляет координаты центра отображаемой области карты.
     4. Проверка расстояния:
     • Мы используем координаты центра (center) и текущего местоположения (location) для вычисления расстояния между ними с помощью center.distance(from: location).
     • Если это расстояние больше 50 метров, то это может означать, что пользователь переместился на достаточно большое расстояние с последнего обновления. В этом случае мы можем выполнить переданное замыкание (closure), чтобы произвести какие-либо действия.
     5. Выполнение переданного замыкания:
     • Мы вызываем переданное замыкание closure(center), передавая в него координаты центра (center) отображаемой области.
     */
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
