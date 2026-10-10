extends RefCounted
## Cat's next authored layer. Tier 1 source dialogue stays in cat_tier_1.gd.
## Memories refer to settled promises, never inferred personality scores.
const CONFIG := {
	"visit_limits": {"1": 3, "1+": 1, "2": 1},
	"progression": [{"from": 2, "to": 3, "kept": 3, "distinct": 2,
		"promises": ["cat.leave_card", "cat.keep_relic", "cat.protect_card"]}],
	"last_chance": {
		"id": "cat.last_chance.be_plain",
		"prompt": [{"speaker": "cat", "en": "Are you answering me, or trying to get rid of me?", "vi": "Bạn đang trả lời tôi, hay chỉ muốn đuổi tôi đi?"}],
		"answers": [
			{"id": "A", "en": "I'm answering. We don't have to agree.", "vi": "Tôi đang trả lời. Mình đâu cần đồng ý với nhau.", "recovery_success": true,
				"reaction": [{"speaker": "cat", "en": "Then be plain with me.", "vi": "Vậy cứ nói thẳng với tôi."}]},
			{"id": "B", "en": "Just tell me what you want to hear.", "vi": "Cứ nói tôi nên trả lời thế nào đi.", "recovery_success": false,
				"reaction": [{"speaker": "cat", "en": "Nothing, now.", "vi": "Giờ thì chẳng cần gì nữa."}]},
			{"id": "C", "en": "I want some quiet. That's all.", "vi": "Tôi muốn yên tĩnh một chút. Chỉ vậy thôi.", "recovery_success": true,
				"reaction": [{"speaker": "cat", "en": "You could have said that.", "vi": "Bạn cứ nói vậy từ đầu là được."}]}
		]},
	"special": []
}

const NODES := [
	{"id": "cat.t2.boundaries", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "boundaries", "kind": "QUESTION",
		"prompt": [{"speaker": "cat", "en": "If I asked you to keep something forever, would you?", "vi": "Nếu tôi bảo bạn giữ một thứ mãi mãi, bạn có giữ không?"}],
		"answers": [
			{"id": "A", "en": "No. Liking it doesn't mean I owe it forever.", "vi": "Không. Thích nó đâu có nghĩa tôi phải giữ mãi.", "delta": 1,
				"reaction": [{"speaker": "cat", "en": "Good. Forever is a stupid promise.", "vi": "Tốt. Hứa mãi mãi ngớ ngẩn lắm."}]},
			{"id": "B", "en": "I'd keep it until I had a reason not to.", "vi": "Tôi sẽ giữ đến khi có lý do để bỏ.", "delta": 0,
				"reaction": [{"speaker": "cat", "en": "A reason. Not an excuse.", "vi": "Lý do nhé. Không phải cái cớ."}]},
			{"id": "C", "en": "Anything you want.", "vi": "Bạn muốn gì cũng được.", "delta": -1,
				"reaction": [{"speaker": "cat", "en": "You didn't even ask what it was.", "vi": "Bạn còn chưa hỏi đó là gì."}]}
		]},
	{"id": "cat.t2.sit_here", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "company", "kind": "QUESTION",
		"prompt": [{"speaker": "cat", "en": "You can play without me. Why do you still sit here?", "vi": "Bạn chơi mà không có tôi cũng được. Sao vẫn ngồi đây?"}],
		"answers": [
			{"id": "A", "en": "I like having you here.", "vi": "Tôi thích có bạn ở đây.", "delta": 1,
				"reaction": [{"speaker": "cat", "en": "Mm. Move your elbow. You're taking my space.", "vi": "Ừm. Dời khuỷu tay đi. Bạn chiếm chỗ của tôi rồi."}]},
			{"id": "B", "en": "The chair's comfortable.", "vi": "Cái ghế này ngồi dễ chịu.", "delta": 0,
				"reaction": [{"speaker": "cat", "en": "It is. I picked it.", "vi": "Đúng vậy. Tôi chọn mà."}]},
			{"id": "C", "en": "I'm hoping you'll go easier on me tonight.", "vi": "Tôi mong tối nay bạn sẽ nhẹ tay hơn.", "delta": -1,
				"reaction": [{"speaker": "cat", "en": "There it is. An invoice.", "vi": "Đấy. Lại tính toán."}]}
		]},
	{"id": "cat.t2.your_choice", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "choice", "kind": "QUESTION",
		"requirements": {"target": "CARD"},
		"prompt": [{"speaker": "cat", "en": "Today, you choose what stays. Does that make it easier?", "vi": "Hôm nay bạn chọn thứ mình giữ. Vậy có dễ hơn không?"}],
		"answers": [
			{"id": "A", "en": "Harder. I can't blame you for the choice.", "vi": "Khó hơn. Tôi không thể đổ lỗi cho bạn vì lựa chọn đó.", "delta": 1,
				"reaction": [{"speaker": "cat", "en": "Exactly.", "vi": "Chính xác."}]},
			{"id": "B", "en": "Depends on the cards.", "vi": "Còn tùy những lá bài.", "delta": 0,
				"reaction": [{"speaker": "cat", "en": "Have a look, then.", "vi": "Vậy cứ xem đi."}]},
			{"id": "C", "en": "I'll pick whichever costs me least.", "vi": "Tôi chọn lá khiến mình thiệt ít nhất.", "delta": -1,
				"reaction": [{"speaker": "cat", "en": "Of course you will.", "vi": "Dĩ nhiên rồi."}]}
		],
		"followup": [{"speaker": "cat", "en": "Pick one. Leave it alone this afternoon.", "vi": "Chọn một lá. Để yên nó chiều nay."}],
		"promise_from": "cat.t1plus.leave_it_alone", "initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "This one.", "vi": "Lá này."}, {"speaker": "cat", "en": "Yours, then. I'll remember.", "vi": "Vậy là bạn chọn nhé. Tôi sẽ nhớ."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "No promise today.", "vi": "Hôm nay tôi không hứa."}, {"speaker": "cat", "en": "Then don't make one.", "vi": "Vậy đừng hứa."}]}},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "cat", "en": "You chose it. You kept it.", "vi": "Bạn đã chọn nó. Bạn đã giữ lời."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "cat", "en": "You chose it. I didn't choose for you.", "vi": "Bạn đã chọn nó. Tôi đâu có chọn hộ bạn."}]}}},
	{"id": "cat.t2.card_memory", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "favorite_card", "kind": "QUESTION",
		"memory_key": "cat.leave_card",
		"prompts": {
			"FULFILLED": [{"speaker": "cat", "en": "You left {target} alone. Were you watching it the whole time?", "vi": "Bạn đã để yên {target}. Bạn có nhìn nó suốt không?"}],
			"BROKEN": [{"speaker": "cat", "en": "You used {target} after saying you wouldn't. What changed?", "vi": "Bạn dùng {target} dù đã hứa không dùng. Có gì thay đổi?"}],
			"REFUSED": [{"speaker": "cat", "en": "You wouldn't promise to leave a card alone. Was it the card, or the promise?", "vi": "Bạn không chịu hứa để yên một lá bài. Vì lá bài, hay vì lời hứa?"}]},
		"answers_by_result": {
			"FULFILLED": [
				{"id": "A", "en": "Yes. I kept thinking about using it.", "vi": "Có. Tôi cứ nghĩ đến việc dùng nó.", "delta": 1, "reaction": [{"speaker": "cat", "en": "I wondered.", "vi": "Tôi cũng đoán vậy."}]},
				{"id": "B", "en": "Sometimes. It wasn't the whole game.", "vi": "Thỉnh thoảng. Nó đâu phải cả ván bài.", "delta": 0, "reaction": [{"speaker": "cat", "en": "No. It wasn't.", "vi": "Ừ. Không phải."}]},
				{"id": "C", "en": "It was easy. Pick something that matters next time.", "vi": "Dễ mà. Lần sau chọn thứ có giá trị đi.", "delta": -1, "reaction": [{"speaker": "cat", "en": "You still think I didn't.", "vi": "Bạn vẫn nghĩ tôi chọn thứ vô giá trị."}]}],
			"BROKEN": [
				{"id": "A", "en": "I wanted to use it more than I wanted to keep my word.", "vi": "Tôi muốn dùng nó hơn là giữ lời.", "delta": 1, "reaction": [{"speaker": "cat", "en": "That sounds like what happened.", "vi": "Nghe đúng với chuyện đã xảy ra."}]},
				{"id": "B", "en": "The hand changed. I made a different choice.", "vi": "Bài trên tay thay đổi. Tôi quyết định khác.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Your choice. Keep that part.", "vi": "Bạn quyết định. Nhớ phần đó nhé."}]},
				{"id": "C", "en": "You must have watched the wrong card.", "vi": "Chắc bạn nhìn nhầm lá rồi.", "delta": -1, "reaction": [{"speaker": "cat", "en": "I didn't.", "vi": "Không nhầm đâu."}]}],
			"REFUSED": [
				{"id": "A", "en": "The promise. I wasn't sure I could keep it.", "vi": "Lời hứa. Tôi không chắc mình giữ được.", "delta": 1, "reaction": [{"speaker": "cat", "en": "Better than pretending.", "vi": "Vậy tốt hơn giả vờ."}]},
				{"id": "B", "en": "The card. I wanted to play it.", "vi": "Lá bài. Tôi muốn dùng nó.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Then play it.", "vi": "Vậy cứ dùng đi."}]},
				{"id": "C", "en": "I thought you'd forget.", "vi": "Tôi tưởng bạn sẽ quên.", "delta": -1, "reaction": [{"speaker": "cat", "en": "Bad guess.", "vi": "Đoán sai rồi."}]}]}},
	{"id": "cat.t2.relic_memory", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "keeping_things", "kind": "QUESTION",
		"memory_key": "cat.keep_relic",
		"prompts": {
			"FULFILLED": [{"speaker": "cat", "en": "You kept {target} when I asked. Would you have kept it without me?", "vi": "Bạn giữ {target} khi tôi nhờ. Không có tôi, bạn có giữ không?"}],
			"BROKEN": [{"speaker": "cat", "en": "You let {target} go. Did you need to, or did you want to?", "vi": "Bạn đã bỏ {target}. Vì cần, hay vì muốn?"}],
			"REFUSED": [{"speaker": "cat", "en": "You said you might need the money. Do you regret saying no?", "vi": "Bạn nói có thể sẽ cần tiền. Bạn có tiếc vì đã từ chối không?"}]},
		"answers": [
			{"id": "A", "en": "It was my decision. I don't want to dress it up for you.", "vi": "Tôi đã quyết định. Tôi không muốn nói cho đẹp lòng bạn.", "delta": 1, "reaction": [{"speaker": "cat", "en": "Don't. I asked you, not a nicer version of you.", "vi": "Đừng. Tôi hỏi bạn, không phải phiên bản dễ nghe hơn của bạn."}]},
			{"id": "B", "en": "I'm still not sure how I feel about it.", "vi": "Tôi vẫn chưa biết mình cảm thấy thế nào.", "delta": 0, "reaction": [{"speaker": "cat", "en": "You can take longer than an afternoon.", "vi": "Bạn đâu phải nghĩ xong trong một buổi chiều."}]},
			{"id": "C", "en": "I'll say whatever makes this easier.", "vi": "Tôi sẽ nói điều gì khiến chuyện này dễ hơn.", "delta": -1, "reaction": [{"speaker": "cat", "en": "It won't.", "vi": "Không dễ hơn đâu."}]}
		]},
	{"id": "cat.t2.change_memory", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "transformed_card", "kind": "QUESTION",
		"memory_key": "cat.protect_card",
		"prompts": {
			"FULFILLED": [{"speaker": "cat", "en": "You left {target} as it was until I came back. Was that for me?", "vi": "Bạn giữ nguyên {target} đến khi tôi về. Vì tôi à?"}],
			"BROKEN": [{"speaker": "cat", "en": "You changed {target} after promising not to. Was it worth breaking the promise?", "vi": "Bạn đổi {target} sau khi hứa không đổi. Có đáng để thất hứa không?"}],
			"REFUSED": [{"speaker": "cat", "en": "You said it was your card. I know. What did you think I was asking for?", "vi": "Bạn nói đó là bài của bạn. Tôi biết. Bạn nghĩ tôi đang đòi gì?"}]},
		"answers": [
			{"id": "A", "en": "A choice that means something. Not just a better card.", "vi": "Một lựa chọn có ý nghĩa. Không chỉ một lá bài tốt hơn.", "delta": 1, "reaction": [{"speaker": "cat", "en": "There. You were listening.", "vi": "Đấy. Bạn có nghe mà."}]},
			{"id": "B", "en": "I was thinking about the next game.", "vi": "Tôi đang nghĩ về ván tiếp theo.", "delta": 0, "reaction": [{"speaker": "cat", "en": "You're always allowed to think.", "vi": "Bạn lúc nào cũng được phép nghĩ."}]},
			{"id": "C", "en": "It's a card. Why are we still talking about it?", "vi": "Chỉ là một lá bài. Sao mình vẫn nói về nó?", "delta": -1, "reaction": [{"speaker": "cat", "en": "We aren't. We're talking about what you said.", "vi": "Không phải. Mình đang nói về lời bạn đã nói."}]}
		]}
]
