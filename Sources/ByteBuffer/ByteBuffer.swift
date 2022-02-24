import Foundation

public struct ByteBuffer {

    public var buffer: [UInt8] = []
    var index = 0
    public var count: Int {
        return buffer.count
    }

    public init(){}

    public init(slice: ArraySlice<UInt8>) {
        self.buffer = Array(slice)
    }

    public init(buffer: [UInt8]) {
        self.buffer = buffer
    }

    public init(buffer: NSData) {
        let count = buffer.length / MemoryLayout<UInt8>.size
        var array = [UInt8](repeating: 0, count: count)
        buffer.getBytes(&array, length: count * MemoryLayout<UInt8>.size)
        self.buffer = array
    }

    /// Initialize with string composed of UTF8 characters
    public init(string: String) {
        let bytes = string.utf8
        self.buffer = [UInt8](bytes)
    }

    public mutating func append(_ byte: UInt8) {
        buffer.append(byte)
    }

    public func byte(at index: Int) -> UInt8 {
        if buffer.isEmpty {
            return 0
        }
        return self.buffer[index]
    }

    public func bytes(at index: Int, count: Int) -> [UInt8] {
        if buffer.isEmpty {
            return []
        }
        if index+count > buffer.count {
            return []
        }
        return Array(self.buffer[index...(index+count)])
    }

    public func character(at index: Int) -> Character? {
        if buffer.isEmpty {
            return nil
        }
        let u = UnicodeScalar(self.buffer[index])
        return Character(u)
    }

    public func string(at index: Int, length: Int) -> String? {
        let end = index + length
        if end < self.buffer.count {
            var subArray = self.buffer[index..<end]
            subArray.append(0)
            return String(bytes: subArray, encoding: String.Encoding.ascii)!
        }
        return nil
    }


    // DDFFetchVariable()
    /// fetchArray()
    /// Fetch a variable length array from a record, and allocate it as a new array.
    func fetchArray(maximumLength: Int,
                    firstDelimiter: UInt8,
                    secondDelimiter: UInt8) -> (Int, [UInt8]) {
        var i = 0
        var consumedCount = 0

        // Find any delimiter
        while i < maximumLength - 1 && self.buffer[i] != firstDelimiter && self.buffer[i] != secondDelimiter {
            i += 1
        }
        consumedCount = i
        if i < maximumLength && (self.buffer[i] == firstDelimiter || self.buffer[i] == secondDelimiter) {
            consumedCount += 1
        }
        return (consumed: consumedCount, array: Array(self.buffer[0..<i])) // Skip the delimiter
        //return String(bytes: pszRecord[0...i], encoding: .utf8)!
    }

    public func fetchArray(maximumLength: Int,
                            firstDelimiter: UInt8,
                            secondDelimiter: UInt8,
                            completion: (_ count: Int, _ value: [UInt8]) -> Void)  {
        let result = fetchArray(maximumLength: maximumLength, firstDelimiter: firstDelimiter, secondDelimiter: secondDelimiter)
        if result.1.isEmpty {
            completion(result.0, [])
        }
        completion(result.0, result.1)
    }

    public func fetchString(maximumLength: Int,
                            firstDelimiter: UInt8,
                            secondDelimiter: UInt8,
                            completion: (_ count: Int, _ value: String) -> Void)  {
        let result = fetchArray(maximumLength: maximumLength, firstDelimiter: firstDelimiter, secondDelimiter: secondDelimiter)
        if result.1.isEmpty {
            completion(result.0, "")
        }
        if let string = String(bytes: result.1, encoding: .utf8) {
            completion(result.0, string)
        }
        completion(result.0, "")
    }

    public func int(at index: Int) -> Int? {
        let b = byte(at: index)
        return Int(b)
    }

    /// Returns an integer from the string at, of length.
    public func int(at index: Int, length: Int) -> Int? {
        // Might have to remove leading zeros
        guard let s = string(at: index, length: length) else { return nil }
        return (s as NSString).integerValue
    }

    /// Applies to the whole buffer
    ///
    /// Returns false if buffer contains a non-alpha numeric character or is invalid.
    public func isAlphaNumeric() -> Bool {
        guard let s = String(bytes: self.buffer, encoding: String.Encoding.ascii) else { return false }
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 "
        let disallowedChars = NSCharacterSet(charactersIn: allowedChars).inverted
        let nss = NSString(string: s)
        return nss.rangeOfCharacter(from: disallowedChars).location == NSNotFound
    }


    /* scanVariable() */
    /// variableLength
    /// returns an Int
    /// Establish the length of a variable length string
    func variableLength(maximumLength: Int, delimiter: UInt8) -> Int {
        var i = 0
        while i < maximumLength - 1 && buffer[i] != delimiter {
            i += 1
        }
        return i
    }

    init(byteBuffer: ByteBuffer) {
        self.buffer = byteBuffer.buffer
    }

    init(array:[UInt8]) {
        self.buffer = array
    }

    init(length: Int){
        self.buffer = [UInt8](repeating: 0, count: length)
    }

    mutating func skip(offset: Int) {
        index = index + offset
    }

    func getUInt8(offset: Int) -> UInt8{
        return buffer[offset]
    }

    mutating func getUInt8() -> UInt8 {
        if buffer.count > 0 {
            let byte = buffer[index]
            index += 1
            return byte
        }
        return 0
    }

    mutating func getString(size: Int) -> String {
        if index+size > buffer.count {
            return ""
        }
        let s = Array(buffer[index...index+size]).asUTF8String(length: size)
        index += size
        return s
    }

    func getString(offset: Int, size: Int) -> String {
        let subArray = Array(buffer[offset...offset+size])
        return subArray.asUTF8String()
    }

    func getString(byteBuffer: ByteBuffer, size: Int) -> String {
        if byteBuffer.buffer.isEmpty {
            return ""
        }

        return byteBuffer.buffer.asUTF8String(length: size)
    }

    func getString(byteBuffer: ByteBuffer, offset: Int, size: Int) -> String {
        if byteBuffer.buffer.isEmpty {
            return ""
        }

        let subArray = Array(byteBuffer.buffer[offset...offset+size])
        return subArray.asUTF8String()
    }


    func getString(array:[UInt8], size: Int) -> String {
        if array.isEmpty {
            return ""
        }
        return array.asUTF8String(length: size)
    }

    func getString(array:[UInt8], offset: Int, size: Int) -> String {
        if array.isEmpty {
            return ""
        }
        if offset > array.count {
            return ""
        }

        let subArray = Array(array[offset...offset+size])
        return subArray.asUTF8String()
    }

    func getInteger(array:[UInt8], offset: Int, size: Int) -> Int {
        var subArray = Array(array[offset..<offset+size])
        subArray = stripLeadingZeros(source: subArray)
        let s = subArray.asUTF8String()
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        let n = formatter.number(from: s)
        return n!.intValue
    }

    mutating func decodeInteger(size: Int) -> Int {
        if buffer.isEmpty {
            return 0
        }

        let i = getInteger(array: buffer, offset: index, size: size)
        index += size
        return i
    }

    func decodeInteger(offset: Int, size: Int) -> Int {
        if buffer.isEmpty {
            return 0
        }
        return getInteger(array: buffer, offset: offset, size: size)
    }

    mutating func setSize(size: Int){
        var newSize = 0
        if buffer.count < size {
            newSize = buffer.count
        }
        let newBuffer = Array(buffer[0...newSize])
        buffer = newBuffer
    }

    mutating func rewind() {
        index = 0
    }

    func position() -> Int {
        return index
    }

    mutating func gotoPosition(newPosition: Int){
        index = newPosition
    }

    func getUInt8Array() -> [UInt8] {
        return buffer
    }

    func getUInt8Array(array: [UInt8], offset: Int) -> [UInt8] {
        if offset > array.count {
            return []
        }
        return Array(array[offset..<array.count])
    }

    func getUInt8Array(offset: Int) -> [UInt8] {
        if offset > buffer.count {
            return []
        }
        return Array(buffer[offset..<buffer.count])
    }


    func getFieldAsString(terminator: [UInt8]) -> String {
        if buffer.isEmpty {
            return ""
        }

        let seperator = terminator.asUTF8String()
        let source = buffer.asUTF8String()
        let components = source.components(separatedBy: seperator)
        if components.count > 0 {
            return components.first!
        }
        return ""
    }

    public func substring(from: Int) -> String {
        if buffer.isEmpty {
            return ""
        }
        if from > buffer.count {
            return ""
        }
        let bytes = buffer[from...]
        guard let s = String(bytes: bytes, encoding: .utf8) else {
            return ""
        }
        return s
    }

    public func substring(from: Int, length: Int) -> String {
        if buffer.isEmpty {
            return ""
        }
        if from + length > buffer.count {
            return ""
        }
        let subArray = Array(buffer[from..<from+length])
        guard let s = String(bytes: subArray, encoding: .utf8) else {
            return ""
        }
        return s
    }


    /**
     Strip leading zeros from array.

     Parameters:
     - source: [CChar]

     Returns: [CChar]
     */
    func stripLeadingZeros(source: [UInt8]) -> [UInt8] {
        var result = [UInt8]()
        var firstNonZero = 0

        //for i in 0..<source.count {
        for (index, element) in source.enumerated() {
            if source[index] == 0x30 {
                if firstNonZero == 0 {
                    continue
                } else {
                    result.append(element)
                }
            } else {
                firstNonZero = index
                result.append(source[index])
            }
        }
        return result
    }

    /**
     * reads the content of fc, at the current position into the buffer.
     * @param fc
     * @throws IOException
     */
//    func readFrom(fc: FileHandle) {
//        let data = fc.readDataToEndOfFile()
//
//        // the number of elements:
//        let count = data.count / MemoryLayout<UInt8>.size // sizeof(UInt8)
//
//        // create array of appropriate length:
//        buffer = [UInt8](repeating: 0, count: count)
//
//        // copy bytes into array
//        data.getUInt8s(&buffer, length:count * MemoryLayout<UInt8>.size)
//        //data.copyUInt8s<[UInt8]>(to: buffer, count: count * MemoryLayout<UInt8>.size)
//    }
}

// MARK: - UInt8
extension UInt8 {
    public func isDigit() -> Bool {
        return UInt8(48) ... UInt8(57) ~= self
    }

    public func isAlpha() -> Bool {
        var isAlpha = false
        if UInt8(97) ... UInt8(122) ~= self {
            isAlpha = true
        }

        else if UInt8(65) ... UInt8(90) ~= self {
            isAlpha = true
        }
        return isAlpha
    }
}

// MARK: - S57 Functions
public extension ByteBuffer {
    func isValidHeader() -> Bool {

        let five = self.int(at: 5)
        let six = self.int(at: 6)
        let eight = self.int(at: 8)

        if (five != 49) && (five != 50) && (five != 51) { // 1, 2, or 3
            return false
        }

        if (six != 76) { // L
            return false
        }

        if( eight != 49 && eight != 32 ) {  // 1, or SPACE
            return false
        }

        return true
    }
}

// MARK: - Array
extension Array {
    /**
     Retreive UTF8 Encoded String - Whole buffer

     Returns: String
     */
    func asUTF8String() -> String {
        let data = NSData(bytes: self, length: MemoryLayout<UInt8>.size * self.count)
        let string = String(data: data as Data, encoding: String.Encoding.ascii)
        return string!
    }

    func asUTF8String(length: Int) -> String {
        let data = NSData(bytes: self, length: MemoryLayout<UInt8>.size * length)
        let string = String(data: data as Data, encoding: String.Encoding.ascii)
        return string!
    }
}
