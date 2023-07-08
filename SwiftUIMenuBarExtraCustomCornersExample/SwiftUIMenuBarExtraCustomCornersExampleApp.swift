//
//  SwiftUIMenuBarExtraCustomCornersExampleApp.swift
//  SwiftUIMenuBarExtraCustomCornersExample
//
//  Created by Stephan Casas on 7/8/23.
//

import SwiftUI;

@main
struct SwiftUIMenuBarExtraCustomCornersExampleApp: App {
    
    @State var cornerRadius: CGFloat = MenuBarExtraWindowService.kDefaultCornerRadius;
    
    var body: some Scene {
        MenuBarExtra(content: {
            
            ContentView(self.$cornerRadius)
                .background(
                    MenuBarExtraWindowService.HelperView()
                        .cornerRadius(self.$cornerRadius))
            
        }, label: { Image(systemName: "viewfinder") })
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Content

struct ContentView: View {
    
    @Binding var cornerRadius: CGFloat;
    
    init(_ cornerRadius: Binding<CGFloat>) {
        self._cornerRadius = cornerRadius;
    }
    
    var body: some View {
        VStack(content: {
            
            Text("\(self.cornerRadius.rounded())")
                .font(.title.monospacedDigit())
            
            Text("Corner Radius")
                .font(.subheadline)
            
            Slider(value: self.$cornerRadius, in: 0...100);
            
        })
        .frame(width: 250, height: 250)
        .padding()
    }
}

// MARK: - Lossless Method Exchanger

extension NSObject {
    
    /// Swap the given named instance method of the given named class with the given
    /// named instance method of this class.
    /// - Parameters:
    ///   - method: The name of the instance method whose implementation will be exchanged.
    ///   - className: The name of the class whose instance method implementation will be exchanged.
    ///   - newMethod: The name of the instance method on this class which will replace the first given method.
    static func exchange(method: String, in className: String, for newMethod: String) {
        guard let classRef = objc_getClass(className) as? AnyClass,
              let original = class_getInstanceMethod(classRef, Selector((method))),
              let replacement = class_getInstanceMethod(self, Selector((newMethod)))
        else {
            fatalError("Could not exchange method \(method) on class \(className).");
        }
        
        method_exchangeImplementations(original, replacement);
    }
    
}

// MARK: - Custom Window Corner Mask Implementation

extension NSObject {
    
    @objc func __SwiftUIMenuBarExtraPanel___cornerMask() -> NSImage? {
        let radius = MenuBarExtraWindowService.shared.cornerRadius;
        let radiusForDraw = max(radius, 1);
        
        let width = radiusForDraw * 2;
        let height = radiusForDraw * 2;
        
        let image = NSImage(size: CGSizeMake(width, height));
        
        image.lockFocus();
        
        /// Draw a rounded-rectangle corner mask.
        ///
        /// If the radius is zero, fallback to 90º
        /// corners in a normal rect.
        ///
        NSColor.black.setFill();
        if radius >= 1 {
            NSBezierPath(
                roundedRect: CGRectMake(0, 0, width, height),
                xRadius: radiusForDraw,
                yRadius: radiusForDraw)
            .fill();
        } else {
            NSBezierPath(
                rect: CGRectMake(0, 0, width, height))
            .fill()
        }
        
        image.unlockFocus();
        
        image.capInsets = .init(
            top: radiusForDraw,
            left: radiusForDraw,
            bottom: radiusForDraw,
            right: radiusForDraw);
        
        return image;
    }
    
}

// MARK: - MenuBarExtra Support Service

class MenuBarExtraWindowService {
    
    static let shared = MenuBarExtraWindowService();
    
    static let kDefaultCornerRadius: CGFloat = 13;
    
    var cornerRadius: CGFloat = kDefaultCornerRadius;
    
    private var _didExchangeMethods = false;
    
    var didExchangeMethods: Bool {
        get { self._didExchangeMethods }
        set { if newValue { self._didExchangeMethods = true } }
    }
    
    // MARK: - Context Window Accessor View
    
    struct HelperView: NSViewRepresentable {
        
        @Binding private var cornerRadius: CGFloat;
        
        init() {
            self._cornerRadius = .constant(
                MenuBarExtraWindowService.kDefaultCornerRadius
            );
        }
        
        func cornerRadius(_ cornerRadius: Binding<CGFloat>) -> Self {
            var copy = self;
            copy._cornerRadius = cornerRadius;
            
            return copy;
        }
        
        func updateNSView(_ nsView: Helper, context: Context) {
            MenuBarExtraWindowService.shared.cornerRadius = self.cornerRadius.rounded();
            nsView.notifyWindowCornerMaskDidChange();
        }
        
        func makeNSView(context: Context) -> Helper { Helper() }
        
        // MARK: - NSView / AppKit Context
        
        class Helper: NSView {
            
            override func viewWillDraw() {
                if MenuBarExtraWindowService.shared.didExchangeMethods { return }
                
                guard
                    let window: AnyObject = self.window,
                    let windowClass = window.className
                else { return }
                
                
                NSObject.exchange(
                    method: "_cornerMask",
                    in: windowClass,
                    for: "__SwiftUIMenuBarExtraPanel___cornerMask");
                
                self.notifyWindowCornerMaskDidChange();
                
                MenuBarExtraWindowService.shared.didExchangeMethods = true;
            }
            
            func notifyWindowCornerMaskDidChange() {
                guard let window: AnyObject = self.window else { return }
                let _ = window.perform(Selector(("_cornerMaskChanged")));
            }
            
        }
        
    }
    
}


