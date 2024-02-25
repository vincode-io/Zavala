//
//  Created by Maurice Parker on 1/9/24.
//

#if canImport(UIKit)

import UIKit

public extension UIApplication {
	
	var foregroundActiveScene: UIWindowScene? {
		// This code doesn't work. As of iOS 15 there is only one way to get the correct scene.
		// You have to use the deprecated property.
		return UIApplication.shared.keyWindow?.windowScene
		// This code does not work.
		// connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
	}
	
}

#endif
