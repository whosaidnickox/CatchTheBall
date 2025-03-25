//
//  RulesScene.swift
//  CatchTheBall
//
//  Created by Роман  on 17.03.2025.
//

import SpriteKit

class RulesScene: SKScene {
    
    private var backgroundNode: SKSpriteNode?
    private var titleLabel: SKLabelNode?
    private var rulesBackgroundNode: SKSpriteNode?
    private var backButton: SKSpriteNode?
    
    override func sceneDidLoad() {
        setupBackground()
        setupBackButton()
        setupTitle()
        setupRulesBackground()
        setupRulesText()
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
        title.text = "Rules"
        title.fontSize = min(frame.width * 0.08, 40)
        title.fontColor = .white
        title.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        title.zPosition = 3
        addChild(title)
        self.titleLabel = title
    }
    
    private func setupRulesBackground() {
        let rulesBackground = SKSpriteNode(imageNamed: "rules_background")
        
        // Устанавливаем размер фона в процентах от размера экрана
        // Увеличиваем ширину и высоту фона для лучшего соответствия тексту
        let maxWidth = frame.width * 1
        let maxHeight = frame.height * 0.7
        
        // Сохраняем пропорции фона
        let widthScale = maxWidth / rulesBackground.size.width
        let heightScale = maxHeight / rulesBackground.size.height
        let finalScale = min(widthScale, heightScale)
        
        rulesBackground.size = CGSize(width: rulesBackground.size.width * finalScale,
                                    height: rulesBackground.size.height * finalScale)
        
        // Располагаем фон в центре экрана
        rulesBackground.position = CGPoint(x: frame.midX, y: frame.height * 0.45)
        rulesBackground.zPosition = 1
        addChild(rulesBackground)
        self.rulesBackgroundNode = rulesBackground
    }
    
    private func setupRulesText() {
        // Создаем единый текст для отображения внутри фона
        if let background = rulesBackgroundNode {
            // Полный текст правил
            let rulesText = """
            THIS IS AN EXCITING GAME WITH PHYSICS ELEMENTS, CONSISTING OF 15 LEVELS. YOUR TASK IS TO DROP THE BALLS INTO THE APPROPRIATE CONTAINERS.
            ADJUST THE FORCE AND ANGLE OF THE THROW, THEN RELEASE, CHOOSING THE PERFECT MOMENT.
            THE WHITE BALLS SHOULD GO INTO THE WHITE CONTAINERS, AND THE PINK ONES SHOULD GO INTO THE PINK ONES.
            TO EARN 3 STARS, COMPLETE THE LEVEL USING THE MINIMUM AMOUNT OF TIME.
            """
            
            // Создаем текст внутри фона
            let textNode = SKLabelNode(fontNamed: "Helvetica-Bold")
            textNode.numberOfLines = 0
            textNode.preferredMaxLayoutWidth = background.size.width * 0.9
            textNode.horizontalAlignmentMode = .center
            textNode.verticalAlignmentMode = .center
            
            // Настраиваем размер шрифта для текста внутри фона
            let fontSize = min(frame.width * 0.03, 10)
            
            // Настраиваем стиль параграфа
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 13
            paragraphStyle.paragraphSpacing = 20
            
            textNode.attributedText = NSAttributedString(
                string: rulesText,
                attributes: [
                    NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold),
                    NSAttributedString.Key.foregroundColor: UIColor.white,
                    NSAttributedString.Key.strokeColor: UIColor.purple,
                    NSAttributedString.Key.strokeWidth: -1.0,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle
                ]
            )
            
            textNode.position = CGPoint.zero
            textNode.zPosition = 2
            
            let textContainer = SKNode()
            textContainer.position = background.position
            textContainer.addChild(textNode)
            addChild(textContainer)
        }
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "backButton" {
                handleBackButton()
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
}
