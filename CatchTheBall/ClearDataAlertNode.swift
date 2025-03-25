import SpriteKit

class ClearDataAlertNode: SKNode {
    
    // Callback для обработки нажатия кнопок
    var onBackButtonPressed: (() -> Void)?
    var onYesButtonPressed: (() -> Void)?
    
    // Основные элементы диалогового окна
    private var backgroundNode: SKSpriteNode?
    private var titleLabel: SKLabelNode?
    private var messageLabel: SKLabelNode?
    private var backButton: SKSpriteNode?
    private var yesButton: SKSpriteNode?
    
    // Инициализация с размером экрана
    init(size: CGSize) {
        super.init()
        setup(with: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(with size: CGSize) {
        // Создаем полупрозрачный фон на весь экран
        let overlay = SKSpriteNode(color: .black, size: size)
        overlay.alpha = 0.7
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.zPosition = 10
        addChild(overlay)
        
        // Создаем кастомный фон для диалогового окна на весь экран
        let background = SKSpriteNode(imageNamed: "alert_background")
        background.size = size
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = 11
        addChild(background)
        self.backgroundNode = background
        
        // Создаем заголовок
        let title = SKLabelNode(fontNamed: "Arial-Bold")
        title.text = "Clear data?"
        title.fontSize = min(size.width * 0.08, 40)
        title.fontColor = .white
        title.position = CGPoint(x: size.width/2, y: size.height/2 + size.height * 0.15)
        title.zPosition = 12
        addChild(title)
        self.titleLabel = title
        
        // Создаем текст сообщения
        let message = SKLabelNode(fontNamed: "Arial-Bold")
        message.text = "DO YOU WANT TO CLEAR\nYOUR SAVED GAME?"
        message.numberOfLines = 2
        message.fontSize = min(size.width * 0.05, 24)
        message.fontColor = .white
        message.position = CGPoint(x: size.width/2, y: size.height/2 - size.height * 0.05)
        message.zPosition = 12
        addChild(message)
        self.messageLabel = message
        
        // Создаем кнопки
        setupButtons(with: size)
    }
    
    private func setupButtons(with size: CGSize) {
        // Кнопка "BACK"
        let backButton = SKSpriteNode(imageNamed: "back_button_alert")
        let buttonWidth = size.width * 0.2 // Уменьшаем размер кнопок еще больше
        let backScale = buttonWidth / backButton.size.width
        backButton.size = CGSize(width: buttonWidth, height: backButton.size.height * backScale)
        backButton.position = CGPoint(x: size.width/2 - buttonWidth * 0.6, y: size.height/2 - size.height * 0.22)
        backButton.name = "backButton"
        backButton.zPosition = 12
        addChild(backButton)
        self.backButton = backButton
        
        // Добавляем текст "BACK" на кнопку
        let backLabel = SKLabelNode(fontNamed: "Arial-Bold")
       // backLabel.text = "BACK"
        backLabel.fontSize = min(size.width * 0.03, 16)
        backLabel.fontColor = .white
        backLabel.position = CGPoint(x: backButton.position.x, y: backButton.position.y - backButton.size.height * 0.05)
        backLabel.zPosition = 13
        addChild(backLabel)
        
        // Кнопка "YES"
        let yesButton = SKSpriteNode(imageNamed: "yes_button_alert")
        let yesScale = buttonWidth / yesButton.size.width
        yesButton.size = CGSize(width: buttonWidth, height: yesButton.size.height * yesScale)
        yesButton.position = CGPoint(x: size.width/2 + buttonWidth * 0.6, y: size.height/2 - size.height * 0.22)
        yesButton.name = "yesButton"
        yesButton.zPosition = 12
        addChild(yesButton)
        self.yesButton = yesButton
        
        // Добавляем текст "YES" на кнопку
        let yesLabel = SKLabelNode(fontNamed: "Arial-Bold")
      //  yesLabel.text = "YES"
        yesLabel.fontSize = min(size.width * 0.03, 16)
        yesLabel.fontColor = .white
        yesLabel.position = CGPoint(x: yesButton.position.x, y: yesButton.position.y - yesButton.size.height * 0.05)
        yesLabel.zPosition = 13
        addChild(yesLabel)
    }
    
    // Обработка нажатий на кнопки
    func handleTouch(at location: CGPoint) {
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "backButton" {
                animateButton(backButton)
                onBackButtonPressed?()
                break
            } else if node.name == "yesButton" {
                animateButton(yesButton)
                onYesButtonPressed?()
                break
            }
        }
    }
    
    // Анимация нажатия кнопки
    private func animateButton(_ button: SKSpriteNode?) {
        button?.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }
    
    // Анимация появления диалогового окна
    func show() {
        self.alpha = 0
        self.run(SKAction.fadeIn(withDuration: 0.3))
    }
    
    // Анимация скрытия диалогового окна
    func hide(completion: @escaping () -> Void) {
        self.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.run {
                completion()
                self.removeFromParent()
            }
        ]))
    }
}
