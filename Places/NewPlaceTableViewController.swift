//
//  NewPlaceTableViewController.swift
//  Places
//
//  Created by Ilya Pavlov on 22.07.2023.
//

import UIKit
import PhotosUI

class NewPlaceTableViewController: UITableViewController {
    
    //объявляем новую переменную, в которую будем писать данные при добавлении новых мест и его параметров
    var newPlace: Place?
    var imageIsChanged = false
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var imageOfPlace: UIImageView!
    @IBOutlet weak var nameOfPlace: UITextField!
    @IBOutlet weak var locationOfPlace: UITextField!
    @IBOutlet weak var typeOfPlace: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Новое место"
        
        // делаем кнопку "Сохранить" недоступной
        saveButton.isEnabled = false
        nameOfPlace.addTarget(self, action: #selector(updateSaveButtonState), for: .editingChanged)
        
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
    
    func saveNewPlace() {
        
        var image: UIImage?
        
        if imageIsChanged {
            image = imageOfPlace.image
        } else {
            let config = UIImage.SymbolConfiguration(hierarchicalColor: .darkGray)
            image = UIImage(systemName: "fork.knife.circle.fill", withConfiguration: config)
        }
        
        newPlace = Place(name: nameOfPlace.text!, location: locationOfPlace.text, type: typeOfPlace.text, image: image, restaurantImage: nil)
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
