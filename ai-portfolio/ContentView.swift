import SwiftUI
import AVFoundation
import Vision

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Main Game View
struct ContentView: View {
    @StateObject private var gameManager = GameManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.brown.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Score Header
                    HStack {
                        Text("Score: \(gameManager.score)")
                            .font(.title)
                            .bold()
                            .padding()
                        
                        Spacer()
                        
                        Text("Lives: \(gameManager.lives)")
                            .font(.title)
                            .bold()
                            .padding()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Game Area
                    if gameManager.isPlaying {
                        GamePlayView(gameManager: gameManager)
                    } else {
                        GameOverView(
                            score: gameManager.score,
                            onRestart: { gameManager.startGame() }
                        )
                    }
                    
                    Spacer()
                    
                    // Camera View for Hand Detection
                    CameraHandDetectionView(onGestureDetected: {
                        gameManager.shoot()
                    })
                    .frame(height: 200)
                    .cornerRadius(15)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yellow, lineWidth: 3)
                            .padding()
                    )
                }
            }
            .onAppear {
                gameManager.setScreenSize(width: geometry.size.width, height: geometry.size.height)
                gameManager.startGame()
            }
        }
    }
}

// MARK: - Game Play View
struct GamePlayView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        ZStack {
            ForEach(gameManager.targets) { target in
                TargetView(target: target)
                    .position(x: target.position.x, y: target.position.y)
                    .onTapGesture {
                        gameManager.hitTarget(target)
                    }
            }
            
            // Crosshair
            Image(systemName: "scope")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Target View
struct TargetView: View {
    let target: Target
    
    var body: some View {
        ZStack {
            Circle()
                .fill(target.isGood ? Color.green : Color.red)
                .frame(width: 60, height: 60)
            
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 60, height: 60)
            
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
            
            Text(target.isGood ? "👍" : "💀")
                .font(.title)
        }
        .scaleEffect(target.scale)
        .opacity(target.opacity)
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    let score: Int
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🤠")
                .font(.system(size: 100))
            
            Text("Game Over!")
                .font(.largeTitle)
                .bold()
            
            Text("Final Score: \(score)")
                .font(.title)
            
            Button(action: onRestart) {
                Text("Play Again")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(Color.brown)
                    .cornerRadius(15)
            }
        }
        .foregroundColor(.white)
    }
}

#if canImport(UIKit)
// MARK: - Camera Hand Detection View
struct CameraHandDetectionView: UIViewRepresentable {
    let onGestureDetected: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let cameraView = CameraHandDetector(onGestureDetected: onGestureDetected)
        
        cameraView.previewLayer.frame = view.bounds
        view.layer.addSublayer(cameraView.previewLayer)
        
        context.coordinator.cameraDetector = cameraView
        cameraView.startSession()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var cameraDetector: CameraHandDetector?
        
        deinit {
            cameraDetector?.stopSession()
        }
    }
}

// MARK: - Camera Hand Detector
class CameraHandDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    let previewLayer = AVCaptureVideoPreviewLayer()
    let videoDataOutput = AVCaptureVideoDataOutput()
    
    var handPoseRequest = VNDetectHumanHandPoseRequest()
    var onGestureDetected: () -> Void
    var lastGestureTime: Date = Date.distantPast
    
    init(onGestureDetected: @escaping () -> Void) {
        self.onGestureDetected = onGestureDetected
        super.init()
        setupCamera()
    }
    
    func setupCamera() {
        captureSession.sessionPreset = .medium
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        previewLayer.session = captureSession
        previewLayer.videoGravity = .resizeAspectFill
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        captureSession.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
            guard let observation = handPoseRequest.results?.first else { return }
            
            // Detect pointing gesture
            if detectPointingGesture(observation: observation) {
                // Prevent multiple rapid triggers
                let now = Date()
                if now.timeIntervalSince(lastGestureTime) > 0.5 {
                    lastGestureTime = now
                    DispatchQueue.main.async {
                        self.onGestureDetected()
                    }
                }
            }
        } catch {
            // Silent error handling
        }
    }
    
    func detectPointingGesture(observation: VNHumanHandPoseObservation) -> Bool {
        guard let indexTip = try? observation.recognizedPoint(.indexTip),
              let indexDIP = try? observation.recognizedPoint(.indexDIP),
              let indexMCP = try? observation.recognizedPoint(.indexMCP),
              let middleTip = try? observation.recognizedPoint(.middleTip),
              let middleMCP = try? observation.recognizedPoint(.middleMCP),
              let thumbTip = try? observation.recognizedPoint(.thumbTip) else {
            return false
        }
        
        // Check confidence
        guard indexTip.confidence > 0.7,
              indexDIP.confidence > 0.7,
              thumbTip.confidence > 0.7 else {
            return false
        }
        
        // Index finger should be extended (tip is above base)
        let indexExtended = indexTip.location.y > indexMCP.location.y + 0.05
        
        // Middle finger should be curled (tip is below base)
        let middleCurled = middleTip.location.y < middleMCP.location.y + 0.02
        
        // Thumb should be somewhat extended (gun shape)
        let thumbExtended = abs(thumbTip.location.x - indexTip.location.x) > 0.05
        
        return indexExtended && (middleCurled || thumbExtended)
    }
}
#else
// Fallback for non-iOS platforms
struct CameraHandDetectionView: View {
    let onGestureDetected: () -> Void
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Text("Camera not available on this platform")
                .foregroundColor(.white)
        }
    }
}
#endif

// MARK: - Game Models
struct Target: Identifiable {
    let id = UUID()
    var position: CGPoint
    var isGood: Bool
    var scale: CGFloat = 0.0
    var opacity: Double = 1.0
}

// MARK: - Game Manager
class GameManager: ObservableObject {
    @Published var targets: [Target] = []
    @Published var score = 0
    @Published var lives = 3
    @Published var isPlaying = false
    
    private var timer: Timer?
    private var targetTimer: Timer?
    private var screenWidth: CGFloat = 400
    private var screenHeight: CGFloat = 600
    
    func setScreenSize(width: CGFloat, height: CGFloat) {
        self.screenWidth = width
        self.screenHeight = height - 400 // Reserve space for UI
    }
    
    func startGame() {
        score = 0
        lives = 3
        targets = []
        isPlaying = true
        
        startSpawningTargets()
    }
    
    func startSpawningTargets() {
        targetTimer?.invalidate()
        targetTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.spawnTarget()
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateTargets()
        }
    }
    
    func spawnTarget() {
        let x = CGFloat.random(in: 50...(screenWidth - 50))
        let y = CGFloat.random(in: 50...(screenHeight - 50))
        let isGood = Bool.random()
        
        var target = Target(position: CGPoint(x: x, y: y), isGood: isGood)
        
        withAnimation(.easeOut(duration: 0.3)) {
            target.scale = 1.0
        }
        
        targets.append(target)
        
        // Remove target after 2 seconds if not hit
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.removeTarget(target.id)
        }
    }
    
    func updateTargets() {
        for i in targets.indices {
            if targets[i].opacity > 0 {
                targets[i].opacity -= 0.01
            }
        }
        
        targets.removeAll { $0.opacity <= 0 }
    }
    
    func shoot() {
        // Shoot the nearest target to center
        guard let centerTarget = findCenterTarget() else { return }
        hitTarget(centerTarget)
    }
    
    func findCenterTarget() -> Target? {
        let center = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
        
        return targets.min(by: { target1, target2 in
            let dist1 = distance(target1.position, center)
            let dist2 = distance(target2.position, center)
            return dist1 < dist2
        })
    }
    
    func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }
    
    func hitTarget(_ target: Target) {
        if let index = targets.firstIndex(where: { $0.id == target.id }) {
            let hitTarget = targets[index]
            
            if hitTarget.isGood {
                // Hit a good target (friendly) - lose life
                lives -= 1
            } else {
                // Hit a bad target - gain points
                score += 10
            }
            
            withAnimation {
                targets[index].scale = 1.5
                targets[index].opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.targets.removeAll { $0.id == target.id }
            }
            
            if lives <= 0 {
                endGame()
            }
        }
    }
    
    func removeTarget(_ id: UUID) {
        targets.removeAll { $0.id == id }
    }
    
    func endGame() {
        isPlaying = false
        timer?.invalidate()
        targetTimer?.invalidate()
        targets = []
    }
}

#Preview {
    ContentView()
}
