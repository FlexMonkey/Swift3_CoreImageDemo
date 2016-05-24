//
//  ViewController.swift
//  Swift3_CoreImageDemo
//
//  Created by Simon Gladman on 24/05/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.gray()
        
        CustomFiltersVendor.registerFilters()
        
        guard let filterName = CIFilter.filterNames(inCategory: CategoryCustomFilters).first else
        {
            return
        }
        
        let threshold: NSNumber = 0.5
        let mona = CIImage(image: UIImage(named: "monalisa.jpg")!)!
        
        let filter = CIFilter(
            name: filterName,
            withInputParameters: [kCIInputImageKey: mona, "inputThreshold": threshold])
        
        guard let outputImage = filter?.outputImage else
        {
            return
        }
        
        let context = CIContext()
        
        let final: CGImage = context.createCGImage(outputImage, from: outputImage.extent)
        
        let frame = CGRect(
            x: Int(view.bounds.midX) - final.width / 2,
            y: Int(view.bounds.midY) - final.height / 2,
            width: final.width,
            height: final.height)
        
        let imageView = UIImageView(frame: frame)
        
        imageView.image = UIImage(cgImage: final)
        
        view.addSubview(imageView)
    }


}

// MARK: Filters

let CategoryCustomFilters = "Custom Filters"

class CustomFiltersVendor: NSObject, CIFilterConstructor
{
    static func registerFilters()
    {
        CIFilter.registerName(
            "ThresholdFilter",
            constructor: CustomFiltersVendor(),
            classAttributes: [
                kCIAttributeFilterCategories: [CategoryCustomFilters.nsString]
            ])
    }
    
    func filter(withName name: String) -> CIFilter?
    {
        switch name
        {
        case "ThresholdFilter":
            return ThresholdFilter()
            
        default:
            return nil
        }
    }
}

class ThresholdFilter: CIFilter
{
    var inputImage : CIImage?
    var inputThreshold: NSNumber = 0.75
    
    override var attributes: [String : AnyObject]
    {
        return [
            kCIAttributeFilterDisplayName: "Threshold Filter",
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage.nsString] as AnyObject,
            "inputThreshold": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.75,
                kCIAttributeDisplayName: "Threshold",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar.nsString] as AnyObject
        ]
    }
    
    override func setDefaults()
    {
        inputThreshold = 0.75
    }
    
    override init()
    {
        super.init()
        
        thresholdKernel = CIColorKernel(string:
            "kernel vec4 thresholdFilter(__sample image, float threshold)" +
                "{" +
                "   float luma = dot(image.rgb, vec3(0.2126, 0.7152, 0.0722));" +
                
                "   return vec4(vec3(step(threshold, luma)), 1.0);" +
            "}"
        )
        
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    var thresholdKernel: CIColorKernel?
    
    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage,
            thresholdKernel = thresholdKernel else
        {
            return nil
        }
        
        let extent = inputImage.extent
        let arguments = [inputImage, inputThreshold]
        
        return thresholdKernel.apply(withExtent: extent, arguments: arguments)
    }
}

// MARK: Extensions

extension String
{
    var nsString: NSString
    {
        return NSString(string: self)
    }
}
