//
//  Created by Maurice Parker on 1/10/24.
//

#if canImport(UIKit)

import UIKit

public extension UIApplication {
	
	var foregroundActiveScene: UIWindowScene? {
		connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
	}
	
}

#endif
