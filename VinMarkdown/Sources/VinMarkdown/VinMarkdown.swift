//
//  VinMarkdown.swift
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias VinFont = UIFont
public typealias VinFontDescriptor = UIFontDescriptor
public typealias VinFontDescriptorSymbolicTraits = UIFontDescriptor.SymbolicTraits
let vinBoldTrait = UIFontDescriptor.SymbolicTraits.traitBold
let vinItalicTrait = UIFontDescriptor.SymbolicTraits.traitItalic
let vinFamilyAttribute = UIFontDescriptor.AttributeName.family
#elseif canImport(AppKit)
import AppKit
public typealias VinFont = NSFont
public typealias VinFontDescriptor = NSFontDescriptor
public typealias VinFontDescriptorSymbolicTraits = NSFontDescriptor.SymbolicTraits
let vinBoldTrait = NSFontDescriptor.SymbolicTraits.bold
let vinItalicTrait = NSFontDescriptor.SymbolicTraits.italic
let vinFamilyAttribute = NSFontDescriptor.AttributeName.family
#endif
