//
//  Created by Maurice Parker on 1/5/25.
//

extension Int {
	
	public func legalNumbering(level: Int) -> String {
		switch level {
		case 1:
			return roman + "."
		case 2:
			return alphabetic.uppercased() + "."
		case 3:
			return String(self) + "."
		case 4:
			return alphabetic + "."
		case 5:
			return "(\(String(self)))"
		case 6:
			return "(\(alphabetic))"
		case 7:
			return "(\(roman.lowercased()))"
		default:
			return "(??)"
		}
	}
	
}

private extension Int {

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
			
			while (div != 0) {
				div = div - 1
				result.append(sym[i])
			}
			
			i = i - 1
		}
		
		return result
	}

	var alphabetic: String {
		guard self > 0 && self < 703 else { return "??" }
			
		let sym = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"];
		
		let div = (self - 1) / 26
		let rem = (self - 1) % 26
		
		if div > 0 {
			return sym[div - 1] + sym[rem]
		} else {
			return sym[rem]
		}
	}

}
