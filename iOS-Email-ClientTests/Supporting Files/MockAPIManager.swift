//
//  MockAPIManager.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 6/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Alamofire
@testable import iOS_Email_Client

class MockAPIManager: APIManager {
    override class func getEmailBody(metadataKey: Int, token: String, completion: @escaping ((ResponseData) -> Void)){
        completion(ResponseData.SuccessString("ytw8v0ntriuhtkirglsdfnakncbdjshndls"))
    }
    
    override class func acknowledgeEvents(eventIds: [Int32], token: String){
        return
    }
    
    override class func registerFile(parameters: [String: Any], token: String, completion: @escaping ((Error?, Any?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/upload"
        let headers = ["Authorization": "Basic \(token)"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let value = response.result.value else {
                completion(response.error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    override class func uploadChunk(chunk: Data, params: [String: Any], token: String, progressDelegate: ProgressDelegate, completion: @escaping ((Error?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/chunk"
        let headers = ["Authorization": "Basic \(token)"]
        let filetoken = params["filetoken"] as! String
        let part = params["part"] as! Int
        let filename = params["filename"] as! String
        let mimeType = params["mimeType"] as! String
        Alamofire.upload(multipartFormData: { (multipartForm) in
            for (key, value) in params {
                multipartForm.append("\(value)".data(using: .utf8)!, withName: key)
            }
            multipartForm.append(chunk, withName: "chunk", fileName: filename, mimeType: mimeType)
        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { (result) in
            switch(result){
            case .success(let request, _, _):
                request.uploadProgress(closure: { (progress) in
                    progressDelegate.chunkUpdateProgress(progress.fractionCompleted, for: filetoken, part: part)
                })
                request.responseJSON(completionHandler: { (response) in
                    if let error = response.error {
                        completion(error)
                        return
                    }
                    guard response.response?.statusCode == 200 else {
                        let criptextError = CriptextError(code: .noValidResponse)
                        completion(criptextError)
                        return
                    }
                    completion(nil)
                })
            case .failure(_):
                let error = CriptextError(code: .noValidResponse)
                completion(error)
            }
        }
    }
    
    override class func getFileMetadata(filetoken: String, token: String, completion: @escaping ((Error?, [String: Any]?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/\(filetoken)"
        let headers = ["Authorization": "Basic \(token)"]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON{
            (response) in
            guard response.response?.statusCode == 200,
                let responseData = response.result.value as? [String: Any] else {
                    let criptextError = CriptextError(code: .noValidResponse)
                    completion(criptextError, nil)
                    return
            }
            completion(nil, responseData)
        }
    }
    
    override class func downloadChunk(filetoken: String, part: Int, token: String, progressDelegate: ProgressDelegate, completion: @escaping ((Error?, String?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/\(filetoken)/chunk/\(part)"
        let headers = ["Authorization": "Basic \(token)"]
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("\(filetoken).part\(part)")
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.removePreviousFile])
        }
        Alamofire.download(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers, to: destination).downloadProgress { (progress) in
            progressDelegate.chunkUpdateProgress(progress.fractionCompleted, for: filetoken, part: part)
            }.response { (response) in
                if let error = response.error {
                    completion(error, nil)
                    return
                }
                guard response.response?.statusCode == 200 else {
                    let criptextError = CriptextError(code: .noValidResponse)
                    completion(criptextError, nil)
                    return
                }
                completion(nil, fileURL.path)
        }
    }
}
