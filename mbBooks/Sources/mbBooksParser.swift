//
//  mbBooksParser.swift
//  mbBooks
//
//  Created by Mélodie Borel on 30/04/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation
//import KissXML

let kMimeTypeEpub = "application/epub+zip"
let kMimeTypeiBooks = "application/x-ibooks+zip"

class mbBooksParser: NSObject {
    private var parser: XMLParser?
    private var rootPath = ""
    private var items: NSMutableDictionary = [:]
    private var spinearray: [NSMutableDictionary] = []
    
    func bookType(forBaseURL baseURL: URL?) -> mbBooksBookType {
        var bookType = mbBooksBookType.Unknown
        let mimetypeURL: URL? = baseURL?.appendingPathComponent("mimetype")
        var mimetype: String? = nil
        do {
            if let mimetypeURL = mimetypeURL {
                mimetype = try String(contentsOf: mimetypeURL, encoding: String.Encoding(rawValue: String.Encoding.ascii.rawValue))
            }
        } catch {
        }
        
        let mimeRange: NSRange? = (mimetype as NSString?)?.range(of: kMimeTypeEpub)
        
        if mimeRange?.location == 0 && mimeRange?.length == 20 {
            bookType = mbBooksBookType.Epub2
        } else if (mimetype == kMimeTypeiBooks) {
            bookType = mbBooksBookType.iBook
        }
        
        return bookType
    }

    func contentEncryption(forBaseURL baseURL: URL?) -> mbBooksBookEncryption {
        let containerURL: URL? = baseURL?.appendingPathComponent("META-INF").appendingPathComponent("sinf.xml")
        var document: XMLDocument? = nil
        var content: String? = nil
        do {
            if let containerURL = containerURL {
                content = try String(contentsOf: containerURL, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            }
            document = try XMLDocument(xmlString: content!, options: [])
        } catch {
            return mbBooksBookEncryption.None
        }
        var sinfNodes: [XMLNode]? = nil
        do {
            sinfNodes = try document?.rootElement()!.nodes(forXPath: "/fairplay:sinf")
        } catch {
        }
        if sinfNodes == nil || sinfNodes?.count == 0 {
            return mbBooksBookEncryption.None
        } else {
            return mbBooksBookEncryption.Fairplay
        }
    }

    
    func rootFile(forBaseURL baseURL: URL?) -> URL? {
        let containerURL: URL? = baseURL?.appendingPathComponent("META-INF").appendingPathComponent("container.xml")
        var content: String? = nil
        do {
            content = try String(contentsOf: containerURL!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        } catch {
        }
        var document: XMLDocument? = nil
        do {
            document = try XMLDocument(xmlString: content!, options: [])
        } catch {
        }
     
        let root = document?.rootElement()

        //let defaultNamespace = root?.namespace(forPrefix: "")
        var objectElements: [XMLNode]? = nil
        do {
            objectElements = try root?.nodes(forXPath: "/container/rootfiles/rootfile")
        } catch {
        }

        var count: Int = 0
        var value: String? = nil
        for xmlElement in objectElements ?? [] {
            value = self.mbRetrieveKey(for: "full-path", in: xmlElement.description)
            count += 1   
        }
        
        if count == 1 && value != nil {
            return baseURL?.appendingPathComponent(value ?? "")
        } else if count == 0 {
            print("no root file found.")
        } else {
            print("there are more than one root files. this is odd.")
        }
        return nil
    }

    
    func coverPathComponent(from document: XMLDocument?) -> String? {
        var coverPath: String = ""
        let root = document?.rootElement()
        //let defaultNamespace = root?.namespace(forPrefix: "")
        var metaNodes: [XMLNode]? = nil
        do {
            metaNodes = try root?.nodes(forXPath: "/item[@properties='cover-image']")
        } catch {
        }
        
        if metaNodes != [] {
            coverPath = self.mbRetrieveKey(for: "href", in: (metaNodes?.last!.description)!)
        }
        
        if coverPath == "" {
            var coverItemId: String = ""
            
            //let defaultNamespace = root?.namespace(forPrefix: "")
            do {
                metaNodes = try root?.nodes(forXPath: "/package/metadata/meta")
                
            } catch {
            }
            for xmlElement in metaNodes! {
                if (self.mbRetrieveKey(for: "name", in: xmlElement.description) == "cover")
                {
                    coverItemId = self.mbRetrieveKey(for: "content", in: xmlElement.description)
                }
            }
            if (coverItemId=="") {
                return nil
            } else {
                //var defaultNamespace = root!.namespace(forPrefix: "")
                var itemNodes: [XMLNode]? = nil
                do {
                    itemNodes = try root!.nodes(forXPath: "/package/manifest/item")
                } catch {
                }
                
                for itemElement in itemNodes ?? [] {
                    if (self.mbRetrieveKey(for: "id", in: itemElement.description) == coverItemId) {
                        coverPath = self.mbRetrieveKey(for: "href", in: itemElement.description)
                    }
                }
            }
        }
        return coverPath
    }

    func mbRetrieveKey(for key: String, in text:String) -> String{
        do {
        let regex = try NSRegularExpression(pattern: "\(key)=\"[^\"]*\"", options: [])
        let value3 = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let value = value3.map{String(text[Range($0.range, in: text)!])}
            if (value.count >= 1 ) {
                return String(value[0].split(separator: "\"")[1])
            } else {return ""}
        } catch {
            NSLog("\(key) is not a key")
            return ""
        }
    }
    
    
    func metaData(from document: XMLDocument?) -> NSMutableDictionary? {
        let metaData: NSMutableDictionary = [:]
        let root = document?.rootElement()
        //let defaultNamespace = root?.namespace(forPrefix: "")
        var metaNodes: [XMLNode]? = nil
        do {
            metaNodes = try root?.nodes(forXPath: "/package/metadata")
        } catch {
        }
        
        if metaNodes?.count == 1 {
            let metaNode = metaNodes?[0] as? XMLElement
            let metaElements = metaNode?.children
            
            for xmlElement in metaElements as? [XMLElement] ?? [] {
                if isValidNode(xmlElement) {
                    if metaData[xmlElement.localName!] == nil {
                        metaData[xmlElement.localName!] = xmlElement.stringValue
                    } else {
                        let attributeString = (xmlElement.attributes?.first as? NSNumber)?.stringValue ?? ""
                        var metaDataKeyString = "\(String(describing: xmlElement.localName))-\(attributeString)"
                        metaData[metaDataKeyString] = xmlElement.stringValue
                    }
                }
            }
        }
        else {
            print("meta data invalid")
            return nil
        }
        return metaData
    }
    
    func spine(from document: XMLDocument?) -> [String] {
        var spine: [String] = []
        let root = document?.rootElement() as? XMLElement
        let defaultNamespace = root?.namespace(forPrefix: "")
        var spineNodes: [XMLNode]? = nil
        do {
            spineNodes = try root?.nodes(forXPath: "/package/spine") as! [XMLNode]
        } catch {
        }
        
        if spineNodes?.count == 1 {
            let spineElement = spineNodes?[0] as? XMLElement
            
            let toc = self.mbRetrieveKey(for: "toc", in: spineElement!.description)
            if toc != nil {
                spine.append(toc ?? "")
            } else {
                spine.append("")
            }
            let spineElements = spineElement?.children
            for xmlElement in spineElements as? [XMLElement] ?? [] {
                if isValidNode(xmlElement) {
                    spine.append(self.mbRetrieveKey(for: "idref", in: xmlElement.description))
                }
            }
        }
        else {
            print("spine data invalid")
            return [""]
        }
        return spine
    }
    
    
    func isRTL(from document: XMLDocument?) -> Bool {
        let root = document?.rootElement()
        //let defaultNamespace = root?.namespace(forPrefix: "")
        var spineNodes: [XMLNode]? = nil
        do {
            spineNodes = try root?.nodes(forXPath: "/package/spine")
        } catch {
        }
        if spineNodes?.count == 1 {
            let spineElement = spineNodes?[0] as? XMLElement
            let referenceElements = spineElement?.children
            
            for xmlElement in referenceElements as? [XMLElement] ?? [] {
                let ppd = self.mbRetrieveKey(for: "page-progression-direction", in: xmlElement.description)

                if (ppd == "rtl") {
                    return true
                }
            }
            return false
        } else {
            print("spine data invalid")
            return false
        }
    }

    func manifest(from document: XMLDocument?) -> NSMutableDictionary? {
        var manifest: NSMutableDictionary = [:]
        var items: NSMutableDictionary = [:]
        
        let root = document?.rootElement()
        let defaultNamespace = root?.namespace(forPrefix: "")
        var manifestNodes: [XMLNode]? = nil
        do {
            manifestNodes = try root?.nodes(forXPath: "/package/manifest")
        } catch {
        }
        
        if manifestNodes?.count == 1 {
            let itemElements = (manifestNodes?[0] as? XMLElement)?.children
            for xmlElement in itemElements as? [XMLElement] ?? [] {
                if isValidNode(xmlElement) && (xmlElement.attributes != nil) {
                    NSLog(" spineElement is \(xmlElement.description)")
                    let href = self.mbRetrieveKey(for: "href", in: xmlElement.description)
                    NSLog(" href is \(href)")
                    let itemId = self.mbRetrieveKey(for: "id", in: xmlElement.description)
                    let mediaType = self.mbRetrieveKey(for: "media-type", in: xmlElement.description)
                    items=[:]
                    if (itemId != "") {
                        if (href != "") {
                            items.setObject(href, forKey: "href" as NSCopying)
                        }
                        if (mediaType != "") {
                            items.setObject(mediaType, forKey: "media" as NSCopying)
                        }
                        manifest.setObject(items, forKey: itemId as NSCopying)
                    }
                }
            }
        } else {
            print("manifest data invalid")
            return nil
        }
        return manifest
    }

    func guide(from document: XMLDocument?) -> [Any]? {
        var guide: [NSMutableDictionary] = []
        let root = document?.rootElement()
        
        let defaultNamespace = root?.namespace(forPrefix: "")
        var guideNodes: [XMLNode]? = nil
        do {
            guideNodes = try root?.nodes(forXPath: "/package/guide") as? [XMLNode]
        } catch {
        }
        
        if guideNodes?.count == 1 {
            let guideElement = guideNodes?[0] as? XMLElement
            let referenceElements = guideElement?.children
            
            for xmlElement in referenceElements as? [XMLElement] ?? [] {
                if isValidNode(xmlElement) {
                    let type = self.mbRetrieveKey(for: "type", in: xmlElement.description)
                    let href = self.mbRetrieveKey(for: "href", in: xmlElement.description)
                    let title = self.mbRetrieveKey(for: "title", in: xmlElement.description)
                    var reference: NSMutableDictionary = [:]
                    if (type != "") {
                        reference.setObject(type, forKey: type as NSCopying)
                    }
                    if (href != nil) {
                        reference.setObject(href, forKey: "href" as NSCopying)
                    }
                    if (title != nil) {
                        reference.setObject(title, forKey: "title" as NSCopying)
                    }
                    guide.append(reference)
                }
            }
        } else {
            print("guide data invalid")
            return nil
        }
        
        return guide
    }

    func isValidNode(_ node: XMLElement?) -> Bool {
        return true //(node!.kind != XML_COMMENT_NODE)
    }
}
