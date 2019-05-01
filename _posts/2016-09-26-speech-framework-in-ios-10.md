---
title: Speech framework in iOS 10
date: 2016-09-26
categories: [ios]
---

At WWDC 2016, Apple introduced the Speech framework, an API which allows app developers to incorporate speech recognition in their apps. The exciting fact about this API is that it can perform real-time or recorded speech recognition, in almost 50 languages.

Nowadays, many speech recognition frameworks are available, but most of them are expensive.

In this post, I will show you how to use the Speech framework in **live** scenarios: with the microphone. You can also read a file (audio or video) as data input. First let’s see what we need to begin.

# Permission

To start, import the framework and conform to the `SFSpeechRecognizerDelegate` protocol.

```swift
import Speech
import UIKit
public class ViewController: UIViewController, SFSpeechRecognizerDelegate {}
```

In order to perform speech recognition using the framework, it is mandatory to first ask for the user permission. **Why?** The framework is based on SiriKit, all data are sent and processed on Apple’s servers. You need to inform the user and ask its permission.

Add a property into `Info.plist`. Set your custom message for the `Privacy — Speech Recognition Usage Description` key.

{% include 
    image.html 
    src="speech-recognition-plist-usage.png"
    alt="Authorization message for Speech Recognition"
    caption="Authorization message for Speech Recognition"
%}

Now we need to *actually* ask the permission. I recommend *calling* this method only when you need to trigger speech recognition.

```swift
private func askForSpeechRecognitionPermissions() {
    SFSpeechRecognizer.requestAuthorization { authStatus in
            
    	var enabled: Bool = false
        var message: String?
            
        switch authStatus {
                
            case .authorized:
        	    enabled = true
                
            case .denied:
                enabled = false
                message = "User denied access to speech recognition"
                
            case .restricted:
                enabled = false
                message = "Speech recognition restricted on this device"
                
            case .notDetermined:
                enabled = false
                message = "Speech recognition not yet authorized"
        }
        
        /* The callback may not be called on the main thread. Add an operation to the main queue if you want to perform action on UI. */     
        
        OperationQueue.main.addOperation {
        	// here you can perform UI action, e.g. enable or disable a record button
        }
    }
}
```

# Speech Recognition

Declare two objects, required to perform speech recognition:

```swift
private var speechRecognizer: SFSpeechRecognizer!
private var recognitionTask: SFSpeechRecognitionTask?
```

* `speechRecognizier`: handles speech recognition (*oh really?*)

* `recognizitionTask`: gives the result of the recognition. Task can be cancelled or stopped

Now, the setup, to let the recognizer know what language the user is speaking and to make it our delegate:

```swift
speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
speechRecognizer.delegate = self
```

*Note*: Speech recognition **will not work** unless you are running on a **physical device** (currently). My best guess is, as it is Siri based, only real devices have the capabilities. Hopefully we have a property, [`isAvailable`](https://developer.apple.com/reference/speech/sfspeechrecognizer/1649885-isavailable), to find out if the recognizer is available. A method, `availabilityDidChange`, is also provided by the delegate, that notify when the availability of the speech recognizer has changed:

```swift
public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
	if available {
    	// e.g. enable record button
    } else {
       // e.g. disable record button
    }
}
```

Configuration was pretty simple, now let’s see **input data**!

## Microphone

Like speech recognition, user’s permission is required to use the microphone. Add a new property into `Info.plist`, `Privacy — Microphone Usage Description` and provide a message.

{% include 
    image.html 
    src="speech-recognition-plist-microphone.png"
    alt="Authorization message for Microphone"
    caption="Authorization message for Microphone"
%}

Start by adding these two objects:

```swift
private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
private let audioEngine = AVAudioEngine()
```

* `recognitionRequest`: handles the speech recognition request and provides an audio source (buffer) to the speech recognizer.

* `audioEngine`: provides your audio input, here the microphone.

## Implementing

```swift
private func startRecording() throws {
        // 1
        if let recognitionTask = self.recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // 2
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        
        // 3
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        self.recognitionRequest.shouldReportPartialResults = true
        
        // 4
        self.recognitionTask = self.speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in 
            
            var isFinal = false
            
            // 5
            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            // 6
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
            }
        }
        
        // 7
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
  
        audioEngine.prepare()
        
        try audioEngine.start()
}
```

1. Cancel current speech recognition task if running

2. Prepare for the audio recording, `AVAudioEngine` is required to process the input audio signals

3. Init speech recognition request ; here we choose to retrieve partial results as soon as they’re available (when words are recognized), because it can take some time (several seconds) for the server to finalize the result of recognition and finally send it back

4. Set the speech recognition task with the request: the completion handler will be called each time its state change (cancelled, new input, final results, etc.)

5. Check if partial results are available and display it

6. Final results: stop microphone and clean speech recognition objects

7. Add microphone input to speech recognition request and start microphone

## Task delegate

What if you want more control over speech recognition task? A delegate is available! Just conform to `SFSpeechRecognitionTaskDelegate` protocol. Here a few methods available:

* `speechRecognitionTask(_:didHypothesizeTranscription:)`: a new transcription is available

* `speechRecognitionTask(_:didFinishRecognition:)`: final recognition completed

* `speechRecognitionTaskFinishedReadingAudio(_:)`: no longer accepting input data

## Triggering

Finally, launch the recognition. Assume we bind this method to an `UIButton`:

```swift
@IBAction func recordButtonTapped() {
    if audioEngine.isRunning {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recordButton.isEnabled = false
    } else {
        try! startRecording()
    }
}
```

Start only occurs when microphone is not already running, so we only have one task running at a time.

{% include 
    image.html 
    src="speech-recognition-demo.gif"
    alt="Demo project"
    caption="Demo project"
%}

The project (based on Apple’s sample code *SpeakToMe*) [is available on GitHub](https://github.com/gaelfoppolo/SpeakToMe).

# File based recognition

It is also possible to use file as data input. Even if the API wasn’t designed for that purpose, it can be useful to transcript lyrics, podcast or [generate live subtitles of a video](https://github.com/zats/SpeechRecognition).

And it does not need much change to work.

## Request object type

```swift
private var recognitionRequest: SFSpeechURLRecognitionRequest?
```

## `startRecording()` function

```swift
private func startRecording() throws {
    
    if let recognitionTask = recognitionTask {
        recognitionTask.cancel()
        self.recognitionTask = nil
    }
    let path = Bundle.main.path(forResource: "your-file", ofType: "mp3")
    if let path = path {
        let url = URL(fileURLWithPath: path)
        recognitionRequest = SFSpeechURLRecognitionRequest(url: url)
    }
    guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechURLRecognitionRequest object") }
    recognitionRequest.shouldReportPartialResults = true
    
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
        var isFinal = false
        
        if let result = result {
            self.textView.text = result.bestTranscription.formattedString
            isFinal = result.isFinal
        }
        
        if error != nil || isFinal {
            
            self.recognitionRequest = nil
            self.recognitionTask = nil
            
            self.recordButton.isEnabled = true
        }
    }
}
```

Instead of the audio engine, the path of a file is required, it will be played internally automatically by the recognizer.

## Trigger

```swift
@IBAction func recordButtonTapped() {
    if (self.recognitionTask?.state == .running) {
        self.recognitionTask?.finish()
        self.recognitionRequest = nil
        self.recordButton.isEnabled = false
    } else {
        try! startRecording()
    }
}
```

Task state is check instead of audio input state.

*That’s all!*

# References
[https://developer.apple.com/reference/speech](https://developer.apple.com/reference/speech)

[https://developer.apple.com/reference/speech/sfspeechrecognizerdelegate](https://developer.apple.com/reference/speech/sfspeechrecognizerdelegate)

[https://developer.apple.com/reference/speech/sfspeechrecognitiontaskdelegate](https://developer.apple.com/reference/speech/sfspeechrecognitiontaskdelegate)

[https://developer.apple.com/videos/play/wwdc2016/509/](https://developer.apple.com/videos/play/wwdc2016/509/)

[https://developer.apple.com/library/content/samplecode/SpeakToMe/Introduction/Intro.html#//apple_ref/doc/uid/TP40017110](https://developer.apple.com/library/content/samplecode/SpeakToMe/Introduction/Intro.html#//apple_ref/doc/uid/TP40017110)