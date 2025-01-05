//
//  Created by Maurice Parker on 1/5/25.
//

extension Int {
	
	public func legalNumbering(level: Int) -> String {
		switch level {
		case 1:
			return legalNumberingLevel1
		default:
			return ""
		}
	}
	
}

private extension Int {

	var legalNumberingLevel1: String {
		return roman
	}
	
	// https://www.geeksforgeeks.org/converting-decimal-number-lying-between-1-to-3999-to-roman-numerals/
	var roman: String {
		var result = String()
		
		let num = [1,4,5,9,10,40,50,90,100,400,500,900,1000];
		let sym = ["I","IV","V","IX","X","XL","L","XC","C","CD","D","CM","M"];
		
		var number = self
		var i = 12;
		
		while (number > 0) {
			var div = number / num[i]
			number = number % num[i]
			
			while(div != 0) {
				div = div - 1
				result.append(sym[i])
			}
			i = i - 1
		}
		
		return result
	}
	
}
