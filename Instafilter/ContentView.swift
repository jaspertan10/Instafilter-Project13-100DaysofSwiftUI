//
//  ContentView.swift
//  Instafilter
//
//  Created by Jasper Tan on 1/2/25.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import StoreKit


struct ContentView: View {
    
    @State private var processedImage: Image?
    
    //Filter settings
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var filterScale = 0.5
    @State private var filterAmount = 0.5
    @State private var filterEV = 0.5
    
    @State private var selectedItem: PhotosPickerItem?
    
    @State private var showingFilters = false
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()

    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    @State private var filterChangesBeforeReviewRequest = 3
    
    @State private var inputKeys = [String]()
    
    private var imageNotSelected: Bool {
        if processedImage == nil {
            return true
        }
        return false
    }
    
    var body: some View {
        
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    }
                    else {
                        ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                    }
                }
                //.buttonStyle(.plain) makes the button grey instead of blue colored
                .onChange(of: selectedItem) {
                    loadImage()
                }
                
                Spacer()
                
                VStack {
                    HStack {
                        Text("Intensity")
                        Slider(value: $filterIntensity)
                            .onChange(of: filterIntensity) {
                                applyProcessing()
                            }
                    }
                    .disabled(!inputKeys.contains(kCIInputIntensityKey))
                    
                    HStack {
                        Text("Radius")
                        Slider(value: $filterRadius)
                            .onChange(of: filterRadius) {
                                applyProcessing()
                            }
                    }
                    .disabled(!inputKeys.contains(kCIInputRadiusKey))
                    
                    HStack {
                        Text("Scale")
                        Slider(value: $filterScale)
                            .onChange(of: filterScale) {
                                applyProcessing()
                            }
                    }
                    .disabled(!inputKeys.contains(kCIInputScaleKey))
                    
                    
                    HStack {
                        Text("Amount")
                        Slider(value: $filterAmount)
                            .onChange(of: filterAmount) {
                                applyProcessing()
                            }
                    }
                    .disabled(!inputKeys.contains(kCIInputAmountKey))
        
                    
                    HStack {
                        Text("EV")
                        Slider(value: $filterEV)
                            .onChange(of: filterEV) {
                                applyProcessing()
                            }
                    }
                    .disabled(!inputKeys.contains(kCIInputEVKey))
                }
                .disabled(imageNotSelected)
                .padding(.vertical)
                
                HStack {
                    Button("Change filter") {
                        changeFilter()
                    }
                    .disabled(imageNotSelected)
                    
                    Spacer()
                    
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Filter Image", image: processedImage))
                    }
                }
            
                
            }
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters, actions: {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Thermal") { setFilter(CIFilter.thermal()) }
                Button("Vibrance") { setFilter(CIFilter.vibrance()) }
                Button("Exposure") { setFilter(CIFilter.exposureAdjust()) }
                Button("Cancel", role: .cancel) { }
            })
            .padding([.horizontal, .bottom])
        }
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
            Task {
                guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else {
                    return
                }
                
                guard let inputImage = UIImage(data: imageData) else {
                    return
                }
                
                let beginImage = CIImage(image: inputImage)
                
                currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
                applyProcessing()
            }
        }
    
    func applyProcessing() {
        
        inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey)
        {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey)
        {
            currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey)
        {
            currentFilter.setValue(filterScale * 10, forKey: kCIInputScaleKey)
        }
        if inputKeys.contains(kCIInputAmountKey)
        {
            currentFilter.setValue(filterAmount * 5, forKey: kCIInputAmountKey)
        }
        if inputKeys.contains(kCIInputEVKey)
        {
            currentFilter.setValue(filterEV * 5, forKey: kCIInputEVKey)
        }
        
        guard let outputImage = currentFilter.outputImage else {
            return
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return
        }
        
        let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        
        if filterCount >= 3 {
            requestReview()
            filterChangesBeforeReviewRequest = 10
        }
    }
}

#Preview {
    ContentView()
}

struct secondSandboxView: View {
    
    // Stores item (photo) that is selected
    //@State private var pickerItem: PhotosPickerItem?
    // Below allows us to store multiple items (photos)
    @State private var pickerItems = [PhotosPickerItem]()
    
    // Stores a single selected item (photo) as a SwiftUI image.
    //@State private var selectedImage: Image?
    //Below allows us to store multiple items (photos) as SwiftUI images.
    @State private var selectedImages = [Image]()
    

    var body: some View {
        ScrollView {
            
            PhotosPicker(selection: $pickerItems, maxSelectionCount: 3, matching: .images) {
                Label("Select a picture", systemImage: "photo")
            }

            
            ForEach(0..<selectedImages.count, id: \.self) { i in
                selectedImages[i]
                    .resizable()
                    .scaledToFit()
            }
        }
        .onChange(of: pickerItems) { // watch picker item for changes. Changes indicates User has selected a picture to load.
            Task {
                // Call load transferable when picture selected, this method tells SwiftUI we want to load the data from the picker item into a SwiftUI Image
                //selectedImage = try await pickerItem?.loadTransferable(type: Image.self)
                
                //clear array so that when new items are selected, old items are removed.
                selectedImages.removeAll()
                
                for item in pickerItems {
                    if let loadedImage = try await item.loadTransferable(type: Image.self) {
                        selectedImages.append(loadedImage)
                    }
                }
            }
        }
    }
}

/*
 
    - PhotosPicker view allows us to import one or more photos from the user's photo library
    - Data (photos) are provided to us as a special type called PhotosPickerItem
        - This is loaded asynchronously to prevent performance hiccups.
        - This data is then converted into a SwiftUI image.
 
    - PhotosPicker can be changed to be an array of PhotosPickerItems, which allows the user to select several photos.
 
 
 */


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



/*  SandboxView: Core Image, How to alter add filters to an image.
    
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
