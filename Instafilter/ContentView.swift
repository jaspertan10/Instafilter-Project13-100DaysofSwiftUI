//
//  ContentView.swift
//  Instafilter
//
//  Created by Jasper Tan on 1/2/25.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct SandboxView: View {
    
    @State private var image: Image?
    @State private var settingScale: Float = 1

    
    var body: some View {
        VStack {
            // ? after image indicates Optional Chaining. It ensures resizable and scaledToFit modifier are only executed if image is non-nil. This prevents program crash.
            image?
                .resizable()
                .scaledToFit()
            
            Slider(value: $settingScale, in: 0...1)
                .onChange(of: settingScale) { oldValue, newValue in
                    loadImage()
                }
        }
        .onAppear {
            loadImage()
        }

    }
    
    func loadImage() {
        
        //create a UIImage then manipulate it using Core Image.
        
        //Load example image in to UIImage
        let inputImage = UIImage(resource: .golden)
        
        //Convert UIImage to CIImage, which is what Core Image wants to work with
        let beginImage = CIImage(image: inputImage)
        
        //Create a Core Image context and a Core Image filter.
        let context = CIContext()
        let currentFilter = CIFilter.crystallize()

        //Customize the filter:
        //  inputImage - image we want to change
        currentFilter.inputImage = beginImage
        
        //Dynamically setting intensity of the filter settings
        let amount = settingScale

        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(amount, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(amount * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(amount * 10, forKey: kCIInputScaleKey) }
    
        //  intensity - how strongly the sepia effect should be applied (range of 0...1, in decimals)
        //currentFilter.scale = settingScale
        
        
        //Now we need to convert the output from our filter to a SwiftUI Image that we can display in our view.
        /*  - Read output image from our filter, which will be a CIImage. This might fail, so return an optional.
            - Ask our context to create a CG Image from that output image. This also might fail, return an optional
            - Convert CGImage into a UIImage
            - Convert UIImage into a SwiftUI Image
         
            FYI: It is possible to go from CGImage to SwiftUI Image, but it requires extra parameters and adds complexity...
         */
        
        // get a CIImage from filter or exit if it fails
        guard let outputImage = currentFilter.outputImage else {
            return
        }
        
        // attempt to get CGImage from CIImage (outputImage)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return
        }
        
        // convert cgImage to a UIImage
        let uiImage = UIImage(cgImage: cgImage)
        
        // convert UIImage to SwiftUI Image
        image = Image(uiImage: uiImage)
        
    }
}

#Preview {
    SandboxView()
}



/*
 
 - Image view is a great end point, but it's not great if you want to create images dynamically, apply Core Image filters, etc.
 
 - There are a total of 4 image types:
    - Image, comes from SwiftUI
    - UIImage, comes from UIKit. It is closest in functionality to SwiftUI in comparison to the other 2
    - CGImage, comes from Core Graphics. Simpler image type that is really just a two dimensional array of pixels
    - CIImage, comes from Core Image. Stores all information required to produce an image, but doesn't turn it into pixels unless asked.
        CIImage is an "Image recipe" rather than an actual image
 
 
 - There is interoperability between the various image types:
    - We can create a UIImage from a CGImage, and create CGImage from a UIImage
    - We can create a CIImage from a UIImage and from a CGImage, and can create a CGImage from a CIImage
    - We can create a SwiftUI Image from both a UIImage and a CGImage
 
 - Filters are the things that do actual work of transforming image data, such as:
    - Blur
    - Sharpening
    - Adjusting Colors
    - Pixelating
    - Crystallizing
    - etc
 
 */
