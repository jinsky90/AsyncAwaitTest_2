//
//  ViewController.swift
//  AsyncAwaitTest_2
//
//  Created by sky on 2022/04/18.
//

import UIKit

enum TestError: Error {
    case defaultError
}

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("메인 쓰레드 진행중 - 0")
        print("메인 쓰레드 진행중 - 1")
        
        Task {
            // Async
//            let image = await requestImageDataAsync()
//            imageView.image = image
            
            // AsyncSequence + How to
//            await requestImageDataBytes()
            
            // AsyncSequence + image with progress
//            let image = await requestImageInProgress(1)
//            imageView.image = image
            
            // AsyncSequence + Parallel
            await requestImageParallel()
        }
        
        print("메인 쓰레드 진행중 - 2")
        print("메인 쓰레드 진행중 - 3")
    }
    
    // MARK: - Async + data
    // Chap1에서 활용한 Async + data 방식
    func requestImageDataAsync() async -> UIImage? {
        let url = URL(string:"https://cdn.pixabay.com/photo/2016/08/12/22/38/apple-1589874_1280.jpg")!
        
        var image: UIImage? = nil
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            image = UIImage(data: data)
            
        } catch {
            print("서버통신중 에러가 났습니다.")
        }
        return image
    }
    
    // MARK: - AsyncSequence + bytes
    // 어떤 방식으로 AsyncSequence를 활용할 수 있을까?
    func requestImageDataBytes() async {
        let url = URL(string:"https://cdn.pixabay.com/photo/2016/08/12/22/38/apple-1589874_1280.jpg")!
        
        do {
            let (asyncBytes, _) = try await URLSession.shared.bytes(from: url, delegate: nil)

            // for문 활용
            for try await byte in asyncBytes {
                print("byte: \(byte)")
            }
            
            // while문 활용
//            var asyncDownloadIterator = asyncBytes.makeAsyncIterator()
//
//            while let byte = try await asyncDownloadIterator.next() {
//                print("byte: \(byte)")
//            }
            
            // for문 + 고차함수 활용
//            for try await byteString in asyncBytes.map { "byte: \($0)" } {
//                print(byteString)
//            }
        } catch {
            print("서버통신중 에러가 났습니다.")
        }
    }
    
    // MARK: - AsyncSequence + Parallel
    // Parallel하게 async를 사용하여도 AsyncSequence인 경우 순차적으로 실행됨
    func requestImageParallel() async {
        async let image1 = requestImageInProgress(1)
        async let image2 = requestImageInProgress(2)
        async let image3 = requestImageInProgress(3)
        async let image4 = requestImageInProgress(4)
        
        let imageDatum = try await [image1, image2, image3, image4]
    }
    
    // MARK: - Progress + image
    
    func requestImageInProgress(_ index: Int) async -> UIImage? {
        let url = URL(string:"https://cdn.pixabay.com/photo/2016/08/12/22/38/apple-1589874_1280.jpg")!
        do {
            let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(from: url)
            let length = (urlResponse.expectedContentLength)
            var data = Data()
            data.reserveCapacity(Int(length))

            for try await byte in asyncBytes {
                data.append(byte)
                let progress = Double(data.count) / Double(length)
                await progressUpdate(progress: Float(progress))
            }
            print("\(index)번 이미지 다운완료")
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
    
    @MainActor func progressUpdate(progress: Float) async {
        self.progressView.progress = progress
    }
}
