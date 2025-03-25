//
//  GameScene.swift
//  CatchTheBall
//
//  Created by Роман  on 17.03.2025.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Категории физических тел
    struct PhysicsCategory {
                static let none      : UInt32 = 0
                static let ball      : UInt32 = 0b1        // 1
                static let container : UInt32 = 0b10       // 2
                static let platform  : UInt32 = 0b100      // 4
                static let wall      : UInt32 = 0b1000     // 8
                static let box       : UInt32 = 0b10000    // 16
                static let edge      : UInt32 = 0b100000   // 32
                static let all       : UInt32 = UInt32.max
            }
            
            // MARK: - Свойства
            // Уровень
            private var currentLevel: Int = 1
            
            // UI элементы
            private var backButton: SKSpriteNode?
            private var restartButton: SKSpriteNode?
            private var timerBackground: SKSpriteNode?
            private var timerLabel: SKLabelNode?
            
            // Игровые объекты
            private var balls: [SKSpriteNode] = []
            private var containers: [SKSpriteNode] = []
            private var currentBall: SKSpriteNode?
            private var launcher: SKSpriteNode?
            private var isGameOver: Bool = false // Добавляем флаг окончания игры
            
            // Управление
            private var touchStartLocation: CGPoint?
            private var touchEndLocation: CGPoint?
            private var aimLine: SKShapeNode?
            private var isAiming: Bool = false
            
            // Таймер
            private var gameTime: TimeInterval = 0
            private var levelTimeLimit: TimeInterval = 90 // 1:30 (90 секунд) на уровень
            private var lastUpdateTime: TimeInterval = 0
            private var timerActive: Bool = false
            
            // MARK: - Инициализация
            init(size: CGSize, level: Int) {
                self.currentLevel = level
                super.init(size: size)
            }
            
            required init?(coder aDecoder: NSCoder) {
                super.init(coder: aDecoder)
            }
            
            // MARK: - Жизненный цикл
            override func sceneDidLoad() {
                setupPhysics()
                setupUI()
                loadLevel(level: currentLevel)
            }
            
            // MARK: - Настройка сцены
            private func setupPhysics() {
                physicsWorld.gravity = CGVector(dx: 0, dy: -5.0) // Уменьшаем гравитацию для более высоких прыжков
                physicsWorld.contactDelegate = self
                
                // Создаем границы экрана
                let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
                borderBody.friction = 0.3
                borderBody.restitution = 0.8 // Увеличиваем отскок от стен
                borderBody.categoryBitMask = PhysicsCategory.wall
                borderBody.collisionBitMask = PhysicsCategory.all
                self.physicsBody = borderBody
            }
            
            private func setupUI() {
                // Фон
                let background = SKSpriteNode(imageNamed: "background")
                background.position = CGPoint(x: frame.midX, y: frame.midY)
                
                // Масштабируем фон, чтобы он полностью покрывал экран
                let scale = max(frame.width / background.size.width,
                               frame.height / background.size.height)
                background.size = CGSize(width: background.size.width * scale,
                                       height: background.size.height * scale)
                
                background.zPosition = -1
                addChild(background)
                
                // Кнопка "Назад"
                let backButton = SKSpriteNode(imageNamed: "back_button")
                let buttonWidth = frame.width * 0.08
                let scale2 = buttonWidth / backButton.size.width
                backButton.size = CGSize(width: buttonWidth, height: backButton.size.height * scale2)
                backButton.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.9)
                backButton.name = "backButton"
                backButton.zPosition = 10
                addChild(backButton)
                self.backButton = backButton
                
                // Кнопка "Перезапуск" (используем кастомное изображение)
                let restartButton = SKSpriteNode(imageNamed: "restart_button")
                restartButton.size = backButton.size
                restartButton.position = CGPoint(x: frame.width * 0.9, y: frame.height * 0.9)
                restartButton.name = "restartButton"
                restartButton.zPosition = 10
                addChild(restartButton)
                self.restartButton = restartButton
                
                // Кастомный таймер с фоном
                let timerBackground = SKSpriteNode(imageNamed: "timer_background")
                let timerWidth = frame.width * 0.15
                let timerScale = timerWidth / timerBackground.size.width
                timerBackground.size = CGSize(width: timerWidth, height: timerBackground.size.height * timerScale)
                timerBackground.position = CGPoint(x: frame.width * 0.5, y: frame.height * 0.9) // Возвращаем по центру
                timerBackground.zPosition = 9
                addChild(timerBackground)
                self.timerBackground = timerBackground
                
                // Текст таймера
                let timerLabel = SKLabelNode(fontNamed: "Arial-Bold")
                timerLabel.text = "1:30"
                timerLabel.fontSize = min(frame.width * 0.04, 20)
                timerLabel.fontColor = .white
                timerLabel.verticalAlignmentMode = .center
                timerLabel.horizontalAlignmentMode = .center
                timerLabel.position = CGPoint(x: timerWidth * 0.1, y: 0) // Сдвигаем текст немного правее внутри фона
                timerLabel.zPosition = 10
                timerBackground.addChild(timerLabel)
                self.timerLabel = timerLabel
                
                // Линия прицеливания
                let aimLine = SKShapeNode()
                aimLine.strokeColor = .white
                aimLine.lineWidth = 2
                aimLine.zPosition = 5
                aimLine.isHidden = true
                addChild(aimLine)
                self.aimLine = aimLine
                
                // Пусковая установка
                let launcher = SKSpriteNode(color: .gray, size: CGSize(width: frame.width * 0.1, height: frame.height * 0.02))
                launcher.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.2)
                launcher.zPosition = 2
                addChild(launcher)
                self.launcher = launcher
            }
            
            private func loadSounds() {
                // Функция оставлена пустой для будущей реализации
            }
            
            // MARK: - Загрузка уровня
            private func loadLevel(level: Int) {
                // Очищаем предыдущий уровень
                clearLevel()
                
                // Устанавливаем параметры уровня
                switch level {
                case 1:
                    setupLevel1()
                case 2:
                    setupLevel2()
                case 3:
                    setupLevel3()
                case 4:
                    setupLevel4()
                case 5:
                    setupLevel5()
                case 6:
                    setupLevel6()
                case 7:
                    setupLevel7()
                case 8:
                    setupLevel8()
                case 9:
                    setupLevel9()
                case 10:
                    setupLevel10()
                case 11:
                    setupLevel11()
                case 12:
                    setupLevel12()
                case 13:
                    setupLevel13()
                case 14:
                    setupLevel14()
                case 15:
                    setupLevel15()
                default:
                    setupLevel1()
                }
                
                // Запускаем таймер
                gameTime = 0
                timerActive = true
            }
            
            private func clearLevel() {
                // Удаляем все шарики
                for ball in balls {
                    ball.removeFromParent()
                }
                balls.removeAll()
                
                // Удаляем все контейнеры
                for container in containers {
                    container.removeFromParent()
                }
                containers.removeAll()
                
                // Удаляем текущий шарик
                currentBall?.removeFromParent()
                currentBall = nil
                
                // Сбрасываем состояние игры
                isAiming = false
                aimLine?.isHidden = true
            }
            
            // MARK: - Настройка уровней
            private func setupLevel1() {
                // Создаем U-образный контейнер (красный)
                let container = createContainer(color: .red, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.2))
                containers.append(container)
                
                // Создаем платформу-основание (розовую)
                let platformColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0) // Розовый цвет
                createPlatform(
                    size: CGSize(width: frame.width, height: frame.height * 0.02),
                    position: CGPoint(x: frame.width * 0.5, y: frame.height * 0.1),
                    rotation: 0,
                    color: platformColor
                )
                
                // Создаем мяч и размещаем его прямо на сером лаунчере
                let ball = createBall(color: .red)
                ball.position = CGPoint(x: launcher!.position.x, y: launcher!.position.y + ball.size.height/2)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel2() {
                // Создаем U-образный контейнер (розовый)
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.3))
                containers.append(container)
                
                // Создаем большую розовую стену с закругленными углами
                let wallSize = CGSize(width: frame.width * 0.1, height: frame.height * 0.5)
                let wallPosition = CGPoint(x: frame.midX, y: frame.height * 0.25)
                let wallPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize), cornerRadius: wallSize.width / 2)
                let wall = SKShapeNode(path: wallPath.cgPath)
                wall.fillColor = pinkColor
                wall.position = wallPosition
                wall.zRotation = 0.0 // Убираем наклон
                wall.zPosition = 2
                wall.name = "custom_wall"
                
                // Настраиваем физику для закругленной стены
                let physicsBody = SKPhysicsBody(polygonFrom: wallPath.cgPath)
                physicsBody.isDynamic = false
                physicsBody.categoryBitMask = PhysicsCategory.wall
                physicsBody.contactTestBitMask = PhysicsCategory.ball
                physicsBody.collisionBitMask = PhysicsCategory.all
                physicsBody.restitution = 0.5
                physicsBody.friction = 0.3
                wall.physicsBody = physicsBody
                
                addChild(wall)
                
                // Создаем платформу-основание
                createPlatform(
                    size: CGSize(width: frame.width, height: frame.height * 0.02),
                    position: CGPoint(x: frame.width * 0.5, y: frame.height * 0.1),
                    rotation: 0,
                    color: pinkColor
                )
                
                // Создаем мяч (розовый)
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.15)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel3() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                // Создаем U-образный контейнер (розовый)
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.15, y: frame.height * 0.2))
                containers.append(container)
                
                // Создаем L-образную фигуру
                let customShapePath = UIBezierPath()
                
                // Размеры для L-образной фигуры
                let verticalWidth = frame.width * 0.15
                let verticalHeight = frame.height * 0.6
                let horizontalWidth = frame.width * 0.4
                let horizontalHeight = frame.height * 0.15
                
                // Создаем L-образную форму
                customShapePath.move(to: CGPoint(x: 0, y: 0)) // Начало в нижнем левом углу
                customShapePath.addLine(to: CGPoint(x: horizontalWidth, y: 0)) // Горизонтальная часть
                customShapePath.addLine(to: CGPoint(x: horizontalWidth, y: horizontalHeight)) // Правый край горизонтальной части
                customShapePath.addLine(to: CGPoint(x: verticalWidth, y: horizontalHeight)) // К вертикальной части
                customShapePath.addLine(to: CGPoint(x: verticalWidth, y: verticalHeight)) // Вертикальная часть
                customShapePath.addLine(to: CGPoint(x: 0, y: verticalHeight)) // Верхняя часть
                customShapePath.close() // Замыкаем форму
                
                let customShape = SKShapeNode(path: customShapePath.cgPath)
                customShape.fillColor = pinkColor
                customShape.strokeColor = pinkColor
                customShape.position = CGPoint(x: frame.width * 0.6, y: frame.height * 0.2)
                customShape.zPosition = 2
                customShape.name = "custom_shape"
                
                // Настраиваем физику для фигуры
                let physicsBody = SKPhysicsBody(polygonFrom: customShapePath.cgPath)
                physicsBody.isDynamic = false
                physicsBody.categoryBitMask = PhysicsCategory.wall
                physicsBody.contactTestBitMask = PhysicsCategory.ball
                physicsBody.collisionBitMask = PhysicsCategory.all
                physicsBody.restitution = 0.5
                physicsBody.friction = 0.3
                customShape.physicsBody = physicsBody
                
                addChild(customShape)
                
                // Создаем мяч (розовый) и размещаем его на горизонтальной части L-образной фигуры
                let ball = createBall(color: pinkColor)
                // Позиционируем мяч на горизонтальной части L-образной фигуры
                ball.position = CGPoint(x: frame.width * 0.8, y: frame.height * 0.35) // Размещаем мяч на горизонтальной части L-образной фигуры
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel4() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                // Создаем U-образный контейнер (розовый) и размещаем его под углом
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.15, y: frame.height * 0.2))
                container.zRotation = CGFloat.pi * 0.15 // Поворачиваем контейнер на 27 градусов
                containers.append(container)
                
                // Создаем первую L-образную фигуру (справа)
                let customShapePath1 = UIBezierPath()
                
                // Размеры для первой L-образной фигуры
                let verticalWidth1 = frame.width * 0.15
                let verticalHeight1 = frame.height * 0.6
                let horizontalWidth1 = frame.width * 0.4
                let horizontalHeight1 = frame.height * 0.15
                
                // Создаем первую L-образную форму
                customShapePath1.move(to: CGPoint(x: 0, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth1, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth1, y: horizontalHeight1))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth1, y: horizontalHeight1))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth1, y: verticalHeight1))
                customShapePath1.addLine(to: CGPoint(x: 0, y: verticalHeight1))
                customShapePath1.close()
                
                let customShape1 = SKShapeNode(path: customShapePath1.cgPath)
                customShape1.fillColor = pinkColor
                customShape1.strokeColor = pinkColor
                customShape1.position = CGPoint(x: frame.width * 0.6, y: frame.height * 0.2)
                customShape1.zPosition = 2
                customShape1.name = "custom_shape_1"
                
                // Настраиваем физику для первой фигуры
                let physicsBody1 = SKPhysicsBody(polygonFrom: customShapePath1.cgPath)
                physicsBody1.isDynamic = false
                physicsBody1.categoryBitMask = PhysicsCategory.wall
                physicsBody1.contactTestBitMask = PhysicsCategory.ball
                physicsBody1.collisionBitMask = PhysicsCategory.all
                physicsBody1.restitution = 0.5
                physicsBody1.friction = 0.3
                customShape1.physicsBody = physicsBody1
                
                addChild(customShape1)
                
                // Создаем вторую L-образную фигуру (слева, перевернутую)
                let customShapePath2 = UIBezierPath()
                
                // Размеры для второй L-образной фигуры (уменьшаем верхнюю часть)
                let verticalWidth2 = frame.width * 0.15
                let verticalHeight2 = frame.height * 0.4 // Уменьшаем высоту
                let horizontalWidth2 = frame.width * 0.35
                let horizontalHeight2 = frame.height * 0.15
                let gapWidth = frame.width * 0.25 // Увеличиваем ширину прохода
                
                // Создаем вторую L-образную форму (перевернутую) с увеличенным проходом сверху
                customShapePath2.move(to: CGPoint(x: 0, y: 0))
                customShapePath2.addLine(to: CGPoint(x: horizontalWidth2, y: 0))
                customShapePath2.addLine(to: CGPoint(x: horizontalWidth2, y: verticalHeight2))
                customShapePath2.addLine(to: CGPoint(x: horizontalWidth2 - gapWidth, y: verticalHeight2))
                customShapePath2.addLine(to: CGPoint(x: horizontalWidth2 - gapWidth, y: horizontalHeight2))
                customShapePath2.addLine(to: CGPoint(x: 0, y: horizontalHeight2))
                customShapePath2.close()
                
                let customShape2 = SKShapeNode(path: customShapePath2.cgPath)
                customShape2.fillColor = pinkColor
                customShape2.strokeColor = pinkColor
                customShape2.position = CGPoint(x: frame.width * 0.35, y: frame.height * 0.4)
                customShape2.zPosition = 2
                customShape2.name = "custom_shape_2"
                
                // Настраиваем физику для второй фигуры
                let physicsBody2 = SKPhysicsBody(polygonFrom: customShapePath2.cgPath)
                physicsBody2.isDynamic = false
                physicsBody2.categoryBitMask = PhysicsCategory.wall
                physicsBody2.contactTestBitMask = PhysicsCategory.ball
                physicsBody2.collisionBitMask = PhysicsCategory.all
                physicsBody2.restitution = 0.5
                physicsBody2.friction = 0.3
                customShape2.physicsBody = physicsBody2
                
                addChild(customShape2)
                
                // Создаем мяч (розовый) и размещаем его на горизонтальной части первой L-образной фигуры
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.8, y: frame.height * 0.35)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel5() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                // Создаем U-образный контейнер (розовый) и размещаем его под углом
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.2))
                container.zRotation = CGFloat.pi * -0.15 // Поворачиваем контейнер на -27 градусов
                containers.append(container)
                
                // Создаем первую L-образную фигуру (слева)
                let customShapePath1 = UIBezierPath()
                
                // Размеры для первой L-образной фигуры
                let verticalWidth1 = frame.width * 0.15
                let verticalHeight1 = frame.height * 0.6
                let horizontalWidth1 = frame.width * 0.4
                let horizontalHeight1 = frame.height * 0.15
                
                // Создаем первую L-образную форму
                customShapePath1.move(to: CGPoint(x: 0, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth1, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth1, y: horizontalHeight1))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth1, y: horizontalHeight1))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth1, y: verticalHeight1))
                customShapePath1.addLine(to: CGPoint(x: 0, y: verticalHeight1))
                customShapePath1.close()
                
                let customShape1 = SKShapeNode(path: customShapePath1.cgPath)
                customShape1.fillColor = pinkColor
                customShape1.strokeColor = pinkColor
                customShape1.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.2)
                customShape1.zPosition = 2
                customShape1.name = "custom_shape_1"
                
                // Настраиваем физику для первой фигуры
                let physicsBody1 = SKPhysicsBody(polygonFrom: customShapePath1.cgPath)
                physicsBody1.isDynamic = false
                physicsBody1.categoryBitMask = PhysicsCategory.wall
                physicsBody1.contactTestBitMask = PhysicsCategory.ball
                physicsBody1.collisionBitMask = PhysicsCategory.all
                physicsBody1.restitution = 0.5
                physicsBody1.friction = 0.3
                customShape1.physicsBody = physicsBody1
                
                addChild(customShape1)
                
                // Создаем вертикальную стену с закругленными углами (справа)
                let wallSize = CGSize(width: frame.width * 0.1, height: frame.height * 0.5)
                let wallPosition = CGPoint(x: frame.width * 0.6, y: frame.height * 0.3)
                let wallPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize), cornerRadius: wallSize.width / 2)
                let wall = SKShapeNode(path: wallPath.cgPath)
                wall.fillColor = pinkColor
                wall.strokeColor = pinkColor
                wall.position = wallPosition
                wall.zRotation = 0.0
                wall.zPosition = 2
                wall.name = "custom_wall"
                
                // Настраиваем физику для закругленной стены
                let physicsBody2 = SKPhysicsBody(polygonFrom: wallPath.cgPath)
                physicsBody2.isDynamic = false
                physicsBody2.categoryBitMask = PhysicsCategory.wall
                physicsBody2.contactTestBitMask = PhysicsCategory.ball
                physicsBody2.collisionBitMask = PhysicsCategory.all
                physicsBody2.restitution = 0.5
                physicsBody2.friction = 0.3
                wall.physicsBody = physicsBody2
                
                addChild(wall)
                
                // Создаем мяч (розовый) и размещаем его на горизонтальной части первой L-образной фигуры
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.3, y: frame.height * 0.35)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel6() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем первую наклонную стену
                let wallSize1 = CGSize(width: frame.width * 0.1, height: frame.height * 0.5)
                let wallPosition1 = CGPoint(x: frame.width * 0.3, y: frame.height * 0.25) // Изменена позиция по Y
                let wallPath1 = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize1), cornerRadius: wallSize1.width / 2)
                let wall1 = SKShapeNode(path: wallPath1.cgPath)
                wall1.fillColor = pinkColor
                wall1.strokeColor = pinkColor
                wall1.position = wallPosition1
                wall1.zRotation = CGFloat.pi * -0.15 // Наклон -27 градусов
                wall1.zPosition = 2
                wall1.name = "custom_wall_1"
                
                // Настраиваем физику для первой стены
                let physicsBody1 = SKPhysicsBody(polygonFrom: wallPath1.cgPath)
                physicsBody1.isDynamic = false
                physicsBody1.categoryBitMask = PhysicsCategory.wall
                physicsBody1.contactTestBitMask = PhysicsCategory.ball
                physicsBody1.collisionBitMask = PhysicsCategory.all
                physicsBody1.restitution = 0.5
                physicsBody1.friction = 0.3
                wall1.physicsBody = physicsBody1
                
                addChild(wall1)
                
                // Создаем вторую горизонтальную стену
                let wallSize2 = CGSize(width: frame.width * 0.5, height: frame.width * 0.1)
                let wallPosition2 = CGPoint(x: frame.width * 0.7, y: frame.height * 0.4)
                let wallPath2 = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize2), cornerRadius: wallSize2.height / 2)
                let wall2 = SKShapeNode(path: wallPath2.cgPath)
                wall2.fillColor = pinkColor
                wall2.strokeColor = pinkColor
                wall2.position = wallPosition2
                wall2.zRotation = 0 // Горизонтальное положение
                wall2.zPosition = 2
                wall2.name = "custom_wall_2"
                
                // Настраиваем физику для второй стены
                let physicsBody2 = SKPhysicsBody(polygonFrom: wallPath2.cgPath)
                physicsBody2.isDynamic = false
                physicsBody2.categoryBitMask = PhysicsCategory.wall
                physicsBody2.contactTestBitMask = PhysicsCategory.ball
                physicsBody2.collisionBitMask = PhysicsCategory.all
                physicsBody2.restitution = 0.5
                physicsBody2.friction = 0.3
                wall2.physicsBody = physicsBody2
                
                addChild(wall2)
                
                // Создаем U-образный контейнер под горизонтальной стеной
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.7, y: frame.height * 0.2))
                containers.append(container)
                
                // Создаем мяч (розовый)
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.7)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel7() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем первую наклонную стену слева сверху
                let wallSize1 = CGSize(width: frame.width * 0.1, height: frame.height * 0.3)
                let wallPosition1 = CGPoint(x: frame.width * 0.2, y: frame.height * 0.8)
                let wallPath1 = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize1), cornerRadius: wallSize1.width / 2)
                let wall1 = SKShapeNode(path: wallPath1.cgPath)
                wall1.fillColor = pinkColor
                wall1.strokeColor = pinkColor
                wall1.position = wallPosition1
                wall1.zRotation = CGFloat.pi * -0.15 // Наклон -27 градусов
                wall1.zPosition = 2
                wall1.name = "custom_wall_1"
                
                // Настраиваем физику для первой стены
                let physicsBody1 = SKPhysicsBody(polygonFrom: wallPath1.cgPath)
                physicsBody1.isDynamic = false
                physicsBody1.categoryBitMask = PhysicsCategory.wall
                physicsBody1.contactTestBitMask = PhysicsCategory.ball
                physicsBody1.collisionBitMask = PhysicsCategory.all
                physicsBody1.restitution = 0.5
                physicsBody1.friction = 0.3
                wall1.physicsBody = physicsBody1
                
                addChild(wall1)
                
                // Создаем вторую наклонную стену справа сверху
                let wallSize2 = CGSize(width: frame.width * 0.1, height: frame.height * 0.3)
                let wallPosition2 = CGPoint(x: frame.width * 0.8, y: frame.height * 0.8)
                let wallPath2 = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize2), cornerRadius: wallSize2.width / 2)
                let wall2 = SKShapeNode(path: wallPath2.cgPath)
                wall2.fillColor = pinkColor
                wall2.strokeColor = pinkColor
                wall2.position = wallPosition2
                wall2.zRotation = CGFloat.pi * 0.15 // Наклон 27 градусов
                wall2.zPosition = 2
                wall2.name = "custom_wall_2"
                
                // Настраиваем физику для второй стены
                let physicsBody2 = SKPhysicsBody(polygonFrom: wallPath2.cgPath)
                physicsBody2.isDynamic = false
                physicsBody2.categoryBitMask = PhysicsCategory.wall
                physicsBody2.contactTestBitMask = PhysicsCategory.ball
                physicsBody2.collisionBitMask = PhysicsCategory.all
                physicsBody2.restitution = 0.5
                physicsBody2.friction = 0.3
                wall2.physicsBody = physicsBody2
                
                addChild(wall2)
                
                // Создаем третью горизонтальную стену в центре
                let wallSize3 = CGSize(width: frame.width * 0.4, height: frame.width * 0.08)
                let wallPosition3 = CGPoint(x: frame.width * 0.5, y: frame.height * 0.6)
                let wallPath3 = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize3), cornerRadius: wallSize3.height / 2)
                let wall3 = SKShapeNode(path: wallPath3.cgPath)
                wall3.fillColor = pinkColor
                wall3.strokeColor = pinkColor
                wall3.position = wallPosition3
                wall3.zRotation = CGFloat.pi * 0.1 // Небольшой наклон
                wall3.zPosition = 2
                wall3.name = "custom_wall_3"
                
                // Настраиваем физику для третьей стены
                let physicsBody3 = SKPhysicsBody(polygonFrom: wallPath3.cgPath)
                physicsBody3.isDynamic = false
                physicsBody3.categoryBitMask = PhysicsCategory.wall
                physicsBody3.contactTestBitMask = PhysicsCategory.ball
                physicsBody3.collisionBitMask = PhysicsCategory.all
                physicsBody3.restitution = 0.5
                physicsBody3.friction = 0.3
                wall3.physicsBody = physicsBody3
                
                addChild(wall3)
                
                // Создаем четвертую и пятую короткие вертикальные стены по бокам
                let wallSize4 = CGSize(width: frame.width * 0.08, height: frame.height * 0.25)
                let wallPosition4 = CGPoint(x: frame.width * 0.3, y: frame.height * 0.4)
                let wallPath4 = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize4), cornerRadius: wallSize4.width / 2)
                let wall4 = SKShapeNode(path: wallPath4.cgPath)
                wall4.fillColor = pinkColor
                wall4.strokeColor = pinkColor
                wall4.position = wallPosition4
                wall4.zRotation = CGFloat.pi * -0.1 // Небольшой наклон влево
                wall4.zPosition = 2
                wall4.name = "custom_wall_4"
                
                // Настраиваем физику для четвертой стены
                let physicsBody4 = SKPhysicsBody(polygonFrom: wallPath4.cgPath)
                physicsBody4.isDynamic = false
                physicsBody4.categoryBitMask = PhysicsCategory.wall
                physicsBody4.contactTestBitMask = PhysicsCategory.ball
                physicsBody4.collisionBitMask = PhysicsCategory.all
                physicsBody4.restitution = 0.5
                physicsBody4.friction = 0.3
                wall4.physicsBody = physicsBody4
                
                addChild(wall4)
                
                let wallSize5 = CGSize(width: frame.width * 0.08, height: frame.height * 0.25)
                let wallPosition5 = CGPoint(x: frame.width * 0.7, y: frame.height * 0.4)
                let wallPath5 = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize5), cornerRadius: wallSize5.width / 2)
                let wall5 = SKShapeNode(path: wallPath5.cgPath)
                wall5.fillColor = pinkColor
                wall5.strokeColor = pinkColor
                wall5.position = wallPosition5
                wall5.zRotation = CGFloat.pi * 0.1 // Небольшой наклон вправо
                wall5.zPosition = 2
                wall5.name = "custom_wall_5"
                
                // Настраиваем физику для пятой стены
                let physicsBody5 = SKPhysicsBody(polygonFrom: wallPath5.cgPath)
                physicsBody5.isDynamic = false
                physicsBody5.categoryBitMask = PhysicsCategory.wall
                physicsBody5.contactTestBitMask = PhysicsCategory.ball
                physicsBody5.collisionBitMask = PhysicsCategory.all
                physicsBody5.restitution = 0.5
                physicsBody5.friction = 0.3
                wall5.physicsBody = physicsBody5
                
                addChild(wall5)
                
                // Создаем шестую горизонтальную стену внизу
                let wallSize6 = CGSize(width: frame.width * 0.3, height: frame.width * 0.08)
                let wallPosition6 = CGPoint(x: frame.width * 0.5, y: frame.height * 0.25)
                let wallPath6 = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize6), cornerRadius: wallSize6.height / 2)
                let wall6 = SKShapeNode(path: wallPath6.cgPath)
                wall6.fillColor = pinkColor
                wall6.strokeColor = pinkColor
                wall6.position = wallPosition6
                wall6.zRotation = CGFloat.pi * -0.1 // Небольшой наклон в противоположную сторону
                wall6.zPosition = 2
                wall6.name = "custom_wall_6"
                
                // Настраиваем физику для шестой стены
                let physicsBody6 = SKPhysicsBody(polygonFrom: wallPath6.cgPath)
                physicsBody6.isDynamic = false
                physicsBody6.categoryBitMask = PhysicsCategory.wall
                physicsBody6.contactTestBitMask = PhysicsCategory.ball
                physicsBody6.collisionBitMask = PhysicsCategory.all
                physicsBody6.restitution = 0.5
                physicsBody6.friction = 0.3
                wall6.physicsBody = physicsBody6
                
                addChild(wall6)
                
                // Создаем U-образный контейнер внизу справа
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.15))
                containers.append(container)
                
                // Создаем мяч (розовый)
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel8() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем первую L-образную фигуру в нижнем левом углу
                let customShapePath1 = UIBezierPath()
                let verticalWidth1 = frame.width * 0.15
                let verticalHeight1 = frame.height * 0.4
                let horizontalWidth1 = frame.width * 0.3
                let horizontalHeight1 = frame.height * 0.15
                
                customShapePath1.move(to: CGPoint(x: 0, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth1, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth1, y: horizontalHeight1))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth1, y: horizontalHeight1))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth1, y: verticalHeight1))
                customShapePath1.addLine(to: CGPoint(x: 0, y: verticalHeight1))
                customShapePath1.close()
                
                let customShape1 = SKShapeNode(path: customShapePath1.cgPath)
                customShape1.fillColor = pinkColor
                customShape1.strokeColor = pinkColor
                customShape1.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.4) // Поднял фигуру выше
                customShape1.zPosition = 2
                customShape1.name = "custom_shape_1"
                
                let physicsBody1 = SKPhysicsBody(polygonFrom: customShapePath1.cgPath)
                physicsBody1.isDynamic = false
                physicsBody1.categoryBitMask = PhysicsCategory.wall
                physicsBody1.contactTestBitMask = PhysicsCategory.ball
                physicsBody1.collisionBitMask = PhysicsCategory.all
                physicsBody1.restitution = 0.5
                physicsBody1.friction = 0.3
                customShape1.physicsBody = physicsBody1
                
                addChild(customShape1)
                
                // Создаем вторую L-образную фигуру (перевернутую) в нижнем правом углу
                let customShapePath2 = UIBezierPath()
                let verticalWidth2 = frame.width * 0.15
                let verticalHeight2 = frame.height * 0.4
                let horizontalWidth2 = frame.width * 0.3
                let horizontalHeight2 = frame.height * 0.15
                
                customShapePath2.move(to: CGPoint(x: 0, y: 0))
                customShapePath2.addLine(to: CGPoint(x: horizontalWidth2, y: 0))
                customShapePath2.addLine(to: CGPoint(x: horizontalWidth2, y: verticalHeight2))
                customShapePath2.addLine(to: CGPoint(x: horizontalWidth2 - verticalWidth2, y: verticalHeight2))
                customShapePath2.addLine(to: CGPoint(x: horizontalWidth2 - verticalWidth2, y: horizontalHeight2))
                customShapePath2.addLine(to: CGPoint(x: 0, y: horizontalHeight2))
                customShapePath2.close()
                
                let customShape2 = SKShapeNode(path: customShapePath2.cgPath)
                customShape2.fillColor = pinkColor
                customShape2.strokeColor = pinkColor
                customShape2.position = CGPoint(x: frame.width * 0.6, y: frame.height * 0.4) // Поднял фигуру выше
                customShape2.zPosition = 2
                customShape2.name = "custom_shape_2"
                
                let physicsBody2 = SKPhysicsBody(polygonFrom: customShapePath2.cgPath)
                physicsBody2.isDynamic = false
                physicsBody2.categoryBitMask = PhysicsCategory.wall
                physicsBody2.contactTestBitMask = PhysicsCategory.ball
                physicsBody2.collisionBitMask = PhysicsCategory.all
                physicsBody2.restitution = 0.5
                physicsBody2.friction = 0.3
                customShape2.physicsBody = physicsBody2
                
                addChild(customShape2)
                
                // Заменяем центральную фигуру на custom_wall
                let wallSize = CGSize(width: frame.width * 0.2, height: frame.height * 0.2)
                let wallPosition = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5) // Поднял фигуру выше
                let wallPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize), cornerRadius: wallSize.width / 2)
                let customWall = SKShapeNode(path: wallPath.cgPath)
                customWall.fillColor = pinkColor
                customWall.strokeColor = pinkColor
                customWall.position = wallPosition
                customWall.zPosition = 2
                customWall.name = "custom_wall"
                
                let physicsBody3 = SKPhysicsBody(polygonFrom: wallPath.cgPath)
                physicsBody3.isDynamic = false
                physicsBody3.categoryBitMask = PhysicsCategory.wall
                physicsBody3.contactTestBitMask = PhysicsCategory.ball
                physicsBody3.collisionBitMask = PhysicsCategory.all
                physicsBody3.restitution = 0.5
                physicsBody3.friction = 0.3
                customWall.physicsBody = physicsBody3
                
                addChild(customWall)
                
                // Создаем U-образный контейнер в правом нижнем углу
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.15))
                container.zRotation = CGFloat.pi * -0.1 // Небольшой наклон для усложнения
                containers.append(container)
                
                // Создаем мяч (розовый) в верхнем левом углу
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel9() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем сложные препятствия с наклонными стенами
                let wallSize = CGSize(width: frame.width * 0.1, height: frame.height * 0.4)
                let wallPosition1 = CGPoint(x: frame.width * 0.2, y: frame.height * 0.7)
                let wall1 = createWall(size: wallSize, position: wallPosition1, rotation: CGFloat.pi * -0.15, color: pinkColor)
                addChild(wall1)
                
                let wallPosition2 = CGPoint(x: frame.width * 0.8, y: frame.height * 0.7)
                let wall2 = createWall(size: wallSize, position: wallPosition2, rotation: CGFloat.pi * 0.15, color: pinkColor)
                addChild(wall2)
                
                let wallPosition3 = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
                let wall3 = createWall(size: wallSize, position: wallPosition3, rotation: CGFloat.pi * 0.1, color: pinkColor)
                addChild(wall3)
                
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.5, y: frame.height * 0.2))
                containers.append(container)
                
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel10() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем сложные препятствия с вертикальными и горизонтальными стенами
                let wallSize = CGSize(width: frame.width * 0.1, height: frame.height * 0.5)
                let wallPosition1 = CGPoint(x: frame.width * 0.3, y: frame.height * 0.6)
                let wall1 = createWall(size: wallSize, position: wallPosition1, rotation: 0, color: pinkColor)
                addChild(wall1)
                
                let wallPosition2 = CGPoint(x: frame.width * 0.7, y: frame.height * 0.6)
                let wall2 = createWall(size: wallSize, position: wallPosition2, rotation: 0, color: pinkColor)
                addChild(wall2)
                
                let wallPosition3 = CGPoint(x: frame.width * 0.5, y: frame.height * 0.4)
                let wall3 = createWall(size: wallSize, position: wallPosition3, rotation: CGFloat.pi * 0.1, color: pinkColor)
                addChild(wall3)
                
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.5, y: frame.height * 0.2))
                containers.append(container)
                
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel11() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем сложные препятствия с наклонными и горизонтальными стенами
                let wallSize = CGSize(width: frame.width * 0.1, height: frame.height * 0.4)
                let wallPosition1 = CGPoint(x: frame.width * 0.2, y: frame.height * 0.8)
                let wall1 = createWall(size: wallSize, position: wallPosition1, rotation: CGFloat.pi * -0.1, color: pinkColor)
                addChild(wall1)
                
                let wallPosition2 = CGPoint(x: frame.width * 0.8, y: frame.height * 0.8)
                let wall2 = createWall(size: wallSize, position: wallPosition2, rotation: CGFloat.pi * 0.1, color: pinkColor)
                addChild(wall2)
                
                let wallPosition3 = CGPoint(x: frame.width * 0.5, y: frame.height * 0.6)
                let wall3 = createWall(size: wallSize, position: wallPosition3, rotation: 0, color: pinkColor)
                addChild(wall3)
                
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.5, y: frame.height * 0.2))
                containers.append(container)
                
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel12() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем L-образную фигуру ниже
                let customShapePath1 = UIBezierPath()
                let verticalWidth1 = frame.width * 0.15
                let verticalHeight1 = frame.height * 0.4
                let horizontalWidth1 = frame.width * 0.3
                let horizontalHeight1 = frame.height * 0.15
                
                customShapePath1.move(to: CGPoint(x: 0, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth1, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth1, y: horizontalHeight1))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth1, y: horizontalHeight1))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth1, y: verticalHeight1))
                customShapePath1.addLine(to: CGPoint(x: 0, y: verticalHeight1))
                customShapePath1.close()
                
                let customShape1 = SKShapeNode(path: customShapePath1.cgPath)
                customShape1.fillColor = pinkColor
                customShape1.strokeColor = pinkColor
                customShape1.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.3) // Опустили ниже
                customShape1.zPosition = 2
                customShape1.name = "custom_shape_1"
                
                let physicsBody1 = SKPhysicsBody(polygonFrom: customShapePath1.cgPath)
                physicsBody1.isDynamic = false
                physicsBody1.categoryBitMask = PhysicsCategory.wall
                physicsBody1.contactTestBitMask = PhysicsCategory.ball
                physicsBody1.collisionBitMask = PhysicsCategory.all
                physicsBody1.restitution = 0.5
                physicsBody1.friction = 0.3
                customShape1.physicsBody = physicsBody1
                
                addChild(customShape1)
                
                // Создаем наклонную стену в центре (тоже ниже)
                let wallSize = CGSize(width: frame.width * 0.1, height: frame.height * 0.4)
                let wallPosition = CGPoint(x: frame.width * 0.5, y: frame.height * 0.4) // Опустили ниже
                let wallPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize), cornerRadius: wallSize.width / 2)
                let wall = SKShapeNode(path: wallPath.cgPath)
                wall.fillColor = pinkColor
                wall.strokeColor = pinkColor
                wall.position = wallPosition
                wall.zRotation = CGFloat.pi * 0.25 // 45 градусов
                wall.zPosition = 2
                wall.name = "custom_wall"
                
                let physicsBody2 = SKPhysicsBody(polygonFrom: wallPath.cgPath)
                physicsBody2.isDynamic = false
                physicsBody2.categoryBitMask = PhysicsCategory.wall
                physicsBody2.contactTestBitMask = PhysicsCategory.ball
                physicsBody2.collisionBitMask = PhysicsCategory.all
                physicsBody2.restitution = 0.5
                physicsBody2.friction = 0.3
                wall.physicsBody = physicsBody2
                
                addChild(wall)
                
                // Создаем U-образный контейнер справа внизу
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.15))
                container.zRotation = CGFloat.pi * -0.15
                containers.append(container)
                
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel13() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем лабиринт из стен
                let wallSize1 = CGSize(width: frame.width * 0.1, height: frame.height * 0.4)
                let wallPositions = [
                    (pos: CGPoint(x: frame.width * 0.2, y: frame.height * 0.7), rot: CGFloat.pi * 0.15),
                    (pos: CGPoint(x: frame.width * 0.5, y: frame.height * 0.6), rot: CGFloat.pi * -0.15),
                    (pos: CGPoint(x: frame.width * 0.8, y: frame.height * 0.5), rot: CGFloat.pi * 0.15)
                ]
                
                for (position, rotation) in wallPositions {
                    let wallPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize1), cornerRadius: wallSize1.width / 2)
                    let wall = SKShapeNode(path: wallPath.cgPath)
                    wall.fillColor = pinkColor
                    wall.strokeColor = pinkColor
                    wall.position = position
                    wall.zRotation = rotation
                    wall.zPosition = 2
                    wall.name = "custom_wall"
                    
                    let physicsBody = SKPhysicsBody(polygonFrom: wallPath.cgPath)
                    physicsBody.isDynamic = false
                    physicsBody.categoryBitMask = PhysicsCategory.wall
                    physicsBody.contactTestBitMask = PhysicsCategory.ball
                    physicsBody.collisionBitMask = PhysicsCategory.all
                    physicsBody.restitution = 0.5
                    physicsBody.friction = 0.3
                    wall.physicsBody = physicsBody
                    
                    addChild(wall)
                }
                
                // Создаем U-образный контейнер в сложном месте
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.2))
                container.zRotation = CGFloat.pi * 0.1
                containers.append(container)
                
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel14() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем сложную конструкцию из L-образных фигур
                let customShapePath1 = UIBezierPath()
                let verticalWidth = frame.width * 0.15
                let verticalHeight = frame.height * 0.4
                let horizontalWidth = frame.width * 0.3
                let horizontalHeight = frame.height * 0.15
                
                // Первая L-образная фигура
                customShapePath1.move(to: CGPoint(x: 0, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth, y: 0))
                customShapePath1.addLine(to: CGPoint(x: horizontalWidth, y: horizontalHeight))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth, y: horizontalHeight))
                customShapePath1.addLine(to: CGPoint(x: verticalWidth, y: verticalHeight))
                customShapePath1.addLine(to: CGPoint(x: 0, y: verticalHeight))
                customShapePath1.close()
                
                let customShape1 = SKShapeNode(path: customShapePath1.cgPath)
                customShape1.fillColor = pinkColor
                customShape1.strokeColor = pinkColor
                customShape1.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.4)
                customShape1.zPosition = 2
                customShape1.name = "custom_shape_1"
                
                let physicsBody1 = SKPhysicsBody(polygonFrom: customShapePath1.cgPath)
                physicsBody1.isDynamic = false
                physicsBody1.categoryBitMask = PhysicsCategory.wall
                physicsBody1.contactTestBitMask = PhysicsCategory.ball
                physicsBody1.collisionBitMask = PhysicsCategory.all
                physicsBody1.restitution = 0.5
                physicsBody1.friction = 0.3
                customShape1.physicsBody = physicsBody1
                
                addChild(customShape1)
                
                // Добавляем несколько наклонных стен
                let wallPositions = [
                    (pos: CGPoint(x: frame.width * 0.4, y: frame.height * 0.7), rot: CGFloat.pi * 0.25),
                    (pos: CGPoint(x: frame.width * 0.6, y: frame.height * 0.5), rot: CGFloat.pi * -0.25),
                    (pos: CGPoint(x: frame.width * 0.8, y: frame.height * 0.3), rot: CGFloat.pi * 0.25)
                ]
                
                for (position, rotation) in wallPositions {
                    let wallSize = CGSize(width: frame.width * 0.1, height: frame.height * 0.3)
                    let wallPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSize), cornerRadius: wallSize.width / 2)
                    let wall = SKShapeNode(path: wallPath.cgPath)
                    wall.fillColor = pinkColor
                    wall.strokeColor = pinkColor
                    wall.position = position
                    wall.zRotation = rotation
                    wall.zPosition = 2
                    wall.name = "custom_wall"
                    
                    let physicsBody = SKPhysicsBody(polygonFrom: wallPath.cgPath)
                    physicsBody.isDynamic = false
                    physicsBody.categoryBitMask = PhysicsCategory.wall
                    physicsBody.contactTestBitMask = PhysicsCategory.ball
                    physicsBody.collisionBitMask = PhysicsCategory.all
                    physicsBody.restitution = 0.5
                    physicsBody.friction = 0.3
                    wall.physicsBody = physicsBody
                    
                    addChild(wall)
                }
                
                // Создаем U-образный контейнер в сложном месте
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.15))
                container.zRotation = CGFloat.pi * -0.1
                containers.append(container)
                
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.15, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            private func setupLevel15() {
                // Убираем серую платформу для этого уровня
                launcher?.removeFromParent()
                launcher = nil
                
                let pinkColor = UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)
                
                // Создаем систему из трех наклонных стен разной длины
                let wallSizes = [
                    CGSize(width: frame.width * 0.1, height: frame.height * 0.5),
                    CGSize(width: frame.width * 0.1, height: frame.height * 0.3),
                    CGSize(width: frame.width * 0.1, height: frame.height * 0.4)
                ]
                
                let wallPositions = [
                    (pos: CGPoint(x: frame.width * 0.15, y: frame.height * 0.7), rot: CGFloat.pi * -0.2),
                    (pos: CGPoint(x: frame.width * 0.5, y: frame.height * 0.6), rot: CGFloat.pi * 0.25),
                    (pos: CGPoint(x: frame.width * 0.8, y: frame.height * 0.5), rot: CGFloat.pi * -0.15)
                ]
                
                for i in 0..<3 {
                    let wallPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: wallSizes[i]), cornerRadius: wallSizes[i].width / 2)
                    let wall = SKShapeNode(path: wallPath.cgPath)
                    wall.fillColor = pinkColor
                    wall.strokeColor = pinkColor
                    wall.position = wallPositions[i].pos
                    wall.zRotation = wallPositions[i].rot
                    wall.zPosition = 2
                    wall.name = "custom_wall_\(i+1)"
                    
                    let physicsBody = SKPhysicsBody(polygonFrom: wallPath.cgPath)
                    physicsBody.isDynamic = false
                    physicsBody.categoryBitMask = PhysicsCategory.wall
                    physicsBody.contactTestBitMask = PhysicsCategory.ball
                    physicsBody.collisionBitMask = PhysicsCategory.all
                    physicsBody.restitution = 0.5
                    physicsBody.friction = 0.3
                    wall.physicsBody = physicsBody
                    
                    addChild(wall)
                }
                
                // Создаем U-образный контейнер в сложном месте
                let container = createContainer(color: pinkColor, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.2))
                container.zRotation = CGFloat.pi * 0.1 // Положительный наклон для усложнения
                containers.append(container)
                
                let ball = createBall(color: pinkColor)
                ball.position = CGPoint(x: frame.width * 0.1, y: frame.height * 0.85)
                addChild(ball)
                currentBall = ball
            }
            
            // MARK: - Создание игровых объектов
            private func createBall(color: UIColor) -> SKSpriteNode {
                // Создаем мяч с кастомным изображением
                let ball = SKSpriteNode(imageNamed: "ball_red")
                ball.colorBlendFactor = 0.0 // Отключаем наложение цвета, чтобы сохранить оригинальные цвета изображений
                
                // Сохраняем цвет в userData
                ball.userData = NSMutableDictionary()
                ball.userData?.setValue(color, forKey: "color")
                
                // Настраиваем размер мяча
                let ballWidth = frame.width * 0.06
                let scale = ballWidth / ball.size.width
                ball.size = CGSize(width: ballWidth, height: ball.size.height * scale)
                
                // Добавляем физическое тело
                let radius = ball.size.width / 2
                ball.physicsBody = SKPhysicsBody(circleOfRadius: radius)
                ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
                ball.physicsBody?.contactTestBitMask = PhysicsCategory.container | PhysicsCategory.platform | PhysicsCategory.wall
                ball.physicsBody?.collisionBitMask = PhysicsCategory.container | PhysicsCategory.platform | PhysicsCategory.wall
                // Делаем мяч очень легким
                ball.physicsBody?.mass = 0.1
                // Большее линейное затухание для лучшей остановки
                ball.physicsBody?.linearDamping = 0.3
                // Минимальная прыгучесть для предотвращения бесконечных отскоков
                ball.physicsBody?.restitution = 0.3
                // Минимальное трение
                ball.physicsBody?.friction = 0.2
                ball.physicsBody?.allowsRotation = true
                ball.physicsBody?.isDynamic = true
                ball.physicsBody?.affectedByGravity = true
                
                // Добавляем имя для легкой идентификации
                ball.name = "ball"
                
                // Добавляем тень для более реалистичного вида
                ball.shadowCastBitMask = 1
                
                // Добавляем мяч на сцену
                ball.zPosition = 3
                return ball
            }
            
            private func createContainer(color: UIColor, position: CGPoint) -> SKSpriteNode {
                let containerWidth = frame.width * 0.15
                let containerHeight = frame.height * 0.15
                
                // Используем кастомное изображение для контейнера
                let container = SKSpriteNode(imageNamed: "container_red")
                container.size = CGSize(width: containerWidth, height: containerHeight)
                container.position = position
                container.zPosition = 2
                
                // Создаем физическое тело для области внутри контейнера с более широким захватом
                let innerWidth = containerWidth * 0.8
                let innerHeight = containerHeight * 0.7
                
                let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: innerWidth, height: innerHeight),
                                              center: CGPoint(x: 0, y: -containerHeight * 0.3))
                
                physicsBody.isDynamic = false
                physicsBody.categoryBitMask = PhysicsCategory.container
                physicsBody.contactTestBitMask = PhysicsCategory.ball
                physicsBody.collisionBitMask = PhysicsCategory.ball
                physicsBody.friction = 0.5    // Увеличиваем трение для лучшей остановки
                physicsBody.restitution = 0.2 // Уменьшаем отскок
                container.physicsBody = physicsBody
                
                // Сохраняем цвет в userData
                container.userData = NSMutableDictionary()
                container.userData?.setValue(color, forKey: "color")
                
                addChild(container)
                return container
            }
            
            private func createContainer(color: UIColor) -> SKSpriteNode {
                // Создаем контейнер с позицией по умолчанию в верхнем правом углу
                return createContainer(color: color, position: CGPoint(x: frame.width * 0.85, y: frame.height * 0.7))
            }
            
            private func createPlatform(size: CGSize, position: CGPoint, rotation: CGFloat = 0, color: UIColor) -> SKSpriteNode {
                let platform = SKSpriteNode(color: color, size: size)
                platform.position = position
                platform.zRotation = rotation
                platform.zPosition = 2
                
                // Настраиваем физику
                let physicsBody = SKPhysicsBody(rectangleOf: size)
                physicsBody.isDynamic = false // Платформа статична
                physicsBody.categoryBitMask = PhysicsCategory.platform
                physicsBody.contactTestBitMask = PhysicsCategory.ball
                physicsBody.collisionBitMask = PhysicsCategory.all
                physicsBody.restitution = 0.5 // Упругость
                physicsBody.friction = 0.3
                platform.physicsBody = physicsBody
                
                addChild(platform)
                return platform
            }
            
            private func createWall(size: CGSize, position: CGPoint, rotation: CGFloat, color: UIColor) -> SKShapeNode {
                let wallPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.width / 2)
                let wall = SKShapeNode(path: wallPath.cgPath)
                wall.fillColor = color
                wall.strokeColor = color
                wall.position = position
                wall.zRotation = rotation
                wall.zPosition = 2
                wall.name = "custom_wall"
                
                let physicsBody = SKPhysicsBody(polygonFrom: wallPath.cgPath)
                physicsBody.isDynamic = false
                physicsBody.categoryBitMask = PhysicsCategory.wall
                physicsBody.contactTestBitMask = PhysicsCategory.ball
                physicsBody.collisionBitMask = PhysicsCategory.all
                physicsBody.restitution = 0.5
                physicsBody.friction = 0.3
                wall.physicsBody = physicsBody
                
                return wall
            }
            
            // MARK: - Обработка касаний
            override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
                guard let touch = touches.first else { return }
                let location = touch.location(in: self)
                
                // Проверяем нажатие на кнопки
                let touchedNodes = nodes(at: location)
                for node in touchedNodes {
                    if node.name == "backButton" {
                        handleBackButton()
                        return
                    } else if node.name == "restartButton" {
                        restartLevel()
                        return
                    } else if node.name == "nextButton" {
                        handleNextButton()
                        return
                    } else if node.name == "menuButton" {
                        handleMenuButton()
                        return
                    } else if node.name == "tryAgainButton" {
                        handleTryAgainButton(node: node)
                        return
                    }
                }
                
                // Если игра окончена, не обрабатываем касания мяча
                if isGameOver { return }
                
                // Проверяем касание по любому мячу (включая запущенные)
                for node in touchedNodes {
                    if let ball = node as? SKSpriteNode,
                       (ball == currentBall || balls.contains(ball)) {
                        currentBall = ball
                        touchStartLocation = location
                        isAiming = true
                        aimLine?.isHidden = false
                        updateAimLine(endPoint: location)
                        return
                    }
                }
                
                // Если не коснулись мяча, но есть активный мяч
                if let ball = currentBall, !isAiming {
                    touchStartLocation = location
                    isAiming = true
                    aimLine?.isHidden = false
                    updateAimLine(endPoint: location)
                }
            }
            
            override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
                guard let touch = touches.first, isAiming else { return }
                let location = touch.location(in: self)
                
                // Обновляем линию прицеливания
                updateAimLine(endPoint: location)
            }
            
            override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
                guard let touch = touches.first, isAiming, let startLocation = touchStartLocation else { return }
                let location = touch.location(in: self)
                
                // Запускаем шарик
                launchBall(from: startLocation, to: location)
                
                // Сбрасываем состояние прицеливания
                isAiming = false
                touchStartLocation = nil
                aimLine?.isHidden = true
            }
            
            override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
                // Сбрасываем состояние прицеливания
                isAiming = false
                touchStartLocation = nil
                aimLine?.isHidden = true
            }
            
            // MARK: - Игровая логика
            private func updateAimLine(endPoint: CGPoint) {
                guard let ball = currentBall, let startLocation = touchStartLocation else { return }
                
                // Создаем путь для линии прицеливания
                let path = CGMutablePath()
                
                // Вычисляем вектор направления (от точки касания к шарику)
                let dx = ball.position.x - endPoint.x
                let dy = ball.position.y - endPoint.y
                
                // Ограничиваем длину линии
                let maxLength: CGFloat = 150
                let length = sqrt(dx*dx + dy*dy)
                let scale = min(maxLength, length) / length
                
                let endX = ball.position.x + dx * scale
                let endY = ball.position.y + dy * scale
                
                // Создаем пунктирную линию с помощью точек
                let dashLength: CGFloat = 10.0
                let gapLength: CGFloat = 5.0
                let totalLength = sqrt(pow(endX - ball.position.x, 2) + pow(endY - ball.position.y, 2))
                let normalizedDX = (endX - ball.position.x) / totalLength
                let normalizedDY = (endY - ball.position.y) / totalLength
                
                var currentX = ball.position.x
                var currentY = ball.position.y
                var distanceCovered: CGFloat = 0
                
                while distanceCovered < totalLength {
                    // Рисуем отрезок
                    path.move(to: CGPoint(x: currentX, y: currentY))
                    
                    let nextX = currentX + normalizedDX * dashLength
                    let nextY = currentY + normalizedDY * dashLength
                    
                    path.addLine(to: CGPoint(x: nextX, y: nextY))
                    
                    // Пропускаем промежуток
                    currentX = nextX + normalizedDX * gapLength
                    currentY = nextY + normalizedDY * gapLength
                    
                    distanceCovered += dashLength + gapLength
                }
                
                aimLine?.path = path
            }
            
            private func launchBall(from startPoint: CGPoint, to endPoint: CGPoint) {
                guard let ball = currentBall else { return }
                
                // Скрываем линию прицеливания
                aimLine?.isHidden = true
                
                // Вычисляем вектор движения
                let dx = startPoint.x - endPoint.x
                let dy = startPoint.y - endPoint.y
                
                // Нормализуем расстояние чтобы ограничить максимальную силу
                let magnitude = sqrt(dx*dx + dy*dy)
                let normalizedDx = dx / magnitude
                let normalizedDy = dy / magnitude
                
                // Увеличиваем силу броска для более заметного движения
                let maxForce: CGFloat = 80.0
                // Ограничиваем расстояние для нормализации силы
                let maxDistance: CGFloat = 150.0
                let normalizedDistance = min(magnitude, maxDistance) / maxDistance
                
                // Делаем шарик динамическим (подверженным физике)
                ball.physicsBody?.isDynamic = true
                
                // Останавливаем текущее движение перед новым броском
                ball.physicsBody?.velocity = CGVector.zero
                ball.physicsBody?.angularVelocity = 0
                
                // Применяем силу для броска
                let forceX = normalizedDx * maxForce * normalizedDistance
                let forceY = normalizedDy * maxForce * normalizedDistance
                
                // Применяем импульс для мгновенного движения
                ball.physicsBody?.applyImpulse(CGVector(dx: forceX, dy: forceY))
                
                // Добавляем мяч в список запущенных, если его там еще нет
                if !balls.contains(ball) {
                    balls.append(ball)
                }
            }
            
            private func checkLevelCompletion() -> Bool {
                // Проверяем, все ли шарики в контейнерах
                var allBallsInContainers = true
                
                for ball in balls {
                    var ballInContainer = false
                    let ballColor = ball.userData?.value(forKey: "color") as? UIColor
                    
                    for container in containers {
                        let containerColor = container.userData?.value(forKey: "color") as? UIColor
                        
                        // Проверяем, находится ли шарик в контейнере соответствующего цвета
                        if let ballPos = ball.parent?.convert(ball.position, to: container),
                           container.contains(ballPos),
                           ballColor == containerColor {
                            ballInContainer = true
                            break
                        }
                    }
                    
                    if !ballInContainer {
                        allBallsInContainers = false
                        break
                    }
                }
                
                // Если все шарики в контейнерах, уровень пройден
                if allBallsInContainers && !balls.isEmpty {
                    levelCompleted()
                    return true
                }
                
                return false
            }
            
            private func levelCompleted() {
                // Останавливаем таймер
                timerActive = false
                isGameOver = true // Устанавливаем флаг окончания игры
                
                // Останавливаем все мячи
                for ball in balls {
                    ball.physicsBody?.velocity = .zero
                    ball.physicsBody?.angularVelocity = 0
                }
                if let currentBall = currentBall {
                    currentBall.physicsBody?.velocity = .zero
                    currentBall.physicsBody?.angularVelocity = 0
                }
                
                // Определяем количество звезд на основе времени прохождения
                var stars = 0
                if gameTime <= 10 { // Если прошел за 10 секунд или быстрее
                    stars = 3
                } else if gameTime <= 20 { // Если прошел за 20 секунд или быстрее
                    stars = 2
                } else { // Если прошел за любое время до истечения таймера
                    stars = 1
                }
                
                // Сохраняем результат
                let key = "level_\(currentLevel - 1)_stars"
                let currentStars = UserDefaults.standard.integer(forKey: key)
                if stars > currentStars {
                    UserDefaults.standard.set(stars, forKey: key)
                }
                
                // Разблокируем следующий уровень
                let unlockedLevels = UserDefaults.standard.integer(forKey: "unlockedLevels")
                if currentLevel >= unlockedLevels {
                    UserDefaults.standard.set(currentLevel + 1, forKey: "unlockedLevels")
                }
                
                // Показываем экран завершения уровня
                showLevelCompletionScreen(stars: stars)
            }
            
            private func showLevelCompletionScreen(stars: Int) {
                // Создаем размытый фон на всю сцену
                let blurEffect = SKEffectNode()
                blurEffect.shouldRasterize = true
                blurEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 20.0])
                blurEffect.position = CGPoint(x: frame.midX, y: frame.midY)
                blurEffect.zPosition = 100
                
                let background = SKSpriteNode(color: .black, size: self.size)
                background.alpha = 0.4 // Уменьшаем затемнение с 0.7 до 0.4
                blurEffect.addChild(background)
                addChild(blurEffect)
                
                // Создаем контейнер для UI элементов
                let container = SKNode()
                container.position = CGPoint(x: frame.midX, y: frame.midY)
                container.zPosition = 101
                addChild(container)
                
                // Добавляем текст "YOU WIN!"
                let winLabel = SKLabelNode(fontNamed: "Arial-Bold")
                winLabel.text = "YOU WIN!"
                winLabel.fontSize = 40
                winLabel.fontColor = .magenta
                winLabel.position = CGPoint(x: 0, y: frame.height * 0.1)
                
                // Добавляем обводку для текста
                let strokeColor = UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1.0)
                let strokeWidth: CGFloat = 2.0
                let attributedText = NSAttributedString(
                    string: "YOU WIN!",
                    attributes: [
                        .strokeColor: strokeColor,
                        .strokeWidth: strokeWidth,
                        .foregroundColor: UIColor.magenta,
                        .font: UIFont.boldSystemFont(ofSize: 40)
                    ]
                )
                let strokeLabel = SKLabelNode()
                strokeLabel.attributedText = attributedText
                strokeLabel.position = winLabel.position
                container.addChild(strokeLabel)
                
                // Добавляем фон для звезд (кастомное изображение)
                let starsBackground = SKSpriteNode(imageNamed: "stars_background")
                starsBackground.size = CGSize(width: 120, height: 64) // Уменьшаем размер фона еще больше
                starsBackground.position = CGPoint(x: 0, y: -20) // Немного ниже текста
                container.addChild(starsBackground)
                
                // Добавляем звезды
                let starSpacing: CGFloat = 28 // Уменьшаем расстояние между звездами пропорционально
                let startX = -starSpacing // Начальная позиция для первой звезды
                
                // Создаем контейнер для звезд, чтобы они были над фоном
                let starsContainer = SKNode()
                starsContainer.position = starsBackground.position
                starsContainer.zPosition = starsBackground.zPosition + 1
                container.addChild(starsContainer)
                
                for i in 0..<3 {
                    let starImageName = i < stars ? "star_filled" : "star_empty"
                    let star = SKSpriteNode(imageNamed: starImageName)
                    star.size = CGSize(width: 20, height: 20) // Уменьшаем размер звезд пропорционально
                    star.position = CGPoint(x: startX + CGFloat(i) * starSpacing, y: 0)
                    starsContainer.addChild(star)
                    
                    // Анимация появления звезд
                    star.setScale(0)
                    let delay = TimeInterval(i) * 0.2
                    star.run(SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.scale(to: 1.0, duration: 0.3)
                    ]))
                }
                
                // Добавляем кнопку Next
                let nextButton = SKSpriteNode(imageNamed: "next_button")
                nextButton.size = CGSize(width: 200, height: 80) // Размер кнопки остается прежним
                nextButton.position = CGPoint(x: 0, y: -frame.height * 0.3) // Увеличиваем отступ снизу еще больше
                nextButton.name = "nextButton"
                container.addChild(nextButton)
            }
            
            // MARK: - Обработчики событий
            private func handleBackButton() {
                // Анимация нажатия
                backButton?.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
                
                // Переход к экрану выбора уровней
                let levelsScene = LevelsScene(size: self.size)
                levelsScene.scaleMode = .resizeFill
                
                let transition = SKTransition.fade(withDuration: 0.5)
                self.view?.presentScene(levelsScene, transition: transition)
            }
            
            private func restartLevel() {
                // Анимация нажатия
                restartButton?.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
                
                // Сбрасываем флаг окончания игры
                isGameOver = false
                
                // Перезагружаем текущий уровень
                loadLevel(level: currentLevel)
            }
            
            private func handleNextButton() {
                // Мгновенный переход к следующему уровню
                let nextLevel = self.currentLevel + 1
                let gameScene = GameScene(size: self.size, level: nextLevel)
                gameScene.scaleMode = .resizeFill
                view?.presentScene(gameScene)
            }
            
            private func handleMenuButton() {
                // Переход к экрану выбора уровней
                let levelsScene = LevelsScene(size: self.size)
                levelsScene.scaleMode = .resizeFill
                
                let transition = SKTransition.fade(withDuration: 0.5)
                self.view?.presentScene(levelsScene, transition: transition)
            }
            
            private func handleTryAgainButton(node: SKNode) {
                // Находим родительский контейнер (это SKNode с позицией в центре экрана)
                if let container = node.parent {
                    // Находим эффект размытия (это первый родитель с размытием)
                    if let blurEffect = container.parent?.children.first(where: { $0 is SKEffectNode }) {
                        // Анимация исчезновения
                        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                        let remove = SKAction.removeFromParent()
                        let sequence = SKAction.sequence([fadeOut, remove])
                        
                        // Применяем анимацию к обоим узлам
                        container.run(sequence)
                        blurEffect.run(sequence)
                        
                        // Сбрасываем флаг окончания игры
                        isGameOver = false
                        
                        // Перезапускаем уровень
                        loadLevel(level: currentLevel)
                    }
                }
            }
            
            // MARK: - Обновление
            override func update(_ currentTime: TimeInterval) {
                // Инициализируем lastUpdateTime при первом вызове
                if lastUpdateTime == 0 {
                    lastUpdateTime = currentTime
                    return
                }
                
                // Вычисляем дельту времени
                let dt = currentTime - lastUpdateTime
                lastUpdateTime = currentTime
                
                // Обновляем игровой таймер
                if timerActive {
                    gameTime += dt
                    updateTimerLabel()
                    
                    // Проверяем, не истекло ли время
                    if gameTime >= levelTimeLimit {
                        timerActive = false
                        showLevelFailScreen() // Показываем экран поражения вместо рестарта
                        return
                    }
                }
                
                // Проверяем завершение уровня
                checkBallInContainer()
                
                // Проверяем, не упал ли шарик за пределы экрана
                checkBallsOutOfBounds()
            }
            
            private func updateTimerLabel() {
                let timeLeft = max(0, levelTimeLimit - gameTime)
                let minutes = Int(timeLeft) / 60
                let seconds = Int(timeLeft) % 60
                timerLabel?.text = String(format: "%d:%02d", minutes, seconds)
                
                // Добавляем визуальное предупреждение, когда осталось мало времени
                if timeLeft <= 10 {
                    // Мигаем красным, если осталось меньше 10 секунд
                    if Int(timeLeft * 2) % 2 == 0 {
                        timerLabel?.fontColor = .red
                    } else {
                        timerLabel?.fontColor = .white
                    }
                } else {
                    timerLabel?.fontColor = .white
                }
            }
            
            private func checkBallsOutOfBounds() {
                // Проверяем, не упал ли какой-то из шариков за пределы экрана
                for (index, ball) in balls.enumerated().reversed() {
                    if ball.position.y < -frame.height * 0.1 {
                        // Удаляем шарик из массива активных шариков и со сцены
                        balls.remove(at: index)
                        ball.removeFromParent()
                    }
                }
            }
            
            private func checkBallInContainer() {
                for ball in balls {
                    guard let ballColor = ball.userData?.value(forKey: "color") as? UIColor else { continue }
                    
                    for container in containers {
                        guard let containerColor = container.userData?.value(forKey: "color") as? UIColor else { continue }
                        
                        if ballColor != containerColor { continue }
                        
                        if let ballPosInContainer = ball.parent?.convert(ball.position, to: container) {
                            let containerBottom = -container.size.height * 0.3
                            let checkHeight = container.size.height * 0.4
                            let checkWidth = container.size.width * 0.7
                            
                            if ballPosInContainer.x > -checkWidth/2 &&
                               ballPosInContainer.x < checkWidth/2 &&
                               ballPosInContainer.y > containerBottom - checkHeight/2 &&
                               ballPosInContainer.y < containerBottom + checkHeight/2 {
                                
                                print("Победа! Мяч в контейнере!")
                                
                                let flash = SKSpriteNode(color: .white, size: container.size)
                                flash.position = CGPoint.zero
                                flash.alpha = 0.8
                                flash.zPosition = 5
                                container.addChild(flash)
                                
                                flash.run(SKAction.sequence([
                                    SKAction.fadeOut(withDuration: 0.5),
                                    SKAction.removeFromParent()
                                ]))
                                
                                ball.name = "completedBall"
                                balls.removeAll { $0 == ball }
                                
                                self.levelCompleted()
                                
                                return
                            }
                        }
                    }
                }
            }
            
            private func showLevelFailScreen() {
                // Останавливаем таймер
                timerActive = false
                isGameOver = true // Устанавливаем флаг окончания игры
                
                // Останавливаем все мячи
                for ball in balls {
                    ball.physicsBody?.velocity = .zero
                    ball.physicsBody?.angularVelocity = 0
                }
                if let currentBall = currentBall {
                    currentBall.physicsBody?.velocity = .zero
                    currentBall.physicsBody?.angularVelocity = 0
                }
                
                // Создаем размытый фон на всю сцену
                let blurEffect = SKEffectNode()
                blurEffect.shouldRasterize = true
                blurEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 20.0])
                blurEffect.position = CGPoint(x: frame.midX, y: frame.midY)
                blurEffect.zPosition = 100
                
                let background = SKSpriteNode(color: .black, size: self.size)
                background.alpha = 0.4
                blurEffect.addChild(background)
                addChild(blurEffect)
                
                // Создаем контейнер для UI элементов
                let container = SKNode()
                container.position = CGPoint(x: frame.midX, y: frame.midY)
                container.zPosition = 101
                addChild(container)
                
                // Добавляем текст "YOU LOSE"
                let loseLabel = SKLabelNode()
                let attributedText = NSAttributedString(
                    string: "YOU LOSE",
                    attributes: [
                        .strokeColor: UIColor(red: 0.5, green: 0, blue: 0, alpha: 1.0),
                        .strokeWidth: 2.0,
                        .foregroundColor: UIColor.red,
                        .font: UIFont.boldSystemFont(ofSize: 40)
                    ]
                )
                loseLabel.attributedText = attributedText
                loseLabel.position = CGPoint(x: 0, y: frame.height * 0.05) // Уменьшаем отступ сверху
                container.addChild(loseLabel)
                
                // Добавляем кастомную кнопку Try Again
                let tryAgainButton = SKSpriteNode(imageNamed: "try_again_button")
                tryAgainButton.size = CGSize(width: 200, height: 80)
                tryAgainButton.position = CGPoint(x: 0, y: -frame.height * 0.15) // Уменьшаем отступ снизу
                tryAgainButton.name = "tryAgainButton"
                container.addChild(tryAgainButton)
            }
            
            // MARK: - Обработка столкновений
            func didBegin(_ contact: SKPhysicsContact) {
                let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
                
                // Проверяем столкновение шарика с контейнером
                if collision == PhysicsCategory.ball | PhysicsCategory.container {
                    // Определяем, какое тело является шариком, а какое контейнером
                    let ballBody: SKPhysicsBody
                    let containerBody: SKPhysicsBody
                    
                    if contact.bodyA.categoryBitMask == PhysicsCategory.ball {
                        ballBody = contact.bodyA
                        containerBody = contact.bodyB
                    } else {
                        ballBody = contact.bodyB
                        containerBody = contact.bodyA
                    }
                    
                    // Получаем узлы шарика и контейнера
                    guard let ball = ballBody.node as? SKSpriteNode,
                          let container = containerBody.node as? SKSpriteNode else {
                        return
                    }
                    
                    // Проверяем совпадение цветов
                    let ballColor = ball.userData?.value(forKey: "color") as? UIColor
                    let containerColor = container.userData?.value(forKey: "color") as? UIColor
                    
                    if ballColor == containerColor {
                        // Создаем вспышку для обратной связи
                        let flash = SKSpriteNode(color: .white, size: container.size)
                        flash.position = .zero
                        flash.alpha = 0.5
                        flash.zPosition = 5
                        container.addChild(flash)
                        
                        // Создаем анимацию вспышки
                        flash.run(SKAction.sequence([
                            SKAction.fadeOut(withDuration: 0.3),
                            SKAction.removeFromParent()
                        ]))
                        
                        // Помечаем мяч как завершенный
                        ball.name = "completedBall"
                        balls.removeAll { $0 == ball }
                        
                        // Засчитываем победу
                        self.levelCompleted()
                    }
                }
            }
}/*ss GameScene: SKScene, SKPhysicsContactDelegate {
            
            // MARK: - Категории физических тел
            struct PhysicsCategory {*/

              
