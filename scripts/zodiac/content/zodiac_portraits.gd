extends RefCounted
## Public portraits: hints about a person, not solutions to their conversations.
## Intimate history belongs in the earned dialogue and private scenes.
const ENTRIES := {
	"rooster": {
		"en": "Rooster arrives before the kettle boils and notices who hasn't come home. His ledger is immaculate; his worry is less orderly. A straight refusal earns more respect than a beautiful excuse, but learning to spend an hour without accounting for it may be his hardest work.",
		"vi": "Dậu đến trước khi nước sôi, nhớ cả người chưa về nhà. Sổ sách ngay ngắn; nỗi lo thì không. Anh trọng lời từ chối thẳng hơn cái cớ đẹp, nhưng học cách dành một giờ không cần tính toán có lẽ là việc khó nhất."
	},
	"cat": {
		"en": "Cat chooses the best chair and lets you think it was yours. She treasures things that have outlived their usefulness, then acts offended when anyone notices her affection. Her questions sound idle. Her attention isn't.",
		"vi": "Mão chọn ghế tốt nhất rồi để bạn tưởng đó là ghế mình. Cô quý những món đã hết hữu dụng, rồi tỏ vẻ khó chịu khi ai nhận ra tình cảm ấy. Câu hỏi nghe vu vơ. Sự chú ý thì không."
	},
	"monkey": {
		"en": "Monkey can turn a dropped bottle cap into a performance before it hits the floor. He wants a partner in mischief, but sometimes forgets to ask whether the other person is having fun. Listen for the moment he lets a joke fail without replacing it.",
		"vi": "Thân biến nắp chai rơi thành tiết mục trước khi nó chạm đất. Anh muốn có bạn cùng nghịch, đôi khi quên hỏi người kia có vui không. Hãy để ý lúc anh để một câu đùa thất bại mà không vội thay bằng câu khác."
	},
	"dog": {
		"en": "Dog remembers your cup and leaves your chair until last. He is steady, stubborn, and much easier to hurt than he looks. He wants someone who comes back willingly; learning not to wait at every closed door is taking longer.",
		"vi": "Tuất nhớ cốc của bạn, xếp ghế bạn sau cùng. Anh bền lòng, bướng bỉnh, dễ tổn thương hơn vẻ ngoài. Anh muốn người tự nguyện quay về; còn học cách thôi chờ trước mọi cánh cửa đóng thì lâu hơn."
	},
	"pig": {
		"en": "Pig makes room for another bowl even when the table is full. He loves a bargain, hates an empty stomach, and reaches for the bill too quickly. He can tell you what everything costs; what his company is worth without paying is another question.",
		"vi": "Bàn đầy, Hợi vẫn kê thêm được một bát. Anh thích món hời, ghét để ai đói, đưa tay trả tiền quá nhanh. Mọi thứ giá bao nhiêu anh đều biết; có anh ngồi cùng đáng giá gì khi không trả hộ lại là câu khác."
	},
	"ox": {
		"en": "Buffalo checks the load before he lifts it, then quietly takes the heavier end. His advice comes in short sentences and aches he rarely mentions. He knows rest is sensible. Believing he deserves it takes more practice.",
		"vi": "Sửu xem gánh trước khi nâng, rồi lặng lẽ nhận đầu nặng hơn. Lời khuyên ngắn gọn, những chỗ đau ít nhắc. Anh biết nghỉ là khôn ngoan. Tin mình xứng đáng được nghỉ thì còn phải tập."
	},
	"horse": {
		"en": "Horse knows every road out and keeps discovering reasons to take the long way back. He talks with his feet, thinks in corners, and mistakes hurry for purpose when he's unsettled. The rarest invitation he can offer is to stay for the view.",
		"vi": "Ngọ biết mọi đường đi, rồi cứ tìm ra cớ vòng xa để trở lại. Anh nói bằng bước chân, nghĩ bằng ngã rẽ; lúc bất an dễ nhầm vội vã với có mục đích. Lời mời hiếm nhất của anh là ở lại ngắm cảnh."
	},
	"goat": {
		"en": "Goat hears the dropped spoon as clearly as the melody. She is exacting, dryly funny, and far harsher with her own notebook than with anyone else's mistakes. She wants a listener who can hear a rest without rushing to fill it.",
		"vi": "Mùi nghe thìa rơi rõ như nghe giai điệu. Cô kỹ tính, hài hước tỉnh queo, khắt khe với sổ nhạc của mình hơn lỗi người khác. Cô muốn người nghe được dấu lặng mà không vội lấp đầy."
	},
	"rat": {
		"en": "Rat knows a useful thing by its scratches and a loan by whether it comes back. His pockets hold repairs, possibilities, and a few objects he can't quite justify keeping. He asks who pays for a shortcut because somebody always does.",
		"vi": "Tý nhận đồ hữu dụng qua vết xước, nhận khoản mượn qua việc có trả lại. Túi anh đầy đồ cần sửa, khả năng còn để ngỏ, vài món không biết giữ làm gì. Anh hỏi ai trả giá cho lối tắt vì lúc nào cũng có người phải trả."
	},
	"tiger": {
		"en": "Tiger notices a flinch before a compliment. He respects a clear challenge and a firm refusal, though his presence can make both difficult. He is beginning to suspect that a room falling silent isn't the same as a room making him welcome.",
		"vi": "Dần nhận ra cái giật mình trước lời khen. Anh trọng lời thách rõ ràng và lời từ chối vững vàng, dù chính sự hiện diện của anh khiến cả hai khó nói. Anh bắt đầu ngờ rằng căn phòng im bặt không giống căn phòng đón mình."
	},
	"snake": {
		"en": "Snake can make a request feel like the next inevitable note. She knows exactly how sweetness changes an answer, and doesn't always like how easily she uses it. Read her terms, listen to her pauses, and notice when she chooses plain words.",
		"vi": "Tỵ khiến lời nhờ nghe như nốt tiếp theo không thể tránh. Cô biết sự ngọt ngào đổi câu trả lời ra sao, không phải lúc nào cũng thích mình dùng nó dễ đến thế. Đọc điều kiện, nghe khoảng nghỉ, để ý lúc cô chọn nói thẳng."
	},
	"dragon": {
		"en": "Dragon measures you against your own history. A familiar trick earns no awe simply because you perform it loudly. The challenge is to show what the player you have become can really do.",
		"vi": "Thìn lấy chính quá khứ của bạn làm thước đo. Trò quen không đáng kinh ngạc hơn chỉ vì diễn ồn ào. Thử thách là cho thấy người chơi bạn đã trở thành thật sự làm được gì."
	}
}
