//
//  SettingsScene..swift
//  CatchTheBall
//
//  Created by Роман  on 18.03.2025.
//
import SpriteKit

class SettingsScene: SKScene {
    
    private var backgroundNode: SKSpriteNode?
    private var titleLabel: SKLabelNode?
    private var backButton: SKSpriteNode?
    private var soundButton: SKSpriteNode?
    private var clearDataButton: SKSpriteNode?
    private var soundLabel: SKLabelNode?
    private var clearDataLabel: SKLabelNode?
    
    // Флаг для отслеживания состояния звука
    private var isSoundOn = true
    
    // Диалоговое окно подтверждения очистки данных
    private var clearDataAlert: ClearDataAlertNode?
    
    override func sceneDidLoad() {
        // Загружаем сохраненное состояние звука
        isSoundOn = UserDefaults.standard.bool(forKey: "soundEnabled")
        
        setupBackground()
        setupBackButton()
        setupTitle()
        setupSettingsContainer()
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Масштабируем фон, чтобы он полностью покрывал экран
        let scale = max(frame.width / background.size.width,
                       frame.height / background.size.height)
        background.size = CGSize(width: background.size.width * scale,
                               height: background.size.height * scale)
        
        background.zPosition = -1
        addChild(background)
        self.backgroundNode = background
    }
    
    private func setupTitle() {
        let title = SKLabelNode(fontNamed: "Arial-Bold")
        title.text = "Settings"
        title.fontSize = min(frame.width * 0.08, 40)
        title.fontColor = .white
        title.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        title.zPosition = 3
        addChild(title)
        self.titleLabel = title
    }
    
    private func setupBackButton() {
        let backButton = SKSpriteNode(imageNamed: "back_button")
        let buttonWidth = frame.width * 0.08
        let scale = buttonWidth / backButton.size.width
        backButton.size = CGSize(width: buttonWidth, height: backButton.size.height * scale)
        backButton.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.85)
        backButton.name = "backButton"
        backButton.zPosition = 3
        addChild(backButton)
        self.backButton = backButton
    }
    
    private func setupSettingsContainer() {
        // Создаем контейнер для настроек
        let settingsContainer = SKNode()
        settingsContainer.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(settingsContainer)
        
        // Настраиваем кнопку звука
        setupSoundButton(in: settingsContainer)
        
        // Настраиваем кнопку очистки данных
        setupClearDataButton(in: settingsContainer)
    }
    
    private func setupSoundButton(in container: SKNode) {
        // Загружаем кнопку звука в зависимости от текущего состояния
        let buttonImageName = isSoundOn ? "sound_on" : "sound_off"
        let soundButton = SKSpriteNode(imageNamed: buttonImageName)
        
        // Настраиваем размер кнопки (уменьшаем до 20% от ширины экрана)
        let buttonWidth = frame.width * 0.2
        let scale = buttonWidth / soundButton.size.width
        soundButton.size = CGSize(width: buttonWidth, height: soundButton.size.height * scale)
        
        // Располагаем кнопку в верхней части контейнера
        soundButton.position = CGPoint(x: 0, y: frame.height * 0.1)
        soundButton.name = "soundButton"
        soundButton.zPosition = 2
        
        container.addChild(soundButton)
        self.soundButton = soundButton
        
        // Добавляем текст под кнопкой
        let soundLabel = SKLabelNode(fontNamed: "Arial-Bold")
        soundLabel.text = "SOUND"
        soundLabel.fontSize = min(frame.width * 0.04, 18)
        soundLabel.fontColor = .white
        soundLabel.position = CGPoint(x: 0, y: soundButton.position.y - soundButton.size.height/2 - 20)
        soundLabel.zPosition = 2
        
        container.addChild(soundLabel)
        self.soundLabel = soundLabel
    }
    
    private func setupClearDataButton(in container: SKNode) {
        // Загружаем кнопку очистки данных
        let clearDataButton = SKSpriteNode(imageNamed: "clear_data")
        
        // Настраиваем размер кнопки (уменьшаем до 20% от ширины экрана)
        let buttonWidth = frame.width * 0.2
        let scale = buttonWidth / clearDataButton.size.width
        clearDataButton.size = CGSize(width: buttonWidth, height: clearDataButton.size.height * scale)
        
        // Располагаем кнопку под кнопкой звука
        if let soundButton = self.soundButton {
            clearDataButton.position = CGPoint(x: 0, y: soundButton.position.y - soundButton.size.height - 20)
        } else {
            clearDataButton.position = CGPoint(x: 0, y: 0)
        }
        
        clearDataButton.name = "clearDataButton"
        clearDataButton.zPosition = 2
        
        container.addChild(clearDataButton)
        self.clearDataButton = clearDataButton
        
        // Добавляем текст под кнопкой
        let clearDataLabel = SKLabelNode(fontNamed: "Arial-Bold")
       // clearDataLabel.text = "CLEAR DATA"
        clearDataLabel.fontSize = min(frame.width * 0.04, 18)
        clearDataLabel.fontColor = .white
        clearDataLabel.position = CGPoint(x: 0, y: clearDataButton.position.y - clearDataButton.size.height/2 - 10)
        clearDataLabel.zPosition = 2
        
        container.addChild(clearDataLabel)
        self.clearDataLabel = clearDataLabel
    }
    
    // Метод для переключения состояния звука
    private func toggleSound() {
        isSoundOn.toggle()
        
        // Обновляем изображение кнопки
        let buttonImageName = isSoundOn ? "sound_on" : "sound_off"
        let texture = SKTexture(imageNamed: buttonImageName)
        soundButton?.texture = texture
        
        // Анимация нажатия
        soundButton?.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        // Сохраняем настройку в UserDefaults
        UserDefaults.standard.set(isSoundOn, forKey: "soundEnabled")
    }
    
    // Метод для показа диалогового окна подтверждения очистки данных
    private func showClearDataConfirmation() {
        // Анимация нажатия кнопки
        clearDataButton?.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        // Создаем и настраиваем диалоговое окно
        let alert = ClearDataAlertNode(size: self.size)
        alert.zPosition = 100 // Поверх всех других элементов
        
        // Настраиваем обработчики нажатия кнопок
        alert.onBackButtonPressed = { [weak self] in
            self?.dismissClearDataAlert()
        }
        
        alert.onYesButtonPressed = { [weak self] in
            self?.performClearData()
            self?.dismissClearDataAlert()
        }
        
        // Добавляем и показываем диалоговое окно
        addChild(alert)
        alert.show()
        
        // Сохраняем ссылку на диалоговое окно
        self.clearDataAlert = alert
    }
    
    // Метод для скрытия диалогового окна
    private func dismissClearDataAlert() {
        clearDataAlert?.hide {
            self.clearDataAlert = nil
        }
    }
    
    // Метод для фактической очистки данных
    private func performClearData() {
        // Сбрасываем все данные об уровнях
        for i in 0...10 {
            UserDefaults.standard.removeObject(forKey: "level_\(i)_stars")
        }
        
        // Устанавливаем разблокированным только первый уровень
        UserDefaults.standard.set(1, forKey: "unlockedLevels")
        
        // Принудительно синхронизируем изменения
        UserDefaults.standard.synchronize()
        
        // Показываем подтверждение очистки данных
        let confirmLabel = SKLabelNode(fontNamed: "Arial-Bold")
        confirmLabel.text = "Данные очищены!"
        confirmLabel.fontSize = min(frame.width * 0.04, 18)
        confirmLabel.fontColor = .green
        
        // Позиционируем сообщение под кнопкой очистки данных
        if let clearDataButton = self.clearDataButton {
            confirmLabel.position = CGPoint(x: clearDataButton.position.x,
                                         y: clearDataButton.position.y - clearDataButton.size.height)
        } else {
            confirmLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.2)
        }
        
        confirmLabel.zPosition = 3
        addChild(confirmLabel)
        
        // Удаляем сообщение через 2 секунды
        confirmLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Если открыто диалоговое окно, передаем ему обработку нажатия
        if let alert = clearDataAlert {
            alert.handleTouch(at: location)
            return
        }
        
        // Иначе обрабатываем нажатия на основные элементы
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "backButton" {
                handleBackButton()
                break
            } else if node.name == "soundButton" {
                toggleSound()
                break
            } else if node.name == "clearDataButton" {
                showClearDataConfirmation()
                break
            }
        }
    }
    
    private func handleBackButton() {
        // Анимация нажатия
        backButton?.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        // Переход обратно в главное меню
        let mainMenu = MainMenuScene(size: self.size)
        mainMenu.scaleMode = .resizeFill
        
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(mainMenu, transition: transition)
    }
    
    // Метод для адаптации интерфейса при изменении размера экрана
    override func didChangeSize(_ oldSize: CGSize) {
        // Обновляем позиции элементов при изменении размера экрана
        setupBackground()
        
        // Обновляем позицию заголовка
        titleLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        
        // Обновляем позицию кнопки назад
        backButton?.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.85)
        
        // Обновляем размеры и позиции кнопок
        if let soundButton = self.soundButton {
            // Обновляем размер кнопки звука
            let soundButtonWidth = frame.width * 0.2
            let soundScale = soundButtonWidth / soundButton.size.width
            soundButton.size = CGSize(width: soundButtonWidth, height: soundButton.size.height * soundScale)
            soundButton.position = CGPoint(x: 0, y: frame.height * 0.1)
        }
        
        if let soundLabel = self.soundLabel, let soundButton = self.soundButton {
            soundLabel.position = CGPoint(x: 0, y: soundButton.position.y - soundButton.size.height/2 - 20)
        }
        
        if let clearDataButton = self.clearDataButton, let soundButton = self.soundButton {
            // Обновляем размер кнопки очистки данных
            let clearDataButtonWidth = frame.width * 0.2
            let clearDataScale = clearDataButtonWidth / clearDataButton.size.width
            clearDataButton.size = CGSize(width: clearDataButtonWidth, height: clearDataButton.size.height * clearDataScale)
            clearDataButton.position = CGPoint(x: 0, y: soundButton.position.y - soundButton.size.height - 20)
        }
        
        if let clearDataLabel = self.clearDataLabel, let clearDataButton = self.clearDataButton {
            clearDataLabel.position = CGPoint(x: 0, y: clearDataButton.position.y - clearDataButton.size.height/2 - 10)
        }
    }
}
