extends RefCounted
## Pig likes a full table and an honest limit. Wealth is room to share.
const EARN := {
	"id": "pig.earn", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "scoring_income", "deal_phase": 0, "resource_amount": 50000,
	"en": "Earn at least 50.000 VND in total from positive payouts of successful Melds or Extensions during the next Deal. Gifts, loans, and other wallet credits do not count.",
	"vi": "Kiếm tổng cộng ít nhất 50.000 VND từ tiền trả dương của Phỏm hoặc Nối thành công trong Ván kế tiếp. Quà, khoản vay và tiền vào ví từ nguồn khác không được tính."
}
const EARN_SMALL := {
	"id": "pig.earn", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "scoring_income", "deal_phase": 0, "resource_amount": 25000,
	"en": "Earn at least 25.000 VND in total from positive payouts of successful Melds or Extensions during the next Deal. Gifts, loans, and other wallet credits do not count.",
	"vi": "Kiếm tổng cộng ít nhất 25.000 VND từ tiền trả dương của Phỏm hoặc Nối thành công trong Ván kế tiếp. Quà, khoản vay và tiền vào ví từ nguồn khác không được tính."
}
const RESERVE := {
	"id": "pig.reserve", "polarity": "DONT", "interaction": "wallet_floor", "target_kind": "ACTION",
	"window": "ZODIAC_RETURN", "resource_amount": 10000,
	"en": "Keep your wallet at or above 10.000 VND from acceptance until Pig's Afternoon return. Falling below it and earning the money back still breaks this promise.",
	"vi": "Giữ ví từ 10.000 VND trở lên từ lúc nhận lời đến khi Hợi trở lại buổi Chiều. Tụt dưới mức đó rồi kiếm lại vẫn là thất hứa."
}
const RESERVE_SMALL := {
	"id": "pig.reserve", "polarity": "DONT", "interaction": "wallet_floor", "target_kind": "ACTION",
	"window": "ZODIAC_RETURN", "resource_amount": 5000,
	"en": "Keep your wallet at or above 5.000 VND from acceptance until Pig's Afternoon return. Falling below it and earning the money back still breaks this promise.",
	"vi": "Giữ ví từ 5.000 VND trở lên từ lúc nhận lời đến khi Hợi trở lại buổi Chiều. Tụt dưới mức đó rồi kiếm lại vẫn là thất hứa."
}
const CARD := {
	"id": "pig.card", "polarity": "DO", "interaction": "card_play", "target_kind": "CARD",
	"targeting": "ANY", "window": "NEXT_DEAL", "require_income": true,
	"en": "Choose a card and play it in a new Meld or Extension that actually earns positive VND during the next Deal. Discards, swaps, and zero-payout plays do not count.",
	"vi": "Chọn một lá rồi hạ vào Phỏm mới hoặc dùng để Nối có tiền trả dương thực tế trong Ván kế tiếp. Bỏ, đổi hoặc nước chơi không trả tiền không được tính."
}
const COUNTER_REFUSE := {"delta": 0, "dialogue": [
	{"speaker": "player", "en": "I can't promise the smaller amount either.", "vi": "Mức nhỏ hơn tôi cũng không hứa được."},
	{"speaker": "pig", "en": "Then leave it open. A promise shouldn't empty your pockets.", "vi": "Vậy để ngỏ nhé. Lời hứa không nên vét sạch túi bạn."}
]}
const CONFIG := {
	"visit_limits": {"1": 3, "1+": 1, "2": 1},
	"progression": [{"from": 2, "to": 3, "kept": 3, "distinct": 2, "promises": ["pig.earn", "pig.reserve", "pig.card"]}],
	"memory_button": {"en": "Pig's accounts", "vi": "Sổ của Hợi"},
	"memory_title": {"en": "What Pig remembers", "vi": "Điều Hợi nhớ"},
	"memory_topics": {
		"pig.earn": {"en": "Earn your share", "vi": "Kiếm phần mình"},
		"pig.reserve": {"en": "Breathing room", "vi": "Khoảng để thở"},
		"pig.card": {"en": "Put it to work", "vi": "Cho nó việc làm"}
	},
	"emblem_unlock": {"relationship_tier": 3, "promises_kept": 3, "promise_kinds": 2, "promises_refused": 1, "pleased_victories": 1},
	"private_scene": [
		{"en": "Pig makes room between the glasses. There is no bill on the table, only a chair he leaves for you to take.", "vi": "Hợi dọn chỗ giữa những chiếc ly. Trên bàn không có hóa đơn, chỉ có chiếc ghế anh để bạn tự ngồi xuống."},
		{"en": "\"I like a full table better than an empty promise. And I like knowing when you've had enough.\"", "vi": "\"Tôi thích bàn đông người hơn lời hứa rỗng. Và thích biết lúc nào bạn thấy đủ.\""},
		{"en": "He sets a small pig Emblem beside your glass. \"Bring it when our day comes. We'll leave room for one more.\"", "vi": "Anh đặt Huy hiệu con heo nhỏ cạnh ly của bạn. \"Đến ngày của mình thì mang theo. Ta sẽ chừa thêm một chỗ.\""}
	],
	"last_chance": {
		"id": "pig.last_chance.enough",
		"prompt": [{"speaker": "pig", "en": "Tell me plainly. What can you afford to give today?", "vi": "Nói thật nhé. Hôm nay bạn cho được đến đâu?"}],
		"answers": [
			{"id": "A", "en": "Only what I can give without pretending.", "vi": "Chỉ điều tôi cho được mà không giả vờ.", "recovery_success": true, "reaction": [{"speaker": "pig", "en": "That's a share I can accept.", "vi": "Phần đó thì tôi nhận được."}]},
			{"id": "B", "en": "Nothing today. I need to look after myself.", "vi": "Hôm nay không có gì. Tôi cần lo cho mình.", "recovery_success": true, "reaction": [{"speaker": "pig", "en": "Then keep your place. You don't owe me a gift.", "vi": "Vậy cứ giữ chỗ nhé. Bạn không nợ tôi món quà nào."}]},
			{"id": "C", "en": "Anything. Just make tonight cheaper for me.", "vi": "Gì cũng được. Miễn tối nay bạn nhẹ tay hơn.", "recovery_success": false, "reaction": [{"speaker": "pig", "en": "Then we should stop bargaining with words.", "vi": "Vậy mình nên thôi mặc cả bằng lời nói."}]}
		]},
	"special": []
}
const NODES := [
	{"id": "pig.t1.table", "zodiac": "pig", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "One more person comes to a full table. What do you move?", "vi": "Bàn đã đông mà có thêm người đến. Bạn dời gì?"}],
		"answers": [
			{"id": "A", "en": "My chair. Ask what they need.", "vi": "Ghế của tôi. Hỏi họ cần gì.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Good. Room before a speech.", "vi": "Tốt. Chừa chỗ trước rồi hãy nói."}]},
			{"id": "B", "en": "A glass, if they'll be staying.", "vi": "Một chiếc ly, nếu họ ở lại.", "delta": 0, "reaction": [{"speaker": "pig", "en": "Let them answer that.", "vi": "Để họ trả lời điều đó nhé."}]},
			{"id": "C", "en": "Nothing, unless they pay.", "vi": "Không dời gì, trừ khi họ trả tiền.", "delta": -1, "reaction": [{"speaker": "pig", "en": "A crowded table can still be lonely.", "vi": "Bàn đông người vẫn có thể cô đơn."}]}
		]},
	{"id": "pig.t1.enough", "zodiac": "pig", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "How do you know you have enough?", "vi": "Làm sao bạn biết mình đã có đủ?"}],
		"answers": [
			{"id": "A", "en": "I can meet my needs and still choose what to share.", "vi": "Tôi lo được nhu cầu của mình và vẫn tự chọn chia sẻ.", "delta": 1, "reaction": [{"speaker": "pig", "en": "A little room to breathe. I understand that.", "vi": "Có chút khoảng để thở. Tôi hiểu."}]},
			{"id": "B", "en": "I know when the next bill arrives.", "vi": "Đến hóa đơn tiếp theo tôi mới biết.", "delta": 0, "reaction": [{"speaker": "pig", "en": "Keep that one in view, then.", "vi": "Vậy đừng quên nhìn hóa đơn đó."}]},
			{"id": "C", "en": "When everybody else has less.", "vi": "Khi mọi người khác có ít hơn.", "delta": -1, "reaction": [{"speaker": "pig", "en": "That measure never fills you up.", "vi": "Đo như thế thì chẳng bao giờ thấy đủ."}]}
		]},
	{"id": "pig.t1.gift", "zodiac": "pig", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "Someone refuses your gift. What now?", "vi": "Có người từ chối quà của bạn. Giờ sao?"}],
		"answers": [
			{"id": "A", "en": "Keep it. Their no belongs to them.", "vi": "Giữ lại. Họ có quyền nói không.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Then it was a gift, not a hook.", "vi": "Vậy mới là quà, không phải cái móc."}]},
			{"id": "B", "en": "Ask if something else would help.", "vi": "Hỏi xem thứ khác có giúp được không.", "delta": 0, "reaction": [{"speaker": "pig", "en": "Ask once. Listen after.", "vi": "Hỏi một lần thôi. Sau đó lắng nghe."}]},
			{"id": "C", "en": "Remind them what they owe me.", "vi": "Nhắc họ đang nợ tôi những gì.", "delta": -1, "reaction": [{"speaker": "pig", "en": "Then you were offering a bill.", "vi": "Vậy bạn đang đưa hóa đơn rồi."}]}
		]},
	{"id": "pig.t1plus.earn", "zodiac": "pig", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "What makes money yours to count on?", "vi": "Điều gì khiến bạn trông cậy được vào tiền mình có?"}],
		"answers": [
			{"id": "A", "en": "Knowing where I earned it.", "vi": "Biết mình đã kiếm nó từ đâu.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Seeing it in my wallet.", "vi": "Thấy nó trong ví.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Convincing someone to cover the difference.", "vi": "Thuyết phục ai đó bù phần thiếu.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "pig", "en": "Next Deal, earn 50.000 VND from your Melds and Extensions. No loan dressed up as earnings. Can you promise that?", "vi": "Ván tới kiếm 50.000 VND bằng Phỏm và Nối nhé. Không tính khoản vay giả làm thu nhập. Bạn hứa được không?"}],
		"promise": EARN,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "I'll count what the plays actually pay.", "vi": "Tôi sẽ tính tiền nước chơi thực sự trả."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "A clear limit. Keep it.", "vi": "Giới hạn rõ ràng. Cứ giữ lấy."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": EARN_SMALL, "dialogue": [{"speaker": "pig", "en": "Make it 25.000 VND, with the same earning rule. Read that amount before you agree.", "vi": "Đổi thành 25.000 VND, vẫn cùng cách tính thu nhập. Đọc mức đó rồi hãy nhận nhé."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "pig", "en": "You earned the amount we agreed. That leaves something solid to plan around.", "vi": "Bạn đã kiếm đủ mức mình thống nhất. Vậy có điều chắc chắn để tính việc tiếp."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "pig", "en": "The plays didn't earn the promised amount. Next time, give me a limit you mean.", "vi": "Nước chơi chưa kiếm đủ mức đã hứa. Lần tới hãy nói giới hạn bạn thực sự giữ được."}]}
		}},
	{"id": "pig.t1plus.reserve", "zodiac": "pig", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "If you give everything away, who looks after you?", "vi": "Nếu cho đi hết, ai lo cho bạn?"}],
		"answers": [
			{"id": "A", "en": "I need to keep some breathing room.", "vi": "Tôi cần giữ chút khoảng để thở.", "delta": 1, "reaction": []},
			{"id": "B", "en": "I'll see what I need later.", "vi": "Để sau xem tôi cần gì.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Whoever owes me for being generous.", "vi": "Người đang nợ tôi vì tôi hào phóng.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "pig", "en": "Keep at least 10.000 VND in your wallet until I return. Not for me. A reserve you don't have to win back.", "vi": "Giữ ít nhất 10.000 VND trong ví đến khi tôi quay lại. Không phải để cho tôi. Là khoản dự phòng bạn không phải kiếm lại."}],
		"promise": RESERVE,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "Keep that room all the way through.", "vi": "Giữ khoảng đó suốt đến lúc gặp lại nhé."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "Then don't pretend the money is free to keep.", "vi": "Vậy đừng giả vờ tiền đó giữ lại dễ dàng."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": RESERVE_SMALL, "dialogue": [{"speaker": "pig", "en": "A smaller reserve: 5.000 VND until my return. Is that one you can protect?", "vi": "Dự phòng nhỏ hơn nhé: 5.000 VND đến khi tôi quay lại. Mức đó bạn giữ được chứ?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "pig", "en": "You kept the reserve the whole time. That's room you made for yourself.", "vi": "Bạn đã giữ khoản dự phòng suốt thời gian đó. Là khoảng bạn tự dành cho mình."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "pig", "en": "Your wallet fell below the reserve. Money coming back doesn't erase that moment.", "vi": "Ví bạn đã tụt dưới khoản dự phòng. Tiền trở lại không xóa được lúc đó."}]}
		}},
	{"id": "pig.t1plus.card", "zodiac": "pig", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "Which matters more: owning a card, or finding it a job?", "vi": "Điều nào hơn: có một lá bài, hay tìm được việc cho nó?"}],
		"answers": [
			{"id": "A", "en": "Finding a use I can actually follow through on.", "vi": "Tìm cách dùng mà tôi thực sự làm được.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Sometimes keeping it is useful too.", "vi": "Đôi khi giữ lại cũng có ích.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Owning it. Somebody else can do the work.", "vi": "Có nó. Việc cứ để người khác làm.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "pig", "en": "Choose one of these three. Next Deal, put it into a Meld or Extension that actually pays. Want to take that on?", "vi": "Chọn một trong ba lá này. Ván tới dùng nó trong Phỏm hoặc Nối thực sự trả tiền. Bạn nhận việc đó chứ?"}],
		"promise": CARD, "initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "Your pick. I'll look for the actual payout.", "vi": "Bạn chọn nhé. Tôi sẽ xem tiền trả thực tế."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "Then keep the choice open. No fee for a no.", "vi": "Vậy cứ để ngỏ lựa chọn. Nói không chẳng mất phí."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "pig", "en": "Your chosen card earned its place. You gave it work, not just a price.", "vi": "Lá bạn chọn đã có chỗ làm. Bạn cho nó việc, không chỉ cho nó giá."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "pig", "en": "That card didn't enter a paying play. The promise needed the actual money.", "vi": "Lá đó chưa vào nước chơi trả tiền. Lời hứa cần tiền thực tế."}]}
		}},
	{"id": "pig.t2.earn_memory", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "pig.earn", "promise_from": "pig.t1plus.earn",
		"prompts": {
			"FULFILLED": [{"speaker": "pig", "en": "You earned what we agreed: {target} What did that give you room to do?", "vi": "Bạn đã kiếm đúng mức mình thống nhất: {target} Khoản đó giúp bạn có chỗ làm gì?"}],
			"BROKEN": [{"speaker": "pig", "en": "We didn't reach this amount: {target} What would you change about the promise?", "vi": "Mình chưa đạt mức này: {target} Bạn sẽ đổi điều gì ở lời hứa?"}],
			"REFUSED": [{"speaker": "pig", "en": "You didn't commit to this: {target} I'm glad you left the number honest.", "vi": "Bạn không nhận cam kết này: {target} Tôi mừng vì bạn không nói quá con số."}]
		},
		"answers": [
			{"id": "A", "en": "Plan from what I can actually earn.", "vi": "Tính từ điều tôi thực sự kiếm được.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Then the plan has something under it.", "vi": "Vậy kế hoạch mới có nền để đứng."}]},
			{"id": "B", "en": "Leave more room for an uncertain hand.", "vi": "Chừa thêm khoảng cho bài chưa biết.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Count any money that happens to arrive.", "vi": "Tính mọi khoản tiền tình cờ đến.", "delta": -1, "reaction": [{"speaker": "pig", "en": "That isn't the agreement I remember.", "vi": "Tôi nhớ mình không thống nhất như vậy."}]}
		]},
	{"id": "pig.t2.reserve_memory", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "pig.reserve", "promise_from": "pig.t1plus.reserve",
		"prompts": {
			"FULFILLED": [{"speaker": "pig", "en": "You protected this reserve: {target} Did it feel like room or a restriction?", "vi": "Bạn đã giữ khoản dự phòng này: {target} Bạn thấy nhẹ hơn hay bị hạn chế?"}],
			"BROKEN": [{"speaker": "pig", "en": "Your wallet went below this: {target} What needed the money?", "vi": "Ví bạn đã tụt dưới mức này: {target} Việc gì cần khoản tiền đó?"}],
			"REFUSED": [{"speaker": "pig", "en": "You wouldn't promise this reserve: {target} What did you need to leave open?", "vi": "Bạn không hứa khoản dự phòng này: {target} Bạn cần để ngỏ điều gì?"}]
		},
		"answers": [
			{"id": "A", "en": "A choice I could make without hiding the cost.", "vi": "Lựa chọn mà tôi không phải giấu cái giá.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Good. Say the cost before you give the word.", "vi": "Tốt. Nói cái giá trước rồi hãy hứa."}]},
			{"id": "B", "en": "I was deciding what mattered most.", "vi": "Tôi đang chọn điều quan trọng nhất.", "delta": 0, "reaction": []},
			{"id": "C", "en": "The promise only mattered when you were watching.", "vi": "Lời hứa chỉ quan trọng khi bạn nhìn.", "delta": -1, "reaction": [{"speaker": "pig", "en": "Then it wasn't a reserve for you.", "vi": "Vậy đó chẳng phải dự phòng cho bạn."}]}
		]},
	{"id": "pig.t2.card_memory", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "pig.card", "promise_from": "pig.t1plus.card",
		"prompts": {
			"FULFILLED": [{"speaker": "pig", "en": "{target} went into a play that paid. Did you see that use before you picked it?", "vi": "{target} đã vào nước chơi trả tiền. Bạn thấy cách dùng đó trước khi chọn chứ?"}],
			"BROKEN": [{"speaker": "pig", "en": "{target} never earned through the promised play. What did you see in that choice?", "vi": "{target} chưa kiếm tiền bằng nước đã hứa. Bạn nhìn thấy gì ở lựa chọn đó?"}],
			"REFUSED": [{"speaker": "pig", "en": "You left the three-card offer open. What would make the choice worth a promise?", "vi": "Bạn để ngỏ đề nghị ba lá. Điều gì khiến lựa chọn đáng để hứa?"}]
		},
		"answers": [
			{"id": "A", "en": "A real route to a payout, not just a hopeful price.", "vi": "Cách thực sự kiếm tiền, không chỉ cái giá tôi mong.", "delta": 1, "reaction": [{"speaker": "pig", "en": "That difference matters to me.", "vi": "Khác biệt đó quan trọng với tôi."}]},
			{"id": "B", "en": "I needed to see the rest of the hand.", "vi": "Tôi cần xem phần bài còn lại.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I expected the card to do the thinking.", "vi": "Tôi trông chờ lá bài nghĩ hộ.", "delta": -1, "reaction": [{"speaker": "pig", "en": "It still needed your hands.", "vi": "Nó vẫn cần đôi tay bạn."}]}
		]},
	{"id": "pig.t2.empty_seat", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "If I couldn't buy the next round, would you still take this chair?", "vi": "Nếu tôi không mời được lượt nước tiếp, bạn vẫn ngồi ghế này chứ?"}],
		"answers": [
			{"id": "A", "en": "Yes. I came to sit with you.", "vi": "Có. Tôi đến để ngồi cùng bạn.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Then I'll leave the glass where it is.", "vi": "Vậy tôi để ly ở đây nhé."}]},
			{"id": "B", "en": "We can order less.", "vi": "Mình gọi ít hơn cũng được.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Then what would you bring to the table?", "vi": "Vậy bạn mang được gì đến bàn?", "delta": -1, "reaction": [{"speaker": "pig", "en": "Myself. I'd hoped that counted.", "vi": "Chính tôi. Tôi đã mong điều đó cũng được tính."}]}
		]},
	{"id": "pig.t2.generous", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "Can I be generous and still say I've had enough?", "vi": "Tôi có thể hào phóng mà vẫn nói mình đã đủ không?"}],
		"answers": [
			{"id": "A", "en": "Yes. A limit doesn't take the gift back.", "vi": "Có. Giới hạn không lấy lại món quà.", "delta": 1, "reaction": [{"speaker": "pig", "en": "That's a word I'd like to keep.", "vi": "Điều đó thì tôi muốn giữ."}]},
			{"id": "B", "en": "People may need time to understand.", "vi": "Có người cần thời gian để hiểu.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Not if you want them to keep liking you.", "vi": "Không, nếu muốn họ tiếp tục thích bạn.", "delta": -1, "reaction": [{"speaker": "pig", "en": "That's a very expensive chair.", "vi": "Chiếc ghế đó đắt quá."}]}
		]},
	{"id": "pig.t2.guest", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "When you're the guest, is it hard to let somebody give?", "vi": "Khi làm khách, bạn có khó để người khác cho mình không?"}],
		"answers": [
			{"id": "A", "en": "Sometimes. I can accept without making it a debt.", "vi": "Đôi khi. Tôi có thể nhận mà không biến thành món nợ.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Then sit. We don't need to settle every kindness.", "vi": "Vậy ngồi nhé. Mình không cần thanh toán từng điều tử tế."}]},
			{"id": "B", "en": "I'd like to bring something next time.", "vi": "Lần tới tôi muốn mang gì đó.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I'll accept if I can use it against them later.", "vi": "Tôi nhận nếu sau này dùng nó để ép họ được.", "delta": -1, "reaction": [{"speaker": "pig", "en": "Then leave the gift here.", "vi": "Vậy để quà lại đây thôi."}]}
		]}
]
