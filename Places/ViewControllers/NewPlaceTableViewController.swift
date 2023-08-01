//
//  NewPlaceTableViewController.swift
//  Places
//
//  Created by Ilya Pavlov on 22.07.2023.
//

import UIKit
import PhotosUI

class NewPlaceTableViewController: UITableViewController {
    
 // объявляем новую переменную, в которую будем писать данные при добавлении новых мест и его параметров (для добавления в базу)
 // var newPlace = Place()
    // создаем данную переменную, чтобы хранить в ней текущее значение ячейки
    var currentPlace: Place!
    var imageIsChanged = false
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var imageOfPlace: UIImageView!
    @IBOutlet weak var nameOfPlace: UITextField!
    @IBOutlet weak var locationOfPlace: UITextField!
    @IBOutlet weak var typeOfPlace: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Новое место"
        
        
        // делаем кнопку "Сохранить" недоступной
        saveButton.isEnabled = false
        nameOfPlace.addTarget(self, action: #selector(updateSaveButtonState), for: .editingChanged)
        
        setUpEditScreen()
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 0))
    }
    
    
    
    // MARK: - Table View delegate
    
    // для того, чтобы скрывать клавиатуру при нажатии в любое место. по условию делаем так, что игнорируем то место, где у нас должна быть картинка заведения ё
    // + настраиваем всплывающее меню с камерой и фото
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            let cameraIcon = UIImage(systemName: "camera")
            let photoIcon = UIImage(systemName: "photo")
            
            // если нажимаем на изображение, то должно появляться вспылвающее меню (выбрать камеру, выбрать фото и отменить)
            // создаем сначала меню выбора, далее создаем наши параметры для этого меню
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let camera = UIAlertAction(title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            camera.setValue(cameraIcon, forKey: "image")
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let photo = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            photo.setValue(photoIcon, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let cancel = UIAlertAction(title: "Camera", style: .cancel)
            
            // добалвяем параметры к меню
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            
            present(actionSheet, animated: true)
            
        } else {
            view.endEditing(true)
        }
    }
    
    func savePlace() {
        
        var image: UIImage?
        
        if imageIsChanged {
            image = imageOfPlace.image
        } else {
            let config = UIImage.SymbolConfiguration(hierarchicalColor: .darkGray)
            image = UIImage(systemName: "fork.knife.circle", withConfiguration: config)
        }
        
        let imageData = image?.pngData()
        let newPlace = Place(name: nameOfPlace.text!, location: locationOfPlace.text, type: typeOfPlace.text, imageData: imageData, rating: Double(ratingControl.rating))
        
        // данная проверка нужна, чтобы разделить момент добавления или редактирования ячейки
        if currentPlace != nil {
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            // сохраняем объект в базе
            StorageManager.saveObject(newPlace)
        }
        
        /*
         это более замороченный способ инициализации данных. Чтобы было проще, создадим в модели convinience инициализатор
        let newPlace = Place()

        newPlace.name = nameOfPlace.text!
        newPlace.location = locationOfPlace.text
        newPlace.type = typeOfPlace.text
        newPlace.imageData = imageData
         */
    }
    
    private func setUpEditScreen() {
        if currentPlace != nil {
            
            imageIsChanged = true
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else {return}
            
 
            imageOfPlace.image = image
            imageOfPlace.contentMode = .scaleAspectFill
            nameOfPlace.text = currentPlace?.name
            locationOfPlace.text = currentPlace?.location
            typeOfPlace.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
            
            title = currentPlace?.name
            saveButton.isEnabled = true
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

// MARK: - Text field delegate

extension NewPlaceTableViewController: UITextFieldDelegate {
    // метод для скрытия клавиатуры при нажатии done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // метод для проверки, есть ли в поле Имя данные. Если да, то кнопка становится активной, в противном случае - остается неактивной
    @objc private func updateSaveButtonState() {
        if nameOfPlace.text?.isEmpty == false {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
}

// MARK: - Work with image
extension NewPlaceTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // проработка логики работы imagePicker
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = source
        
        // если картинку базовую заменили, то меняем свойство на тру
        imageIsChanged = true
        
        present(imagePicker, animated: true)
    }
    
    // метод для того, чтобы отследить, что изображение выбрано
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        /*
        Что делает данный метод:
        1) imageOfPlace.image = info[.editedImage] as? UIImage: Здесь мы получаем выбранное изображение из словаря info по ключу .editedImage. Этот ключ указывает на отредактированное изображение, если пользователь выбрал его после редактирования. Мы присваиваем это изображение свойству image объекта imageOfPlace, которое, предположительно, является UIImageView, чтобы отобразить выбранное изображение.
        2) Затем мы устанавливаем режим отображения изображения imageOfPlace.contentMode на .scaleAspectFill. Это означает, что изображение будет масштабироваться и заполнять всю площадь UIImageView, сохраняя при этом пропорции, но возможно обрезая часть изображения.
        3) Мы также устанавливаем свойство clipsToBounds объекта imageOfPlace в true. Это означает, что любые подслои или контент, выходящий за границы UIImageView, будет обрезан, чтобы изображение отображалось только в пределах его рамок.
        4) Наконец, мы закрываем UIImagePickerController, вызывая метод dismiss(animated:). Это закрывает экран выбора изображения после того, как пользователь выбрал изображение, и возвращает наш контроллер к предыдущему экрану.
         */
        imageOfPlace.image = info[.editedImage] as? UIImage

        // используем свойства для настройки выбранного изображения
        imageOfPlace.contentMode = .scaleAspectFill
        imageOfPlace.clipsToBounds = true
        dismiss(animated: true)
    }
}
