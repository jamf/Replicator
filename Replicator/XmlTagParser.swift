import Foundation

class XmlTagParser: NSObject, XMLParserDelegate {
    private var foundFirstTag = false
    private var firstTagValue = ""
    private var isCapturingTag = false
    private var targetTagName = ""
    
    func findFirstTagValue(tagName: String, in xmlString: String) -> String? {
        print("[XmlTagParser] Finding first tag value for \(tagName) in \(xmlString)...")
        guard let data = xmlString.data(using: .utf8) else { return nil }
        
        print("[XmlTagParser] passed guard...")
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        // Reset state
        foundFirstTag = false
        firstTagValue = ""
        isCapturingTag = false
        targetTagName = tagName
        
        parser.parse()
        
        return foundFirstTag ? firstTagValue : nil
    }
    
    // MARK: - XMLParserDelegate Methods
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // Only care about the target tag, ignore everything else
        if elementName == targetTagName && !foundFirstTag {
            isCapturingTag = true
            firstTagValue = "" // Reset in case of multiple character callbacks
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isCapturingTag && !foundFirstTag {
            firstTagValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == targetTagName && isCapturingTag {
            foundFirstTag = true
            isCapturingTag = false
            // We found what we need, no need to continue parsing
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Handle parse errors gracefully
        print("XML Parse Error: \(parseError.localizedDescription)")
    }
}
