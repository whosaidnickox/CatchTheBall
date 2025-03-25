import SpriteKit

class LevelsScene: SKScene {
    
    // MARK: - Свойства
    private var backgroundNode: SKSpriteNode?
    private var titleLabel: SKLabelNode?
    private var backButton: SKSpriteNode?
    
    // Контейнер для страниц с уровнями
    private var pagesContainer: SKNode?
    private var currentPage = 0
    private let totalPages = 3 // 15 уровней по 6 на странице = 3 страницы (было 5 на странице)
    
    // Массив для хранения кнопок уровней
    private var levelButtons: [SKSpriteNode] = []
    
    // Массив для хранения звездочек для каждого уровня
    private var levelStars: [[SKSpriteNode]] = []
    
    // Начальная точка касания для определения свайпа
    private var touchStartLocation: CGPoint?
    
    // MARK: - Жизненный цикл
    override func sceneDidLoad() {
        setupBackground()
        setupBackButton()
        setupTitle()
        setupPagesContainer()
        loadLevelsProgress()
    }
    
    // MARK: - Настройка UI
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
        title.text = "Levels"
        title.fontSize = min(frame.width * 0.08, 40)
        title.fontColor = .white
        title.position = CGPoint(x: frame.midX, y: frame.height * 0.90)
        title.zPosition = 3
        
        // Добавляем обводку для лучшей видимости
        let strokeAction = SKAction.customAction(withDuration: 0) { node, _ in
            if let label = node as? SKLabelNode {
                let shadow = SKLabelNode(fontNamed: label.fontName)
                shadow.text = label.text
                shadow.fontSize = label.fontSize
                shadow.fontColor = .purple
                shadow.position = CGPoint(x: 2, y: -2)
                shadow.zPosition = -1
                label.addChild(shadow)
            }
        }
        title.run(strokeAction)
        
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
    
    private func setupPagesContainer() {
        // Очищаем существующие кнопки и звезды
        levelButtons.removeAll()
        levelStars.removeAll()
        
        // Удаляем существующий контейнер, если он есть
        pagesContainer?.removeFromParent()
        
        // Создаем контейнер для страниц
        let container = SKNode()
        container.position = CGPoint(x: 0, y: 0)
        container.zPosition = 1
        addChild(container)
        self.pagesContainer = container
        
        // Создаем страницы с уровнями
        for pageIndex in 0..<totalPages {
            let page = createLevelsPage(pageIndex: pageIndex)
            page.position = CGPoint(x: frame.midX + CGFloat(pageIndex) * frame.width, y: frame.midY)
            container.addChild(page)
        }
        
        // Устанавливаем начальную страницу
        showPage(pageIndex: 0, animated: false)
    }
    
    private func createLevelsPage(pageIndex: Int) -> SKNode {
        let page = SKNode()
        page.name = "page_\(pageIndex)"
        
        // Количество уровней на странице
        let levelsPerPage = 6 // Увеличиваем до 6 уровней на странице
        
        // Начальный индекс уровня для этой страницы
        let startLevelIndex = pageIndex * levelsPerPage
        
        // Количество уровней в строке и столбце
        let levelsPerRow = 3 // 3 уровня в ряду
        let levelsPerColumn = 2 // 2 ряда (верхний и нижний)
        
        // Размер кнопки уровня (уменьшаем с 18% до 15% от ширины экрана)
        let buttonSize = frame.width * 0.15
        
        // Отступы между кнопками (уменьшаем отступы)
        let horizontalSpacing = frame.width * 0.04
        let verticalSpacing = frame.height * 0.04 // Уменьшаем вертикальный отступ с 0.12 до 0.08
        
        // Вычисляем общую ширину и высоту сетки
        let gridWidth = CGFloat(levelsPerRow) * buttonSize + CGFloat(levelsPerRow - 1) * horizontalSpacing
        let gridHeight = CGFloat(levelsPerColumn) * buttonSize + CGFloat(levelsPerColumn - 1) * verticalSpacing
        
        // Начальная позиция для первой кнопки (верхний левый угол сетки)
        let startX = -gridWidth / 2 + buttonSize / 2
        let startY = gridHeight / 2 - buttonSize / 2
        
        // Создаем кнопки уровней для этой страницы
        for i in 0..<levelsPerPage {
            let levelIndex = startLevelIndex + i
            
            // Проверяем, не превышает ли индекс общее количество уровней
            if levelIndex < 15 {
                // Вычисляем позицию кнопки в сетке
                let row = i / levelsPerRow
                let col = i % levelsPerRow
                
                let xPos = startX + CGFloat(col) * (buttonSize + horizontalSpacing)
                let yPos = startY - CGFloat(row) * (buttonSize + verticalSpacing)
                
                // Создаем кнопку уровня
                createLevelButton(levelIndex: levelIndex, position: CGPoint(x: xPos, y: yPos), size: buttonSize, parent: page)
            }
        }
        
        return page
    }
    
    private func createLevelButton(levelIndex: Int, position: CGPoint, size: CGFloat, parent: SKNode) {
        // Определяем, разблокирован ли уровень
        let isUnlocked = isLevelUnlocked(levelIndex)
        
        // Выбираем изображение в зависимости от состояния уровня
        let imageName = isUnlocked ? "level_button_unlocked" : "level_button_locked"
        let levelButton = SKSpriteNode(imageNamed: imageName)
        
        // Настраиваем размер кнопки
        levelButton.size = CGSize(width: size, height: size)
        levelButton.position = position
        levelButton.name = "level_\(levelIndex)"
        levelButton.zPosition = 2
        
        // Добавляем текстовую метку с номером уровня вместо кастомного изображения
        if isUnlocked {
            // Для разблокированных уровней используем текстовую метку
            let levelLabel = SKLabelNode(fontNamed: "Arial-Bold")
            levelLabel.text = "\(levelIndex + 1)"
            levelLabel.fontSize = size * 0.4
            levelLabel.fontColor = .white
            levelLabel.verticalAlignmentMode = .center
            levelLabel.horizontalAlignmentMode = .center
            levelLabel.position = CGPoint(x: 0, y: 0)
            levelLabel.zPosition = 3
            
            levelButton.addChild(levelLabel)
            
            // Добавляем звездочки
            addStarsToButton(levelButton: levelButton, levelIndex: levelIndex, buttonSize: size)
            
            // Добавляем анимацию пульсации для доступных уровней
            let pulseAction = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            levelButton.run(SKAction.repeatForever(pulseAction))
        } else {
            // Для заблокированных уровней можно оставить замок или добавить затемненную версию цифры
            // Здесь мы просто добавляем замок, который уже должен быть частью изображения level_button_locked
        }
        
        parent.addChild(levelButton)
        levelButtons.append(levelButton)
    }
    
    private func addStarsToButton(levelButton: SKSpriteNode, levelIndex: Int, buttonSize: CGFloat) {
        // Получаем количество звезд для уровня (0-3)
        let starsCount = getStarsForLevel(levelIndex)
        
        // Размер звездочки (уменьшаем с 25% до 22% от размера кнопки)
        let starSize = buttonSize * 0.22
        
        // Создаем массив для хранения звездочек этого уровня
        var starsForLevel: [SKSpriteNode] = []
        
        // Добавляем звездочки
        for i in 0..<3 {
            let starImageName = i < starsCount ? "star_filled" : "star_empty"
            let star = SKSpriteNode(imageNamed: starImageName)
            star.size = CGSize(width: starSize, height: starSize)
            
            // Располагаем звездочки в ряд внизу кнопки (уменьшаем отступ между звездами)
            let xPos = CGFloat(i - 1) * starSize * 1.0
            let yPos = -levelButton.size.height * 0.35
            
            star.position = CGPoint(x: xPos, y: yPos)
            star.zPosition = 3
            levelButton.addChild(star)
            
            starsForLevel.append(star)
        }
        
        levelStars.append(starsForLevel)
    }
    
    // MARK: - Навигация по страницам
    private func showPage(pageIndex: Int, animated: Bool) {
        guard let container = pagesContainer else { return }
        
        // Проверяем, что индекс страницы в допустимом диапазоне
        let safePageIndex = max(0, min(pageIndex, totalPages - 1))
        
        // Вычисляем новую позицию контейнера
        let newX = -CGFloat(safePageIndex) * frame.width
        
        // Обновляем текущую страницу
        currentPage = safePageIndex
        
        if animated {
            // Анимируем переход
            let moveAction = SKAction.moveTo(x: newX, duration: 0.3)
            moveAction.timingMode = .easeInEaseOut
            container.run(moveAction)
        } else {
            // Мгновенно перемещаем контейнер
            container.position = CGPoint(x: newX, y: container.position.y)
        }
        
        // Добавляем индикаторы страниц (маленькие точки внизу экрана)
        updatePageIndicators()
    }
    
    private func updatePageIndicators() {
        // Удаляем существующие индикаторы
        self.children.filter { $0.name?.starts(with: "pageIndicator") ?? false }.forEach { $0.removeFromParent() }
        
        // Размер и отступ для индикаторов
        let indicatorSize: CGFloat = 10
        let spacing: CGFloat = 15
        
        // Вычисляем общую ширину всех индикаторов
        let totalWidth = CGFloat(totalPages) * indicatorSize + CGFloat(totalPages - 1) * spacing
        
        // Начальная позиция X для первого индикатора
        let startX = frame.midX - totalWidth / 2 + indicatorSize / 2
        
        // Создаем индикаторы для каждой страницы
        for i in 0..<totalPages {
            let indicator = SKShapeNode(circleOfRadius: indicatorSize / 2)
            // Размещаем индикаторы ниже, чтобы они не перекрывались с кнопками уровней
            indicator.position = CGPoint(x: startX + CGFloat(i) * (indicatorSize + spacing), y: frame.height * 0.08)
            indicator.fillColor = i == currentPage ? .white : .gray
            indicator.strokeColor = .clear
            indicator.name = "pageIndicator_\(i)"
            indicator.zPosition = 5
            addChild(indicator)
        }
    }
    
    // MARK: - Обработка касаний
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Сохраняем начальную точку касания для определения свайпа
        touchStartLocation = location
        
        // Проверяем нажатие на кнопку "Назад"
        let touchedNodes = nodes(at: location)
        for node in touchedNodes {
            if node.name == "backButton" {
                handleBackButton()
                return
            }
        }
        
        // Проверяем нажатие на кнопки уровней
        for (index, button) in levelButtons.enumerated() {
            if button.contains(touch.location(in: button.parent!)) && isLevelUnlocked(index) {
                handleLevelSelection(levelIndex: index)
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, 
              let startLocation = touchStartLocation,
              let container = pagesContainer else { return }
        
        let currentLocation = touch.location(in: self)
        let deltaX = currentLocation.x - startLocation.x
        
        // Обновляем позицию контейнера в реальном времени для эффекта перетаскивания
        let newX = container.position.x + deltaX
        
        // Ограничиваем перетаскивание, чтобы не уйти за пределы страниц
        let minX = -frame.width * CGFloat(totalPages - 1)
        let maxX = 0.0
        
        let clampedX = max(minX, min(maxX, newX))
        container.position = CGPoint(x: clampedX, y: container.position.y)
        
        // Обновляем начальную точку для следующего движения
        touchStartLocation = currentLocation
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, 
              let startLocation = touchStartLocation,
              let container = pagesContainer else { return }
        
        let endLocation = touch.location(in: self)
        
        // Вычисляем расстояние свайпа по горизонтали
        let swipeDistance = endLocation.x - startLocation.x
        
        // Определяем текущую позицию в терминах страниц
        let currentPositionInPages = -container.position.x / frame.width
        
        // Определяем, к какой странице перейти
        var targetPage = currentPage
        
        if abs(swipeDistance) > frame.width * 0.2 {
            // Если свайп достаточно длинный, переходим к следующей/предыдущей странице
            if swipeDistance > 0 && currentPage > 0 {
                // Свайп вправо - предыдущая страница
                targetPage = currentPage - 1
            } else if swipeDistance < 0 && currentPage < totalPages - 1 {
                // Свайп влево - следующая страница
                targetPage = currentPage + 1
            }
        } else {
            // Если свайп короткий, определяем ближайшую страницу
            targetPage = Int(round(currentPositionInPages))
            targetPage = max(0, min(totalPages - 1, targetPage))
        }
        
        // Переходим к целевой странице с анимацией
        showPage(pageIndex: targetPage, animated: true)
        
        // Сбрасываем начальную точку касания
        touchStartLocation = nil
    }
    
    // MARK: - Обработчики событий
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
    
    private func handleLevelSelection(levelIndex: Int) {
        // Анимация нажатия
        if levelIndex < levelButtons.count {
            levelButtons[levelIndex].run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
        
        // Переход к выбранному уровню
        print("Выбран уровень \(levelIndex + 1)")
        
        // Создаем игровую сцену с выбранным уровнем
        let gameScene = GameScene(size: self.size, level: levelIndex + 1)
        gameScene.scaleMode = .resizeFill
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(gameScene, transition: transition)
    }
    
    // MARK: - Логика уровней
    private func isLevelUnlocked(_ levelIndex: Int) -> Bool {
        // Первый уровень всегда разблокирован
        if levelIndex == 0 {
            return true
        }
        
        // Получаем информацию о разблокированных уровнях из UserDefaults
        let unlockedLevels = UserDefaults.standard.integer(forKey: "unlockedLevels")
        return levelIndex < unlockedLevels
    }
    
    private func getStarsForLevel(_ levelIndex: Int) -> Int {
        // Получаем количество звезд для уровня из UserDefaults
        let key = "level_\(levelIndex)_stars"
        return UserDefaults.standard.integer(forKey: key)
    }
    
    private func loadLevelsProgress() {
        // Если нет сохраненного прогресса, разблокируем первые 3 уровня для демонстрации
        if UserDefaults.standard.integer(forKey: "unlockedLevels") == 0 {
            UserDefaults.standard.set(6, forKey: "unlockedLevels") // Увеличиваем до 6 уровней
            
            // Устанавливаем звезды для первых шести уровней
            UserDefaults.standard.set(3, forKey: "level_0_stars") // 3 звезды для уровня 1
            UserDefaults.standard.set(3, forKey: "level_1_stars") // 3 звезды для уровня 2
            UserDefaults.standard.set(2, forKey: "level_2_stars") // 2 звезды для уровня 3
            UserDefaults.standard.set(2, forKey: "level_3_stars") // 2 звезды для уровня 4
            UserDefaults.standard.set(1, forKey: "level_4_stars") // 1 звезда для уровня 5
            UserDefaults.standard.set(1, forKey: "level_5_stars") // 1 звезда для уровня 6
        }
    }
    
    // MARK: - Адаптивный дизайн
    override func didChangeSize(_ oldSize: CGSize) {
        // Обновляем позиции элементов при изменении размера экрана
        setupBackground()
        
        // Обновляем позицию заголовка
        titleLabel?.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        
        // Обновляем позицию кнопки назад
        backButton?.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.85)
        
        // Пересоздаем страницы с уровнями
        setupPagesContainer()
        
        // Показываем текущую страницу
        showPage(pageIndex: currentPage, animated: false)
        
        // Обновляем индикаторы страниц
        updatePageIndicators()
    }
} 
