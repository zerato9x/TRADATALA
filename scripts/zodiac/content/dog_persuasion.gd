extends RefCounted
## Loyalty includes a freely given no. Dog trusts continuity, not obedience.
const BUILD := {
	"id": "dog.build", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "extend_first_meld", "deal_phase": 1,
	"en": "Create your first new Meld in Phase 1 of the next Deal and extend that same Meld at least once before Phase 1 ends.",
	"vi": "Tạo Phỏm mới đầu tiên trong Hiệp 1 của Ván kế tiếp và Nối chính Phỏm đó ít nhất một lần trước khi Hiệp 1 kết thúc."
}
const BUILD_ALTERNATE := {
	"id": "dog.build", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "do_action", "action": "extension", "deal_phase": 0,
	"en": "Complete at least one Extension to any Meld during either Phase of the next Deal.",
	"vi": "Nối ít nhất một lần vào Phỏm bất kỳ trong một trong hai Hiệp của Ván kế tiếp."
}
const CARD := {
	"id": "dog.card", "polarity": "DONT", "interaction": "card_alter", "target_kind": "CARD",
	"targeting": "ANY", "window": "ZODIAC_RETURN",
	"en": "Do not Reset, Reduce, transform, remove, or otherwise permanently alter your selected card before Dog returns. Playing or discarding it is allowed.",
	"vi": "Không Hoàn nguyên, Giảm, biến đổi, loại bỏ hoặc thay đổi vĩnh viễn lá đã chọn trước khi Tuất trở lại. Vẫn được hạ hoặc bỏ lá đó."
}
const RELIC := {
	"id": "dog.relic", "polarity": "DONT", "interaction": "relic_loss", "target_kind": "RELIC",
	"window": "ZODIAC_RETURN",
	"en": "Do not sell, give away, or lose the selected Relic before Dog returns.",
	"vi": "Không bán, cho đi hoặc làm mất Di vật đã chọn trước khi Tuất trở lại."
}
const COUNTER_REFUSE := {"delta": 0, "dialogue": [
	{"speaker": "player", "en": "I can't promise the alternative either.", "vi": "Phương án khác tôi cũng không hứa được."},
	{"speaker": "dog", "en": "All right. I'll stop setting a place for a promise you haven't made.", "vi": "Được. Tôi thôi chừa chỗ cho một lời hứa bạn chưa nhận."}
]}
const CONFIG := {
	"visit_limits": {"1": 3, "1+": 1, "2": 1},
	"progression": [{"from": 2, "to": 3, "kept": 3, "distinct": 2,
		"promises": ["dog.build", "dog.card", "dog.relic"]}],
	"memory_button": {"en": "Dog's trust", "vi": "Niềm tin của Tuất"},
	"memory_title": {"en": "What Dog remembers", "vi": "Điều Tuất nhớ"},
	"memory_topics": {
		"dog.build": {"en": "Build on it", "vi": "Tiếp nối"},
		"dog.card": {"en": "Keep it as it is", "vi": "Giữ như cũ"},
		"dog.relic": {"en": "Keep it with you", "vi": "Giữ bên mình"}
	},
	"emblem_unlock": {"relationship_tier": 3, "promises_kept": 3, "promise_kinds": 2, "promises_refused": 1, "pleased_victories": 1},
	"private_scene": [
		{"en": "Dog has stacked every chair but yours. When you notice, he puts his own back down too.", "vi": "Tuất xếp hết ghế, chỉ chừa ghế bạn. Thấy bạn nhìn, anh lại hạ ghế mình xuống."},
		{"en": "\"I used to wait outside after closing. Thought leaving first meant I cared less. Ridiculous, looking back. Didn't feel ridiculous then.\"", "vi": "\"Trước kia đóng cửa rồi tôi vẫn đứng chờ ngoài. Tưởng về trước là mình quý người ta ít hơn. Giờ nghĩ thấy ngớ ngẩn. Lúc đó thì không.\""},
		{"en": "He sets a dog Emblem by your cup. \"Bring it on our day. Or tell me you can't come. I can keep a place without keeping you.\"", "vi": "Anh đặt Huy hiệu con chó cạnh cốc. \"Đến ngày của mình thì mang nhé. Hoặc báo là không đến được. Tôi giữ chỗ được, đâu cần giữ chân bạn.\""}
	],
	"last_chance": {
		"id": "dog.last_chance.honest",
		"prompt": [{"speaker": "dog", "en": "Before you answer again... do you actually want to be here?", "vi": "Trước khi trả lời thêm... bạn có thật sự muốn ở đây không?"}],
		"answers": [
			{"id": "A", "en": "Yes. I can disagree and still stay.", "vi": "Có. Tôi có thể không đồng ý mà vẫn ở lại.", "recovery_success": true,
				"reaction": [{"speaker": "dog", "en": "Good. Move your cup over. We're not finished talking.", "vi": "Được. Xích cốc qua đi. Mình chưa hết chuyện đâu."}]},
			{"id": "B", "en": "I need space today. That isn't a betrayal.", "vi": "Hôm nay tôi cần khoảng riêng. Đó không phải phản bội.", "recovery_success": true,
				"reaction": [{"speaker": "dog", "en": "No. It isn't. I might miss you. That's mine to deal with.", "vi": "Không. Không phải phản bội. Có thể tôi sẽ nhớ bạn. Đó là phần tôi tự lo."}]},
			{"id": "C", "en": "I'll say anything if it makes you easier tonight.", "vi": "Tôi nói gì cũng được, miễn tối nay bạn dễ hơn.", "recovery_success": false,
				"reaction": [{"speaker": "dog", "en": "I wanted your company. You wanted an easier opponent. Let's stop here.", "vi": "Tôi muốn có bạn ngồi cùng. Bạn muốn đối thủ dễ hơn. Mình dừng nhé."}]}
		]},
	"special": []
}
const NODES := [
	{"id": "dog.t1.wait", "zodiac": "dog", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "Say you're not coming back tomorrow. When would I hear about it?", "vi": "Giả sử mai bạn không quay lại. Bao giờ tôi được biết?"}],
		"answers": [
			{"id": "A", "en": "As soon as I knew. You shouldn't have to wait.", "vi": "Nói ngay khi biết. Bạn không nên phải chờ.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Thank you. I can put the spare cup away.", "vi": "Cảm ơn. Tôi còn biết mà cất cái cốc thừa."}]},
			{"id": "B", "en": "I'd explain when I next saw you.", "vi": "Lần gặp sau tôi sẽ giải thích.", "delta": 0, "reaction": [{"speaker": "dog", "en": "I'd listen. Might have some cold tea by then.", "vi": "Tôi sẽ nghe. Lúc ấy trà chắc nguội rồi."}]},
			{"id": "C", "en": "Nothing. You'd work it out.", "vi": "Không nói gì. Bạn tự hiểu thôi.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Eventually. I'd rather hear it from you than from an empty chair.", "vi": "Rồi cũng biết. Nhưng tôi muốn nghe bạn nói, hơn là nhìn ghế trống mà đoán."}]}
		]},
	{"id": "dog.t1.loyal", "zodiac": "dog", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "If I ask you to back me up when I'm wrong, is saying yes loyalty?", "vi": "Nếu tôi sai mà nhờ bạn bênh, đồng ý có phải trung thành không?"}],
		"answers": [
			{"id": "A", "en": "It means giving you an answer I can stand by.", "vi": "Nghĩa là cho bạn câu trả lời tôi giữ được.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Good. I'd rather be corrected by you than cheered into a mistake.", "vi": "Tốt. Tôi thà để bạn sửa còn hơn được cổ vũ làm sai."}]},
			{"id": "B", "en": "Sometimes it means helping.", "vi": "Đôi khi nghĩa là giúp đỡ.", "delta": 0, "reaction": [{"speaker": "dog", "en": "It does. Help me see the mistake, too.", "vi": "Đúng. Nhớ giúp tôi nhìn ra lỗi nữa."}]},
			{"id": "C", "en": "It means doing whatever you ask.", "vi": "Nghĩa là làm mọi điều bạn yêu cầu.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Then I'd have two voices and nobody watching my back.", "vi": "Thế tôi có hai giọng nói, mà chẳng ai nhắc lúc tôi sơ suất."}]}
		]},
	{"id": "dog.t1.help", "zodiac": "dog", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "I'm wrestling with a stuck shutter. You could lift it easily. What do you do?", "vi": "Tôi đang vật lộn với cửa cuốn bị kẹt. Bạn nâng dễ thôi. Bạn làm gì?"}],
		"answers": [
			{"id": "A", "en": "Ask what help you want.", "vi": "Hỏi bạn muốn được giúp thế nào.", "delta": 1, "reaction": [{"speaker": "dog", "en": "The left side. If I ask. Let me have one more try first.", "vi": "Bên trái nhé. Nếu tôi nhờ. Để tôi thử thêm lần nữa đã."}]},
			{"id": "B", "en": "Stay close in case you ask.", "vi": "Ở gần, phòng khi bạn cần.", "delta": 0, "reaction": [{"speaker": "dog", "en": "I will. Probably sooner than I'd like.", "vi": "Tôi sẽ nhờ. Chắc sớm hơn tôi muốn thừa nhận."}]},
			{"id": "C", "en": "Take over. You'll thank me later.", "vi": "Làm thay hết. Rồi bạn sẽ cảm ơn.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Maybe. I'd still have liked a say before you took it from my hands.", "vi": "Có thể. Tôi vẫn muốn được hỏi trước khi bạn giành khỏi tay."}]}
		]},
	{"id": "dog.t1plus.build", "zodiac": "dog", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "Once you start something, what keeps you with it?", "vi": "Khi đã bắt đầu một việc, điều gì khiến bạn tiếp tục?"}],
		"answers": [
			{"id": "A", "en": "Seeing what I can build on.", "vi": "Nhìn xem mình có thể làm tiếp điều gì.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Whether the next step is possible.", "vi": "Xem bước tiếp theo có làm được không.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Keeping up appearances.", "vi": "Giữ vẻ ngoài cho người ta thấy.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "dog", "en": "Next Deal, build on the first Meld you create in Phase 1. Extend that same Meld before the Phase ends. Can you commit?", "vi": "Ván tới, tiếp nối Phỏm đầu bạn tạo trong Hiệp 1 nhé. Nối chính Phỏm đó trước khi Hiệp kết thúc. Bạn hứa được không?"}],
		"promise": BUILD,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "The first Meld, then its Extension. I'll be looking for the follow-through.", "vi": "Phỏm đầu tiên, rồi nối chính Phỏm đó. Tôi chờ xem bạn làm tiếp."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "Then no obligation. Thank you for being clear.", "vi": "Vậy không có nghĩa vụ gì. Cảm ơn bạn đã nói rõ."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": BUILD_ALTERNATE, "dialogue": [{"speaker": "dog", "en": "Any one Extension instead, in either Phase. Read that as a new promise before you answer.", "vi": "Thay bằng một lần Nối bất kỳ, Hiệp nào cũng được. Đọc như lời hứa mới rồi hãy trả lời nhé."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "dog", "en": "You came back to what you started. Yes. That means something to me.", "vi": "Bạn quay lại với việc mình bắt đầu. Ừ. Điều ấy có ý nghĩa với tôi."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "dog", "en": "I believed you would do it. I'm disappointed. I don't need you to pretend otherwise.", "vi": "Tôi đã tin bạn sẽ làm. Tôi buồn đấy. Không cần giả vờ là không có gì."}]}
		}},
	{"id": "dog.t1plus.card", "zodiac": "dog", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "Can something stay itself and still be useful?", "vi": "Một thứ giữ nguyên như cũ thì vẫn có ích được chứ?"}],
		"answers": [
			{"id": "A", "en": "Yes. I can find a place for it as it is.", "vi": "Có. Tôi có thể tìm chỗ cho nó như hiện tại.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Sometimes.", "vi": "Đôi khi.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Only until something better comes along.", "vi": "Chỉ đến khi có thứ tốt hơn.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "dog", "en": "Choose one of these three cards. Keep its permanent state unchanged until I return. You can still play it.", "vi": "Chọn một trong ba lá này. Giữ trạng thái vĩnh viễn của nó đến khi tôi trở lại. Bạn vẫn được dùng nó."}],
		"promise": CARD, "initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "That card. Let it play; just don't remake it before I return.", "vi": "Lá đó nhé. Cứ đem chơi; chỉ đừng biến đổi nó trước khi tôi về."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "Then keep the freedom to change it.", "vi": "Vậy cứ giữ quyền thay đổi nó."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "dog", "en": "Same card. Same shape. Good to see it again.", "vi": "Vẫn lá ấy. Vẫn như cũ. Gặp lại thật tốt."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "dog", "en": "You changed it. I wish you'd said no when I asked.", "vi": "Bạn đã đổi nó. Giá mà lúc tôi hỏi, bạn từ chối."}]}
		}},
	{"id": "dog.t1plus.relic", "zodiac": "dog", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "What makes you keep something close?", "vi": "Điều gì khiến bạn giữ một thứ bên mình?"}],
		"answers": [
			{"id": "A", "en": "I still choose to carry it.", "vi": "Tôi vẫn tự chọn mang nó theo.", "delta": 1, "reaction": []},
			{"id": "B", "en": "It's useful for now.", "vi": "Hiện giờ nó có ích.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Someone would be angry if I didn't.", "vi": "Không giữ thì có người sẽ giận.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "dog", "en": "Will you keep this Relic until I come back? You can refuse. I won't hold it for you.", "vi": "Bạn giữ Di vật này đến khi tôi quay lại được không? Từ chối cũng được. Tôi không giữ hộ bạn đâu."}],
		"promise": RELIC,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "All right. Keep it close until I'm back.", "vi": "Được. Giữ bên mình đến khi tôi về nhé."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "A clear no is better than a borrowed yes.", "vi": "Nói không rõ ràng còn hơn nói có cho xong."}]},
			"HAGGLE": {"delta": 0, "strategy": "OTHER_RELIC", "dialogue": [{"speaker": "dog", "en": "A different Relic, then. This one. Does that change your answer?", "vi": "Vậy đổi Di vật khác nhé. Cái này. Bạn có đổi câu trả lời không?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "dog", "en": "You kept it. I know there were other things you could have done.", "vi": "Bạn giữ lại rồi. Tôi biết bạn có thể chọn làm việc khác."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "dog", "en": "It's gone. I remember you saying it would still be here.", "vi": "Mất rồi. Tôi nhớ bạn bảo nó sẽ vẫn ở đây."}]}
		}},
	{"id": "dog.t2.build_memory", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "dog.build", "promise_from": "dog.t1plus.build",
		"prompts": {
			"FULFILLED": [{"speaker": "dog", "en": "You did what you said: {target} I noticed. You don't have to make a speech about it.", "vi": "Bạn làm đúng lời: {target} Tôi có để ý. Không cần nói thêm cho hay đâu."}],
			"BROKEN": [{"speaker": "dog", "en": "This is what I was waiting for: {target} It didn't happen. I'd rather hear from you than make up a reason.", "vi": "Tôi đã chờ điều này: {target} Nó không xảy ra. Tôi muốn nghe bạn kể hơn là tự đoán lý do."}],
			"REFUSED": [{"speaker": "dog", "en": "You said no: {target} I didn't like it at first. I did know where I stood.", "vi": "Bạn từ chối: {target} Lúc đầu tôi không vui. Nhưng tôi biết rõ để thu xếp."}]
		},
		"answers": [
			{"id": "A", "en": "I need my answer to match what I can do.", "vi": "Tôi cần trả lời đúng với điều mình làm được.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Then I know when to wait, and when to put the kettle away.", "vi": "Vậy tôi biết lúc nào nên chờ, lúc nào nên cất ấm."}]},
			{"id": "B", "en": "Some hands are harder than others.", "vi": "Có lúc bài khó hơn lúc khác.", "delta": 0, "reaction": []},
			{"id": "C", "en": "You should trust me without checking.", "vi": "Bạn nên tin tôi mà không cần kiểm tra.", "delta": -1, "reaction": [{"speaker": "dog", "en": "I do trust you. That doesn't make me forget what happened.", "vi": "Tôi có tin bạn. Nhưng không vì vậy mà quên chuyện đã xảy ra."}]}
		]},
	{"id": "dog.t2.card_memory", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "dog.card", "promise_from": "dog.t1plus.card",
		"prompts": {
			"FULFILLED": [{"speaker": "dog", "en": "There's {target}, unchanged. Were you tempted to remake it?", "vi": "{target} đây rồi, vẫn như cũ. Bạn có lúc nào muốn đổi nó không?"}],
			"BROKEN": [{"speaker": "dog", "en": "I barely recognized {target}. You'd said you'd leave it unchanged. Talk to me.", "vi": "Tôi suýt không nhận ra {target}. Bạn từng bảo giữ nguyên. Kể tôi nghe nhé."}],
			"REFUSED": [{"speaker": "dog", "en": "You wouldn't promise to preserve a card. I keep reminding myself that wasn't you rejecting me.", "vi": "Bạn không hứa giữ nguyên lá bài. Tôi cứ phải tự nhắc: đâu phải bạn từ chối chính tôi."}]
		},
		"answers": [
			{"id": "A", "en": "To decide honestly, even if you wouldn't like it.", "vi": "Được quyết thật lòng, kể cả khi bạn không thích.", "delta": 1, "reaction": [{"speaker": "dog", "en": "I won't enjoy it. I can still hear it.", "vi": "Tôi sẽ không vui. Nhưng vẫn nghe được."}]},
			{"id": "B", "en": "Room to think about the hand.", "vi": "Có thời gian nghĩ về bài.", "delta": 0, "reaction": []},
			{"id": "C", "en": "To say yes now and change it later.", "vi": "Nói có trước rồi đổi sau.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Then I'd be waiting for an answer you already took back.", "vi": "Vậy tôi lại chờ một câu trả lời bạn đã rút lại từ lâu."}]}
		]},
	{"id": "dog.t2.relic_memory", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "dog.relic", "promise_from": "dog.t1plus.relic",
		"prompts": {
			"FULFILLED": [{"speaker": "dog", "en": "Still carrying {target}. Was that easy, or did I ask more than I realized?", "vi": "Vẫn giữ {target}. Dễ không, hay tôi đã nhờ nhiều hơn mình tưởng?"}],
			"BROKEN": [{"speaker": "dog", "en": "I looked for {target} when I came back. It was gone. You remember what you told me?", "vi": "Lúc quay lại tôi tìm {target}. Không còn nữa. Bạn nhớ đã nói gì với tôi chứ?"}],
			"REFUSED": [{"speaker": "dog", "en": "You said you couldn't keep {target}. I put that hope away before it became waiting.", "vi": "Bạn nói không giữ {target} được. Tôi gác mong đợi ấy xuống trước khi nó thành chờ đợi."}]
		},
		"answers": [
			{"id": "A", "en": "My word should be something I choose to give.", "vi": "Lời hứa phải là điều tôi tự chọn trao.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Yes. I don't want it if I have to drag it out of you.", "vi": "Ừ. Nếu phải ép bạn nói, tôi không muốn nhận."}]},
			{"id": "B", "en": "I was balancing what I needed.", "vi": "Tôi đang cân nhắc điều mình cần.", "delta": 0, "reaction": []},
			{"id": "C", "en": "The words were only there to please you.", "vi": "Tôi nói chỉ để bạn vui thôi.", "delta": -1, "reaction": [{"speaker": "dog", "en": "They don't. They just leave me waiting longer.", "vi": "Không đâu. Chúng chỉ khiến tôi chờ lâu hơn."}]}
		]},
	{"id": "dog.t2.space", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "I nearly asked you to stay longer. Is asking all right?", "vi": "Suýt nữa tôi xin bạn ở thêm. Xin như vậy có được không?"}],
		"answers": [
			{"id": "A", "en": "You can ask. Let me answer for myself.", "vi": "Bạn có thể hỏi. Để tôi tự trả lời.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Then... stay a little longer? It's all right if you can't.", "vi": "Vậy... ở thêm chút nhé? Không được cũng không sao."}]},
			{"id": "B", "en": "Depends why I'm leaving.", "vi": "Còn tùy vì sao tôi đi.", "delta": 0, "reaction": []},
			{"id": "C", "en": "If you cared, you wouldn't let me go.", "vi": "Nếu quan tâm, bạn sẽ không để tôi đi.", "delta": -1, "reaction": [{"speaker": "dog", "en": "I could block the door. You wouldn't be coming back to me then.", "vi": "Tôi chặn cửa được. Nhưng như thế đâu còn là bạn muốn quay về với tôi."}]}
		]},
	{"id": "dog.t2.disagree", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "I think you're wrong. You think I'm stubborn. Tea before we try again?", "vi": "Tôi nghĩ bạn sai. Bạn nghĩ tôi bướng. Uống trà rồi nói tiếp nhé?"}],
		"answers": [
			{"id": "A", "en": "Say it plainly. Keep listening.", "vi": "Nói thẳng. Rồi vẫn lắng nghe.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Good. Mine's gone cold. That happens when I start arguing.", "vi": "Được. Trà tôi nguội rồi. Cứ cãi nhau là thế."}]},
			{"id": "B", "en": "Give it some time.", "vi": "Cho nhau chút thời gian.", "delta": 0, "reaction": []},
			{"id": "C", "en": "You agree with me. That's loyalty.", "vi": "Bạn phải đồng ý với tôi. Đó mới là trung thành.", "delta": -1, "reaction": [{"speaker": "dog", "en": "That's a mirror. I'd rather have you.", "vi": "Như vậy là cái gương. Tôi muốn có bạn hơn."}]}
		]},
	{"id": "dog.t2.return", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "Cards are packed away. You can go, you know. Why are you still here?", "vi": "Bài cất hết rồi. Bạn về được mà. Sao vẫn còn đây?"}],
		"answers": [
			{"id": "A", "en": "Because you're still here.", "vi": "Vì bạn vẫn ở đây.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Oh. Right. I'll leave my chair down, then.", "vi": "Ồ. Ừ. Vậy tôi để ghế mình đây nhé."}]},
			{"id": "B", "en": "I like this corner.", "vi": "Tôi thích góc này.", "delta": 0, "reaction": []},
			{"id": "C", "en": "You might still owe me something.", "vi": "Có khi bạn vẫn còn nợ tôi gì đó.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Tell me what it is. I'd rather settle it than mistake it for friendship.", "vi": "Nói tôi biết món gì. Tôi thà trả cho xong còn hơn nhầm nó với tình bạn."}]}
		]}
]
