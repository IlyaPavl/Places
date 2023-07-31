//
//  RatingControl.swift
//  Places
//
//  Created by Ilya Pavlov on 30.07.2023.
//

import UIKit

class RatingControl: UIStackView {
    
    var rating = 0 {
        didSet {
            updateButtonSelectionState()
        }
    }
    
    // создаем массив кнопок
    private var ratingButtons = [UIButton]()
    
    var starSize: CGSize = CGSize(width: 45.0, height: 45.0) {
        didSet {
            setUpButtons()
        }
    }
    var starCount: Int = 5 {
        didSet {
            setUpButtons()
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setUpButtons()
    }
    
    // MARK: - Button setup
    
    @objc func ratingButtonTapped(button: UIButton) {
        // создаем индекс звезды
        guard let index = ratingButtons.firstIndex(of: button) else {return}
        
        let selectedRating = index + 1
        
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
    }
    
    
    private func setUpButtons() {
        spacing = 6
        
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        
        ratingButtons.removeAll()
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemBlue])

        let filledStar = UIImage(systemName: "star.fill")
        let emptyStar = UIImage(systemName: "star")
        let highlightedStar = UIImage(systemName: "", withConfiguration: config)
        
        // создаем цикл для создания 5 кнопок
        for _ in 1...starCount {
            // создаем кнопку
            let button = UIButton()
            
            // настраиваем поведение кнопки
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(highlightedStar, for: [.highlighted, .selected])
            
            // добавляем Constraints
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            
            // добавляем кнопке действие
            button.addTarget(self, action: #selector(ratingButtonTapped(button: )), for: .touchUpInside)
            
            // добавляем кнопку в стэквью
            addArrangedSubview(button)
            
            // добавляем кнопку в массив
            ratingButtons.append(button)
            
        }
        
        updateButtonSelectionState()
    }
    
    // логика установки рейтинга
    private func updateButtonSelectionState() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
}
