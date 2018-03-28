/*:
 # KeyGrids
 
*/

import UIKit
import PlaygroundSupport
import AudioToolbox

extension UIColor {
    static var background: UIColor {
        return UIColor(red: 30/255, green: 32/255, blue: 40/255, alpha: 1)
    }
    
    static var botColor: UIColor {
        return UIColor(red: 255/255, green: 235/255, blue: 195/255, alpha: 1)
    }
    
    static var borderColor: UIColor {
        return UIColor(white: 1, alpha: 0.25)
    }
}

func * (point: CGPoint, length: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * length, y: point.y * length)
}

enum Direction {
    case up
    case down
    case left
    case right
    case none
}

class Note {
    var name: String
    var index: UInt8
    var color: UIColor
    
    init() {
        self.name = ""
        self.index = 0
        self.color = .background
    }
    
    init(name: String, index: UInt8, color: UIColor) {
        self.name = name
        self.index = index
        self.color = color
    }
    
    var sequence: MusicSequence? = nil
    var track: MusicTrack? = nil
    var musicPlayer:MusicPlayer? = nil
    
    func play() {
        if name != "" {
            DispatchQueue.main.async {
                NewMusicSequence(&self.sequence)
                MusicSequenceNewTrack(self.sequence!, &self.track)
                
                var note = MIDINoteMessage(channel: 0, note: self.index, velocity: 127, releaseVelocity: 0, duration: 0.5)
                MusicTrackNewMIDINoteEvent(self.track!, 0, &note)
                
                var musicPlayer: MusicPlayer? = nil
                NewMusicPlayer(&musicPlayer)
                MusicPlayerSetSequence(musicPlayer!, self.sequence!)
                MusicPlayerStart(musicPlayer!)
            }
        }
    }
}

class Tile: UIView {
    var position = CGPoint() {
        didSet {
            contract()
            UIView.animate(withDuration: 0.25) {
                self.frame.origin = self.position * self.frame.width
            }
        }
    }
    
    var note: Note! {
        didSet {
            let dir = direction; direction = dir
            if note.name.trimmingCharacters(in: .whitespaces).isEmpty { direction = .none }
            noteLabel.text = note.name
            UIView.animate(withDuration: 0.25) {
                self.noteLabel.backgroundColor = self.note.color
            }
        }
    }
    
    var direction: Direction = .none {
        didSet {
            if direction != .none {
                directionView.image = UIImage(named: "\(direction).png")?.withRenderingMode(.alwaysTemplate)
                directionView.tintColor = note.name == "" ? .white : .black
            } else {
                directionView.image = UIImage()
                directionView.tintColor = .black
            }
        }
    }
    
    let noteLabel = UILabel()
    let directionView = UIImageView()
    
    func create(with note: Note) {
        position = CGPoint.zero
        setupNoteLabel()
        setupDirectionView()
        
        self.note = note
    }
    
    func create(with direction: Direction) {
        position = CGPoint.zero
        setupNoteLabel()
        setupDirectionView()
        
        self.direction = direction
    }
    
    func create(with length: CGFloat, at point: CGPoint) {
        frame.size = CGSize(width: length, height: length)
        position = point
        backgroundColor = .background
        
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.borderColor.cgColor
        
        setupNoteLabel()
        setupDirectionView()
    }
    
    func setupNoteLabel() {
        note = Note()
        noteLabel.backgroundColor = .clear
        noteLabel.textAlignment = .center
        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noteLabel)
        
        let top = NSLayoutConstraint(item: noteLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: noteLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: noteLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: noteLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        
        addConstraints([top, bottom, left, right])
    }
    
    func setupDirectionView() {
        directionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(directionView)
        let bottom = NSLayoutConstraint(item: directionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: directionView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: directionView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.5, constant: 0)
        let height = NSLayoutConstraint(item: directionView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.5, constant: 0)
        
        addConstraints([bottom, right, width, height])
    }
    
    func expand() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.75, options: .curveEaseOut, animations: {
            self.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }, completion: nil)
    }
    
    func contract() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.75, options: .curveEaseOut, animations: {
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: nil)
    }
}

class Bot: UIView {
    var startPosition: CGPoint! {
        didSet {
            position = startPosition
        }
    }
    var position: CGPoint! {
        didSet {
            UIView.animate(withDuration: speed) {
                self.frame.origin = self.position * self.frame.width
            }
        }
    }
    var direction: Direction = .none
    var speed: Double = 0
    var head = UIView()
    
    func create(with length: CGFloat, at point: CGPoint, duration: Double) {
        frame.size = CGSize(width: length, height: length)
        startPosition = point
        speed = duration
        
        setupHead()
    }
    
    func setupHead() {
        head.backgroundColor = .botColor
        head.translatesAutoresizingMaskIntoConstraints = false
        addSubview(head)
        
        let width = NSLayoutConstraint(item: head, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.5, constant: 0)
        let height = NSLayoutConstraint(item: head, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.5, constant: 0)
        let centerX = NSLayoutConstraint(item: head, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: head, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        addConstraints([width, height, centerX, centerY])
        
        head.layer.cornerRadius = self.frame.height/4
        head.clipsToBounds = true
    }
    
    func reset() {
        position = startPosition
    }
    
    func move(inside grid: [[Tile]]) {
        let tile = grid[Int(position.x)][Int(position.y)]
        let nextDirection = tile.direction
        if nextDirection != .none {
            direction = nextDirection
        }
        
        switch direction {
        case .up:
            if position.y > 0 {
                position.y -= 1
            }
        case .down:
            if position.y < CGFloat(grid[0].count - 1) {
                position.y += 1
            }
        case .left:
            if position.x > 0 {
                position.x -= 1
            }
        case .right:
            if position.x < CGFloat(grid.count - 1) {
                position.x += 1
            }
        default:
            break
        }
        
        tile.note.play()
    }
}

class ViewController : UIViewController {
    
    var firstLaunch = true
    
    var tileLength: CGFloat! {
        return gridContainer.frame.width / CGFloat(gridSize)
    }
    
    var hoveredTile: Tile! {
        didSet {
            if let tile = hoveredTile {
                if bots.count != 0 {
                    gridContainer.insertSubview(tile, belowSubview: bots.first!)
                } else {
                    gridContainer.bringSubview(toFront: tile)
                }
            }
            
            grid.forEach { (row) in
                row.forEach({ (tile) in
                    if tile == hoveredTile { tile.expand() }
                })
            }
        }
    }
    
    var selectedTile: Tile! {
        didSet {
            if selectedTile == nil {
                hideMenu()
            } else {
                showMenu()
            }

            grid.forEach { (row) in
                row.forEach({ (tile) in
                    if tile == selectedTile {
                        tile.expand()
                    } else {
                        tile.contract()
                    }
                })
            }
        }
    }
    
    // grid variables
    
    let gridContainer = UIView()
    let gridSize: Int = 8
    var grid: [[Tile]] = []
    
    // bot variables
    
    var bots: [Bot] = []
    var selectedBot: Bot? {
        didSet {
            if selectedBot != nil { showDeleteLabel() }
            else { hideDeleteLabel() }
        }
    }
    
    // slider variables
    
    let sliderView = UISlider()
    let sliderLabel = UILabel()
    
    var tps: Int! {
        didSet {
            sliderView.value = Float(tps)
            sliderLabel.text = "\(tps!) tiles/s"
            sliderLabel.sizeToFit()
            timeInterval = 1/Double(tps)
            
            if timer != nil {
                if timer.isValid {
                    timer.invalidate()
                    timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.refresh), userInfo: nil, repeats: true)
                }
            }
        }
    }
    var timeInterval: Double = 0.25
    var timer: Timer!
    
    // start button variables
    
    let startButton = UIButton()
    
    // menu variables
    
    var directions: [Direction] = [.none, .up, .down, .left, .right]
    
    let menuView = UIView()
    var menuCollectionView: UICollectionView!
    var actionCollectionView: UICollectionView!
    
    // delete variables
    
    let deleteLabel = UILabel()
    
    // clear variables
    let clearButton = UIButton()
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .background
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if firstLaunch {
            setupGridContainer()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstLaunch {
            setupMenuView()
            setupMenuCollectionView()
            setupActionCollectionView()
            generateGrid()
            setupStartButton()
            setupSliderView()
            setupSliderLabel()
            setupDeleteLabel()
            setupClearButton()
            
            createBot(at: CGPoint.zero)
            grid[0][0].direction = .right
            
            firstLaunch = false
        }
    }
    
    func setupGridContainer() {
        gridContainer.backgroundColor = .clear
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridContainer)
        
        let top = NSLayoutConstraint(item: gridContainer, attribute: .top, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: gridContainer, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: gridContainer, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: gridContainer, attribute: .height, relatedBy: .equal, toItem: gridContainer, attribute: .width, multiplier: 1, constant: 0)
        
        view.addConstraints([top, left, right, height])
    }
    
    func setupMenuView() {
        menuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuView)
        
        let top = NSLayoutConstraint(item: menuView, attribute: .top, relatedBy: .equal, toItem: gridContainer, attribute: .bottom, multiplier: 1, constant: 20)
        let left = NSLayoutConstraint(item: menuView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .leftMargin, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: menuView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .rightMargin, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: menuView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: tileLength * 4)
        view.addConstraints([top, left, right, height])
        
        hideMenu()
    }
    
    func setupStartButton() {
        startButton.setImage(UIImage(named: "play"), for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        startButton.addTarget(self, action: #selector(self.startAction), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)
        
        let left = NSLayoutConstraint(item: startButton, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: startButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: startButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: startButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 2, constant: tileLength)
        view.addConstraints([left, right, bottom, height])
    }
    
    func setupSliderView() {
        sliderView.minimumValue = 1
        sliderView.minimumTrackTintColor = .white
        sliderView.maximumValue = 20
        sliderView.maximumTrackTintColor = .clear
        sliderView.addTarget(self, action: #selector(self.sliderAction(_:)), for: .allEvents)
        sliderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderView)
        
        tps = 5
        
        let left = NSLayoutConstraint(item: sliderView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 20)
        let bottom = NSLayoutConstraint(item: sliderView, attribute: .bottom, relatedBy: .equal, toItem: startButton, attribute: .top, multiplier: 1, constant: 0)
        
        view.addConstraints([left, bottom])
    }
    
    func setupSliderLabel() {
        sliderLabel.textColor = .white
        sliderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderLabel)
        
        let left = NSLayoutConstraint(item: sliderLabel, attribute: .left, relatedBy: .equal, toItem: sliderView, attribute: .right, multiplier: 1, constant: 20)
        let right = NSLayoutConstraint(item: sliderLabel, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: -20)
        let bottom = NSLayoutConstraint(item: sliderLabel, attribute: .bottom, relatedBy: .equal, toItem: startButton, attribute: .top, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: sliderLabel, attribute: .height, relatedBy: .equal, toItem: sliderView, attribute: .height, multiplier: 1, constant: 0)
        
        view.addConstraints([left, right, bottom, height])
    }
    
    func setupDeleteLabel() {
        hideDeleteLabel()
        deleteLabel.text = "DELETE BOT"
        deleteLabel.textColor = .red
        deleteLabel.textAlignment = .center
        deleteLabel.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(deleteLabel, belowSubview: gridContainer)
        
        let top = NSLayoutConstraint(item: deleteLabel, attribute: .top, relatedBy: .equal, toItem: gridContainer, attribute: .bottom, multiplier: 1, constant: 20)
        let left = NSLayoutConstraint(item: deleteLabel, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: deleteLabel, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: deleteLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: tileLength)
        view.addConstraints([top, left, right, height])
    }
    
    func setupClearButton() {
        clearButton.setImage(UIImage(named: "delete"), for: .normal)
        clearButton.imageView?.contentMode = .scaleAspectFit
        clearButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        clearButton.addTarget(self, action: #selector(self.clearAction), for: .touchUpInside)
        clearButton.backgroundColor = .background
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(clearButton, belowSubview: gridContainer)
        
        let top = NSLayoutConstraint(item: clearButton, attribute: .top, relatedBy: .equal, toItem: gridContainer, attribute: .bottom, multiplier: 1, constant: 20)
        let left = NSLayoutConstraint(item: clearButton, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: clearButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: clearButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: tileLength)
        view.addConstraints([top, left, right, height])
    }
    
    func hideDeleteLabel() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
            self.deleteLabel.alpha = 0
            self.deleteLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.deleteLabel.backgroundColor = .background
            self.deleteLabel.textColor = .red
        }) { _ in
            self.showClearButton()
        }
    }
    
    func highlightDeleteLabel() {
        hideClearButton()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
            self.deleteLabel.alpha = 1
            self.deleteLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.deleteLabel.backgroundColor = .red
            self.deleteLabel.textColor = .white
        }, completion: nil)
    }
    
    func showDeleteLabel() {
        hideClearButton()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
            self.deleteLabel.alpha = 1
            self.deleteLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.deleteLabel.backgroundColor = .background
            self.deleteLabel.textColor = .red
        }, completion: nil)
    }
    
    func generateGrid() {
        for x in 0 ..< gridSize {
            var row: [Tile] = []
            for y in 0 ..< gridSize {
                let tile = Tile()
                tile.create(with: tileLength, at: CGPoint(x: x, y: y))
                gridContainer.addSubview(tile)
                row.append(tile)
            }
            grid.append(row)
        }
    }
    
    func clearGrid() {
        for row in grid {
            for tile in row {
                tile.direction = .none
                tile.note = Note()
            }
        }
    }
    
    func createBot(at position: CGPoint) {
        let bot = Bot()
        bot.create(with: tileLength, at: position, duration: timeInterval)
        bots.append(bot)
        gridContainer.addSubview(bot)
    }
    
    func delete(_ bot: Bot) {
        bot.removeFromSuperview()
        bots.remove(at: bots.index(of: bot)!)
    }
    
    func resetBots() {
        for bot in bots {
            bot.reset()
        }
    }
    
    func clearBots() {
        for bot in bots {
            delete(bot)
        }
    }
    
    @objc func createAction() {
        createBot(at: selectedTile.position)
    }
    
    @objc func startAction() {
        if startButton.image(for: .normal) == UIImage(named: "play") {
            selectedTile = nil
            timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.refresh), userInfo: nil, repeats: true)
            startButton.setImage(UIImage(named: "rewind"), for: .normal)
        } else {
            timer.invalidate()
            startButton.setImage(UIImage(named: "play"), for: .normal)
            resetBots()
        }
    }
    
    @objc func clearAction() {
        let alertController = UIAlertController(title: "Clear grid?", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let yes = UIAlertAction(title: "Ok", style: .default) { _ in
            self.clearGrid()
            self.clearBots()
        }
        alertController.addAction(cancel)
        alertController.addAction(yes)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func sliderAction(_ sender: UISlider) {
        tps = Int(sender.value)
    }
    
    func hideClearButton() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                self.clearButton.alpha = 0
                self.clearButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }) { _ in
                self.clearButton.isHidden = true
            }
        }
    }
    
    func showClearButton() {
        DispatchQueue.main.async {
            self.clearButton.isHidden = false
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                self.clearButton.alpha = 1
                self.clearButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        }
    }
    
    @objc func refresh() {
        for bot in bots {
            bot.move(inside: grid)
        }
    }
    
    func dismissAction() {
        selectedTile = nil
    }
    
}

extension CGPoint {
    func isIn(_ frame: CGRect) -> Bool {
        return x >= frame.origin.x && x <= frame.origin.x + frame.width && y >= frame.origin.y && y <= frame.origin.y + frame.height
    }
}

extension ViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let location = touches.first?.location(in: gridContainer)
        for bot in bots {
            if (location?.isIn(bot.frame))! {
                selectedBot = bot
                selectedTile = nil
                return
            }
        }
        
        for row in grid {
            for tile in row {
                if (location?.isIn(tile.frame))! {
                    selectedBot = nil
                    hoveredTile = tile
                    break
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let location = touches.first?.location(in: gridContainer)
        if let bot = selectedBot {
            if (location?.isIn(deleteLabel.frame))! {
                highlightDeleteLabel()
            } else {
                showDeleteLabel()
            }
            bot.center = location!
        } else if let tile = hoveredTile {
            selectedTile = nil
            tile.center = location!
        }
    }
    
    func clip(bot: Bot) {
        var x = round(bot.frame.origin.x / tileLength)
        x = x < 0 ? 0 : x
        x = x >= CGFloat(gridSize) ? CGFloat(gridSize) - 1 : x
        
        var y = round(bot.frame.origin.y / tileLength)
        y = y < 0 ? 0 : y
        y = y >= CGFloat(gridSize) ? CGFloat(gridSize) - 1 : y
        
        bot.startPosition = CGPoint(x: x, y: y)
    }
    
    func getNewPosition(of tile: Tile) -> CGPoint {
        var x = round(tile.frame.origin.x / tileLength)
        x = x < 0 ? 0 : x
        x = x >= CGFloat(gridSize) ? CGFloat(gridSize) - 1 : x
        
        var y = round(tile.frame.origin.y / tileLength)
        y = y < 0 ? 0 : y
        y = y >= CGFloat(gridSize) ? CGFloat(gridSize) - 1 : y
        
        return CGPoint(x: x, y: y)
    }
    
    func endAction(with location: CGPoint) {
        if let bot = selectedBot {
            if location.isIn(deleteLabel.frame) {
                delete(bot)
            } else {
                clip(bot: bot)
            }
            selectedBot = nil
        } else if let tile = hoveredTile {
            let new = getNewPosition(of: tile)
            if tile.position == new {
                tile.position = new
                toggleMenu(from: tile)
            } else {
                let old = tile.position
                let switchedTile = grid[Int(new.x)][Int(new.y)]
                switchedTile.position = old
                tile.position = new
                grid[Int(old.x)][Int(old.y)] = switchedTile
                grid[Int(new.x)][Int(new.y)] = tile
                hoveredTile = nil
            }
        } else {
            dismissAction()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        endAction(with: (touches.first?.location(in: gridContainer))!)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

class TileCollectionViewCell: UICollectionViewCell {
    let tile = Tile()
    
    var note: Note! {
        didSet {
            tile.create(with: note)
            setupTile()
        }
    }
    
    var direction: Direction! {
        didSet {
            tile.create(with: direction)
            setupTile()
        }
    }
    
    func setupTile() {
        tile.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tile)
        
        let top = NSLayoutConstraint(item: tile, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: tile, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: tile, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: tile, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        addConstraints([top, bottom, left, right])
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func setupMenuCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: tileLength, height: tileLength)
        menuCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        
        menuCollectionView.delegate = self
        menuCollectionView.dataSource = self
        menuCollectionView.backgroundColor = .background
        menuCollectionView.register(TileCollectionViewCell.self, forCellWithReuseIdentifier: "MenuCell")
        menuCollectionView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(menuCollectionView)
        
        let top = NSLayoutConstraint(item: menuCollectionView, attribute: .top, relatedBy: .equal, toItem: menuView, attribute: .top, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: menuCollectionView, attribute: .left, relatedBy: .equal, toItem: menuView, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: menuCollectionView, attribute: .right, relatedBy: .equal, toItem: menuView, attribute: .right, multiplier: 1, constant: 0)
        menuView.addConstraints([top, left, right])
    }
    
    func setupActionCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: tileLength, height: tileLength)
        actionCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        
        actionCollectionView.delegate = self
        actionCollectionView.dataSource = self
        actionCollectionView.backgroundColor = .background
        actionCollectionView.register(TileCollectionViewCell.self, forCellWithReuseIdentifier: "ActionCell")
        actionCollectionView.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(actionCollectionView)
        
        let top = NSLayoutConstraint(item: actionCollectionView, attribute: .top, relatedBy: .equal, toItem: menuCollectionView, attribute: .bottom, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: actionCollectionView, attribute: .left, relatedBy: .equal, toItem: menuView, attribute: .left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: actionCollectionView, attribute: .right, relatedBy: .equal, toItem: menuView, attribute: .right, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: actionCollectionView, attribute: .bottom, relatedBy: .equal, toItem: menuView, attribute: .bottom, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: menuCollectionView, attribute: .height, relatedBy: .equal, toItem: actionCollectionView, attribute: .height, multiplier: 3, constant: 1)
        menuView.addConstraints([top, left, right, bottom, height])
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == menuCollectionView ? notes.count : directions.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = TileCollectionViewCell()
        if collectionView == menuCollectionView {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as! TileCollectionViewCell
            cell.note = notes[indexPath.row]
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActionCell", for: indexPath) as! TileCollectionViewCell
            if indexPath.row < directions.count {
                cell.direction = directions[indexPath.row]
            } else {
                cell.setupTile()
                let bot = Bot()
                bot.create(with: tileLength, at: CGPoint.zero, duration: 0)
                cell.addSubview(bot)
            }
        }
        cell.layer.borderColor = UIColor.borderColor.cgColor
        cell.layer.borderWidth = 1
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: tileLength, height: tileLength)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            cell.alpha = 1
        }, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let tile = selectedTile {
            if collectionView == menuCollectionView {
                notes[indexPath.row].play()
                tile.note = notes[indexPath.row]
            } else {
                if indexPath.row < directions.count {
                    tile.direction = directions[indexPath.row]
                } else {
                    createBot(at: tile.position)
                }
            }
            let cell = collectionView.cellForItem(at: indexPath)
            collectionView.bringSubview(toFront: cell!)
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                cell?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }) { _ in
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                    cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
                }, completion: nil)
            }
        }
    }
}

extension ViewController {
    func hideMenu() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.menuView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.menuView.alpha = 0
        }) { _ in
            self.menuView.isHidden = true
        }
    }
    
    func showMenu() {
        menuView.isHidden = false
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.menuView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.menuView.alpha = 1
        }, completion: nil)
    }
    
    func toggleMenu(from tile: Tile) {
        if tile == selectedTile {
            if menuView.isHidden {
                selectedTile = tile
            } else {
                selectedTile = nil
            }
        } else {
            selectedTile = tile
        }
    }
}

var notes: [Note] = [Note()]
func readFile() {
    let filePath = Bundle.main.path(forResource:"notes", ofType: "txt")
    let contentData = FileManager.default.contents(atPath: filePath!)
    
    if let content = String(data:contentData!, encoding:String.Encoding.utf8) {
        let rows = content.components(separatedBy: .newlines).filter({ (string) -> Bool in
            return !string.isEmpty
        })
        for row in rows {
            let columns = row.components(separatedBy: .whitespaces)
            let note = Note(name: columns.first!,
                            index: UInt8(columns.last!)!,
                            color: UIColor(hue: CGFloat(notes.count)/CGFloat(rows.count), saturation: 1, brightness: 1, alpha: 1))
            notes.append(note)
        }
    }
}
readFile()

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = ViewController()
