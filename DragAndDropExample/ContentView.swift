import SwiftUI

// MARK: ContentView
struct ContentView: View {
    var body: some View {
        VStack {
            HStack{
                DragView(value: 1, color: .green)
                DragView(value: 2, color: .blue)
                DragView(value: 3, color: .orange)
            }
            DropView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: SomeObject
// see ColorExtension for how to make a Color Codable
class SomeObject : Codable {
    var someValue: Int
    var someColor: Color
    init(value: Int, color: Color) {
        someValue = value
        someColor = color
    }
}

// MARK: DragView
struct DragView: View {
    var value: Int = 0
    var color: Color = .black
    
    var body: some View {
        let dragAndDropItem1 = DragAndDropItem(_someObject: SomeObject(value: value, color: color))
        
        return Rectangle()
            .fill(dragAndDropItem1.someObject.someColor)
            .overlay(Text(String(value)).foregroundColor(.white))
            .padding()
            .onDrag({ NSItemProvider(object: dragAndDropItem1) })
    }
}

// MARK: DropView
struct DropView: View {
    let dropDelegate = MyDropDelegate()
    @State var fillColor = Color.black
    @State var textColor = Color.white
    @State var text = "Drag on to me!"
    
    var body: some View {
        
        dropDelegate.dropEnteredHandler = enteredCallback
        dropDelegate.dropExitedHandler = exitedCallback
        dropDelegate.dropCompletedHandler = completedCallback
        
        return Circle()
            .fill(fillColor)
            .overlay(Text(text).foregroundColor(textColor))
            .padding()
            .onDrop(of: ["public.data"], delegate: dropDelegate)
    }
    
    func enteredCallback() {
        fillColor = Color.yellow
        textColor = Color.black
        text = "Drop it!"
    }
    
    func exitedCallback() {
        fillColor = Color.black
        textColor = Color.white
        text = "Drag on to me!"
    }
    
    func completedCallback(someObject: SomeObject) {
        fillColor = someObject.someColor
        textColor = Color.white
        text = "\(someObject.someValue)"
    }
    
}

// MARK: MyDropDelegate
class MyDropDelegate: DropDelegate {
    
    var dropEnteredHandler: () -> Void = {}
    var dropExitedHandler: () -> Void = {}
    var dropCompletedHandler: (SomeObject) -> Void = {_ in}
    
    func dropEntered(info: DropInfo) {
        dropEnteredHandler()
    }
    
    func dropExited(info: DropInfo) {
        dropExitedHandler()
    }
    
    func performDrop(info: DropInfo) -> Bool {
        print(info)
        if let item = info.itemProviders(for: ["public.data"]).first {
            item.loadObject(ofClass: DragAndDropItem.self) { [weak self] dropItem, error in
                guard error == nil, let myDroppedItem = dropItem as? DragAndDropItem else { return }
                print(myDroppedItem.someObject.someValue)
                self!.dropCompletedHandler(myDroppedItem.someObject)
            }
            return true
        } else {
            return false
        }
    }
}

// MARK: DragAndDropItem
final class DragAndDropItem : NSObject, NSItemProviderWriting, NSItemProviderReading {
    static var readableTypeIdentifiersForItemProvider: [String] {return ["public.data"]}
    static var writableTypeIdentifiersForItemProvider: [String] {return ["public.data"]}
    
    var someObject: SomeObject
    
    init(_someObject: SomeObject) {
        someObject = _someObject
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        do{
            let data = try JSONEncoder().encode(someObject)
            completionHandler(data,nil)
        } catch{
            completionHandler(nil, error)
        }
        return Progress(totalUnitCount: 100)
    }
    
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let item = try JSONDecoder().decode(SomeObject.self, from: data)
        return Self.init(_someObject: item)
    }
}

