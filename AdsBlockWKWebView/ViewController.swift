// AdsBlockWKWebView/ViewController.swift
// Created by Wolfgang Weinmann on 2019/12/31.
// Copyright © 2019 Wolfgang Weinmann.


import UIKit
import WebKit

import AVFoundation
import AVKit
import MediaPlayer

import Security
import OpenSSL
import CertificateSigningRequest

import StoreKit


extension Date {
  func format(_ format: String) -> String {
    let dateFormatter: DateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.string(from: self)
  }
}

extension UIColor {
  public convenience init(r: Int, g: Int, b: Int, a: Int) {
    self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
  }
  //static let colorName: UIColor = UIColor.gray.withAlphaComponent(0.75)
  static let viewBgColor: UIColor = UIColor(white: 0.90, alpha: 1)
  static let viewBgLightColor: UIColor = UIColor(white: 0.95, alpha: 1)
  static let appBgColor: UIColor = UIColor(r: 66, g: 46, b: 151, a: 255)
  static let appBgLightColor: UIColor = UIColor(r: 216, g: 213, b: 234, a: 255)
  static let devBgColor: UIColor = .orange
  static let fieldBgColor: UIColor = .white
  static let buttonFgColor: UIColor = .white
  //static let errorFgColor: UIColor = .red
  static let errorFgColor: UIColor = UIColor(r: 200, g: 55, b: 60, a: 255)
  static let successFgColor: UIColor = UIColor(r: 0, g: 102, b: 0, a: 255)
}

extension URL {
  static var docDir: URL {
    return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  }
  func checkFileExist() -> Bool {
    let path = self.path
    if (FileManager.default.fileExists(atPath: path)) {
      return true
    } else {
      return false
    }
  }
  func rename(to: String) {
    var fileUrl = self
    if fileUrl.checkFileExist() {
      var rv = URLResourceValues()
      rv.name = to
      try! fileUrl.setResourceValues(rv)
    }
  }
}

extension UserDefaults {
  func exists(key: String) -> Bool {
    return object(forKey: key) != nil
  }
  
  func setData(_ value: Any, key: String) {
    let archivedObj = NSKeyedArchiver.archivedData(withRootObject: value)
    set(archivedObj, forKey: key)
  }
  
  func getData<T>(key: String) -> T? {
    //if let value = value(forKey: key) as? Data, 
    if let value = data(forKey: key), 
    let obj = NSKeyedUnarchiver.unarchiveObject(with: value) as? T {
      return obj
    }
    return nil
  }
  
  func fetch<T>(key: String, or value: Any) -> T {
    if exists(key: key) {
      if type(of: value) == String.self {
        return string(forKey: key) as! T
      }
      if type(of: value) == Int.self {
        return integer(forKey: key) as! T
      }
      if type(of: value) == Bool.self {
        return bool(forKey: key) as! T
      }
    }
    return value as! T
  }
}


func debugLog(_ text: String) {
  let logFileName = "debugLog.txt"
  let timestamp = Date().format("dd.MM.yyyy HH:mm:ss")
  if URL.docDir.appendingPathComponent(logFileName).checkFileExist() == false {
    try! "\(timestamp) \(text)\n\n".write(to: URL.docDir.appendingPathComponent(logFileName), atomically: true, encoding: .utf8)
  } else {
    if let fileUpdater = try? FileHandle(forUpdating: URL.docDir.appendingPathComponent(logFileName)) {
      fileUpdater.seekToEndOfFile()
      fileUpdater.write("\(timestamp) \(text)\n\n".data(using: .utf8)!)
      fileUpdater.closeFile()
    }
  }
}


fileprivate let ruleId1 = "MyRuleID 001"
fileprivate let ruleId2 = "MyRuleID 002"

let userDefaults = UserDefaults.standard
let userDefGroup = UserDefaults(suiteName: "group.at.co.weinmann.AdsBlockWKWebView")!

var messages: [String] = []
var alertCounter: Int = 0
let hapticFB = UINotificationFeedbackGenerator()

let player = AVPlayer(url: URL(string: "http://statslive.infomaniak.ch/playlist/tsfjazz/tsfjazz-high.mp3/playlist.m3u")!)
var restoreUrlsJson: String!


////////// USERPREFS //////////
var tableMaxLinesPref: Int = 6 //6
var tableMoveTopPref: Bool = false //true
var webViewStartPagePref: String = "https://www.google.com/"
var webViewRestorePref: String = "ask"
var webViewSearchUrlPref: String = "https://www.google.com/search?q="
var goBackOnEditPref: Int = 2
var autoVideoDownloadPref: Bool = false
//AlleSeitenHinzuStatt+
//IdleTimerEinAus

func loadUserPrefs() {
  tableMaxLinesPref = userDefaults.fetch(key: "tableMaxLinesPref", or: tableMaxLinesPref)
  tableMoveTopPref = userDefaults.fetch(key: "tableMoveTopPref", or: tableMoveTopPref)
  webViewStartPagePref = userDefaults.fetch(key: "webViewStartPagePref", or: webViewStartPagePref)
  webViewRestorePref = userDefaults.fetch(key: "webViewRestorePref", or: webViewRestorePref)
  webViewSearchUrlPref = userDefaults.fetch(key: "webViewSearchUrlPref", or: webViewSearchUrlPref)
  goBackOnEditPref = userDefaults.fetch(key: "goBackOnEditPref", or: goBackOnEditPref)
  autoVideoDownloadPref = userDefaults.fetch(key: "autoVideoDownloadPref", or: autoVideoDownloadPref)
}
////////// USERPREFS //////////


/*
class alertObj {
  var Style: String?
  var Title: String?
  var Message: String
  var Handler: ((Any) -> Void)?
  init (Style: String? = nil, Title: String? = nil, Message: String, Handler: ((Any) -> Void)? = nil) {
    self.Style? = Style!
    self.Title? = Title!
    self.Message = Message
    self.Handler = Handler
  }
}
var alertObjArray = [alertObj]()
*/


var iwashere = "hi"
func initPool() -> WKProcessPool {
let processPool1: WKProcessPool
if let pool: WKProcessPool = getData(key: "pool") {
  processPool1 = pool
  iwashere += "yes2"
} else {
  processPool1 = WKProcessPool()
  setData(processPool1, key: "pool")
  iwashere += "no"
}
return processPool1
}
let processPool: WKProcessPool = initPool()

func setData(_ value: Any, key: String) {
  let archivedPool = NSKeyedArchiver.archivedData(withRootObject: value)
  //UserDefaults.standard.set(archivedPool, forKey: key)
  UserDefaults(suiteName: "group.at.co.weinmann.AdsBlockWKWebView")?.set(archivedPool, forKey: key)
}
func getData<T>(key: String) -> T? {
//if let val = UserDefaults.standard.value(forKey: key) as? Data,
if let val = UserDefaults(suiteName: "group.at.co.weinmann.AdsBlockWKWebView")?.value(forKey: key) as? Data,
  let obj = NSKeyedUnarchiver.unarchiveObject(with: val) as? T {
    iwashere += " yes1"
    return obj
  }
  return nil
}


/*
//import Foundation
import GCDWebServer
var webserv = "hi1"
class WebServer {
  static let instance = WebServer()
  let server = GCDWebServer()
  var base: String {
    return "http://localhost:\(self.server.port)"
  }
  func start() throws {
    webserv = "hi2:\(self.server.port)"
    guard !self.server.isRunning else {
      return
    }
    try self.server.start(
      options: [GCDWebServerOption_Port: 6571, GCDWebServerOption_BindToLocalhost: true, GCDWebServerOption_AutomaticallySuspendInBackground: true]
    )
    webserv = "hi3:\(self.server.port)"
  }
  
  func registerDefaultHandler() {
    server.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { request in
      return GCDWebServerDataResponse(html: "hi:default")
    })
  }
  
  func registerHandlerForMethod(_ method: String, module: String, resource: String, handler: @escaping (_ request: GCDWebServerRequest?) -> GCDWebServerResponse?) {
    webserv += " hi4"
    // Prevent serving content if the requested host isn't a whitelisted local host.
    let wrappedHandler = {(request: GCDWebServerRequest?) -> GCDWebServerResponse? in
      //guard let request = request, request.url.isLocal else {
        //return GCDWebServerResponse(statusCode: 403)
      //}
      
      if request?.url.absoluteString.hasPrefix("http://localhost:6571") == false {
        return GCDWebServerResponse(statusCode: 403)
        //return GCDWebServerDataResponse(html: "hi:nonlocal")
      }
      //webserv += " hi5"
      
      return handler(request)
    }
    server.addHandler(forMethod: method, path: "/\(module)/\(resource)", request: GCDWebServerRequest.self, processBlock: wrappedHandler)
  }
}

class SessionRestoreHandler {
  static func register(_ webServer: WebServer) {
    webServer.registerHandlerForMethod("GET", module: "errors", resource: "restore") { _ in
      guard let sessionRestorePath = Bundle.main.path(forResource: "SessionRestore", ofType: "html"), let sessionRestoreString = try? String(contentsOfFile: sessionRestorePath) else {
        return GCDWebServerResponse(statusCode: 404)
      }
      return GCDWebServerDataResponse(html: sessionRestoreString)
    }
    webServer.registerHandlerForMethod("GET", module: "errors", resource: "error.html") { request in
      if let range = request?.url.absoluteString.range(of: "=") {
        let phoneTest1 = request?.url.absoluteString[range.upperBound...]
        if let fileUpdater = try? FileHandle(forUpdating: URL.docDir.appendingPathComponent("debug2.txt")) {
          fileUpdater.seekToEndOfFile()
          fileUpdater.write("pt0\n\(phoneTest1!)\n\n".data(using: .utf8)!)
          fileUpdater.closeFile()
        }
        //var phoneTest = request?.url.absoluteString[range.upperBound...].replacingOccurrences(of: "%25", with: "%")
        var phoneTest = request?.url.absoluteString[range.upperBound...].removingPercentEncoding!
        //try! "\(phoneTest!)\n\n".write(to: URL.docDir.appendingPathComponent("debug2.txt"), atomically: true, encoding: .utf8)
        if let fileUpdater = try? FileHandle(forUpdating: URL.docDir.appendingPathComponent("debug2.txt")) {
          fileUpdater.seekToEndOfFile()
          fileUpdater.write("pt2\n\(phoneTest!)\n\n".data(using: .utf8)!)
          fileUpdater.closeFile()
        }
        phoneTest = phoneTest!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        NSLog("NSLog: pT3|\(phoneTest!)")
        //let phone = request?.url.absoluteString[range.upperBound...].removingPercentEncoding!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        //let phone = request?.url.absoluteString[range.upperBound...].removingPercentEncoding!
        let phone = request?.url.absoluteString[range.upperBound...]
        NSLog("NSLog: \(phone!)")
        //return GCDWebServerDataResponse(html: "hi:\(phone!)")
        //return GCDWebServerDataResponse(redirect: URL(string: phone!)!, permanent: false)
        return GCDWebServerDataResponse(redirect: URL(string: "\(phone!)")!, permanent: false)
      }
      //return GCDWebServerDataResponse(html: "hi:error")
      return GCDWebServerResponse(statusCode: 404)
      
      //guard let url = request?.url.originalURLFromErrorURL else {
        //return GCDWebServerResponse(statusCode: 404)
      //}
      //return GCDWebServerDataResponse(redirect: url, permanent: false)
    }
  }
}
*/


var wkscheme = "wks"
@available(iOS 11.0, *)
extension ViewController: WKURLSchemeHandler {
  enum schemeError: CustomNSError {
    case general
    case wrongscheme
    case wrongurl(scheme: String)
    var errorCode: Int {
      switch self {
        case .general: return 25001
        case .wrongscheme: return 25002
        case .wrongurl: return 25003
      }
    }
    var errorUserInfo: [String: Any] {
      switch self {
        case .general: return [NSLocalizedDescriptionKey: "A general error has occurred in context with the URL scheme."]
        case .wrongscheme: return [NSLocalizedDescriptionKey: "The URL scheme could not be recognized, or is not supported."]
        //case .wrongurl(let scheme): return [NSLocalizedDescriptionKey: "The requested URL does not exist in the current context.\(scheme)"]
        case .wrongurl(let scheme): return [NSLocalizedDescriptionKey: "The requested URL does not exist in the context of \"\(scheme)://\"."]
      }
    }
  }
  func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    //DispatchQueue.global().async {
    wkscheme += "<br><br>start"
      if let url = urlSchemeTask.request.url, url.scheme == "internal" {
        wkscheme += " internal"
        func sendResponse(data: Data) {
          let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "text/html; charset=utf-8", "Content-Length": "\(data.count)", "Cache-Control": "no-store"])!
          urlSchemeTask.didReceive(response)
          urlSchemeTask.didReceive(data)
          urlSchemeTask.didFinish()
        }
        if url.absoluteString.hasPrefix("internal://local/restore?url1=") {
          wkscheme += " case1<br>\(url)"
          let newUrl = url.absoluteString.replacingOccurrences(of: "internal://local/restore?url1=", with: "internal://local/restore?url2=")
          wkscheme += "<br>redirect: \(newUrl)"
          if let data = "<!DOCTYPE html><html><head><script>location.replace('\(newUrl)');</script></head><body>Loading... \(newUrl)<br><br><a href='javascript:location.reload()'>RELOAD</a><br><br><br></body></html>".data(using: .utf8) {
            sendResponse(data: data)
            //debugLog("Test1234")
          }
        } else if url.absoluteString.hasPrefix("internal://local/restore?url2=") {
          wkscheme += " case2<br>\(url)"
          let newUrl = url.absoluteString.replacingOccurrences(of: "internal://local/restore?url2=", with: "")
          wkscheme += "<br>redirect: \(newUrl)"
          if let data = "<!DOCTYPE html><html><head><script>location.replace('\(newUrl)');</script></head><body>Loading... \(newUrl)<br><br><a href='javascript:location.reload()'>RELOAD</a><br><br><br></body></html>".data(using: .utf8) {
            sendResponse(data: data)
          }
        } else if url.absoluteString.hasPrefix("internal://local/restore?history=") {
          wkscheme += " case3<br>\(url)"
          guard let sessionRestorePath = Bundle.main.path(forResource: "SessionRestore", ofType: "html"), let html = try? String(contentsOfFile: sessionRestorePath), let data = html.data(using: .utf8) else { return }
          sendResponse(data: data)
          //let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: "utf-8")
        } else if url.absoluteString.hasPrefix("internal://local/restorelog") {
          wkscheme += " case4<br>\(url)"
          if let data = "<!DOCTYPE html><html><head></head><body style='margin:30px;'><h1>Restore Log:</h1><br><div style='overflow:scroll;'>\(wkscheme)<br><br>end<br><br><br></div></body></html>".data(using: .utf8) {
            sendResponse(data: data)
          }
        } else {
          wkscheme += "<br>\(url)<br>stop error.wrongurl"
          urlSchemeTask.didFailWithError(schemeError.wrongurl(scheme: url.scheme!))
        }
      } else {
        wkscheme += "<br>\(urlSchemeTask.request.url!)<br>stop error.wrongscheme"
        urlSchemeTask.didFailWithError(schemeError.wrongscheme)
      }
    //}//
  }
  func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    wkscheme += "<br>\(urlSchemeTask.request.url!)<br>stop error.general"
    urlSchemeTask.didFailWithError(schemeError.general)
  }
}


class WebViewHistory: WKBackForwardList {
  /* Solution 1: return nil, discarding what is in backList & forwardList 
  override var backItem: WKBackForwardListItem? {
    return nil
  }
  override var forwardItem: WKBackForwardListItem? {
    return nil
  }*/
  /* Solution 2: override backList and forwardList to add a setter */
  var myBackList = [WKBackForwardListItem]()
  override var backList: [WKBackForwardListItem] {
    get {
      return myBackList
    }
    set(list) {
      myBackList = list
    }
  }
  func clearBackList() {
    backList.removeAll()
  }
}


class WebView: WKWebView {
  
  var history: WebViewHistory
  override var backForwardList: WebViewHistory {
    return history
  }
  //var history: String
  
  //init(frame: CGRect) {
  init(frame: CGRect, history: WebViewHistory) {
    let conf = WKWebViewConfiguration()
    self.history = history
    super.init(frame: frame, configuration: conf)
  }
  required init?(coder decoder: NSCoder) {
    fatalError()
  }
}


/*
class WebView2: WKWebView {

    var history: WebViewHistory

    init(frame: CGRect, configuration: WKWebViewConfiguration, history: WebViewHistory) {
        self.history = history
        super.init(frame: frame, configuration: configuration)
    }
    
    //Not sure about the best way to handle this part, it was just required for the code to compile...
    
    //required init?(coder: NSCoder) {
        //self.history = WebViewHistory()
        //super.init(coder: coder)
    //}
    
    override var backForwardList: WebViewHistory {
        return history
    }
    
    required init?(coder: NSCoder) {

        if let history = coder.decodeObject(forKey: "history") as? WebViewHistory {
            self.history = history
        }
        else {
            history = WebViewHistory()
        }

        super.init(coder: coder)
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(history, forKey: "history")
    }
    
}
*/


//@available(iOS 15, *)
@available(iOS 14.5, *)
extension ViewController: WKDownloadDelegate {
  func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
    //let temporaryDir = NSTemporaryDirectory()
    if let documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
      let fileName = documentsDir + "/" + suggestedFilename
      let url = URL(fileURLWithPath: fileName)
      lb.text! += " wkD:\(url)"
      showAlert(message: "\(url)")
      completionHandler(url)
    }
  }
  
  func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
    let err = error as NSError
    
    showAlert(message: "\(lbcounter) Error: \(err.code) \(err.localizedDescription)")
    lb.text! += " STOP err:\(err.code)"
    
    //showAlert(message: "Download failed \(error)")
  }
  
  func downloadDidFinish(_ download: WKDownload) {
    showAlert(message: "Download finished")
  }
  
}


class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
  
  var webView: WKWebView!
  
  var topNavBgView: UIView!
  //var topNavBgView: UIVisualEffectView!
  var progressView: UIProgressView!
  
  var urlField: UITextField!
  var button: UIButton!
  var kvButton: UIButton!
  //var lb: UITextView!
  var lb: UILabel!
  var lbcounter: Int = 0
  
  var tableView: UITableView!
  var origArray: Array<String> = ["https://www.google.com/"]
  var array: Array<String> = []
  var moverIndex: Int = -1
  var editButtonBgColor: UIColor = .appBgColor
  
  var url: String!
  var currentUserAgent: String = "default"
  var defaultUserAgent: String = "default"
  let desktopUserAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.1 Safari/605.1.15"
  
  var newNav: Bool = true
  
  var navTypeBackForward: Bool = false
  var navTypeDownload: Bool = false
  var showFrameLoadError: Bool = true
  
  var restoreIndex: Int = 0
  var restoreIndexLast: Int = 0
  var restoreUrls: Array<String> = ["https://www.google.com/"]
  var restorePosition: Int = 0
  //var bfarray: Array<String> = []
  var webView2: WebView!
  var webView3: WebView!
  var webViewPrefs: WKPreferences!
  var webViewConfig: WKWebViewConfiguration!
  var avPVC: AVPlayerViewController!
  var navUrl: String!
  var navUrlArray: Array<String> = []
  
  var insetT: CGFloat = 0
  var insetB: CGFloat = 0
  var insetL: CGFloat = 0
  var insetR: CGFloat = 0
  
  var lastDeviceOrientation: String = "initial"
  var allowedOrientations: UIInterfaceOrientationMask = .all
  
  var counter: Int = 0
  
  var shouldHideHomeIndicator = false
  override func prefersHomeIndicatorAutoHidden() -> Bool {
    return shouldHideHomeIndicator
    //return true
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return allowedOrientations
  }
  
  override func canPerformAction(_ action: Selector, withSender sender: Any!) -> Bool {
    //if [#selector(onMenu1(sender:)), #selector(onMenu2(sender:)), #selector(onMenu3(sender:))].contains(action) {
    if [#selector(onMenu1(sender:))].contains(action) && UIPasteboard.general.numberOfItems > 0 {
      return true
    } else {
      return false
    }
  }
  
  @objc internal func onMenu1(sender: UIMenuItem) {
    
    let testio: Int = userDefGroup.getData(key: "testkey")
    showAlert(message: "t: \(testio!)")
    userDefGroup.setData(Int(arc4random_uniform(999999) + 1), key: "testkey")
    
    
    UIPasteboard.general.items = []
    showAlert(message: "Clipboard was cleared.")
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    switch textField {
      case urlField:
        textField.frame.size.width -= 85
        //button.frame.origin.x -= 85
        view.addSubview(button)
        //textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        //textField.selectAll(nil)
        textField.textColor = .appBgColor
      default:
        break
    }
  }
  
  @objc func buttonClicked() {
    urlField.endEditing(true)
    
    /*let videoURL = URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
let player = AVPlayer(url: videoURL!)
let playerLayer = AVPlayerLayer(player: player)
playerLayer.frame = self.view.bounds
self.view.layer.addSublayer(playerLayer)
player.play()*/
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    /*delegate.playerViewController.player = delegate.player
    self.present(delegate.playerViewController, animated: true) {
    delegate.playerViewController.player!.play()
    }*/
    
    
    lb.text! += " \(UIApplication.shared.windows.count)"
    //adjustLabel()
    
    //func findAVPlayerViewController(controller: UIViewController) -> AVPlayerViewController? {
    func findAVPlayerViewController(controller: UIViewController) {
  if controller is AVPlayerViewController {
    lb.text! += " a2"
    //adjustLabel()
    //return controller as? AVPlayerViewController
  } else {
    //lb.text! += " a3"
    //adjustLabel()
    for subcontroller in controller.childViewControllers {
      lb.text! += " a4 \(subcontroller)"
      //adjustLabel()
      //if subcontroller is AVPlayerViewController {
      //return subcontroller as? AVPlayerViewController
      //}
      
      //if let result = findAVPlayerViewController(controller: subcontroller) {
        //lb.text! += " a5"
        //adjustLabel()
        //return result
      //}
    }
  }
  //return nil
}
    
    if UIApplication.shared.windows.count > 99 {
    //if let rootController = UIApplication.shared.keyWindow?.rootViewController {
    if let rootController = UIApplication.shared.windows[4].rootViewController {
    //lb.text! += " a1 \((UIApplication.shared.keyWindow?.rootViewController)!)"
    lb.text! += " a1 \((UIApplication.shared.windows[4].rootViewController)!)"
    //adjustLabel()
    findAVPlayerViewController(controller: rootController)
    //if let avPlayerViewController = findAVPlayerViewController(controller: rootController) {
      //lb.text! += " aX \(avPlayerViewController.player!)"
      //adjustLabel()
    //}
  }
  }
  
  //if UIApplication.shared.windows.count > 4 {
  //lb.text! += " a1 \((UIApplication.shared.windows[4].rootViewController)!)"
  //adjustLabel()
  //}
  
  if UIApplication.shared.windows.count >= 3 {
  if let targetSC = UIApplication.shared.windows[2].rootViewController!.childViewControllers.first(where: { $0 is AVPlayerViewController }) as? AVPlayerViewController {
  avPVC = targetSC
  lb.text! += " VC:\(avPVC!)"
  //lb.text! += " VCP:\(avPVC!.player)"
  if avPVC.player != nil {
  lb.text! += " VCP:\(avPVC!.player!)"
  }
  //adjustLabel()
  }
  }
  
  avPVC.player = player
  avPVC.player!.play()
  
  //BackgroundAudioBegin
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            //try session.setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print(error.localizedDescription)
        }
        lb.text! += " \(session.category)"
        //BackgroundAudioEnd
  
  var navlist = "navlist:"
  navUrlArray.forEach { url in
    navlist = navlist + "\n\n" + url
  }
    
    /*var viewlist = "list:"
    func findViewWithAVPlayerLayer(view: UIView) -> UIView? {
    //if view.layer is AVPlayerLayer {
    if view.layer.isKind(of:AVPlayerLayer.self) {
        lb.text! += " a1"
        //adjustLabel()
        return view
    }
    
    if let sublayers = view.layer.sublayers {
    for layer in sublayers {
    if !(layer is CALayer) {
        viewlist = viewlist + " a2:\(layer)"
        }
    }
}
    
    for v in view.subviews {
    if !(v.layer is CALayer) {
        viewlist = viewlist + " a3:\(v.layer)"
        }
        if let found = findViewWithAVPlayerLayer(view: v) {
            lb.text! += " a4"
            //adjustLabel()
            return found
        }
    }
    return nil
}
    
    if let viewWithAVPlayerLayer = findViewWithAVPlayerLayer(view: self.view) {
      lb.text! += " aX"
      //adjustLabel()
    }
    showAlert(message: viewlist)*/
    
    
    let deviceToken = delegate.sesscat
    lb.text! += " \(deviceToken)"
    //adjustLabel()
    
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    userDefaults.set(appVersion, forKey: "versionInfo")
    
    //let file = Bundle.main.path(forResource: "Info", ofType: "plist")!
    //let p = URL(fileURLWithPath: file)
    //let text = try? String(contentsOf: p)
    
    var text = "error"
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
      do {
        //text = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
        //text = try String(contentsOfFile: path)
        text = try String(contentsOf: URL(fileURLWithPath: path))
      } catch {}
    }
    //if let dic = NSDictionary(contentsOfFile: path) as? [String: Any] {}
    
    /*VerursachtError
    //let blitem = webView2.backForwardList.item(at: 0)!.url.absoluteString
    let blitem = webView2.backForwardList.forwardList.count
    let blcount1 = webView2.backForwardList.backList.count
    webView2.backForwardList.backList.removeAll()
    let blcount2 = webView2.backForwardList.backList.count
    showAlert(message: "\(navlist) \(blitem) \(blcount1)/\(blcount2) \(appVersion!) \(text!)")
    */
    
    showAlert(message: "\(navlist)\n\nfilecontent: \(text)\n\nappversion: \(appVersion!)\n\(webViewStartPagePref) \(webViewRestorePref) \(webViewSearchUrlPref) \(goBackOnEditPref) \(autoVideoDownloadPref)")
  }
  
  @objc func buttonPressed(gesture: UILongPressGestureRecognizer) {
    if gesture.state == .began {
      urlField.endEditing(true)
      changeUserAgent()
    }
  }
  
  @objc func kvButtonClicked() {
    if kvButton.backgroundColor == .appBgColor {
      //webView.evaluateJavaScript("document.body.style.zoom = 0.5;", completionHandler: nil)
      
      //webView.evaluateJavaScript("var el = document.querySelector('meta[name=viewport]'); if (el !== null) { el.setAttribute('content', 'width=1280, initial-scale=1, minimum-scale=0.1, maximum-scale=10, user-scalable=yes'); } else { var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=1280, initial-scale=1, minimum-scale=0.1, maximum-scale=10, user-scalable=yes'); document.getElementsByTagName('head')[0].appendChild(meta); }", completionHandler: nil)
      let pageWidth: CGFloat = 1280
      webView.evaluateJavaScript("var el = document.querySelector('meta[name=viewport]'); if (el === null) { var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta); alert('1'); } el = document.querySelector('meta[name=viewport]'); if (el !== null) { el.setAttribute('content', 'width=\(pageWidth), initial-scale=\(webView.frame.size.width / pageWidth), minimum-scale=0.1, maximum-scale=10, user-scalable=yes'); alert('2'); }", completionHandler: nil)
      //showAlert(message: "\(webView.frame.size.width)\n\(webView.frame.size.width / 1280)")
      
      kvButton.backgroundColor = .gray
    } else {
      //webView.evaluateJavaScript("document.body.style.zoom = 1.0;", completionHandler: nil)
      
      webView.reload()
      
      kvButton.backgroundColor = .appBgColor
    }
  }
  
  @objc func kvButtonPressed(gesture: UILongPressGestureRecognizer) {
    if gesture.state == .began {
      urlField.endEditing(true)
      //hapticFB.notificationOccurred(.success)
      var autoRotateInfo: String = "Enabled"
      if allowedOrientations == .all {
        if lastDeviceOrientation == "ls" {
          allowedOrientations = .landscape
        } else {
          allowedOrientations = .portrait
        }
        autoRotateInfo = "Disabled"
      } else {
        allowedOrientations = .all
      }
      userDefaults.set(Int(allowedOrientations.rawValue), forKey: "allowedOrientationsRaw")
      showAlert(message: "AutoRotate: \(autoRotateInfo)")
      lb.text! += " OR:\(lastDeviceOrientation)\(Int(allowedOrientations.rawValue))"
    }
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    switch textField {
      case urlField:
        if let text = textField.text, let textRange = Range(range, in: text) {
          let updatedText = text.replacingCharacters(in: textRange, with: string)
          array.removeAll()
          origArray.forEach { item in
            if item.lowercased().contains(updatedText.lowercased()) {
              array.append(item)
            }
          }
          if updatedText == "&showall" {
            array = origArray
          }
          if !(array.isEmpty) {
            tableView.isEditing = false
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            if !(tableView.isDescendant(of: view)) {
              view.addSubview(tableView)
            }
          }
          if array.isEmpty {
            if tableView.isDescendant(of: view) {
              tableView.removeFromSuperview()
            }
          }
          textField.textColor = .appBgColor
        }
      default:
        break
    }
    return true
  }
  
  //alertToUseIOS11()
  //var origArray: Array<String> = ["https://google.com","https://orf.at","https://derstandard.at","https://welt.de","https://willhaben.at","https://www.aktienfahrplan.com/plugins/rippletools/ripplenode.cgi"]
  //arrayString = array.joined(separator:" ")
  //array.insert(item, at: 0)
  //array = array.sorted(by: >)
  //array = array.reversed()
  //tableView.selectRow(at: nil, animated: false, scrollPosition: .top)
  //tableView.deselectRow(at: indexPath, animated: true)
  //origArray.append(urlField.text!)
  //array.remove(at: indexPath.row)
  //origArray.remove(at: indexPath.row)
  //origArray.remove(at: origArray.index(of: indexPath.row)!)
  //origArray.append(textField.text!)
  //if !(array.contains(textField.text!)) {}
  //tableView.beginUpdates()
  //tableView.endUpdates()
  //tableView.deleteRows(at: [indexPath], with: .automatic)
  //if updatedText.isEmpty {
  //array = origArray
  //}
  //if (cell.isHighlighted) {}
  //cell.textLabel!.backgroundColor = .gray
  //cell.textLabel!.layer.backgroundColor = UIColor.gray.cgColor
  //cell.layer.backgroundColor = UIColor.gray.cgColor
  //cell.selectionStyle = .blue
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
    cell.backgroundColor = .clear
    cell.textLabel!.font = UIFont.systemFont(ofSize: 15)
    cell.textLabel!.textColor = .appBgColor
    cell.textLabel!.text = "\(array[indexPath.row])"
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    tableView.frame.size.height = CGFloat(min(array.count * 30, tableMaxLinesPref * 30 + 5))
    return array.count
  }
  
  func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    cell?.contentView.backgroundColor = .appBgLightColor
    //cell?.backgroundColor = .gray
  }
  
  func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    cell?.contentView.backgroundColor = .clear
    //cell?.backgroundColor = .clear
  }
  
  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .none
  }
  
  func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
    return false
  }
  
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    if indexPath.row == moverIndex {
      return true
    }
    return false
  }
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let moveToIndex = origArray.firstIndex(of: array[destinationIndexPath.row])!
    let mover = array.remove(at: sourceIndexPath.row)
    array.insert(mover, at: destinationIndexPath.row)
    origArray = origArray.filter{$0 != mover}
    origArray.insert(mover, at: moveToIndex)
    UserDefaults.standard.set(origArray, forKey: "origArray")
    tableView.isEditing = false
    //showAlert(message: "mTI:\(moveToIndex)/\(origArray.count - 1) oA:\(origArray)")
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if array[indexPath.row] != "&showall" {
      urlField.endEditing(true)
      
      alertCounter = 0
      if array[indexPath.row].hasPrefix("javascript:") {
        //showAlert(title: "Interfer1", message: "he")
        webView.evaluateJavaScript(String(array[indexPath.row].dropFirst(11)), completionHandler: nil)
      } else {
        url = array[indexPath.row]
        startLoading()
      }
      
    }
    urlField.text = "\(array[indexPath.row])"
    if tableMoveTopPref == true {
      origArray = origArray.filter{$0 != urlField.text!}
      origArray.insert(urlField.text!, at: 0)
      UserDefaults.standard.set(origArray, forKey: "origArray")
    }
    if array[indexPath.row] == "&showall" {
      array = origArray
      tableView.reloadData()
      tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
  }
  
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
      self.deleteButtonClicked(url: self.array[indexPath.row])
    }
    let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
      self.editButtonClicked(url: self.array[indexPath.row])
    }
    //edit.backgroundColor = .appBgColor
    edit.backgroundColor = editButtonBgColor
    let dev = UITableViewRowAction(style: .normal, title: "Dev") { (action, indexPath) in
      self.devButtonClicked(url: self.array[indexPath.row])
    }
    dev.backgroundColor = .devBgColor
    return [delete, edit, dev]
  }
  
  @available(iOS 11.0, *)
  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, bool) in
      self.deleteButtonClicked(url: self.array[indexPath.row])
    }
    let edit = UIContextualAction(style: .normal, title: "Edit") { (action, view, bool) in
      self.editButtonClicked(url: self.array[indexPath.row])
    }
    //edit.backgroundColor = .appBgColor
    edit.backgroundColor = editButtonBgColor
    let dev = UIContextualAction(style: .normal, title: "Dev") { (action, view, bool) in
      self.devButtonClicked(url: self.array[indexPath.row])
    }
    dev.backgroundColor = .devBgColor
    let swipeActions = UISwipeActionsConfiguration(actions: [delete, edit, dev])
    swipeActions.performsFirstActionWithFullSwipe = false
    return swipeActions
  }
  
  @objc func deleteButtonClicked(url: String) {
    origArray = origArray.filter{$0 != url}
    UserDefaults.standard.set(origArray, forKey: "origArray")
    array = array.filter{$0 != url}
    tableView.reloadData()
  }
  
  @objc func editButtonClicked(url: String) {
    //urlField.endEditing(true)
    moverIndex = array.firstIndex(of: url)!
    tableView.reloadData()
    tableView.isEditing = true
    
    var goBackBy = goBackOnEditPref
    if goBackBy > webView.backForwardList.backList.count {
      goBackBy = webView.backForwardList.backList.count
    }
    webView.go(to: webView.backForwardList.item(at: goBackBy * -1)!)
    
    if #available(iOS 11, *) {
      if editButtonBgColor == .appBgColor {
        resetContentRuleList()
        editButtonBgColor = .gray
      } else {
        setupContentBlockFromStringLiteral() { }
        setupContentBlockFromFile() { }
        editButtonBgColor = .appBgColor
      }
    }
    //showAlert(message: "E:\(url)")
  }
  
  @objc func devButtonClicked(url: String) {
    urlField.endEditing(true)
    
    
    func deleteRSAKeyFromKeychain(tagName: String) {
      let queryFilter: [String: Any] = [String(kSecClass): kSecClassKey, String(kSecAttrKeyType): kSecAttrKeyTypeRSA, String(kSecAttrApplicationTag): tagName]
      SecItemDelete(queryFilter as CFDictionary)
      //let status: OSStatus = SecItemDelete(queryFilter as CFDictionary)
      //lb.text! += " keyDelStatus:\(status.description)"
    }
    
    func generateKeysAndStoreInKeychain(_ algorithm: KeyAlgorithm, keySize: Int, tagPrivate: String, tagPublic: String) -> (SecKey?, SecKey?) {
      deleteRSAKeyFromKeychain(tagName: tagPrivate)
      deleteRSAKeyFromKeychain(tagName: tagPublic)
      let publicKeyParameters: [String: Any] = [String(kSecAttrIsPermanent): true, String(kSecAttrAccessible): kSecAttrAccessibleAfterFirstUnlock, String(kSecAttrApplicationTag): tagPublic.data(using: .utf8)!]
      let privateKeyParameters: [String: Any] = [String(kSecAttrIsPermanent): true, String(kSecAttrAccessible): kSecAttrAccessibleAfterFirstUnlock, String(kSecAttrApplicationTag): tagPrivate.data(using: .utf8)!]
      let parameters: [String: Any] = [String(kSecAttrKeyType): algorithm.secKeyAttrType, String(kSecAttrKeySizeInBits): keySize, String(kSecReturnRef): true, String(kSecPublicKeyAttrs): publicKeyParameters, String(kSecPrivateKeyAttrs): privateKeyParameters]
      var error: Unmanaged<CFError>?
      let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, &error)
      if privateKey == nil {
        lb.text! += " Error:genKeysFail1"
        return (nil, nil)
      }
      let query: [String: Any] = [String(kSecClass): kSecClassKey, String(kSecAttrKeyType): algorithm.secKeyAttrType, String(kSecAttrApplicationTag): tagPublic.data(using: .utf8)!, String(kSecReturnRef): true]
      var publicKeyReturn: CFTypeRef?
      let result = SecItemCopyMatching(query as CFDictionary, &publicKeyReturn)
      if result != errSecSuccess {
        lb.text! += " Error:genKeysFail2"
        return (privateKey, nil)
      }
      let publicKey = publicKeyReturn as! SecKey?
      return (privateKey, publicKey)
    }
    
    func getPublicKeyBits(_ algorithm: KeyAlgorithm, publicKey: SecKey, tagPublic: String) -> Data? {
      let query: [String: Any] = [String(kSecClass): kSecClassKey, String(kSecAttrKeyType): algorithm.secKeyAttrType, String(kSecAttrApplicationTag): tagPublic.data(using: .utf8)!, String(kSecReturnData): true]
      var tempPublicKeyBits: CFTypeRef?
      var _ = SecItemCopyMatching(query as CFDictionary, &tempPublicKeyBits)
      guard let keyBits = tempPublicKeyBits as? Data else {
        lb.text! += " Error:getBitsFail"
        return nil
      }
      return keyBits
    }
    
    
    URL.docDir.appendingPathComponent("CSRNext.certSigningRequest").rename(to: "CSR.certSigningRequest")
    URL.docDir.appendingPathComponent("KEYNext.pem").rename(to: "KEY.pem")
    
    
    let tagPrivate = "at.co.weinmann.private.rsa256"
    let tagPublic = "at.co.weinmann.public.rsa256"
    let keyAlgorithm = KeyAlgorithm.rsa(signatureType: .sha256)
    let sizeOfKey = keyAlgorithm.availableKeySizes.last!
    let (privateKey, publicKey) = generateKeysAndStoreInKeychain(keyAlgorithm, keySize: sizeOfKey, tagPrivate: tagPrivate, tagPublic: tagPublic)
    
    
    /*
    //Get Key from Chain for swCrypt
    import SwCrypt
    let queryTE: [String: Any] = [String(kSecClass): kSecClassKey, String(kSecAttrKeyType): kSecAttrKeyTypeRSA, String(kSecAttrApplicationTag): tagPrivate.data(using: .utf8)!, String(kSecReturnData): true]
    var dataTE: CFTypeRef?
    var _ = SecItemCopyMatching(queryTE as CFDictionary, &dataTE)
    let derKeyAsDataTE = dataTE as? Data
    //Convert Key to PKCS1 with swCrypt
    let privKeyPKCS1 = SwKeyConvert.PrivateKey.derToPKCS1PEM(derKeyAsDataTE!)
    try! privKeyPKCS1.write(to: URL.docDir.appendingPathComponent("KEYPKCS1.pem"), atomically: true, encoding: .utf8)
    showAlert(message: "KEYPKCS1:\n\n\(privKeyPKCS1)")
    //Convert Key to PKCS8 with swCrypt
    let privKeyPKCS8der = PKCS8.PublicKey.addHeader(derKeyAsDataTE!)
    let privKeyPKCS8str = PEM.PublicKey.toPEM(privKeyPKCS8der)
    let privKeyPKCS8 = privKeyPKCS8str.replacingOccurrences(of: "PUBLIC", with: "RSA PRIVATE")
    try! privKeyPKCS8.write(to: URL.docDir.appendingPathComponent("KEYPKCS8.pem"), atomically: true, encoding: .utf8)
    showAlert(message: "KEYPKCS8:\n\n\(privKeyPKCS8)")
    */
    
    
    let publicKeyBits = getPublicKeyBits(keyAlgorithm, publicKey: publicKey!, tagPublic: tagPublic)
    let csr = CertificateSigningRequest(commonName: "Wolfgang Weinmann", countryName: "AT", emailAddress: "apps@weinmann.co.at", keyAlgorithm: keyAlgorithm)
    let builtCSR = csr.buildCSRAndReturnString(publicKeyBits!, privateKey: privateKey!)
    try! builtCSR!.write(to: URL.docDir.appendingPathComponent("CSRNext.certSigningRequest"), atomically: true, encoding: .utf8)
    
    var error: Unmanaged<CFError>?
    let keyData = SecKeyCopyExternalRepresentation(privateKey!, &error)
    let data = keyData! as Data
    //let pemPrefixBuffer: [UInt8] = [0x30, 0x81, 0x9f, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x81, 0x8d, 0x00]
    //var finalPemData = Data(bytes: pemPrefixBuffer as [UInt8], count: pemPrefixBuffer.count)
    //var finalPemData = Data([0x30, 0x2A, 0x30, 0x05, 0x06, 0x03, 0x2B, 0x65, 0x6E, 0x03, 0x21, 0x00])
    //finalPemData.append(data)
    //let finalPemString = finalPemData.base64EncodedString(options: .lineLength64Characters)
    let finalPemString = data.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
    let clientPrivateKeyString = "-----BEGIN RSA PRIVATE KEY-----\n\(finalPemString)\n-----END RSA PRIVATE KEY-----"
    try! clientPrivateKeyString.write(to: URL.docDir.appendingPathComponent("KEYNext.pem"), atomically: true, encoding: .utf8)
    showAlert(message: "KEYNext:\n\n\(clientPrivateKeyString)")
    
    deleteRSAKeyFromKeychain(tagName: tagPrivate)
    deleteRSAKeyFromKeychain(tagName: tagPublic)
    
    
    //https://github.com/digitalbazaar/forge
    //SSL_library_init()
    //SSL_load_error_strings()
    //OpenSSL_add_all_algorithms()
    
    /*
    func pkcs12(fromPem pemCertificate: String, withPrivateKey pemPrivateKey: String, p12Password: String = "XXX", certificateAuthorityFileURL: URL? = nil) throws -> NSData {
    //Create DER-certificate from PEM string
    let modifiedCert = pemCertificate.replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "").replacingOccurrences(of: "-----END CERTIFICATE-----", with: "").replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard let derCertificate = NSData(base64Encoded: modifiedCert, options: [])
    else {
        throw X509Error.cannotReadPEMCert
    }
    //...
    }
    let pemCer = try! String(data: Data(contentsOf: URL.docDir.appendingPathComponent("CER.pem")), encoding: .utf8)!
    let testp12 = try? pkcs12(fromPem: pemCer, withPrivateKey: pemKey)
    */
    
    func pkcs12(fromDer derCertificate: NSData, withPrivateKey pemPrivateKey: String, p12Password: String = "Bitrise78wolfi", certificateAuthorityFileURL: URL? = nil) throws -> NSData {
      let certificatePointer = CFDataGetBytePtr(derCertificate)
      let certificateLength = CFDataGetLength(derCertificate)
      let certificateData = UnsafeMutablePointer<UnsafePointer<UInt8>?>.allocate(capacity: 1)
      certificateData.pointee = certificatePointer
      let certificate = d2i_X509(nil, certificateData, certificateLength)
      let p12Path = try pemPrivateKey.data(using: .utf8)!.withUnsafeBytes { bytes throws -> String in
        let privateKeyBuffer = BIO_new_mem_buf(bytes.baseAddress, Int32(pemPrivateKey.count))
        let privateKey = PEM_read_bio_PrivateKey(privateKeyBuffer, nil, nil, nil)
        defer {
          BIO_free(privateKeyBuffer)
        }
        guard X509_check_private_key(certificate, privateKey) == 1 else {
          throw X509Error.keyDoesNotMatchCert
        }
        OpenSSL_add_all_algorithms()
        ERR_load_CRYPTO_strings()
        let certsStack = sk_X509_new_null()
        if let certificateAuthorityFileURL = certificateAuthorityFileURL {
          let rootCAFileHandle = try FileHandle(forReadingFrom: certificateAuthorityFileURL)
          let rootCAFile = fdopen(rootCAFileHandle.fileDescriptor, "r")
          let rootCA = PEM_read_X509(rootCAFile, nil, nil, nil)
          fclose(rootCAFile)
          rootCAFileHandle.closeFile()
          sk_X509_push(certsStack, rootCA)
        }
        let passPhrase = UnsafeMutablePointer(mutating: (p12Password as NSString).utf8String)
        let name = UnsafeMutablePointer(mutating: ("P12 Certificate" as NSString).utf8String)
        guard let p12 = PKCS12_create(passPhrase, name, privateKey, certificate, certsStack, 0, 0, 0, PKCS12_DEFAULT_ITER, 0) else {
          ERR_print_errors_fp(stderr)
          throw X509Error.cannotCreateKeystore
        }
        let path = URL.docDir.appendingPathComponent("P12.p12").path
        //let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        guard let fileHandle = FileHandle(forWritingAtPath: path) else {
          //NSLog("Test: \(path)")
          throw X509Error.cannotOpenFileHandle
        }
        let p12File = fdopen(fileHandle.fileDescriptor, "w")
        i2d_PKCS12_fp(p12File, p12)
        PKCS12_free(p12)
        fclose(p12File)
        fileHandle.closeFile()
        return path
      }
      guard let p12Data = NSData(contentsOfFile: p12Path) else {
        throw X509Error.cannotReadP12Cert
      }
      //try? FileManager.default.removeItem(atPath: p12Path)
      lb.text! += " p12Path:\(p12Path)"
      return p12Data
    }
    
    enum X509Error: Error {
      case keyDoesNotMatchCert
      case cannotCreateKeystore
      case cannotOpenFileHandle
      case cannotReadP12Cert
    }
    
    var derCer: NSData = NSData()
    let derCerUrl = URL.docDir.appendingPathComponent("CER.cer")
    if derCerUrl.checkFileExist() {
      derCer = NSData(contentsOf: derCerUrl)!
    }
    var pemKey: String = ""
    let pemKeyUrl = URL.docDir.appendingPathComponent("KEY.pem")
    if pemKeyUrl.checkFileExist() {
      pemKey = try! String(data: Data(contentsOf: pemKeyUrl), encoding: .utf8)!
    }
    if !pemKey.isEmpty && derCer.length != 0 {
      //let p12Data = try? pkcs12(fromDer: derCer, withPrivateKey: pemKey)
      //lb.text! += (" p12Data:\(p12Data!)").prefix(50) + "..."
      do {
        let p12Data = try pkcs12(fromDer: derCer, withPrivateKey: pemKey)
        lb.text! += (" p12Data:\(p12Data)").prefix(50) + "..."
      } catch let error as X509Error {
        lb.text! += " X509Error:"
        switch error {
        case .keyDoesNotMatchCert:
          lb.text! += "keyDoesNotMatchCert"
        case .cannotCreateKeystore:
          lb.text! += "cannotCreateKeystore"
        case .cannotOpenFileHandle:
          lb.text! += "cannotOpenFileHandle"
        case .cannotReadP12Cert:
          lb.text! += "cannotReadP12Cert"
        }
      } catch let error {
        lb.text! += " Error:\(error)"
      }
    }
    
    
    if lb.isHidden == true {
      lb.isHidden = false
      webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
      //webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    } else {
      lb.isHidden = true
      webView.removeObserver(self, forKeyPath: "URL")
      //webView.removeObserver(self, forKeyPath: "estimatedProgress")
      UIPasteboard.general.string = lb.text!
    }
    
    webView.evaluateJavaScript("var el = document.querySelector('input[type=password]'); if (el !== null) { window.webkit.messageHandlers.iosListener.postMessage('iP' + el.getAttribute('name')); }", completionHandler: nil)
    //let urlArr = webView.url!.absoluteString.components(separatedBy: "/")
    //let server = urlArr[2]
    let server = "www.example.com"
    let account = "tester2"
    let password = ("test123").data(using: String.Encoding.utf8)!
    var query: [String: Any] = [kSecClass as String: kSecClassInternetPassword, kSecAttrAccount as String: account, kSecAttrServer as String: server, kSecValueData as String: password]
    var status: OSStatus = SecItemDelete(query as CFDictionary)
    var message = "1-del: \(status)\n\n"
    status = SecItemAdd(query as CFDictionary, nil)
    message += "2-add: \(status)\n\n"
    query = [kSecClass as String: kSecClassInternetPassword, kSecAttrAccount as String: account, kSecAttrServer as String: server, kSecReturnData as String: kCFBooleanTrue!]
    var dataTypeRef: AnyObject? = nil
    status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    if status == noErr {
      let result = String(data: (dataTypeRef as! Data?)!, encoding: .utf8)
      message += "3-load: \(result!)"
    } else {
      message += "3-load: \(status)"
    }
    showAlert(message: message)
    
    //SecAddSharedWebCredential(server as CFString, account as CFString, "test12" as CFString) { (error) in
      //self.showAlert(message: "fail2 \(error)")
    //}
    
    //showAlert(message: "D:\(url)")
    //lb.text! += " D"
    lb.text! += " \(defaultUserAgent) \(server)"
    //adjustLabel()
  }
  
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    switch textField {
      case urlField:
        if tableView.isDescendant(of: view) {
          tableView.removeFromSuperview()
        }
        if webView3.isDescendant(of: view) {
          webView3.removeFromSuperview()
        }
        navUrlArray = []
        lb.text = "log:"
        //adjustLabel()
      default:
        break
    }
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    switch textField {
      case urlField:
        if tableView.isDescendant(of: view) {
          tableView.removeFromSuperview()
        }
        textField.selectedTextRange = nil
        button.removeFromSuperview()
        //button.frame.origin.x += 85
        textField.frame.size.width += 85
        //progressView.frame.size.width += 85
      default:
        break
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    switch textField {
      case urlField:
        textField.endEditing(true)
        if !(textField.text!.isEmpty) {
          if textField.text!.hasPrefix("+") {
            textField.text!.removeFirst()
            origArray = origArray.filter{$0 != textField.text!}
            origArray.insert(textField.text!, at: 0)
            UserDefaults.standard.set(origArray, forKey: "origArray")
          }
          if textField.text!.hasPrefix(">") {
            textField.text!.removeFirst()
            navTypeDownload = true
          }
          
          alertCounter = 0
          if textField.text!.hasPrefix("javascript:") {
            webView.evaluateJavaScript(String(textField.text!.dropFirst(11)), completionHandler: nil)
            //break
          } else {
            url = textField.text!
            startLoading()
          }
          
          //url = textField.text!
          //startLoading()
        }
      default:
        break
    }
    return true
  }
  
  /*
  private func showAlertOld(message: String) {
    let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
  */
  
  private func showAlert(message: String? = nil) {
  //private func showAlert(message: String) {
    if let message = message {
      messages.append(message)
    }
    guard messages.count > 0 else { return }
    let message = messages.first
    let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { (action) in
      messages.removeFirst()
      self.showAlert()
    })
    hapticFB.notificationOccurred(.success)
    present(alert, animated: true, completion: nil)
  }
  
  
  private func showJSAlert(type: String, title: String? = nil, message: String, input: String? = nil, completionHandler: @escaping (Any?) -> Void) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    if type == "alert" {
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        completionHandler("\(message)")
      }))
    }
    if type == "confirm" {
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        completionHandler(true)
      }))
      alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
        completionHandler(false)
      }))
    }
    if type == "prompt" {
      alert.addTextField { (textField) in
        textField.text = input
      }
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        if let text = alert.textFields?.first?.text {
          completionHandler(text)
        } else {
          completionHandler(input)
        }
      }))
      alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
        completionHandler(nil)
      }))
    }
    hapticFB.notificationOccurred(.success)
    present(alert, animated: true, completion: nil)
  }
  
  /*
  private func showJSAlert(style: String? = nil, title: String? = nil, message: String? = nil, completionHandler: ((Any) -> Void)? = nil) {
    if let message = message {
      if alertObjArray.count < 5 {
        alertObjArray.append(alertObj(Style: style, Title: title, Message: message, Handler: completionHandler))
      }
    }
    guard alertObjArray.count > 0 else { return }
    let title = alertObjArray.first!.Title ?? "Alert"
    let message = alertObjArray.first!.Message
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
      completionHandler?("\(alertObjArray.count):\(message)")
      alertObjArray.removeFirst()
      if alertObjArray.count > 0 {
      if alertObjArray.first!.Handler != nil {
      self.showAlert() { (response) in
      completionHandler?(alertObjArray.first!.Handler)
      }
      } else {
      self.showAlert()
      }
      } else {
      self.showAlert()
      }
    }))
    self.present(alert, animated: true) { hapticFB.notificationOccurred(.success) }
  }
  */
  
  
  private func adjustLabel() {
    
    lbcounter += 1
    
    let attributedString = NSMutableAttributedString(string: lb.text!)
    if let regularExpression = try? NSRegularExpression(pattern: "STOP") {
      let matchedResults = regularExpression.matches(in: lb.text!, options: [], range: NSRange(location: 0, length: attributedString.length))
      for matched in matchedResults {
        attributedString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.red], range: matched.range)
      }
      lb.attributedText = attributedString
    }
    
    lb.frame.size.height = lb.sizeThatFits(CGSize(width: lb.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
    lb.frame.origin.y = view.frame.height - lb.frame.size.height - insetB + 14
  }
  
  
  @available(iOS 11, *)
  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    insetT = self.view.safeAreaInsets.top
    insetB = self.view.safeAreaInsets.bottom
    insetL = self.view.safeAreaInsets.left
    insetR = self.view.safeAreaInsets.right
    lb.text! += " dc"
  }
  
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    var deviceOrientation = "pt"
    if (view.frame.width > view.frame.height) {
      deviceOrientation = "ls"
    }
    
    if !(deviceOrientation == lastDeviceOrientation) {
      
      let defaultM: CGFloat = 5
      var insetTM: CGFloat = insetT
      //var insetBM: CGFloat = insetB
      var insetLM: CGFloat = insetL
      var insetRM: CGFloat = insetR
      if insetTM == 0 { insetTM = defaultM }
      //if insetBM == 0 { insetBM = defaultM }
      if insetLM == 0 { insetLM = defaultM }
      if insetRM == 0 { insetRM = defaultM }
      let elementH: CGFloat = 30
      let elementW: CGFloat = 80
      
      urlField.frame = CGRect(x: insetLM, y: insetTM, width: view.frame.width - insetLM - insetRM, height: elementH)
      if button.isDescendant(of: view) {
        urlField.frame.size.width = view.frame.width - insetLM - insetRM - elementW - defaultM
      }
      
      button.frame = CGRect(x: insetLM + view.frame.width - insetLM - insetRM - elementW, y: insetTM, width: elementW, height: elementH)
      
      kvButton.frame = CGRect(x: insetLM, y: defaultM, width: elementW, height: elementH)
      
      topNavBgView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: insetTM + elementH + defaultM)
      
      progressView.frame = CGRect(x: insetLM, y: insetTM + elementH + 2, width: view.frame.width - insetLM - insetRM, height: 2)
      progressView.transform = progressView.transform.scaledBy(x: 1, y: 0.5)
      
      tableView.frame = CGRect(x: insetL, y: insetTM + elementH + defaultM, width: view.frame.width - insetL - insetR, height: 0)
      tableView.reloadData()
      
      webView.frame = CGRect(x: insetL, y: insetTM + elementH + defaultM, width: view.frame.width - insetL - insetR, height: view.frame.height - insetTM - elementH - defaultM)
      if webView2.isDescendant(of: view) {
        webView.frame.origin.y = insetTM + elementH + defaultM + 200
        webView.frame.size.height = view.frame.height - insetTM - elementH - defaultM - 200
      }
      
      webView3.frame = CGRect(x: insetL, y: insetTM + elementH + defaultM, width: view.frame.width - insetL - insetR, height: view.frame.height - insetTM - elementH - defaultM)
      //webView3.frame = CGRect(x: insetL, y: insetTM, width: view.frame.width - insetL - insetR, height: view.frame.height - insetTM)
      
      lb.frame = CGRect(x: insetL + 21, y: 0, width: view.frame.width - insetL - insetR - 42, height: 0)
      adjustLabel()
      
      
      //webView.scrollView.contentSize = CGSize(width: self.view.frame.width - insetL - insetR, height: self.view.frame.height - insetT - urlField.frame.size.height - 10)
      //webView.scrollView.contentInset = UIEdgeInsets(top: insetT + urlField.frame.size.height + 10, left: 0, bottom: 0, right: 0)
      //webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: insetT + urlField.frame.size.height + 10, left: 0, bottom: 0, right: 0)
      //webView.scrollView.contentSize.height = self.view.frame.height - insetT - urlField.frame.size.height - 10
      //webView.scrollView.frame.origin.y = insetT + urlField.frame.size.height + 100
      //webView.scrollView.frame.size.height = self.view.frame.height - insetT - urlField.frame.size.height - 100
      //webView.scrollView.contentOffset.y = -insetT - urlField.frame.size.height - 10
      
      /*
      webView.setValue(true, forKey: "_haveSetObscuredInsets")
      webView.setValue(UIEdgeInsets(top: insetT + urlField.frame.size.height + 10, left: 0, bottom: insetB, right: 0), forKey: "_obscuredInsets")
      webView.scrollView.contentInset = UIEdgeInsets(top: insetT + urlField.frame.size.height + 10, left: 0, bottom: insetB, right: 0)
      if #available(iOS 11, *) {
        webView.scrollView.contentInsetAdjustmentBehavior = .never
      }
      //webView.scrollView.scrollIndicatorInsets = webView.scrollView.contentInset
      webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: urlField.frame.size.height + 10, left: 0, bottom: 0, right: 0)
      */
      
      
      if !(lastDeviceOrientation == "initial") {
        if deviceOrientation == "pt" {
          shouldHideHomeIndicator = false
          //shouldHideHomeIndicator = true
        } else {
          shouldHideHomeIndicator = true
        }
        if #available(iOS 11, *) {
          setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
      }
      
      lastDeviceOrientation = deviceOrientation
      lb.text! += " \(insetT) \(insetB) \(insetL) \(insetR) \(deviceOrientation)"
    }
  }
  
  
  override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        loadUserPrefs()
        
        if userDefaults.exists(key: "allowedOrientationsRaw") {
          allowedOrientations = .init(rawValue: UInt(userDefaults.integer(forKey: "allowedOrientationsRaw")))
        }
        
        if (UserDefaults.standard.object(forKey: "origArray") != nil) {
          origArray = UserDefaults.standard.stringArray(forKey: "origArray") ?? [String]()
        }
        
        //view.backgroundColor = .lightGray
        //view.backgroundColor = UIColor(white: 0.90, alpha: 1)
        view.backgroundColor = .viewBgColor
        
        UserDefaults.standard.register(defaults: [
            ruleId1 : false,
            ruleId2 : false
            ])
        UserDefaults.standard.synchronize()
        
        webViewPrefs = WKPreferences()
        webViewPrefs.javaScriptEnabled = true
        webViewPrefs.javaScriptCanOpenWindowsAutomatically = false
        
        webViewConfig = WKWebViewConfiguration()
        webViewConfig.preferences = webViewPrefs
        webViewConfig.processPool = processPool
        webViewConfig.allowsInlineMediaPlayback = true
        webViewConfig.mediaTypesRequiringUserActionForPlayback = []
        //webViewConfig.mediaTypesRequiringUserActionForPlayback = .all
        //webViewConfig.ignoresViewportScaleLimits = true
        
        var userScript: String = ""
        userScript += "document.addEventListener('click', function() { window.webkit.messageHandlers.iosListener.postMessage('c'); });"
        userScript += " "
        userScript += "var el = document.querySelector('meta[name=viewport]'); if (el !== null) { el.setAttribute('content', 'width=device-width, initial-scale=1.0, minimum-scale=0.1, maximum-scale=15.0, user-scalable=yes'); }"
        userScript += " "
        userScript += "document.addEventListener('focus', function() { document.activeElement?.blur(); window.webkit.messageHandlers.iosListener.postMessage('foc'); }); document.querySelector('input').blur(); document.activeElement?.blur(); Object.defineProperty(document, 'activeElement', { get: function() { return null; } });"
        userScript += " "
        userScript += "var el = document.querySelector('input[type=file]'); if (el !== null) { window.webkit.messageHandlers.iosListener.postMessage('iF'); el.removeAttribute('capture'); }"
        userScript += " "
        userScript += "setTimeout(function() { var videos = document.getElementsByTagName('video'); for (var i = 0; i < videos.length; i++) { videos.item(i).pause(); window.webkit.messageHandlers.iosListener.postMessage('vs' + videos.item(i).src); /*window.webkit.messageHandlers.iosListener.postMessage('vc' + videos.item(i).currentSrc);*/ } }, 3000);"
        userScript += " "
        userScript += "window.webkit.messageHandlers.iosListener.postMessage('dF');"
        webViewConfig.userContentController.addUserScript(WKUserScript(source: userScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        //webViewConfig.userContentController.addUserScript(WKUserScript(source: "var el = document.querySelector('meta[name=viewport]'); if (el !== null) { el.setAttribute('content', 'width=device-width, initial-scale=1.0, minimum-scale=0.1, maximum-scale=15.0, user-scalable=yes'); } window.webkit.messageHandlers.iosListener.postMessage('dF'); setTimeout(function() { var videos = document.getElementsByTagName('video'); for (var i = 0; i < videos.length; i++) { videos.item(i).pause(); window.webkit.messageHandlers.iosListener.postMessage('vs' + videos.item(i).src); /*window.webkit.messageHandlers.iosListener.postMessage('vc' + videos.item(i).currentSrc);*/ } }, 3000); var el = document.querySelector('input[type=file]'); if (el !== null) { window.webkit.messageHandlers.iosListener.postMessage('iF'); el.removeAttribute('capture'); } document.querySelector('input').blur(); /*Object.defineProperty(document, 'activeElement', { get: function() { return null; } });*/", injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        //webViewConfig.userContentController.addUserScript(WKUserScript(source: "document.addEventListener('click', function() { window.webkit.messageHandlers.iosListener.postMessage('c'); })", injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        webViewConfig.userContentController.add(self, name: "iosListener")
        
        if #available(iOS 11.0, *) {
          webViewConfig.setURLSchemeHandler(self, forURLScheme: "internal")
        }
        
        webView = WKWebView(frame: view.bounds, configuration: webViewConfig)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.clipsToBounds = false
        webView.scrollView.clipsToBounds = false
        
        /*
        if #available(iOS 11, *) {
        if let cookies: [HTTPCookie] = getData(key: "cookies") {
        for (index, cookie) in cookies.enumerated() {
        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
        iwashere += "\n\ncookie \(index+1)/\(cookies.count):\n\(cookie)"
        //self.lb.text! += " c\(index+1):\(cookie.domain)"
        if index + 1 == cookies.count {
        self.lb.text! += " cR:\(cookies.count)"
        }
        }
        }
        }
        }
        */
        
webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
          self.defaultUserAgent = result as! String
        }
        //webView.isHidden = true
        view.addSubview(webView)
        
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        if #available(iOS 15, *) {
          webView.addObserver(self, forKeyPath: "themeColor", options: .new, context: nil)
        }
        
        counter += 1
        
        //lb = UITextView(frame: CGRect.zero)
        //lb.isEditable = false
        //lb.font = lb.font!.withSize(12)
        lb = UILabel(frame: CGRect.zero)
        lb.text = "log:"
        lb.textAlignment = .center
        lb.font = lb.font.withSize(12)
        lb.backgroundColor = .devBgColor
        
        lb.layer.cornerRadius = 5
        //lb.layer.masksToBounds = true
        lb.clipsToBounds = true
        
        lb.numberOfLines = 0
        //lb.isUserInteractionEnabled = true
        lb.isHidden = true
        view.addSubview(lb)
        
        lb.addObserver(self, forKeyPath: "text", options: [.old, .new], context: nil)
        
        topNavBgView = UIView(frame: CGRect.zero)
        //topNavBgView.backgroundColor = UIColor.viewBgColor.withAlphaComponent(0.85)
        //topNavBgView.backgroundColor = .viewBgColor
        topNavBgView.backgroundColor = .appBgColor
        //topNavBgView = UIVisualEffectView(frame: CGRect.zero)
        //topNavBgView.effect = UIBlurEffect(style: UIBlurEffect.Style.regular)
        //topNavBgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(topNavBgView)
        
        progressView = UIProgressView(frame: CGRect.zero)
        //progressView.progressViewStyle = .bar
        progressView.progressTintColor = .appBgColor
        progressView.trackTintColor = .clear
        view.addSubview(progressView)
        
        urlField = UITextField(frame: CGRect.zero)
        urlField.placeholder = "Type your Address"
        urlField.font = UIFont.systemFont(ofSize: 15)
        urlField.textColor = .appBgColor
        urlField.tintColor = .appBgColor
        urlField.backgroundColor = .fieldBgColor
        //urlField.borderStyle = UITextField.BorderStyle.roundedRect
        //urlField.layer.borderWidth = 0
        
        urlField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 30))
        urlField.leftViewMode = .always
        
        urlField.layer.cornerRadius = 5
        urlField.clipsToBounds = true
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = UITextAutocorrectionType.no
        
        //let keyboardView = UIView(frame: CGRect(x: 0, y: view.frame.height - 2, width: view.frame.width, height: 2))
        //keyboardView.backgroundColor = .appBgColor
        let keyboardView = UIInputView(frame: CGRect(x: 0, y: view.frame.height - 40, width: view.frame.width, height: 40), inputViewStyle: .keyboard)
        //keyboardView.backgroundColor = .gray
        urlField.inputAccessoryView = keyboardView
        kvButton = UIButton(frame: CGRect.zero)
        //kvButton.frame = CGRect(x: 5, y: 5, width: 80, height: 30)
        kvButton.backgroundColor = .appBgColor
        kvButton.layer.cornerRadius = 5
        kvButton.clipsToBounds = true
        kvButton.setTitle("Test", for: .normal)
        kvButton.setTitleColor(.buttonFgColor, for: .normal)
        kvButton.addTarget(self, action: #selector(self.kvButtonClicked), for: .touchUpInside)
        let kvButtonLongPress = UILongPressGestureRecognizer(target: self, action: #selector(kvButtonPressed(gesture:)))
        //kvButtonLongPress.minimumPressDuration = 3
        kvButton.addGestureRecognizer(kvButtonLongPress)
        keyboardView.addSubview(kvButton)
        
        urlField.keyboardType = UIKeyboardType.webSearch
        urlField.returnKeyType = UIReturnKeyType.done
        urlField.clearButtonMode = UITextField.ViewMode.whileEditing
        urlField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        urlField.delegate = self
        view.addSubview(urlField)
        
    //urlField.translatesAutoresizingMaskIntoConstraints = false
    //urlField.leftAnchor.constraint(equalTo: view.safeLeftAnchor, constant: 5.0).isActive = true
    //urlField.rightAnchor.constraint(equalTo: view.safeRightAnchor, constant: -5.0).isActive = true
    //urlField.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 5.0).isActive = true
    //urlField.bottomAnchor.constraint(equalTo: urlField.topAnchor, constant: 30.0).isActive = true
        
        let menuController: UIMenuController = UIMenuController.shared
        menuController.isMenuVisible = true
        menuController.arrowDirection = UIMenuControllerArrowDirection.down
        menuController.setTargetRect(CGRect.zero, in: self.view)
        let menuItem_1: UIMenuItem = UIMenuItem(title: "Clear", action: #selector(onMenu1(sender:)))
        //let menuItem_2: UIMenuItem = UIMenuItem(title: "Menu2", action: #selector(onMenu2(sender:)))
        //let menuItem_3: UIMenuItem = UIMenuItem(title: "Menu3", action: #selector(onMenu3(sender:)))
        //let myMenuItems: [UIMenuItem] = [menuItem_1, menuItem_2, menuItem_3]
        let myMenuItems: [UIMenuItem] = [menuItem_1]
        menuController.menuItems = myMenuItems
        
        
        button = UIButton(frame: CGRect.zero)
        //button.frame = CGRectMake(15, -50, 300, 500)
        //button.frame = CGRect(x: 100, y: 400, width: 100, height: 50)
        button.backgroundColor = .appBgColor
        
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.buttonFgColor, for: .normal)
        button.addTarget(self, action: #selector(self.buttonClicked), for: .touchUpInside)
        
        //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonClicked))
        //tapGesture.numberOfTapsRequired = 1
        //button.addGestureRecognizer(tapGesture)
        let buttonLongPress = UILongPressGestureRecognizer(target: self, action: #selector(buttonPressed(gesture:)))
        //buttonLongPress.minimumPressDuration = 3
        button.addGestureRecognizer(buttonLongPress)
        
        tableView = UITableView(frame: CGRect.zero)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        tableView.dataSource = self
        tableView.delegate = self
        //tableView.backgroundColor = .lightGray
        tableView.backgroundColor = .viewBgLightColor
        tableView.rowHeight = 30
        //tableView.estimatedRowHeight = 0
        //tableView.estimatedSectionHeaderHeight = 0
        //tableView.estimatedSectionFooterHeight = 0
        //if #available(iOS 11.0, *) {
          //tableView.contentInsetAdjustmentBehavior = .never
        //} else {
          //automaticallyAdjustsScrollViewInsets = false
        //}
        //tableView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -15)
        //tableView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -10)
        //tableView.contentSize.width = 100
        //tableView.clipsToBounds = false
        //tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, -30)
        tableView.separatorColor = .appBgColor
        //tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
        
        if (UserDefaults.standard.object(forKey: "urls") != nil) {
        restoreUrls = UserDefaults.standard.stringArray(forKey: "urls") ?? [String]()
        }
        
        if !(restoreUrls[restoreIndex].hasSuffix("//www.google.com/")) {
          restoreUrls.insert("https://www.google.com/", at: 0)
        }
        
        if (UserDefaults.standard.object(forKey: "urlsBackup") != nil) {
        let urlsBackup = UserDefaults.standard.stringArray(forKey: "urlsBackup") ?? [String]()
        let urlsBackupString = urlsBackup.joined(separator: "\n")
        try! urlsBackupString.write(to: URL.docDir.appendingPathComponent("urlsBackup.txt"), atomically: true, encoding: .utf8)
        }
        
        UserDefaults.standard.set(restoreUrls, forKey: "urlsBackup")
        
        if (UserDefaults.standard.object(forKey: "currentIndexButLast") != nil) {
        restorePosition = UserDefaults.standard.integer(forKey: "currentIndexButLast")
        }
        
        restoreIndexLast = restoreUrls.count - 1
        
        //try? WebServer.instance.start()
        //WebServer.instance.registerDefaultHandler()
        //SessionRestoreHandler.register(WebServer.instance)
        
        if (UserDefaults.standard.object(forKey: "urlsJson") != nil) {
        //restoreUrlsJson = UserDefaults.standard.string(forKey: "urlsJson")!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        restoreUrlsJson = UserDefaults.standard.string(forKey: "urlsJson")
        }
        let restoreUrlsJsonData = Data(restoreUrlsJson.utf8)
        if let restoreUrlsJsonSE = try? JSONSerialization.jsonObject(with: restoreUrlsJsonData, options: []) as? [String: Any] {
        if let names = restoreUrlsJsonSE?["history"] as? [String] {
            restoreIndexLast = names.count - 1
        }
    }
        restoreUrlsJson = restoreUrlsJson!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        //if restoreIndexLast > 0 {
          //DispatchQueue.main.async {
            //self.askRestore()
          //}
        //}
        
    //webView.load(URLRequest(url: URL(string: restoreUrls[restoreIndex])!))
    
    let timestamp = Date().format("dd.MM.yyyy HH:mm")
    var bflist = "\(timestamp) LASTbflist:"
    for (index, url) in restoreUrls.enumerated() {
      //self.webView.load(URLRequest(url: url))
      //DispatchQueue.main.async {
      //self.webView.load(URLRequest(url: URL(string: url)!))
      //}
      bflist += "<br><br>\(index+1): \(url)"
    }
    bflist += "<br><br>RestorePosition: \(restorePosition)"
    //DispatchQueue.main.async {
      //self.showAlert(message: "\(bflist)")
    //}
    
    webView2 = WebView(frame: CGRect.zero, history: WebViewHistory())
    //webView2.navigationDelegate = self
    webView2.allowsBackForwardNavigationGestures = true
    webView2.frame = CGRect(x: 0, y: 84, width: webView.frame.size.width, height: 200)
    webView2.loadHTMLString("<b>So long and thanks for all the fish!</b><br><a href='https://www.google.com/'>hoho</a>", baseURL: nil)
    //view.addSubview(webView2)
    
    webView3 = WebView(frame: CGRect.zero, history: WebViewHistory())
    webView3.loadHTMLString("<body style='background-color:transparent;color:white;margin:10px;'><h1 id='a' style='position:relative;top:35px;background-color:white;color:rgba(66,46,151,1.0);'>Loading last Session... <span style='position:absolute;left:310px;'>\(restoreIndex+1)/\(restoreIndexLast+1)</span></h1><div id='b' style='position:relative;top:50px;overflow:scroll;' onclick='copy()'>\(bflist)<br><br>AddressBar: \(origArray.count)<br><br>\(origArray)</div><script>function copy() { var range = document.createRange(); range.selectNode(document.getElementById('b')); window.getSelection().removeAllRanges(); window.getSelection().addRange(range); document.execCommand('copy'); window.getSelection().removeAllRanges(); }</script></body>", baseURL: nil)
    webView3.isOpaque = false
    //webView3.backgroundColor = .orange
    //webView3.scrollView.backgroundColor = .orange
    webView3.backgroundColor = .appBgColor
    webView3.scrollView.backgroundColor = .appBgColor
    webView3.scrollView.isScrollEnabled = true
    //webView3.scrollView.bounces = false
    view.addSubview(webView3)
    
    avPVC = AVPlayerViewController()
    NotificationCenter.default.addObserver(self, selector: #selector(focusNewWindow), name: .UIWindowDidResignKey, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(enterBackground), name: .UIApplicationDidEnterBackground, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(enterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(resignActive), name: .UIApplicationWillResignActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(becomeActive), name: .UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: .UIApplicationWillTerminate, object: nil)
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.togglePlayPauseCommand.addTarget { [unowned self] event in
      if self.avPVC.player!.rate == 0.0 {
        self.avPVC.player!.play()
      } else {
        self.avPVC.player!.pause()
      }
      return .success
    }
    
    
        url = "https://www.google.com/"
        
        if #available(iOS 11, *) {
            let group = DispatchGroup()
            group.enter()
            setupContentBlockFromStringLiteral {
                group.leave()
            }
            group.enter()
            setupContentBlockFromFile {
                group.leave()
            }
            group.notify(queue: .main, execute: { [weak self] in
                //self?.startLoading()
                self?.askRestore()
            })
        } else {
            //alertToUseIOS11()
            //startLoading()
            askRestore()
        }
    }
  
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.body as? String == "restore" {
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
        self.topNavBgView.backgroundColor = .viewBgColor
        self.webView3.removeFromSuperview()
      }
      
      lb.text! += " restoreD"
    }
    
    if (message.body as! String).hasPrefix("vs") && (message.body as! String).count > 2 && autoVideoDownloadPref == true {
      
      showAlert(message: "Download started")
      let downloadUrl = URL(string: String((message.body as! String).dropFirst(2)))!
      let downloadTask = URLSession.shared.downloadTask(with: downloadUrl) {
    urlOrNil, responseOrNil, errorOrNil in
    guard let fileURL = urlOrNil else { return }
    do {
        let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let savedURL = documentsURL.appendingPathComponent("Video\(Int(arc4random_uniform(999999) + 1))." + ((responseOrNil?.suggestedFilename)!.components(separatedBy: ".")).last!)
        self.lb.text! += " \(savedURL)"
        
        //let savedURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)
        try FileManager.default.moveItem(at: fileURL, to: savedURL)
        DispatchQueue.main.async {
          self.showAlert(message: "Download finished")
        }
    } catch {
        //print ("file error: \(error)")
    }
}
downloadTask.resume()
      
      lb.text! += " VideoDownload"
    }
    
    if (message.body as! String).hasPrefix("Script") {
    //webView.loadHTMLString("<body>\(message.body)</body>", baseURL: nil)
    try! (message.body as! String).write(to: URL.docDir.appendingPathComponent("debug.txt"), atomically: true, encoding: .utf8)
    }
    
    lb.text! += " m:\(message.body)"
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if let key = change?[NSKeyValueChangeKey.newKey] {
      
      if keyPath == "text" {
        adjustLabel()
      }
      
      if keyPath == "URL" {
        //webView.evaluateJavaScript("var el = document.querySelector('input[type=file]'); if (el !== null) { window.webkit.messageHandlers.iosListener.postMessage('iF' + el.getAttribute('accept')); el.removeAttribute('accept'); el.removeAttribute('capture'); el.removeAttribute('onclick'); el.click(); }", completionHandler: nil)
        lb.text! += " oV:" + String(String(describing: key).prefix(50))
      }
      
      if keyPath == "title" {
        //webViewDidFinish()
        //lb.text! += " oV:" + String(String(describing: key).prefix(15))
        lb.text! += " ovT:" + String(String(describing: key).prefix(3))
      }
      
      if keyPath == "estimatedProgress" {
        if webView.url!.absoluteString.hasPrefix("internal://local/restore?") == false {
        progressView.progress = Float(webView.estimatedProgress)
        if webView.estimatedProgress == 1 {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.progressView.progress = Float(0)
          }
          webViewDidFinish()
        }
        lb.text! += " oV:" + String(String(describing: key).prefix(4))
        }
      }
      
      if keyPath == "themeColor" {
        if #available(iOS 15, *) {
          
          if webView.themeColor != nil {
            let rgbaArray = webView.themeColor!.cgColor.components
            lb.text! += " otCrgba:\(round(rgbaArray![0]*255)),\(round(rgbaArray![1]*255)),\(round(rgbaArray![2]*255)),\(round(rgbaArray![3]*255))"
            if rgbaArray![0]*255 > 240 && rgbaArray![1]*255 > 240 && rgbaArray![2]*255 > 240 || rgbaArray![3]*255 < 255 {
              topNavBgView.backgroundColor = .viewBgColor
            } else {
              topNavBgView.backgroundColor = webView.themeColor
            }
          } else {
            topNavBgView.backgroundColor = .viewBgColor
            /*
            if webView.underPageBackgroundColor != nil {
              topNavBgView.backgroundColor = webView.underPageBackgroundColor
            } else {
              topNavBgView.backgroundColor = .viewBgColor
            }
            */
          }
          
          lb.text! += " otC:\(key)"
        }
      }
      
    }
  }
  
  @objc private func focusNewWindow() {
    if UIApplication.shared.windows.count > 1 && UIApplication.shared.windows[1].isHidden == false {
      ////
      //UIApplication.shared.windows[2].isHidden = true
      ////
      //lb.text! += " fNW\(UIApplication.shared.windows.count) \(UIApplication.shared.windows[0].isHidden) \(UIApplication.shared.windows[1].isHidden) \(UIApplication.shared.windows[2].isHidden) \(UIApplication.shared.windows[3].isHidden)"
      lb.text! += " fNW\(UIApplication.shared.windows.count)\(UIApplication.shared.windows[2].isHidden) \(navUrl!)"
      //adjustLabel()
      //showAlert(message: "navUrl: \(navUrl!)")
      //navUrlArray.removeAll()
      //UIApplication.shared.windows[0].makeKeyAndVisible()
    }
  }
  
  @objc private func enterBackground() {
    UIApplication.shared.isIdleTimerDisabled = false
    avPVC.player = nil
    lb.text! += " eBg"
    
    if #available(iOS 11, *) {
      webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
        var sessionCookies: [HTTPCookie] = []
        for cookie in cookies {
        if cookie.isSessionOnly {
        sessionCookies.append(cookie)
        //self.lb.text! += " c:\(cookie.domain)"
        }
        }
        //if !sessionCookies.isEmpty {
        setData(sessionCookies, key: "cookies")
        //}
        //self.lb.text! += " c:\(cookies.count)"
        self.lb.text! += " cS:\(sessionCookies.count)/\(cookies.count)"
      }
    }
    
  }
  
  @objc private func enterForeground() {
    UIApplication.shared.isIdleTimerDisabled = true
    loadUserPrefs()
    avPVC.player = player
    lb.text! += " eFg"
    
    //DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { /*AppCrashes self.showAlert(message: iwashere)*/ }
    
    func setTopNavBgViewColor(_ input: Any?) -> Bool {
      if input == nil { return false }
      let inputString = input as! String
      if inputString.hasPrefix("rgba") {
        let rgbaArray: [String] = inputString.components(separatedBy: CharacterSet(charactersIn: "rgba( )")).joined(separator: "").components(separatedBy: ",")
        //lb.text! += " \(rgbaArray) \(rgbaArray[0]) \(rgbaArray[1]) \(rgbaArray[2]) \(rgbaArray[3])"
        if Int(rgbaArray[3])! < 255 {
          return false
        }
        if Int(rgbaArray[0])! > 240 && Int(rgbaArray[1])! > 240 && Int(rgbaArray[2])! > 240 {
          return false
        }
        let rgbaColor = UIColor(r: Int(rgbaArray[0])!, g: Int(rgbaArray[1])!, b: Int(rgbaArray[2])!, a: Int(rgbaArray[3])!)
        topNavBgView.backgroundColor = rgbaColor
        return true
      }
      return false
    }
    
    var success: Bool = false
    webView.evaluateJavaScript("document.querySelector(\"meta[name='theme-color']\").getAttribute('content').replace(/rgb\\(/i,'rgba(').replace(/\\)/i,', 255)')") { (result, error) in
      self.lb.text! += " TC:\(result ?? "nil")"
      success = setTopNavBgViewColor(result)
      if !success {
        self.webView.evaluateJavaScript("window.getComputedStyle(document.body,null).getPropertyValue('background-color').replace(/rgb\\(/i,'rgba(').replace(/\\)/i,', 255)')") { (result, error) in
      self.lb.text! += " BG:\(result ?? "nil")"
      success = setTopNavBgViewColor(result)
      if !success {
        self.topNavBgView.backgroundColor = .viewBgColor
        //self.topNavBgView.backgroundColor = .appBgLightColor
      }
    }
      }
    }
    
    //print("print: TestVC")
    //NSLog("NSLog: TestVC")
    
  }
  
  @objc private func resignActive() {
    if webView.scrollView.contentOffset.y < 0 {
      webView.scrollView.setContentOffset(CGPoint(x: webView.scrollView.contentOffset.x, y: 0), animated: true)
    }
    lb.text! += " rAc"
  }
  
  @objc private func becomeActive() {
    
        if #available(iOS 11, *) {
        if let cookies: [HTTPCookie] = getData(key: "cookies") {
        for (index, cookie) in cookies.enumerated() {
        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
        //iwashere += "\n\ncookie \(index+1)/\(cookies.count):\n\(cookie)"
        //self.lb.text! += " c\(index+1):\(cookie.domain)"
        if index + 1 == cookies.count {
        self.lb.text! += " cR:\(cookies.count)"
        }
        }
        }
        }
        }
        
        if let incomingUrl = userDefGroup.value(forKey: "incomingUrl") as? String {
          urlField.text = incomingUrl
          userDefGroup.removeObject(forKey: "incomingUrl")
        }
        if let incomingText = userDefGroup.value(forKey: "incomingText") as? String {
          urlField.text = incomingText
          userDefGroup.removeObject(forKey: "incomingText")
        }
    
    lb.text! += " bAc"
  }
  
  @objc private func willTerminate() {
    if #available(iOS 11, *) {
      let sessionCookies: [HTTPCookie] = []
      setData(sessionCookies, key: "cookies")
      NSLog("cS:X")
    }
    NSLog("wTe")
  }
  
  
  private func askRestore() {
    func cleanStart() {
      webView.load(URLRequest(url: URL(string: "https://www.google.com/")!))
      //topnavcolorresetten
    }
    func restoreStart() {
      //webView.load(URLRequest(url: URL(string: "\(WebServer.instance.base)/errors/restore?history=\(restoreUrlsJson!)")!))
      webView.load(URLRequest(url: URL(string: "internal://local/restore?history=\(restoreUrlsJson!)")!))
      //DispatchQueue.main.async {
        //self.showAlert(message: "\(iwashere)")
        //self.showAlert(message: "\(WebServer.instance.base)/errors/restore?history=\(restoreUrlsJson!)")
        //self.showAlert(message: "restoreIndexLast: \(self.restoreIndexLast)\nwebViewRestorePref: \(webViewRestorePref)")
      //}
    }
    if webViewRestorePref == "never" {
      cleanStart()
    }
    if webViewRestorePref == "always" {
      if restoreIndexLast > 0 {
        restoreStart()
      } else {
        cleanStart()
      }
    }
    
    if webViewRestorePref == "ask" {
    let alert = UIAlertController(title: "Alert", message: "Restore last session?\n\nThe last session contains \(restoreIndexLast+1) pages.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
      if self.restoreIndexLast > 0 {
        restoreStart()
      } else {
        cleanStart()
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
      cleanStart()
      //self.webView3.removeFromSuperview()
    }))
    hapticFB.notificationOccurred(.success)
    DispatchQueue.main.async { [unowned self] in
      self.present(alert, animated: true, completion: nil)
    }
    }
    
  }
  
  
  /*
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    lb.text! += " wDa"
    UIApplication.shared.isIdleTimerDisabled = false
  }
  */
  
  
  private func changeUserAgent() {
    if currentUserAgent == "default" {
      webView.customUserAgent = desktopUserAgent
      currentUserAgent = "desktop"
    } else {
      webView.customUserAgent = nil
      currentUserAgent = "default"
    }
    webView.reload()
    
    /*
    if webView.customUserAgent != desktopUserAgent {
    //if defaultUserAgent == "default" {
      webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
        self.defaultUserAgent = result as! String
        self.webView.customUserAgent = self.desktopUserAgent
        //self.webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.109 Safari/537.36"
        self.webView.reload()
      }
    } else {
      webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 12_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Mobile/15E148 Safari/604.1"
      //webView.customUserAgent = nil
      //webView.customUserAgent = defaultUserAgent
      //defaultUserAgent = "default"
      webView.reload()
    }
    */
  }
  
  private func searchWithChatGPT() {
    let part1: String = "sk-3TNyPqwqHIyHcj3kqz45T3Blbk"
    let part2: String = "JIPhJlMBF35NihRQFBtum"
    let jsonObject: [String: Any] = ["model": "gpt-3.5-turbo", "messages": [["role": "user", "content": "\(url!)"]], "temperature": 0.7]
    let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject)
    var request = URLRequest(url: URL(string: webViewSearchUrlPref)!)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(part1)F\(part2)", forHTTPHeaderField: "Authorization")
    let task = URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
        let json = try! JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let choices = json?["choices"] as? [[String: Any]], let message = choices[0]["message"] as? [String: Any], let content = message["content"] as? String {
          self.webView.loadHTMLString("<b>Response:</b><br><br>\(httpResponse)<br><br>\(String(data: data, encoding: .utf8)!)<br><br><b>You:</b> \(self.url!.removingPercentEncoding!)<br><br><b>ChatGPT:</b> \(content)", baseURL: URL(string: webViewSearchUrlPref))
        }
      }
    }
    task.resume()
  }
  
  //url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
  //let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
  //var characterset = CharacterSet.urlPathAllowed
  //characterset.insert(charactersIn: "-._~")
  //if url.rangeOfCharacter(from: characterset.inverted) != nil {}
  //let characterset = CharacterSet(charactersIn: " ")
  //if url.rangeOfCharacter(from: characterset) != nil {
  //showAlert(message: "has special chars")
  //}
  //let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
  //let regEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
  //let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[regEx])
  //if !predicate.evaluate(with: url) {
  //switchToWebsearch()
  //}
  //if !UIApplication.shared.canOpenURL(url) {}
  //let request = URLRequest(url: url)
  //request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
  //request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  //var oldurl = url.replacingOccurrences(of: " ", with: "+")
  //String(describing: err.code)
  //if let err = error as? URLError {
  //lb.text! += "err: \(err._code)"
  //switch err.code {
  //case .cancelled:
  //case .cannotFindHost:
  //case .notConnectedToInternet:
  //case .resourceUnavailable:
  //case .timedOut:
  //}}
  //"err: \((error as NSError).code)"
  //if let err = error as NSError {}
  //private func encodeUrl() {}
  //if !(url.hasPrefix("https://") || url.hasPrefix("http://")) {}
  //String(url.filter({$0 == ":"}).count)
  
  
  private func startLoading() {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~:/?#[]@!$&'()*+,;=%")
    url = url.addingPercentEncoding(withAllowedCharacters: allowed)
    //showAlert(message: url)
    var urlobj = URL(string: url)
    if let regularExpression = try? NSRegularExpression(pattern: "^.{1,10}://") {
      let matchedNumber = regularExpression.numberOfMatches(in: url, options: [], range: NSRange(location: 0, length: url.count))
      if matchedNumber == 0 {
        urlobj = URL(string: "http://" + url)
        if !url.contains(".") {
          if webViewSearchUrlPref.contains("openai.com") {
            searchWithChatGPT()
            return
          }
          urlobj = URL(string: webViewSearchUrlPref + url)
        }
      }
      lb.text! += " \(matchedNumber)"
      lb.text! += "|\(urlobj!.absoluteString)"
    }
    navTypeBackForward = false
    let request = URLRequest(url: urlobj!, timeoutInterval: 10.0)
    webView.load(request)
  }
  
  
  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    //lb.text! += " dSPN:\(webView.url!.absoluteString)"
    //lb.text! += " dSPN:" + String(String(describing: webView.url!.absoluteString).prefix(15))
    lb.text! += " dSPN"
  }
  
  
  @available(iOS 14.5, *)
  //@available(iOS 15, *)
  func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
    download.delegate = self
  }
  
  @available(iOS 14.5, *)
  //@available(iOS 15, *)
  func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
    download.delegate = self
  }
  
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let urlStr = navigationAction.request.url?.absoluteString {
      //Full path self.webView.url
      navUrl = urlStr
      navUrlArray.insert(navUrl, at: 0)
      if navUrl == "about:blank" {
        navUrlArray.insert("AB:" + self.webView.url!.absoluteString, at: 0)
      }
    }
    
    if currentUserAgent == "default" {
      webView.customUserAgent = nil
    } else {
      webView.customUserAgent = desktopUserAgent
    }
    
    
    lb.text! += " NT(\(navigationAction.navigationType.rawValue))"
    //adjustLabel()
    if navigationAction.navigationType != .other {
      navTypeBackForward = false
    }
    if navigationAction.navigationType == .backForward {
      ////
      //navTypeBackForward = true
      ////
    }
    if navigationAction.navigationType == .other && navTypeBackForward == true {
      lb.text! += " STOP"
      //adjustLabel()
      
      //DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
        //self.navTypeBackForward = false
        //self.webView.load(navigationAction.request)
      //}
      
      //sleep(2)
      decisionHandler(.cancel)
      return
    }
    
    
    if navigationAction.navigationType == .linkActivated {
      let unilinkUrls: Array<String> = ["https://open.spotify.com", "https://www.amazon.de", "https://mobile.willhaben.at", "https://www.willhaben.at", "https://maps.google.com", "https://tvthek.orf.at"]
      var unilinkStop = false
      unilinkUrls.forEach { item in
        if navigationAction.request.url!.absoluteString.lowercased().hasPrefix(item.lowercased()) {
          //if !webView.url!.absoluteString.lowercased().hasPrefix(item.lowercased()) {
            unilinkStop = true
          //}
        }
      }
      if unilinkStop == true {
        webView.load(navigationAction.request)
        lb.text! += " uni:\(navigationAction.request.url!.absoluteString)"
        //adjustLabel()
        decisionHandler(.cancel)
        return
      }
    }
    
    let desktopUrls: Array<String> = ["https://apps.apple.comXXX", "https://identitysafe.norton.com", "https://de.yahoo.com"]
    var desktopStop = false
    desktopUrls.forEach { item in
      if navigationAction.request.url!.absoluteString.lowercased().hasPrefix(item.lowercased()) {
        desktopStop = true
      }
    }
    if desktopStop == true {
      webView.customUserAgent = desktopUserAgent
      lb.text! += " desk:\(navigationAction.request.url!.absoluteString)"
      //adjustLabel()
      decisionHandler(.allow)
      return
    }
    
    let storekitUrls: Array<String> = ["https://apps.apple.com", "itms-appss://apps.apple.com", "https://itunes.apple.com"]
    var storekitStop = false
    storekitUrls.forEach { item in
      if navigationAction.request.url!.absoluteString.lowercased().hasPrefix(item.lowercased()) {
        storekitStop = true
      }
    }
    if storekitStop == true {
      let productID = navigationAction.request.url!.absoluteString.components(separatedBy: "/id").last!.components(separatedBy: "?")[0]
      let storeKitViewController = SKStoreProductViewController()
      storeKitViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: NSNumber(integerLiteral: Int(productID)!)])
      present(storeKitViewController, animated: true)
      lb.text! += " store:\(navigationAction.request.url!.absoluteString) pID:\(productID)"
      decisionHandler(.cancel)
      return
    }
    
    
    if navigationAction.request.url!.scheme != "internal" {
    if navigationAction.request.url!.absoluteString != "about:blank" && navigationAction.navigationType != .linkActivated {
    if UIApplication.shared.canOpenURL(navigationAction.request.url!) && navigationAction.request.url! != webView.url! {
      //lb.text! += " cO:\(navigationAction.request.url!.absoluteString) \(webView.url!.absoluteString)"
      lb.text! += " cO:" + String(String(describing: navigationAction.request.url!.absoluteString).prefix(15))
    }
    }
    }
    
    
    if !newNav {
      if navigationAction.request.url!.absoluteString == "about:blank" {
        lb.text! += " cO2:ab"
      } else {
        lb.text! += " cO2:" + String(String(describing: navigationAction.request.url!.absoluteString).prefix(15))
      }
    }
    newNav = false
    
    //if navigationAction.request.url?.scheme == "https" && UIApplication.shared.canOpenURL(navigationAction.request.url!) {
      //decisionHandler(.cancel)
      //return
    //}
    //&& navigationAction.targetFrame == nil {
    
    if navigationAction.request.url?.scheme == "itms-appss" {
      webView.stopLoading()
      webView.customUserAgent = desktopUserAgent
      let newUrlStr = navigationAction.request.url!.absoluteString.replacingOccurrences(of: "itms-appss", with: "https")
      let newUrl = URL(string: newUrlStr)
      //var newUrl = URLRequest(url: URL(string: newUrlStr)!)
      //newUrl.setValue(desktopUserAgent, forHTTPHeaderField: "User-Agent")
      if counter < 3 {
      counter += 1
      webView.load(URLRequest(url: newUrl!))
      //webView.load(newUrl)
      lb.text! += " itms-appss:\(navigationAction.request.url!.absoluteString)"
      //adjustLabel()
      }
      //webView.customUserAgent = nil
      //UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
      decisionHandler(.cancel)
      return
    }
    
    let urlSchemes: Array<String> = ["tel", "shortcuts"]
    var urlSchemesStop = false
    urlSchemes.forEach { item in
      if navigationAction.request.url?.scheme == item {
    //if navigationAction.request.url?.scheme == "tel" {
        urlSchemesStop = true
      }
    }
    if urlSchemesStop == true {
      UIApplication.shared.open(URL(string: navigationAction.request.url!.absoluteString.components(separatedBy: " //")[0])!, options: [:], completionHandler: nil)
      //UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
      decisionHandler(.cancel)
      return
    }
    
    //if #available(iOS 15, *) {
    if #available(iOS 14.5, *) {
      if navigationAction.shouldPerformDownload {
        lb.text! += " nAsPD"
        decisionHandler(.download)
        return
      }
    }
    if navTypeDownload {
      navTypeDownload = false
      //if #available(iOS 15, *) {
      if #available(iOS 14.5, *) {
        lb.text! += " nTD"
        decisionHandler(.download)
        return
      }
    }
    
    decisionHandler(.allow)
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
    
    if let urlStr = navigationResponse.response.url?.absoluteString {
      navUrl = urlStr
      navUrlArray.insert("RE:" + navUrl, at: 0)
    }
    
    if let mimeType = navigationResponse.response.mimeType {
      if mimeType == "text/html" {
        lb.text! += " mT"
      } else {
        lb.text! += " mT:\(mimeType)"
      }
      
      if mimeType == "application/application/pdf" {
        if let data = try? Data(contentsOf: navigationResponse.response.url!) {
          webView.stopLoading()
          webView.load(data, mimeType: "application/pdf", characterEncodingName: "", baseURL: navigationResponse.response.url!)
          decisionHandler(.cancel)
          return
        }
      }
      
      /*
      if mimeType == "application/pdf" {
        lb.isHidden = false
      } else {
        lb.isHidden = true
      }
      */
      
    } else {
      lb.text! += " mT:noMime"
    }
    
    showFrameLoadError = true
    if !navigationResponse.canShowMIMEType {
      //if #available(iOS 15, *) {
      if #available(iOS 14.5, *) {
        showFrameLoadError = false
        lb.text! += " nRcSMT"
        decisionHandler(.download)
        return
      }
    }
    
    decisionHandler(.allow)
  }
  
  
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    var presentAlert: Bool = false
    //let err = error as NSError
    //switch err.code {
    switch error._code {
      case -999: break
      case 101, -1003:
        if webViewSearchUrlPref.contains("openai.com") {
          searchWithChatGPT()
        } else {
          url = "\(webViewSearchUrlPref)\(url!)"
          startLoading()
        }
      case 102 where showFrameLoadError == false:
            //if showFrameLoadError == false {
        //showFrameLoadError = true
        break
            //} else {
            //presentAlert = true
            //}
      case 25001...25003:
        urlField.text = webView.url!.absoluteString.replacingOccurrences(of: "internal://local/restore?url2=", with: "")
        urlField.textColor = .appBgColor
        presentAlert = true
      default:
        presentAlert = true
    }
    if presentAlert == true {
      //showAlert(message: "Error \(err.code): \(err.localizedDescription)")
      showAlert(message: "Error \(error._code): \(error.localizedDescription)")
      //error._code error.localizedDescription
    }
    progressView.progress = Float(0)
    //lb.text! += " err:\(err.code)"
    lb.text! += " err:\(error._code)"
  }
  
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    /*->WDF
    if webView.url!.absoluteString.hasPrefix("http://localhost:6571/errors/error.html") == false {
      urlField.text = webView.url!.absoluteString
      
      if webView.hasOnlySecureContent {
        urlField.textColor = .successFgColor
      } else {
        urlField.textColor = .errorFgColor
      }
      //if #available(iOS 14, *) {
        //let mediaType = webView.mediaType
        //showAlert(message: "mT:\(mediaType)!")
      //}
      
    }
    */
    //showAlert(message: defaultUserAgent)
    
    alertCounter = 0
    lb.text! += " w:dF"
    //adjustLabel()
    //webView.evaluateJavaScript("var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width, initial-scale=1.0, minimum-scale=0, maximum-scale=10.0, user-scalable=yes'); document.getElementsByTagName('head')[0].appendChild(meta);", completionHandler: nil)
    //webView.evaluateJavaScript("var el = document.querySelector('meta[name=viewport]'); if (el !== null) { el.setAttribute('content', 'width=device-width, initial-scale=1.0, minimum-scale=0.1, maximum-scale=15.0, user-scalable=yes'); }", completionHandler: nil)
    
    //for item in webView.backForwardList {}
    //for (item: WKBackForwardListItem) in webView.backForwardList.backList {}
    
    //let historySize = webView.backForwardList.backList.count
    //let firstItem = webView.backForwardList.item(at: -historySize)
    //webView.go(to: firstItem!)
    
    var bflist = "bflist:"
    let historySize = webView.backForwardList.backList.count
    if historySize != 0 {
      for index in -historySize..<0 {
        bflist = bflist + " \(index)/\(historySize)/" + webView.backForwardList.item(at: index)!.url.absoluteString
      }
    }
    
    //var bflist = "bflist:"
    //bfarray.append(webView.url!.absoluteString)
    //bfarray.forEach { item in
      //bflist = bflist + " \(item)"
    //}
    //showAlert(message: bflist)
    
    guard let currentItem = self.webView.backForwardList.currentItem else {
    return
    }
    let urls = (self.webView.backForwardList.backList + [currentItem] + self.webView.backForwardList.forwardList).compactMap { $0.url.absoluteString }
    let currentIndexButLast = self.webView.backForwardList.forwardList.count
    
    UserDefaults.standard.set(urls, forKey: "urls")
    UserDefaults.standard.set(currentIndexButLast, forKey: "currentIndexButLast")
    
    bflist = "bflist:"
    urls.forEach { url in
      bflist = bflist + " " + url
    }
    bflist = bflist + " \(currentIndexButLast)"
    //showAlert(message: "\(bflist)")
    
    var urlsJson = "{\"currentPage\": \(currentIndexButLast * -1), \"history\": ["
    urls.forEach { url in
      urlsJson += "\"" + url + "\", "
    }
    urlsJson.removeLast(2)
    urlsJson += "]}"
    UserDefaults.standard.set(urlsJson, forKey: "urlsJson")
    //lb.text! += " urlsJ:\(urlsJson)"
    //adjustLabel()
    
    //if restoreIndex == 25 {
    //restoreIndexLast = 25
    //}
    
    if restoreIndex == restoreIndexLast {
      restoreIndex += 1
      
      /*
      //let sessionRestorePath = Bundle.main.path(forResource: "SessionRestore2.html", ofType: nil)
      //let sessionRestoreString = try? String(contentsOfFile: sessionRestorePath!, encoding: String.Encoding.utf8)
      
      //if let filepath = Bundle.main.url(forResource: "SessionRestore", withExtension: "html") {
        //do {
          //let contents = try String(contentsOf: filepath)
          //self.lb.text! += " RDO"
        //} catch {
          //self.lb.text! += " RNOC"
        //}
      //} else {
        //self.lb.text! += " RNOF"
      //}
      //adjustLabel()
      
      let webServer = GCDWebServer()
      webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
        
        //let sessionRestorePath = Bundle.main.path(forResource: "SessionRestore", ofType: "html")
    //let sessionFileHandler = FileHandle.init(forReadingAtPath: sessionRestorePath!)
    //return GCDWebServerDataResponse(data: (sessionFileHandler?.readDataToEndOfFile())!, contentType: "text/html")
        //return GCDWebServerDataResponse(html:"<html><body><p>Hello Worldi</p><script>history.pushState({}, '', 'http://localhost:6571/orf.at');</script></body></html>")
        
        //return GCDWebServerDataResponse(html: sessionRestoreString!)
        //if let sessionRestorePath = Bundle.main.path(forResource: "SessionRestore.html", ofType: nil), let sessionRestoreString = try? String(contentsOfFile: sessionRestorePath, encoding: String.Encoding.utf8) {
        //self.lb.text! += " RDONE:\(sessionRestoreString)"
        //self.adjustLabel()
        //return GCDWebServerDataResponse(html: sessionRestoreString)
        guard let sessionRestorePath = Bundle.main.url(forResource: "SessionRestore", withExtension: "html"), let sessionRestoreString = try? String(contentsOf: sessionRestorePath) else {
          self.lb.text! += "R404"
          //self.adjustLabel()
          return GCDWebServerResponse(statusCode: 404)
        }
        self.lb.text! += "RDONE"
        //self.adjustLabel()
        return GCDWebServerDataResponse(html: sessionRestoreString)
      })
      
      //crashing:
      //webServer.addGETHandler(forBasePath: "/", directoryPath: Bundle.main.path(forResource: "/", ofType: nil)!, indexFilename: "adaway.json", cacheAge: 0, allowRangeRequests: true)
      
      //webServer.start(withPort: 6571, bonjourName: "GCD Web Server")
      try? webServer.start(options: [GCDWebServerOption_Port: 6571, GCDWebServerOption_BindToLocalhost: true, GCDWebServerOption_AutomaticallySuspendInBackground: true])
      
      //if let restoreUrl = URL(string: "\(WebServer.instance.base)/errors/restore?history={'currentPage': -1, 'history': ['https://orf.at', 'https://derstandard.at']}") {
      if let restoreUrl = URL(string: "\(webServer.serverURL!)") {
        self.webView.load(URLRequest(url: restoreUrl))
        lb.text! += " \(webserv) \(restoreUrl.absoluteString)"
        //adjustLabel()
      }
      */
      
      //try? WebServer.instance.start()
      //SessionRestoreHandler.register(WebServer.instance)
      //var restoreUrlPart = "/errors/restore?history={\"currentPage\": -1, \"history\": [\"https://www.aktienfahrplan.com\", \"https://orf.at\", \"https://www.google.com/search?q=opensea&source=hp\"]}"
      //restoreUrlPart = restoreUrlPart.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      //if let restoreUrl = URL(string: "\(WebServer.instance.base)\(restoreUrlPart)") {
        //self.webView.load(URLRequest(url: restoreUrl))
        //self.lb.text! += " \(restoreUrl.absoluteString)"
      //}
      //lb.text! += " \(webserv) \(restoreUrlPart)"
      
      //lb.text! += " \(webserv)"
      
      //webView.go(to: webView.backForwardList.item(at: restorePosition * -1)!)
      //##webView3.removeFromSuperview()
      
      //var myBackList = [WKBackForwardListItem]()
      //myBackList.append(webView.backForwardList.item(at: 0)!)
        //override var webView.backForwardList.backList: [WKBackForwardListItem] {
        //return myBackList
        //}
        
    }
    if restoreIndex < restoreIndexLast {
      restoreIndex += 1
      //webView.load(URLRequest(url: URL(string: restoreUrls[restoreIndex])!))
      let movingDot = String(repeating: ".", count: restoreIndex)
      webView3.evaluateJavaScript("document.getElementById(\"a\").innerHTML = \"Loading last Session\(movingDot) <span style='position:absolute;left:310px;'>\(restoreIndex+1+restoreIndexLast+1-5)/\(restoreIndexLast+1)</span>\";", completionHandler: nil)
    }
    
    //let urlss = UserDefaults.standard.array(forKey: "urls") as? [URL] ?? [URL]()
    //let currentIndexButLasts = UserDefaults.standard.array(forKey: "currentIndexButLast") as? [Int] ?? [Int]()
    
    //struct BackforwardHistory {
      //var urls: [URL] = []
      //var currentIndexButLast: Int32
    //}
    //let backforwardHistory = BackforwardHistory(urls: urls, currentIndexButLast: Int32(currentIndexButLast))
    
    //do {
    //let appSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    //let filePath = appSupportDir.appendingPathComponent("bfhist.txt").path
    //NSKeyedArchiver.archiveRootObject(backforwardHistory, toFile: filePath)
    //}
    //catch {}
    
  }
  
  func webViewDidFinish() {
    if webView.url!.absoluteString.hasPrefix("http://localhost:6571/errors/error.html") == false && webView.url!.absoluteString.hasPrefix("internal://local/restore?") == false {
      urlField.text = webView.url!.absoluteString
      if webView.hasOnlySecureContent {
        urlField.textColor = .successFgColor
      } else if webView.url!.scheme == "internal" {
        urlField.textColor = .appBgColor
      } else {
        urlField.textColor = .errorFgColor
      }
      //if #available(iOS 15, *) {
        //lb.text! += " mT:\(webView.mediaType ?? "nil") tC:\(webView.themeColor) uC:\(webView.underPageBackgroundColor)"
      //}
    }
    newNav = true
    lb.text! += " WDF"
  }
  
  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
  //@available(iOS 13, *)
  //func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
    if alertCounter < 5 {
      alertCounter += 1
      showJSAlert(type: "alert", title: "Alert", message: message) { (response) in
        self.lb.text! += " RES:\(response!)/\(alertCounter)"
        completionHandler()
      }
    } else {
      completionHandler()
    }
    //let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    //alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
      //completionHandler()
    //}))
    //present(alertController, animated: true, completion: nil)
  }
  
  func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
    if alertCounter < 5 {
      alertCounter += 1
      showJSAlert(type: "confirm", title: "Alert", message: message) { (response) in
        self.lb.text! += " RES:\(response!)/\(alertCounter)"
        completionHandler(response as! Bool)
      }
    } else {
      completionHandler(false)
    }
    //let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    //alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
      //completionHandler(true)
    //}))
    //alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
      //completionHandler(false)
    //}))
    //present(alertController, animated: true, completion: nil)
  }
  
  func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
    if alertCounter < 5 {
      alertCounter += 1
      showJSAlert(type: "prompt", title: "Alert", message: prompt, input: defaultText) { (response) in
        self.lb.text! += " RES:\(response ?? "nil")/\(alertCounter)"
        completionHandler(response as? String)
      }
    } else {
      completionHandler(nil)
    }
    //let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
    //alertController.addTextField { (textField) in
      //textField.text = defaultText
    //}
    //alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
      //if let text = alertController.textFields?.first?.text {
        //completionHandler(text)
      //} else {
        //completionHandler(defaultText)
      //}
    //}))
    //alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
      //completionHandler(nil)
    //}))
    //present(alertController, animated: true, completion: nil)
  }
  
  
    @available(iOS 11.0, *)
    private func setupContentBlockFromStringLiteral(_ completion: (() -> Void)?) {
        // Swift 4  Multi-line string literals
        let jsonString = """
[{
  "trigger": {
    "url-filter": "://googleads\\\\.g\\\\.doubleclick\\\\.net.*"
  },
  "action": {
    "type": "block"
  }
}]
"""
        if UserDefaults.standard.bool(forKey: ruleId1) {
            // list should already be compiled
            WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: ruleId1) { [weak self] (contentRuleList, error) in
                if let error = error {
                    self?.printRuleListError(error, text: "lookup json string literal")
                    UserDefaults.standard.set(false, forKey: ruleId1)
                    self?.setupContentBlockFromStringLiteral(completion)
                    return
                }
                if let list = contentRuleList {
                    self?.webView.configuration.userContentController.add(list)
                    completion?()
                }
            }
        }
        else {
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: ruleId1, encodedContentRuleList: jsonString) { [weak self] (contentRuleList: WKContentRuleList?, error: Error?) in
                if let error = error {
                    self?.printRuleListError(error, text: "compile json string literal")
                    return
                }
                if let list = contentRuleList {
                    self?.webView.configuration.userContentController.add(list)
                    UserDefaults.standard.set(true, forKey: ruleId1)
                    completion?()
                }
            }
        }
    }
    
    @available(iOS 11.0, *)
    private func setupContentBlockFromFile(_ completion: (() -> Void)?) {
        if UserDefaults.standard.bool(forKey: ruleId2) {
            WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: ruleId2) { [weak self] (contentRuleList, error) in
                if let error = error {
                    self?.printRuleListError(error, text: "lookup json file")
                    UserDefaults.standard.set(false, forKey: ruleId2)
                    self?.setupContentBlockFromFile(completion)
                    return
                }
                if let list = contentRuleList {
                    
    let ruleId2File = Bundle.main.url(forResource: "adaway", withExtension: "json")!
    let resourceValues = try! ruleId2File.resourceValues(forKeys: [.contentModificationDateKey])
    let ruleId2FileDate = resourceValues.contentModificationDate!
    var ruleId2FileDateLast = Calendar.current.date(byAdding: .year, value: -1, to: ruleId2FileDate)
    if (UserDefaults.standard.object(forKey: "ruleId2FileDateLast") != nil) {
      ruleId2FileDateLast = UserDefaults.standard.object(forKey: "ruleId2FileDateLast") as? Date
    }
    self?.lb.text = (self?.lb.text)! + " \(ruleId2FileDate) \(ruleId2FileDateLast!)"
    //self?.adjustLabel()
    if ruleId2FileDate > ruleId2FileDateLast! {
      //if #available(iOS 11.0, *) {
      //webView.configuration.userContentController.removeAllContentRuleLists()
      WKContentRuleListStore.default().removeContentRuleList(forIdentifier: ruleId2, completionHandler: { _ in })
      UserDefaults.standard.set(false, forKey: ruleId2)
      //let group = DispatchGroup()
      //group.enter()
      //setupContentBlockFromStringLiteral {
        //group.leave()
      //}
      //group.enter()
      //setupContentBlockFromFile {
        //group.leave()
      //}
      UserDefaults.standard.set(ruleId2FileDate, forKey: "ruleId2FileDateLast")
      self?.lb.text = (self?.lb.text)! + " UPD"
      //self?.adjustLabel()
      self?.setupContentBlockFromFile(completion)
      return
      //}
    }
                    
                    self?.webView.configuration.userContentController.add(list)
                    completion?()
                }
            }
        }
        else {
            if let jsonFilePath = Bundle.main.path(forResource: "adaway.json", ofType: nil),
                let jsonFileContent = try? String(contentsOfFile: jsonFilePath, encoding: String.Encoding.utf8) {
                WKContentRuleListStore.default().compileContentRuleList(forIdentifier: ruleId2, encodedContentRuleList: jsonFileContent) { [weak self] (contentRuleList, error) in
                    if let error = error {
                        self?.printRuleListError(error, text: "compile json file")
                        return
                    }
                    if let list = contentRuleList {
                        self?.webView.configuration.userContentController.add(list)
                        UserDefaults.standard.set(true, forKey: ruleId2)
                        completion?()
                    }
                }
            }
        }
    }
    
    @available(iOS 11.0, *)
    private func resetContentRuleList() {
        let config = webView.configuration
        config.userContentController.removeAllContentRuleLists()
    }
    
    private func alertToUseIOS11() {
        let title: String? = "Use iOS 11 and above for ads-blocking."
        let message: String? = nil
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: { (action) in
            
        }))
        DispatchQueue.main.async { [unowned self] in
            self.view.window?.rootViewController?.present(alertController, animated: true, completion: {
                
            })
        }
    }
    
    
    @available(iOS 11.0, *)
    private func printRuleListError(_ error: Error, text: String = "") {
        guard let wkerror = error as? WKError else {
            print("\(text) \(type(of: self)) \(#function): \(error)")
            return
        }
        switch wkerror.code {
        case WKError.contentRuleListStoreLookUpFailed:
            print("\(text) WKError.contentRuleListStoreLookUpFailed: \(wkerror)")
        case WKError.contentRuleListStoreCompileFailed:
            print("\(text) WKError.contentRuleListStoreCompileFailed: \(wkerror)")
        case WKError.contentRuleListStoreRemoveFailed:
            print("\(text) WKError.contentRuleListStoreRemoveFailed: \(wkerror)")
        case WKError.contentRuleListStoreVersionMismatch:
            print("\(text) WKError.contentRuleListStoreVersionMismatch: \(wkerror)")
        default:
            print("\(text) other WKError \(type(of: self)) \(#function):\(wkerror) \(wkerror)")
            break
        }
    }
    
    //Just for invalidating target="_blank"
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        lb.text! += " cwv"
        //adjustLabel()
        
        guard let url = navigationAction.request.url else {
            return nil
        }
        guard let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame else {
            
            navUrlArray.insert("NW:" + url.absoluteString, at: 0)
            
            webView.load(URLRequest(url: url))
            return nil
        }
        return nil
    }
    

}
