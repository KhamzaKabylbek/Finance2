import Foundation
import Speech

class SpeechRecognizer: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        
        // Проверяем доступность распознавателя сразу
        checkInitialState()
    }
    
    private func checkInitialState() {
        guard let recognizer = speechRecognizer else {
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
            return
        }
        
        if !recognizer.isAvailable {
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
            return
        }
        
        checkAuthorization()
    }
    
    private func checkAuthorization() {
        guard !isAuthorized else { return }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = status == .authorized
            }
        }
    }
    
    func startRecording() throws {
        // Проверяем состояние перед записью
        guard !isRecording else { return }
        
        guard isAuthorized else {
            throw NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Нет разрешения на распознавание речи"])
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw NSError(domain: "SpeechRecognizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Распознавание речи недоступно"])
        }
        
        // Сбрасываем предыдущее состояние
        stopRecording()
        
        do {
            try configureAudioSession()
            try setupRecognition(with: speechRecognizer)
        } catch {
            stopRecording()
            throw error
        }
    }
    
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func setupRecognition(with recognizer: SFSpeechRecognizer) throws {
        transcribedText = ""
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognizer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать запрос распознавания"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func stopRecording() {
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func requestAuthorization() {
        checkInitialState()
    }
}
