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
	{"speaker": "pig", "en": "Then keep it in your pocket. I asked for a promise, not your last coin.", "vi": "Vậy cứ giữ trong túi. Tôi xin lời hứa, đâu xin đồng cuối cùng."}
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
		{"en": "Pig reaches for the bill before remembering there isn't one. He laughs, then leaves his hand flat on the table.", "vi": "Hợi đưa tay lấy hóa đơn rồi mới nhớ chẳng có tờ nào. Anh cười, để nguyên bàn tay trên bàn."},
		{"en": "\"My mother could feed six with enough for four. I thought the trick was never admitting you were hungry. Took me years to ask for seconds.\"", "vi": "\"Mẹ tôi nấu phần bốn người mà nuôi được sáu. Tôi cứ tưởng bí quyết là không nhận mình đói. Mất bao năm tôi mới dám xin thêm.\""},
		{"en": "He places a pig Emblem by your glass. \"Bring this on our day. You can buy the tea, if you like. I'm practicing saying thank you.\"", "vi": "Anh đặt Huy hiệu con heo bên ly. \"Đến ngày của mình thì mang nhé. Bạn muốn mời trà cũng được. Tôi đang tập nói cảm ơn.\""}
	],
	"last_chance": {
		"id": "pig.last_chance.enough",
		"prompt": [{"speaker": "pig", "en": "Before we put anything else on the table: can you afford the yes you're about to give me?", "vi": "Trước khi bày thêm gì lên bàn: bạn có kham nổi tiếng đồng ý sắp nói không?"}],
		"answers": [
			{"id": "A", "en": "Only what I can give without pretending.", "vi": "Chỉ điều tôi cho được mà không giả vờ.", "recovery_success": true, "reaction": [{"speaker": "pig", "en": "Good. No garnish needed.", "vi": "Được. Khỏi thêm thắt cho đẹp."}]},
			{"id": "B", "en": "Nothing today. I need to look after myself.", "vi": "Hôm nay không có gì. Tôi cần lo cho mình.", "recovery_success": true, "reaction": [{"speaker": "pig", "en": "Then keep your money. The chair wasn't on the bill.", "vi": "Vậy giữ tiền đi. Cái ghế đâu có tính trong hóa đơn."}]},
			{"id": "C", "en": "Anything. Just make tonight cheaper for me.", "vi": "Gì cũng được. Miễn tối nay bạn nhẹ tay hơn.", "recovery_success": false, "reaction": [{"speaker": "pig", "en": "Ah. So I'm an investment. Let's close that account.", "vi": "À. Vậy tôi là khoản đầu tư. Mình đóng sổ khoản ấy nhé."}]}
		]},
	"special": []
}
const NODES := [
	{"id": "pig.t1.table", "zodiac": "pig", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "One bowl left. One more guest at the door. What's your first move?", "vi": "Còn một bát. Lại có khách ngoài cửa. Bạn làm gì trước?"}],
		"answers": [
			{"id": "A", "en": "Make room at my side, then ask what they need.", "vi": "Xích chỗ bên tôi, rồi hỏi họ cần gì.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Yes! Let them sit before we decide they're a problem.", "vi": "Đúng! Mời người ta ngồi trước khi coi họ là rắc rối."}]},
			{"id": "B", "en": "Put out a glass and see if they're staying.", "vi": "Bày thêm cốc, xem họ có ở lại không.", "delta": 0, "reaction": [{"speaker": "pig", "en": "Put it down. Thirst doesn't wait for an introduction.", "vi": "Cứ đặt cốc xuống. Khát có chờ giới thiệu đâu."}]},
			{"id": "C", "en": "Ask what they're paying before making room.", "vi": "Hỏi họ trả bao nhiêu rồi mới nhường chỗ.", "delta": -1, "reaction": [{"speaker": "pig", "en": "You've turned a supper into a toll booth.", "vi": "Bạn biến bữa cơm thành trạm thu phí rồi."}]}
		]},
	{"id": "pig.t1.enough", "zodiac": "pig", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "The jars are full. The bills are paid. Why is enough so hard to recognize?", "vi": "Hũ đầy. Hóa đơn trả hết. Sao vẫn khó nhận ra mình đã đủ nhỉ?"}],
		"answers": [
			{"id": "A", "en": "I can meet my needs and still choose what to share.", "vi": "Tôi lo được nhu cầu của mình và vẫn tự chọn chia sẻ.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Yes. Enough left to choose, not just enough left to survive.", "vi": "Ừ. Còn đủ để lựa chọn, chứ không chỉ đủ để cầm cự."}]},
			{"id": "B", "en": "I know when the next bill arrives.", "vi": "Đến hóa đơn tiếp theo tôi mới biết.", "delta": 0, "reaction": [{"speaker": "pig", "en": "I keep mine under the sugar jar. Harder to pretend it isn't there.", "vi": "Tôi kẹp hóa đơn dưới hũ đường. Khó giả vờ không thấy hơn."}]},
			{"id": "C", "en": "When everybody else has less.", "vi": "Khi mọi người khác có ít hơn.", "delta": -1, "reaction": [{"speaker": "pig", "en": "You'll go hungry beside a full pantry counting like that.", "vi": "Đếm kiểu đó thì ngồi cạnh tủ thức ăn đầy vẫn thấy đói."}]}
		]},
	{"id": "pig.t1.gift", "zodiac": "pig", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "You offer a dish. I send it back untouched. What do you do?", "vi": "Bạn mời một đĩa đồ ăn. Tôi trả lại chưa động đũa. Bạn làm gì?"}],
		"answers": [
			{"id": "A", "en": "Take it back. You don't have to be hungry.", "vi": "Nhận lại. Bạn đâu bắt buộc phải đói.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Good. Maybe I was full. It needn't be a trial.", "vi": "Tốt. Có khi tôi no rồi. Đâu cần mở phiên xử."}]},
			{"id": "B", "en": "Ask if something else would help.", "vi": "Hỏi xem thứ khác có giúp được không.", "delta": 0, "reaction": [{"speaker": "pig", "en": "Once, yes. Don't make me refuse the whole kitchen.", "vi": "Hỏi một lần thì được. Đừng bắt tôi từ chối cả căn bếp."}]},
			{"id": "C", "en": "Remind you who paid for it.", "vi": "Nhắc bạn ai đã trả tiền.", "delta": -1, "reaction": [{"speaker": "pig", "en": "Then it wasn't supper. It was credit.", "vi": "Vậy đâu phải bữa cơm. Là cho vay."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "Money from the plays themselves. I know a loan wearing a new hat.", "vi": "Tiền từ chính nước bài nhé. Khoản vay có đội mũ mới tôi vẫn nhận ra."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "A clear limit. Keep it.", "vi": "Giới hạn rõ ràng. Cứ giữ lấy."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": EARN_SMALL, "dialogue": [{"speaker": "pig", "en": "Make it 25.000 VND, with the same earning rule. Read that amount before you agree.", "vi": "Đổi thành 25.000 VND, vẫn cùng cách tính thu nhập. Đọc mức đó rồi hãy nhận nhé."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "pig", "en": "There it is. Earned at the table. Doesn't that feel different from being handed it?", "vi": "Đây rồi. Tự kiếm trên bàn bài. Khác với được đưa cho chứ nhỉ?"}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "pig", "en": "Less came in than you promised. I won't sweeten the total to make it fit.", "vi": "Thu ít hơn đã hứa. Tôi không thêm đường vào con số cho vừa đâu."}]}
		}},
	{"id": "pig.t1plus.reserve", "zodiac": "pig", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "You gave away your last bowl. Very generous. What's for your dinner?", "vi": "Bạn cho bát cuối cùng rồi. Hào phóng thật. Tối bạn ăn gì?"}],
		"answers": [
			{"id": "A", "en": "I need to keep some breathing room.", "vi": "Tôi cần giữ chút khoảng để thở.", "delta": 1, "reaction": []},
			{"id": "B", "en": "I'll see what I need later.", "vi": "Để sau xem tôi cần gì.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Whoever owes me for being generous.", "vi": "Người đang nợ tôi vì tôi hào phóng.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "pig", "en": "Keep at least 10.000 VND in your wallet until I return. Not for me. A reserve you don't have to win back.", "vi": "Giữ ít nhất 10.000 VND trong ví đến khi tôi quay lại. Không phải để cho tôi. Là khoản dự phòng bạn không phải kiếm lại."}],
		"promise": RESERVE,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "A little set aside. Leave it there even when the next bargain winks at you.", "vi": "Để riêng một ít. Cứ giữ đó dù món hời kế tiếp có hấp dẫn đến đâu."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "pig", "en": "Then don't pretend the money is free to keep.", "vi": "Vậy đừng giả vờ tiền đó giữ lại dễ dàng."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": RESERVE_SMALL, "dialogue": [{"speaker": "pig", "en": "A smaller reserve: 5.000 VND until my return. Is that one you can protect?", "vi": "Dự phòng nhỏ hơn nhé: 5.000 VND đến khi tôi quay lại. Mức đó bạn giữ được chứ?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "pig", "en": "You never dipped into it. A full pocket can be a very quiet comfort.", "vi": "Bạn không động đến khoản ấy. Túi còn tiền đôi khi là niềm yên tâm rất lặng."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "pig", "en": "The reserve ran short. Filling the bowl later doesn't mean it was never empty.", "vi": "Khoản để dành bị hụt. Đổ đầy bát sau đó không có nghĩa nó chưa từng cạn."}]}
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
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "pig", "en": "That card brought something home. More than a pretty thing in the drawer, eh?", "vi": "Lá ấy kiếm được tiền rồi. Hơn hẳn món đẹp để ngắm trong ngăn kéo nhỉ?"}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "pig", "en": "No paying play for that card. We were counting earnings, not possibilities.", "vi": "Lá ấy chưa có nước bài ra tiền. Mình tính tiền kiếm được, không tính khả năng."}]}
		}},
	{"id": "pig.t2.earn_memory", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "pig.earn", "promise_from": "pig.t1plus.earn",
		"prompts": {
			"FULFILLED": [{"speaker": "pig", "en": "You earned the amount: {target} Did you let yourself enjoy it, or start counting the next bill?", "vi": "Bạn kiếm đủ rồi: {target} Bạn có vui một chút, hay lại tính hóa đơn tiếp theo?"}],
			"BROKEN": [{"speaker": "pig", "en": "We came up short: {target} Was the number too hopeful from the start?", "vi": "Mình còn hụt: {target} Có phải ngay từ đầu con số đã quá lạc quan?"}],
			"REFUSED": [{"speaker": "pig", "en": "You wouldn't commit to this: {target} Good to know what isn't on the menu.", "vi": "Bạn không nhận việc này: {target} Biết rõ món nào không có cũng tốt."}]
		},
		"answers": [
			{"id": "A", "en": "Make a smaller plan if that's what I can earn.", "vi": "Kiếm được ít hơn thì tôi tính ít hơn.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Good. Build the shopping list after you count the coins.", "vi": "Tốt. Đếm tiền rồi hãy viết danh sách đi chợ."}]},
			{"id": "B", "en": "Remember that I don't know the next hand yet.", "vi": "Nhớ rằng tôi chưa biết tay bài kế tiếp.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Count any money that happens to arrive.", "vi": "Tính mọi khoản tiền tình cờ đến.", "delta": -1, "reaction": [{"speaker": "pig", "en": "That's another pocket. We agreed to count this one.", "vi": "Đó là túi khác. Mình đã hẹn đếm túi này."}]}
		]},
	{"id": "pig.t2.reserve_memory", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "pig.reserve", "promise_from": "pig.t1plus.reserve",
		"prompts": {
			"FULFILLED": [{"speaker": "pig", "en": "Reserve intact: {target} Did having it there make it harder to spend the rest?", "vi": "Khoản để dành còn nguyên: {target} Có nó rồi, bạn thấy khó tiêu phần còn lại hơn không?"}],
			"BROKEN": [{"speaker": "pig", "en": "You dipped below this reserve: {target} Tell me what you needed. I won't pretend it wasn't a choice.", "vi": "Bạn đã xuống dưới khoản này: {target} Kể tôi nghe cần tiền cho gì. Tôi không giả vờ đó chẳng phải lựa chọn."}],
			"REFUSED": [{"speaker": "pig", "en": "You said no to this reserve: {target} Was there something you already needed the money for?", "vi": "Bạn từ chối giữ khoản này: {target} Bạn đã có việc cần đến tiền ấy à?"}]
		},
		"answers": [
			{"id": "A", "en": "To choose without pretending it was free.", "vi": "Được chọn mà không giả vờ chẳng mất gì.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Exactly. Kindness gets sour when the cost turns up afterward.", "vi": "Đúng. Lòng tốt hóa chua khi cái giá xuất hiện sau cùng."}]},
			{"id": "B", "en": "I was deciding what mattered most.", "vi": "Tôi đang chọn điều quan trọng nhất.", "delta": 0, "reaction": []},
			{"id": "C", "en": "The promise only mattered when you were watching.", "vi": "Lời hứa chỉ quan trọng khi bạn nhìn.", "delta": -1, "reaction": [{"speaker": "pig", "en": "Then who was the reserve feeding? Me, or your performance?", "vi": "Vậy khoản ấy nuôi ai? Tôi, hay màn diễn của bạn?"}]}
		]},
	{"id": "pig.t2.card_memory", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "pig.card", "promise_from": "pig.t1plus.card",
		"prompts": {
			"FULFILLED": [{"speaker": "pig", "en": "{target} paid its way! Did you see a good worker there, or just a pretty price tag?", "vi": "{target} kiếm được tiền rồi! Bạn nhìn thấy khả năng của nó, hay chỉ nhìn cái giá đẹp?"}],
			"BROKEN": [{"speaker": "pig", "en": "No earnings from {target} in the promised play. What made you put your faith in it?", "vi": "{target} chưa kiếm được tiền qua nước bài đã hứa. Điều gì khiến bạn tin nó?"}],
			"REFUSED": [{"speaker": "pig", "en": "You passed on all three cards. Sometimes the best bargain is the one you leave on the table.", "vi": "Bạn bỏ qua cả ba lá. Có lúc món hời nhất là món mình không mua."}]
		},
		"answers": [
			{"id": "A", "en": "Seeing how the card could earn, not just hoping it would.", "vi": "Thấy đường kiếm tiền của lá ấy, không chỉ mong nó tự kiếm.", "delta": 1, "reaction": [{"speaker": "pig", "en": "It does. I have a drawer full of things I was going to make useful.", "vi": "Đúng thế. Tôi có cả ngăn kéo đầy đồ từng định đem ra dùng."}]},
			{"id": "B", "en": "I needed to see the rest of the hand.", "vi": "Tôi cần xem phần bài còn lại.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I expected the card to do the thinking.", "vi": "Tôi trông chờ lá bài nghĩ hộ.", "delta": -1, "reaction": [{"speaker": "pig", "en": "Even a good pan won't cook its own dinner.", "vi": "Chảo tốt mấy cũng không tự nấu cơm."}]}
		]},
	{"id": "pig.t2.empty_seat", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "I've left my purse at home. Don't laugh. Would you still have tea with me?", "vi": "Tôi để ví ở nhà rồi. Đừng cười. Bạn vẫn uống trà với tôi chứ?"}],
		"answers": [
			{"id": "A", "en": "Yes. I came to sit with you.", "vi": "Có. Tôi đến để ngồi cùng bạn.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Good. I nearly went home to fetch it before you arrived.", "vi": "May quá. Suýt nữa tôi về lấy trước khi bạn tới."}]},
			{"id": "B", "en": "We can order less.", "vi": "Mình gọi ít hơn cũng được.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Then what would you bring to the table?", "vi": "Vậy bạn mang được gì đến bàn?", "delta": -1, "reaction": [{"speaker": "pig", "en": "I was hoping myself would cover it.", "vi": "Tôi cứ mong chỉ có tôi cũng đã đủ."}]}
		]},
	{"id": "pig.t2.generous", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "I said no to someone today. They looked surprised. Have I taught everyone to expect too much?", "vi": "Hôm nay tôi từ chối một người. Họ ngạc nhiên lắm. Có phải tôi tập cho ai cũng trông chờ quá nhiều không?"}],
		"answers": [
			{"id": "A", "en": "Yes. A limit doesn't take the gift back.", "vi": "Có. Giới hạn không lấy lại món quà.", "delta": 1, "reaction": [{"speaker": "pig", "en": "I'll try to remember that before I open my purse again.", "vi": "Tôi sẽ cố nhớ câu ấy trước khi lại mở ví."}]},
			{"id": "B", "en": "People may need time to understand.", "vi": "Có người cần thời gian để hiểu.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Not if you want them to keep liking you.", "vi": "Không, nếu muốn họ tiếp tục thích bạn.", "delta": -1, "reaction": [{"speaker": "pig", "en": "I've bought enough affection at that price. It never lasts the evening.", "vi": "Tôi mua đủ quý mến với giá ấy rồi. Chẳng lần nào bền hết buổi tối."}]}
		]},
	{"id": "pig.t2.guest", "zodiac": "pig", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "pig", "en": "You offered to pay. I nearly argued. Is it always this awkward being the guest?", "vi": "Bạn mời trả tiền. Tôi suýt cãi lại. Làm khách lúc nào cũng ngượng thế à?"}],
		"answers": [
			{"id": "A", "en": "Sometimes. I can accept without making it a debt.", "vi": "Đôi khi. Tôi có thể nhận mà không biến thành món nợ.", "delta": 1, "reaction": [{"speaker": "pig", "en": "Thank you, then. Just thank you. Look at me learning.", "vi": "Vậy cảm ơn nhé. Chỉ cảm ơn thôi. Thấy tôi đang học không."}]},
			{"id": "B", "en": "I'd like to bring something next time.", "vi": "Lần tới tôi muốn mang gì đó.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I'll accept if I can use it against them later.", "vi": "Tôi nhận nếu sau này dùng nó để ép họ được.", "delta": -1, "reaction": [{"speaker": "pig", "en": "Leave it, then. I'd rather eat alone than owe you that.", "vi": "Vậy để đó đi. Tôi thà ăn một mình còn hơn mắc món nợ ấy."}]}
		]}
]
