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
	{"speaker": "dog", "en": "All right. I'd rather hear that now.", "vi": "Được. Tôi muốn nghe điều đó ngay từ đầu."}
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
		{"en": "Dog stays while the chairs are stacked. He moves one back to the table and waits for you to choose whether to sit.", "vi": "Tuất ở lại khi ghế đã được xếp lên. Anh kéo một chiếc về bàn, đợi bạn tự quyết có ngồi xuống không."},
		{"en": "\"I don't need you to agree with me every time. I need to know your answer belongs to you.\"", "vi": "\"Tôi không cần bạn luôn đồng ý với tôi. Tôi cần biết câu trả lời thật sự là của bạn.\""},
		{"en": "He sets a small dog Emblem beside your glass. \"When our day comes around, bring it. There's a place here for you.\"", "vi": "Anh đặt Huy hiệu con chó nhỏ cạnh ly của bạn. \"Đến ngày của mình thì mang theo. Ở đây có chỗ cho bạn.\""}
	],
	"last_chance": {
		"id": "dog.last_chance.honest",
		"prompt": [{"speaker": "dog", "en": "One honest answer. Are you staying because you want to?", "vi": "Trả lời thật một lần thôi. Bạn ở lại vì bạn muốn chứ?"}],
		"answers": [
			{"id": "A", "en": "Yes. I can disagree and still stay.", "vi": "Có. Tôi có thể không đồng ý mà vẫn ở lại.", "recovery_success": true,
				"reaction": [{"speaker": "dog", "en": "Then we still have something to talk about.", "vi": "Vậy mình vẫn còn chuyện để nói."}]},
			{"id": "B", "en": "I need space today. That isn't a betrayal.", "vi": "Hôm nay tôi cần khoảng riêng. Đó không phải phản bội.", "recovery_success": true,
				"reaction": [{"speaker": "dog", "en": "No. It isn't. Thank you for telling me.", "vi": "Không. Không phải đâu. Cảm ơn bạn đã nói."}]},
			{"id": "C", "en": "I'll say anything if it makes you easier tonight.", "vi": "Tôi nói gì cũng được, miễn tối nay bạn dễ hơn.", "recovery_success": false,
				"reaction": [{"speaker": "dog", "en": "Then let's leave the words here.", "vi": "Vậy lời nói dừng ở đây thôi."}]}
		]},
	"special": []
}
const NODES := [
	{"id": "dog.t1.wait", "zodiac": "dog", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "If you couldn't come back, what would you tell me?", "vi": "Nếu không quay lại được, bạn sẽ nói với tôi điều gì?"}],
		"answers": [
			{"id": "A", "en": "As soon as I knew. You shouldn't have to wait.", "vi": "Nói ngay khi biết. Bạn không nên phải chờ.", "delta": 1, "reaction": [{"speaker": "dog", "en": "That's enough. I can make my own plans.", "vi": "Vậy là đủ. Tôi có thể tự tính việc mình."}]},
			{"id": "B", "en": "I'd explain when I next saw you.", "vi": "Lần gặp sau tôi sẽ giải thích.", "delta": 0, "reaction": [{"speaker": "dog", "en": "I'd hear you out.", "vi": "Tôi sẽ nghe bạn nói."}]},
			{"id": "C", "en": "Nothing. You'd work it out.", "vi": "Không nói gì. Bạn tự hiểu thôi.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Waiting isn't the same as knowing.", "vi": "Chờ đợi đâu có nghĩa là biết."}]}
		]},
	{"id": "dog.t1.loyal", "zodiac": "dog", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "Does loyalty mean saying yes?", "vi": "Trung thành có nghĩa là nói có không?"}],
		"answers": [
			{"id": "A", "en": "It means giving you an answer I can stand by.", "vi": "Nghĩa là cho bạn câu trả lời tôi giữ được.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Even a no. Especially a useful no.", "vi": "Kể cả nói không. Nhất là khi nói không một cách rõ ràng."}]},
			{"id": "B", "en": "Sometimes it means helping.", "vi": "Đôi khi nghĩa là giúp đỡ.", "delta": 0, "reaction": [{"speaker": "dog", "en": "When you choose to.", "vi": "Khi bạn tự chọn giúp."}]},
			{"id": "C", "en": "It means doing whatever you ask.", "vi": "Nghĩa là làm mọi điều bạn yêu cầu.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Then I'd never know where you stand.", "vi": "Vậy tôi chẳng biết bạn thật sự nghĩ gì."}]}
		]},
	{"id": "dog.t1.help", "zodiac": "dog", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "You notice I'm struggling. What do you do?", "vi": "Bạn thấy tôi đang chật vật. Bạn sẽ làm gì?"}],
		"answers": [
			{"id": "A", "en": "Ask what help you want.", "vi": "Hỏi bạn muốn được giúp thế nào.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Good. Leave me a say in it.", "vi": "Được. Để tôi có quyền quyết nữa."}]},
			{"id": "B", "en": "Stay close in case you ask.", "vi": "Ở gần, phòng khi bạn cần.", "delta": 0, "reaction": [{"speaker": "dog", "en": "I might.", "vi": "Có thể tôi sẽ cần."}]},
			{"id": "C", "en": "Take over. You'll thank me later.", "vi": "Làm thay hết. Rồi bạn sẽ cảm ơn.", "delta": -1, "reaction": [{"speaker": "dog", "en": "I'd like to be asked first.", "vi": "Tôi muốn được hỏi trước."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "I'll wait for what you actually do.", "vi": "Tôi sẽ chờ xem bạn thật sự làm gì."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "Then no obligation. Thank you for being clear.", "vi": "Vậy không có nghĩa vụ gì. Cảm ơn bạn đã nói rõ."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": BUILD_ALTERNATE, "dialogue": [{"speaker": "dog", "en": "Any one Extension instead, in either Phase. Read that as a new promise before you answer.", "vi": "Thay bằng một lần Nối bất kỳ, Hiệp nào cũng được. Đọc như lời hứa mới rồi hãy trả lời nhé."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "dog", "en": "You followed through on the work we agreed. I can trust that.", "vi": "Bạn đã làm đến cùng việc mình thống nhất. Tôi tin được điều đó."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "dog", "en": "That wasn't what we agreed. Next time, give me the answer you can keep.", "vi": "Đó chưa phải điều mình thống nhất. Lần tới hãy trả lời bằng điều bạn giữ được."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "Your choice. I won't ask you to keep it out of the game.", "vi": "Bạn chọn nhé. Tôi không bắt bạn để nó ngoài cuộc chơi."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "Then keep the freedom to change it.", "vi": "Vậy cứ giữ quyền thay đổi nó."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "dog", "en": "Still itself. Just as you promised.", "vi": "Vẫn như cũ. Đúng điều bạn hứa."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "dog", "en": "It changed after your promise. I needed your words to mean something.", "vi": "Nó đã đổi sau lời hứa. Tôi cần lời bạn nói có ý nghĩa."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "Then keep it with you. I'll ask on my return.", "vi": "Vậy giữ bên mình nhé. Khi quay lại tôi sẽ hỏi."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "dog", "en": "A clear no is better than a borrowed yes.", "vi": "Nói không rõ ràng còn hơn nói có cho xong."}]},
			"HAGGLE": {"delta": 0, "strategy": "OTHER_RELIC", "dialogue": [{"speaker": "dog", "en": "A different Relic, then. This one. Does that change your answer?", "vi": "Vậy đổi Di vật khác nhé. Cái này. Bạn có đổi câu trả lời không?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "dog", "en": "You kept it with you. I remember the choice you made.", "vi": "Bạn đã giữ bên mình. Tôi nhớ lựa chọn của bạn."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "dog", "en": "It left your hands before I returned. That promise wasn't kept.", "vi": "Nó đã rời tay bạn trước khi tôi trở lại. Lời hứa đó chưa được giữ."}]}
		}},
	{"id": "dog.t2.build_memory", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "dog.build", "promise_from": "dog.t1plus.build",
		"prompts": {
			"FULFILLED": [{"speaker": "dog", "en": "You kept this commitment: {target} What kept you with it?", "vi": "Bạn đã giữ cam kết này: {target} Điều gì giúp bạn làm đến cùng?"}],
			"BROKEN": [{"speaker": "dog", "en": "This commitment wasn't kept: {target} What would you tell me now?", "vi": "Cam kết này chưa được giữ: {target} Giờ bạn muốn nói gì với tôi?"}],
			"REFUSED": [{"speaker": "dog", "en": "You said no to this: {target} I'm glad I didn't have to guess.", "vi": "Bạn đã từ chối việc này: {target} Tôi mừng vì không phải đoán."}]
		},
		"answers": [
			{"id": "A", "en": "I need my answer to match what I can do.", "vi": "Tôi cần trả lời đúng với điều mình làm được.", "delta": 1, "reaction": [{"speaker": "dog", "en": "Then we can make plans honestly.", "vi": "Vậy mình có thể tính việc một cách thật lòng."}]},
			{"id": "B", "en": "Some hands are harder than others.", "vi": "Có lúc bài khó hơn lúc khác.", "delta": 0, "reaction": []},
			{"id": "C", "en": "You should trust me without checking.", "vi": "Bạn nên tin tôi mà không cần kiểm tra.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Trust has to include what happened.", "vi": "Niềm tin phải tính cả điều đã xảy ra."}]}
		]},
	{"id": "dog.t2.card_memory", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "dog.card", "promise_from": "dog.t1plus.card",
		"prompts": {
			"FULFILLED": [{"speaker": "dog", "en": "You left {target} unchanged. Did keeping it feel like your choice?", "vi": "Bạn đã giữ nguyên {target}. Bạn thấy đó là lựa chọn của mình chứ?"}],
			"BROKEN": [{"speaker": "dog", "en": "{target} changed before I returned. What changed your mind?", "vi": "{target} đã đổi trước khi tôi trở lại. Điều gì khiến bạn đổi ý?"}],
			"REFUSED": [{"speaker": "dog", "en": "You didn't promise to preserve a card. What freedom did you need?", "vi": "Bạn không hứa giữ nguyên một lá. Bạn cần tự do làm điều gì?"}]
		},
		"answers": [
			{"id": "A", "en": "To decide honestly, even if you wouldn't like it.", "vi": "Được quyết thật lòng, kể cả khi bạn không thích.", "delta": 1, "reaction": [{"speaker": "dog", "en": "I can hear an answer I don't like.", "vi": "Tôi nghe được cả câu trả lời mình không thích."}]},
			{"id": "B", "en": "Room to think about the hand.", "vi": "Có thời gian nghĩ về bài.", "delta": 0, "reaction": []},
			{"id": "C", "en": "To say yes now and change it later.", "vi": "Nói có trước rồi đổi sau.", "delta": -1, "reaction": [{"speaker": "dog", "en": "Then your yes gives me nothing to trust.", "vi": "Vậy lời có chẳng cho tôi điều gì để tin."}]}
		]},
	{"id": "dog.t2.relic_memory", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "dog.relic", "promise_from": "dog.t1plus.relic",
		"prompts": {
			"FULFILLED": [{"speaker": "dog", "en": "You kept {target} until I returned. Was it the object or the word you gave?", "vi": "Bạn đã giữ {target} đến khi tôi trở lại. Vì món đồ, hay vì lời đã hứa?"}],
			"BROKEN": [{"speaker": "dog", "en": "{target} left before I came back. I remember your promise too.", "vi": "{target} đã rời đi trước khi tôi quay lại. Tôi cũng nhớ lời bạn hứa."}],
			"REFUSED": [{"speaker": "dog", "en": "You wouldn't promise to keep {target}. Thank you for telling me before I waited.", "vi": "Bạn không hứa giữ {target}. Cảm ơn đã nói trước khi tôi chờ."}]
		},
		"answers": [
			{"id": "A", "en": "My word should be something I choose to give.", "vi": "Lời hứa phải là điều tôi tự chọn trao.", "delta": 1, "reaction": [{"speaker": "dog", "en": "And something I can choose to trust.", "vi": "Và là điều tôi có thể tự chọn tin."}]},
			{"id": "B", "en": "I was balancing what I needed.", "vi": "Tôi đang cân nhắc điều mình cần.", "delta": 0, "reaction": []},
			{"id": "C", "en": "The words were only there to please you.", "vi": "Tôi nói chỉ để bạn vui thôi.", "delta": -1, "reaction": [{"speaker": "dog", "en": "They don't please me when they're empty.", "vi": "Lời rỗng thì không làm tôi vui."}]}
		]},
	{"id": "dog.t2.space", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "If you need to leave this table, should I ask you to stay?", "vi": "Nếu bạn cần rời bàn này, tôi có nên xin bạn ở lại không?"}],
		"answers": [
			{"id": "A", "en": "You can ask. Let me answer for myself.", "vi": "Bạn có thể hỏi. Để tôi tự trả lời.", "delta": 1, "reaction": [{"speaker": "dog", "en": "I can do that.", "vi": "Tôi làm được điều đó."}]},
			{"id": "B", "en": "Depends why I'm leaving.", "vi": "Còn tùy vì sao tôi đi.", "delta": 0, "reaction": []},
			{"id": "C", "en": "If you cared, you wouldn't let me go.", "vi": "Nếu quan tâm, bạn sẽ không để tôi đi.", "delta": -1, "reaction": [{"speaker": "dog", "en": "I'd rather leave you a way back.", "vi": "Tôi muốn để bạn có đường quay lại hơn."}]}
		]},
	{"id": "dog.t2.disagree", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "What do we do when we don't agree?", "vi": "Khi không đồng ý với nhau thì mình làm gì?"}],
		"answers": [
			{"id": "A", "en": "Say it plainly. Keep listening.", "vi": "Nói thẳng. Rồi vẫn lắng nghe.", "delta": 1, "reaction": [{"speaker": "dog", "en": "I'd stay for that conversation.", "vi": "Cuộc nói chuyện đó thì tôi ở lại."}]},
			{"id": "B", "en": "Give it some time.", "vi": "Cho nhau chút thời gian.", "delta": 0, "reaction": []},
			{"id": "C", "en": "You agree with me. That's loyalty.", "vi": "Bạn phải đồng ý với tôi. Đó mới là trung thành.", "delta": -1, "reaction": [{"speaker": "dog", "en": "That leaves only one of us at the table.", "vi": "Vậy trên bàn chỉ còn một người thôi."}]}
		]},
	{"id": "dog.t2.return", "zodiac": "dog", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "dog", "en": "Why come back when the game is over?", "vi": "Cuộc chơi đã xong, sao còn quay lại?"}],
		"answers": [
			{"id": "A", "en": "Because you're still here.", "vi": "Vì bạn vẫn ở đây.", "delta": 1, "reaction": [{"speaker": "dog", "en": "I'll move the glass. Sit down.", "vi": "Tôi dời ly sang nhé. Ngồi xuống đi."}]},
			{"id": "B", "en": "I like this corner.", "vi": "Tôi thích góc này.", "delta": 0, "reaction": []},
			{"id": "C", "en": "You might still owe me something.", "vi": "Có khi bạn vẫn còn nợ tôi gì đó.", "delta": -1, "reaction": [{"speaker": "dog", "en": "I'd rather know what you came for.", "vi": "Tôi muốn biết bạn đến vì điều gì hơn."}]}
		]}
]
