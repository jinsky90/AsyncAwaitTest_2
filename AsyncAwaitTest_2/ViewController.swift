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
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var imageView5: UIImageView!
    @IBOutlet weak var imageView6: UIImageView!
    
    @IBOutlet weak var progressView1: UIProgressView!
    @IBOutlet weak var progressView2: UIProgressView!
    @IBOutlet weak var progressView3: UIProgressView!
    @IBOutlet weak var progressView4: UIProgressView!
    @IBOutlet weak var progressView5: UIProgressView!
    @IBOutlet weak var progressView6: UIProgressView!
    
    var imageViews: [UIImageView] = []
    var progressViews: [UIProgressView] = []
    let imageAddresses: [URL] = [
        URL(string:"https://cdn.pixabay.com/photo/2018/10/05/23/31/apple-3727110_1280.jpg")!, // big
        URL(string:"https://cdn.pixabay.com/photo/2016/08/12/22/38/apple-1589874_1280.jpg")!,
        URL(string:"https://cdn.pixabay.com/photo/2016/08/12/22/34/apple-1589869_1280.jpg")!,
        URL(string:"https://cdn.pixabay.com/photo/2020/05/18/19/14/apple-5188076_1280.jpg")!, // big
        URL(string:"https://cdn.pixabay.com/photo/2016/11/29/08/41/apple-1868496_1280.jpg")!,
        URL(string:"https://cdn.pixabay.com/photo/2016/01/05/13/58/apple-1122537_1280.jpg")!,
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageViews = [imageView1, imageView2, imageView3, imageView4, imageView5, imageView6]
        progressViews = [progressView1, progressView2, progressView3, progressView4, progressView5, progressView6]
        
        print("메인 쓰레드 진행중 - 0")
        print("메인 쓰레드 진행중 - 1")
        
        Task {
            // Async
//            let image = await requestImageDataAsync()
//            imageView.image = image
            
            // AsyncSequence + How to
//            await requestImageDataBytes()
            
            // AsyncSequence + image with progress
//            let image = await requestImageInProgress(0)
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
    
    // MARK: - Progress + image
    
    func requestImageInProgress(_ index: Int) async -> UIImage? {
        let url = URL(string:"https://cdn.pixabay.com/photo/2014/09/05/10/54/mattress-camp-436263_1280.jpg")!
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
    
    // MARK: - AsyncSequence + Parallel
    func requestImageParallel() async {
        async let image1 = requestImageInProgressWithUrl(1, url: imageAddresses[0])
        async let image2 = requestImageInProgressWithUrl(2, url: imageAddresses[1])
        async let image3 = requestImageInProgressWithUrl(3, url: imageAddresses[2])
        async let image4 = requestImageInProgressWithUrl(4, url: imageAddresses[3])
        async let image5 = requestImageInProgressWithUrl(5, url: imageAddresses[4])
        async let image6 = requestImageInProgressWithUrl(6, url: imageAddresses[5])
        
        
        let imageDatum = try await [image1, image2, image3, image4, image5, image6]
        
        for (index, imageData) in imageDatum.enumerated() {
            await updateImage(image: imageData, index: index + 1)
        }
    }
    
    func requestImageInProgressWithUrl(_ index: Int, url: URL) async -> UIImage? {
        do {
            let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(from: url)
            let length = (urlResponse.expectedContentLength)
            var data = Data()
            data.reserveCapacity(Int(length))

            for try await byte in asyncBytes {
                data.append(byte)
                let progress = Double(data.count) / Double(length)
                await progressUpdate(progress: Float(progress), index: index)
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
    
    @MainActor func progressUpdate(progress: Float, index: Int) async {
        progressViews[index - 1].progress = progress
    }
    
    @MainActor func updateImage(image: UIImage?, index: Int) async {
        imageViews[index - 1].image = image
    }
}
