//
//  ContentView.swift
//  GeometrySpace
//
//  Created by localadmin on 29.03.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import SwiftUI
import CoreServices
import Combine


let alertPublisher = PassthroughSubject<Void, Never>()
let timePublisher = PassthroughSubject<Void, Never>()
let resetPublisher = PassthroughSubject<Void, Never>()
let winPublisher = PassthroughSubject<Void, Never>()

class SliderData: ObservableObject {
  let didChange = PassthroughSubject<SliderData,Never>()

  @Published var sliderValue: Double = 0 {
    didSet {
      print("sliderValue \(sliderValue)")
      didChange.send(self)
    }
  }
}


struct Fonts {
    static func futuraCondensedMedium(size:CGFloat) -> Font{
        return Font.custom("Futura-CondensedMedium",size: size)
    }
}

let minWidith = CGFloat(42)
let minHeight = CGFloat(48)
let fontSize = CGFloat(48)

//var backgrounds = [Color(UIColor(red: 255/255, green: 105.0/255, blue: 180.0/255, alpha: 1.0)),Color.purple,Color.yellow,Color.red,Color(UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1.0)), Color(UIColor(red: 102/255, green: 178.0/255, blue: 178.0/255, alpha: 1.0))]
var backgrounds = [Color.red, Color.blue, Color.orange, Color.green, Color.purple,Color.yellow,Color(UIColor(red: 255/255, green: 105.0/255, blue: 180.0/255, alpha: 1.0))]
//var backgrounds = [Color.red, Color.blue, Color.orange, Color.green]
struct ContentView: View {
  @State private var rect:[CGRect] = []
  @State private var textText = [String](repeating: "", count: 100)
  @State private var textColors = [Color](repeating: Color.clear, count: 100)
  @State private var textID:Int? = 0
  @State private var textValue:[String] = ["1","2","3","4","5","6","7"]
//  @State private var textValue:[String] = ["1","2","3","4"]
  @State private var timerText = 0
  @State private var startStop = false
  @State private var showingAlert = false
  @State private var showingReset = false
  @State private var showingWin = false
  @State private var poke:String = ""
  
  @State private var sliderDB = [(Int?,Int?)](repeating: (nil,nil), count: 100)
  @ObservedObject var sliderData:SliderData
 
  
  let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
  
  var body: some View {

    let dropDelegate = TheDropDelegate(textID: $textID, textText: $textText, rect: $rect, textColors: $textColors, startStop: $startStop)
    return VStack {
    Spacer()

    Text("\(timerText)")
    .font(Fonts.futuraCondensedMedium(size: fontSize/2))
    .onReceive(timer) { input in
      if self.startStop {
        self.timerText = self.timerText + 1
      }
    }
    .onReceive(timePublisher) { ( _ ) in
      self.startStop = false
    }
    .alert(isPresented: $showingAlert) {
          Alert(title: Text("Sorry You Failed"), message: Text("Zudoku Snaz"), dismissButton: .default(Text("Shake To Try Again!")))
        }
    .onReceive(alertPublisher) { (_) in
      self.showingAlert = true
    }.onReceive(resetPublisher, perform: { (_) in
      self.showingReset = true
    })
    
    Spacer()
    
   
//    Slider(value: $celsius, in: 0...Double(self.textColors.count), step: 1) { changed in
//      print("changed ",self.celsius)
//      let fixed = cellsUsed(textColors: self.textColors, figures: self.rect.count)
//      if self.celsius > fixed {
//        self.celsius = fixed
//      }
//      }.padding()
//    Text("celsius \(celsius)")


    Slider(value: $sliderData.sliderValue, in: 0...Double(self.textColors.count))
  
    
    Spacer().alert(isPresented:$showingReset) {
            Alert(title: Text("Reset Sure?"), message: Text("Zudoku Reset?"), primaryButton: .destructive(Text("Reset")) {
                    for loop in 0 ..< self.textValue.count * self.textValue.count {
                      self.textText[loop] = ""
                      self.textColors[loop] = Color.clear
                    }
                    self.timerText = 0
                    self.startStop = false
            }, secondaryButton: .cancel())
        }
    
    
      HStack(alignment: .center, spacing: 8) {
      ForEach((0 ..< textValue.count), id: \.self) { column in
        Text(self.textValue[column])
          .font(Fonts.futuraCondensedMedium(size: fontSize))
          .frame(width: minWidith, height: minHeight, alignment: .center)
          .background(backgrounds[column])
          .cornerRadius(minHeight/2)
          .onTapGesture {
            self.poke = self.textValue[column]
          }
        .onDrag {
            return NSItemProvider(object: self.textValue[column] as NSItemProviderWriting) }
        }
      }

    Spacer().onReceive(winPublisher, perform: { (_) in
      self.showingWin = true
    }).alert(isPresented: $showingWin) {
          Alert(title: Text("Success, You did it"), message: Text("Well Done"), dismissButton: .default(Text("Shake To Try Again!")))
        }
      VStack(alignment: .center, spacing: 8) {
        ForEach((0 ..< self.textValue.count).reversed(), id: \.self) { row in
          HStack(alignment: .center, spacing: 8) {
            ForEach((0 ..< self.textValue.count).reversed(), id: \.self) { column in
              return VStack {
                if self.textColors[fCalc(c: column, r: row, x: self.textValue.count)] == Color.clear {
//                  cellCell(column: column, row: row, dropDelegate: dropDelegate, textValue: textValue, textText: textText, textColors: textC, rect: rect)
                  Text(self.textText[fCalc(c: column, r: row, x: self.textValue.count)])
                    .font(Fonts.futuraCondensedMedium(size:fontSize - 12))
                    .frame(width: minWidith, height: minHeight, alignment: .center)
                    .background(InsideView(rect: self.$rect))
                    .onDrop(of: ["public.utf8-plain-text"], delegate: dropDelegate)
                    .onTapGesture {
                      if self.poke != "" {
                        self.sliderDB[Int(self.sliderData.sliderValue)] = (column,row)
                        self.sliderData.sliderValue = self.sliderData.sliderValue + 1
                        self.textText[fCalc(c: column, r: row, x: self.textValue.count)] = self.poke
                        self.textColors[fCalc(c: column, r: row, x: self.textValue.count)] = backgrounds[Int(self.poke)! - 1]
                        self.poke = ""
                        self.startStop = true
                        runOnce = false
                        if boardFull(textColors: self.textColors, figures: self.rect.count) {
                          if confirmColours(textColors: self.textColors, figures: self.rect.count) {
                              timePublisher.send()
                          }
                        }
                      }
                  }
                  //                          .onAppear {
                  //                            self.textText[fCalc(c: column, r: row, x: self.textValue.count)] = String(fCalc(c: column, r: row, x: self.textValue.count))
                  //                          }
                } else {
                  Text(self.textText[fCalc(c: column, r: row, x: self.textValue.count)])
                    .onTapGesture {
                      if self.poke != "" {
                        self.sliderDB[Int(self.sliderData.sliderValue)] = (column,row)
                        self.sliderData.sliderValue = self.sliderData.sliderValue + 1
                        self.textText[fCalc(c: column, r: row, x: self.textValue.count)] = self.poke
                        self.textColors[fCalc(c: column, r: row, x: self.textValue.count)] = backgrounds[Int(self.poke)! - 1]
                        self.poke = ""
                        if boardFull(textColors: self.textColors, figures: self.rect.count) {
                          if confirmColours(textColors: self.textColors, figures: self.rect.count) {
                              timePublisher.send()
                          }
                        }
                      } else {
                        self.sliderData.sliderValue = self.sliderData.sliderValue + 1
                        self.sliderDB[Int(self.sliderData.sliderValue)] = (nil,nil)
                        self.textText[fCalc(c: column, r: row, x: self.textValue.count)] = ""
                        self.textColors[fCalc(c: column, r: row, x: self.textValue.count)] = Color.clear
                      }
                  }
                  .font(Fonts.futuraCondensedMedium(size:fontSize))
                  .frame(width: minWidith, height: minHeight, alignment: .center)
                  .background(self.textColors[fCalc(c: column, r: row, x: self.textValue.count)])
                  .onDrop(of: ["public.utf8-plain-text"], delegate: dropDelegate)
                  .onDrag {
                    self.textColors[fCalc(c: column, r: row, x: self.textValue.count)] = Color.clear
                    let copyCell = self.textText[fCalc(c: column, r: row, x: self.textValue.count)]
                    self.textText[fCalc(c: column, r: row, x: self.textValue.count)] = ""
                    return NSItemProvider(object: copyCell as NSItemProviderWriting) }
                }
              }
            }
          }
        }
      }

    Spacer()
    
    }
  }
}

struct cellCell: View {
  @Binding var column: Int
  @Binding var row: Int
//  @Binding var dropDelegate: DropDelegate
  @Binding var textValue:[String]
  @Binding var textText:[String]
//  @Binding var textColors:[Color]
//  @Binding var rect:[CGRect]
  
  var body: some View {
    return Text(self.textText[fCalc(c: column, r: row, x: self.textValue.count)])
                    .font(Fonts.futuraCondensedMedium(size:fontSize - 12))
                    .frame(width: minWidith, height: minHeight, alignment: .center)
//                    .background(InsideView(rect: self.$rect))
//                    .onDrop(of: ["public.utf8-plain-text"], delegate: dropDelegate)
//                    .onDrag {
//                    self.textColors[fCalc(c: self.column, r: self.row, x: self.textValue.count)] = Color.clear
//                      let copyCell = self.textText[fCalc(c: self.column, r: self.row, x: self.textValue.count)]
//                    self.textText[fCalc(c: self.column, r: self.row, x: self.textValue.count)] = ""
//                    return NSItemProvider(object: copyCell as NSItemProviderWriting)
                    
//    }
  }
}

func cellsUsed(textColors:[Color],figures:Int) -> Double {
  var counting:Double = 0
    
  for loop in 0 ..< figures {
      if textColors[loop] != Color.clear {
        counting += 1
      }
    }
  return counting
}

func cellsFree(textColors:[Color],figures:Int) -> Double {
  var counting:Double = 0
  
  for loop in 0 ..< figures {
      if textColors[loop] == Color.clear {
        counting += 1
      }
    }
  return counting
}



func boardFull(textColors:[Color],figures:Int) -> Bool {
  for loop in 0 ..< figures {
      if textColors[loop] == Color.clear {
        return false
      }
    }
  return true
}


func confirmColours(textColors:[Color],figures:Int) -> Bool {
//  print("figures",figures)
  for loop in 0 ..< figures {
      if textColors[loop] == Color.clear {
        return false
      }
    }

  var tfigures = figures - 1
  let rfigure = Int(Double(figures).squareRoot())
//  print("rfig ",rfigure)
  for _ in 0..<rfigure {
  var superSet = Set<String>()
  for loop in stride(from: tfigures, to: tfigures - rfigure, by: -1) {
    superSet.insert(textColors[loop].description)
//    print("loop ",loop)
  }
  tfigures = tfigures - rfigure
//  print("superSet ",superSet,superSet.count)
    if superSet.count != rfigure {
      alertPublisher.send()
      return false
    }
  }

  tfigures = figures - 1
  for _ in 0..<rfigure {
    var superSet = Set<String>()
    for loop in stride(from: tfigures, to: -1, by: -rfigure) {
    superSet.insert(textColors[loop].description)
//    print("loop2 ",loop)
  }
  tfigures = tfigures - 1
//  print("superSet ",superSet,superSet.count)
    if superSet.count != rfigure {
      alertPublisher.send()
      return false
    }
  }
  
  // right diagonally left to right
  
//  var qfigure = (rfigure * rfigure) - 1
//  print("qfigures ",qfigure,rfigure)
//  var superSet = Set<String>()
//  for loop in stride(from: qfigure, to: -1, by: -(rfigure+1)) {
//    superSet.insert(textColors[loop].description)
//    print("loop ",loop)
//  }
//  tfigures = tfigures - 1
//  print("superSet ",superSet,superSet.count)
//  if superSet.count != rfigure {
//    alertPublisher.send()
//    return false
//  }
    
    // left to right diagonally
    
    
//  qfigure = (rfigure * rfigure)  - (rfigure - 1)
//  print("tfigures ",qfigure,rfigure)
//  var superSet2 = Set<String>()
//  for loop in stride(from: tfigures, to: 2, by: -(rfigure+1)) {
//    superSet2.insert(textColors[loop].description)
//    print("loop2 ",loop)
//  }
//  tfigures = tfigures - 1
//  print("superSet ",superSet2,superSet.count)
//  if superSet2.count != rfigure {
//    alertPublisher.send()
//    return false
//  }
  
  
  winPublisher.send()
  return true
}


//struct ContentView: View {
//@State private var rect:[CGRect] = []
//@State private var textText = ["","","",""]
//@State private var textID = 0
//@State private var textValue1:String = "Hello World 1"
//@State private var textValue2:String = "Hello World 2"
//var body: some View {
//let dropDelegate = TheDropDelegate(textID: $textID, textText: $textText, rect: $rect)
//return VStack {
//Spacer()
//Text(textValue1)
//.onDrag {
//return NSItemProvider(object: self.textValue1 as NSItemProviderWriting) }
//Text(textValue2)
//.onDrag {
//return NSItemProvider(object: self.textValue2 as NSItemProviderWriting) }
//Spacer()
//HStack {
//ForEach((0...3).reversed(), id: \.self) {
//Text(self.textText[$0])
//.frame(width: 128, height: 32, alignment: .center)
//.background(Color.yellow)
//.background(InsideView(rect: self.$rect))
//.onDrop(of: ["public.utf8-plain-text"], delegate: dropDelegate)
//}
//}
//Spacer()
//}
//}
//}

func fCalc(c:Int, r:Int, x:Int) -> Int {
  return (c + (r*x))
}

//struct TextView: View {
//  @Binding var column: Int
//  @Binding var row: Int
//  @Binding var dropDelegate: DropDelegate
//  @Binding var textText:[String]
//  @Binding var rect:[CGRect]
//  var body: some View {
//    let calc = (column + (row*4))
//    return BoxView(text: self.textText[calc])
//      .background(InsideView(rect: self.$rect))
//      .onDrop(of: ["public.utf8-plain-text"], delegate: dropDelegate)
//  }
//}
//
//struct BoxView: View {
//  @State var text:String
//  var body: some View {
//    return Text(text)
//    .font(Fonts.futuraCondensedMedium(size:48))
//    .frame(width: 64, height: 32, alignment: .center)
//  }
//}

var runOnce = true

struct InsideView: View {
  @Binding var rect: [CGRect]
  @State var toggle = true
  var body: some View {
    
      return VStack {
        if toggle {
         GeometryReader { geometry in
          Rectangle()
            .fill(Color.yellow)
            .frame(width: minWidith, height: minHeight, alignment: .center)
            .opacity(0.5)
            .onAppear {
              if runOnce {
                self.rect.append(geometry.frame(in: .global))
              }
          }
        }
      }
    }
  }
}

//struct InsideView: View {
//  @Binding var rect: [CGRect]
//  @State var toggle = true
//  var body: some View {
//
//      return VStack {
//        if toggle {
//         GeometryReader { geometry in
//          Rectangle()
//            .fill(Color.yellow)
//            .frame(width: 64, height: 64, alignment: .center)
//            .opacity(0.5)
//            .onAppear {
//              self.rect.append(geometry.frame(in: .global))
//          }.onReceive(colorPublisher) { ( color ) in
//            self.toggle.toggle()
//          }
//        }
//        } else {
//           Rectangle()
//          .fill(Color.red)
//          .frame(width: 64, height: 64, alignment: .center)
//          .opacity(0.5)
//          .onReceive(colorPublisher) { ( color ) in
//            self.toggle.toggle()
//          }
//        }
//      }
//  }
//}

//struct TheDropDelegate: DropDelegate {
//@Binding var textID:Int
//@Binding var textText:[String]
//@Binding var rect:[CGRect]
//
//func dropTarget(info: DropInfo) -> Int {
//if info.location.x > UIScreen.main.bounds.width / 2 {
//return(1)
//} else {
//return(0)
//}
//}
//func performDrop(info: DropInfo) -> Bool {
//textID = dropTarget(info: info)
//if let item = info.itemProviders(for: ["public.utf8-plain-text"]).first {
//item.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { (urlData, error) in
//DispatchQueue.main.async {
//if let urlData = urlData as? Data {
//let text = String(decoding: urlData, as: UTF8.self)
//self.textText[self.textID] = text
//}
//}
//}
//return true
//} else {
//return false
//}
//}
//}

struct TheDropDelegate: DropDelegate {
  @Binding var textID:Int?
  @Binding var textText:[String]
  @Binding var rect:[CGRect]
  @Binding var textColors:[Color]
  @Binding var startStop:Bool


  func validateDrop(info: DropInfo) -> Bool {
          return info.hasItemsConforming(to: ["public.utf8-plain-text"])
        }

        func dropEntered(info: DropInfo) {
            print("drop entered")
        }

        func dropTarget(info: DropInfo) -> Int? {
          for squareno in 0..<rect.count {
            if rect[squareno].contains(info.location) {
              return squareno
            }
          }
          return nil
        }

        func performDrop(info: DropInfo) -> Bool {
            textID = dropTarget(info: info)
            if textID == nil {
              return false
            }
            

            if let item = info.itemProviders(for: ["public.utf8-plain-text"]).first {
                item.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { (urlData, error) in
                    DispatchQueue.main.async {
                        if let urlData = urlData as? Data {
                           let text = String(decoding: urlData, as: UTF8.self)
                           self.textText[self.textID!] = text
                           // we need to subtract 1 cause array starts at zero
                           self.textColors[self.textID!] = backgrounds[Int(text)! - 1]
                           if boardFull(textColors: self.textColors, figures: self.rect.count) {
                            if confirmColours(textColors: self.textColors, figures: self.rect.count) {
                              timePublisher.send()
                            }
                          }
                        }
                    }
                }
                return true
            } else {
                return false
            }

        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            let item = info.hasItemsConforming(to: ["public.utf8-plain-text"])
            let dp = DropProposal(operation: .move)
            self.startStop = true
//            self.textValue = ""
            runOnce = false
            return dp
        }

        func dropExited(info: DropInfo) {
            print("dropExited")
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView(sliderData: SliderData.init())
    }
}

extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
//      print("Device shaken")
      resetPublisher.send()
    }
  }
}

