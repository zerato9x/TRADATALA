extends RefCounted
## Cat's next authored layer. Tier 1 source dialogue stays in cat_tier_1.gd.
## Memories refer to settled promises, never inferred personality scores.
const CONFIG := {
	"visit_limits": {"1": 3, "1+": 1, "2": 1},
	"progression": [{"from": 2, "to": 3, "kept": 3, "distinct": 2,
		"promises": ["cat.leave_card", "cat.keep_relic", "cat.protect_card"]}],
	"last_chance": {
		"id": "cat.last_chance.be_plain",
		"prompt": [{"speaker": "cat", "en": "Are you talking to me, or pressing the right buttons until I go away?", "vi": "Bạn đang nói chuyện với tôi, hay bấm đúng nút cho tôi đi khuất?"}],
		"answers": [
			{"id": "A", "en": "I'm answering. We don't have to agree.", "vi": "Tôi đang trả lời. Mình đâu cần đồng ý với nhau.", "recovery_success": true,
				"reaction": [{"speaker": "cat", "en": "Good. Disagree properly, then.", "vi": "Được. Vậy bất đồng cho đàng hoàng nhé."}]},
			{"id": "B", "en": "Just tell me what you want to hear.", "vi": "Cứ nói tôi nên trả lời thế nào đi.", "recovery_success": false,
				"reaction": [{"speaker": "cat", "en": "Nothing, now.", "vi": "Giờ thì chẳng cần gì nữa."}]},
			{"id": "C", "en": "I want some quiet. That's all.", "vi": "Tôi muốn yên tĩnh một chút. Chỉ vậy thôi.", "recovery_success": true,
				"reaction": [{"speaker": "cat", "en": "Oh. Move over. I can be quiet too.", "vi": "Ồ. Xích qua đi. Tôi cũng biết im mà."}]}
		]},
	"special": []
}

const NODES := [
	{"id": "cat.t2.boundaries", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "boundaries", "kind": "QUESTION",
		"prompt": [{"speaker": "cat", "en": "Forever. People say that very easily. How long do you think it is?", "vi": "Mãi mãi. Người ta nói nhẹ tênh. Bạn nghĩ nó dài bao lâu?"}],
		"answers": [
			{"id": "A", "en": "No. Liking it doesn't mean I owe it forever.", "vi": "Không. Thích nó đâu có nghĩa tôi phải giữ mãi.", "delta": 1,
				"reaction": [{"speaker": "cat", "en": "Good. I don't even know where I'll want to sit tomorrow.", "vi": "Tốt. Mai muốn ngồi đâu tôi còn chưa biết."}]},
			{"id": "B", "en": "I'd keep it until I had a reason not to.", "vi": "Tôi sẽ giữ đến khi có lý do để bỏ.", "delta": 0,
				"reaction": [{"speaker": "cat", "en": "A real reason. Not just something shinier walking past.", "vi": "Lý do thật nhé. Không phải vì có thứ bóng bẩy hơn đi ngang."}]},
			{"id": "C", "en": "Anything you want.", "vi": "Bạn muốn gì cũng được.", "delta": -1,
				"reaction": [{"speaker": "cat", "en": "Careful. I might ask for your chair.", "vi": "Cẩn thận. Tôi có thể đòi cái ghế của bạn đấy."}]}
		]},
	{"id": "cat.t2.sit_here", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "company", "kind": "QUESTION",
		"prompt": [{"speaker": "cat", "en": "The other chair has more sun. You keep choosing this one.", "vi": "Ghế bên kia nhiều nắng hơn. Bạn cứ chọn ghế này."}],
		"answers": [
			{"id": "A", "en": "I like having you here.", "vi": "Tôi thích có bạn ở đây.", "delta": 1,
				"reaction": [{"speaker": "cat", "en": "Mm. Don't make a whole speech of it. Your elbow's in my spot.", "vi": "Ừm. Đừng diễn thuyết nhé. Khuỷu tay bạn đang chiếm chỗ tôi."}]},
			{"id": "B", "en": "The chair's comfortable.", "vi": "Cái ghế này ngồi dễ chịu.", "delta": 0,
				"reaction": [{"speaker": "cat", "en": "Of course. I tested all of them.", "vi": "Dĩ nhiên. Tôi thử hết rồi."}]},
			{"id": "C", "en": "I'm hoping you'll go easier on me tonight.", "vi": "Tôi mong tối nay bạn sẽ nhẹ tay hơn.", "delta": -1,
				"reaction": [{"speaker": "cat", "en": "Ah. Affection with a receipt.", "vi": "À. Quý mến có kèm hóa đơn."}]}
		]},
	{"id": "cat.t2.your_choice", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "choice", "kind": "QUESTION",
		"requirements": {"target": "CARD"},
		"prompt": [{"speaker": "cat", "en": "Your turn to choose what stays untouched. No blaming my excellent taste afterward.", "vi": "Đến lượt bạn chọn lá để yên. Xong đừng đổ cho mắt chọn bài tuyệt vời của tôi."}],
		"answers": [
			{"id": "A", "en": "Harder. I can't blame you for the choice.", "vi": "Khó hơn. Tôi không thể đổ lỗi cho bạn vì lựa chọn đó.", "delta": 1,
				"reaction": [{"speaker": "cat", "en": "Annoying, isn't it? Having your own taste.", "vi": "Phiền nhỉ? Có sở thích riêng ấy."}]},
			{"id": "B", "en": "Depends on the cards.", "vi": "Còn tùy những lá bài.", "delta": 0,
				"reaction": [{"speaker": "cat", "en": "Have a look, then.", "vi": "Vậy cứ xem đi."}]},
			{"id": "C", "en": "I'll pick whichever costs me least.", "vi": "Tôi chọn lá khiến mình thiệt ít nhất.", "delta": -1,
				"reaction": [{"speaker": "cat", "en": "You could at least pretend to look at them.", "vi": "Ít nhất cũng giả vờ nhìn chúng một chút chứ."}]}
		],
		"followup": [{"speaker": "cat", "en": "Pick one. Leave it alone this afternoon.", "vi": "Chọn một lá. Để yên nó chiều nay."}],
		"promise_from": "cat.t1plus.leave_it_alone", "initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "This one.", "vi": "Lá này."}, {"speaker": "cat", "en": "That one. All right. I'll know it when I come back.", "vi": "Lá đó. Được. Lúc về tôi sẽ nhận ra."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "No promise today.", "vi": "Hôm nay tôi không hứa."}, {"speaker": "cat", "en": "Then don't make one.", "vi": "Vậy đừng hứa."}]}},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "cat", "en": "Still there. You looked at it a lot, didn't you?", "vi": "Vẫn ở đó. Bạn nhìn nó nhiều lắm nhỉ?"}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "cat", "en": "That was your choice. I was curious what you'd do with it.", "vi": "Bạn tự chọn mà. Tôi đã tò mò xem bạn sẽ làm gì."}]}}},
	{"id": "cat.t2.card_memory", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "favorite_card", "kind": "QUESTION",
		"memory_key": "cat.leave_card",
		"prompts": {
			"FULFILLED": [{"speaker": "cat", "en": "You left {target} alone. Were you watching it the whole time?", "vi": "Bạn đã để yên {target}. Bạn có nhìn nó suốt không?"}],
			"BROKEN": [{"speaker": "cat", "en": "You used {target} after saying you wouldn't. What changed?", "vi": "Bạn dùng {target} dù đã hứa không dùng. Có gì thay đổi?"}],
			"REFUSED": [{"speaker": "cat", "en": "You wouldn't promise to leave a card alone. Was it the card, or the promise?", "vi": "Bạn không chịu hứa để yên một lá bài. Vì lá bài, hay vì lời hứa?"}]},
		"answers_by_result": {
			"FULFILLED": [
				{"id": "A", "en": "Yes. I kept thinking about using it.", "vi": "Có. Tôi cứ nghĩ đến việc dùng nó.", "delta": 1, "reaction": [{"speaker": "cat", "en": "I noticed. You have a very loud thinking face.", "vi": "Tôi biết. Mặt bạn lúc suy nghĩ dễ đọc lắm."}]},
				{"id": "B", "en": "Sometimes. It wasn't the whole game.", "vi": "Thỉnh thoảng. Nó đâu phải cả ván bài.", "delta": 0, "reaction": [{"speaker": "cat", "en": "No. It wasn't.", "vi": "Ừ. Không phải."}]},
				{"id": "C", "en": "It was easy. Pick something that matters next time.", "vi": "Dễ mà. Lần sau chọn thứ có giá trị đi.", "delta": -1, "reaction": [{"speaker": "cat", "en": "I picked something that mattered to me. You didn't ask.", "vi": "Tôi chọn thứ có ý nghĩa với tôi. Bạn đâu có hỏi."}]}],
			"BROKEN": [
				{"id": "A", "en": "I wanted to use it more than I wanted to keep my word.", "vi": "Tôi muốn dùng nó hơn là giữ lời.", "delta": 1, "reaction": [{"speaker": "cat", "en": "Mm. I prefer that answer to a clever excuse.", "vi": "Ừm. Tôi thích câu ấy hơn một cái cớ khéo léo."}]},
				{"id": "B", "en": "The hand changed. I made a different choice.", "vi": "Bài trên tay thay đổi. Tôi quyết định khác.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Then say you chose. Don't make the cards take the blame.", "vi": "Vậy nói là bạn chọn đi. Đừng bắt bài chịu lỗi."}]},
				{"id": "C", "en": "You must have watched the wrong card.", "vi": "Chắc bạn nhìn nhầm lá rồi.", "delta": -1, "reaction": [{"speaker": "cat", "en": "I know that card. Try another explanation.", "vi": "Tôi nhận ra lá đó. Thử giải thích kiểu khác đi."}]}],
			"REFUSED": [
				{"id": "A", "en": "The promise. I wasn't sure I could keep it.", "vi": "Lời hứa. Tôi không chắc mình giữ được.", "delta": 1, "reaction": [{"speaker": "cat", "en": "Better than pretending.", "vi": "Vậy tốt hơn giả vờ."}]},
				{"id": "B", "en": "The card. I wanted to play it.", "vi": "Lá bài. Tôi muốn dùng nó.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Then play it.", "vi": "Vậy cứ dùng đi."}]},
				{"id": "C", "en": "I thought you'd forget.", "vi": "Tôi tưởng bạn sẽ quên.", "delta": -1, "reaction": [{"speaker": "cat", "en": "Terrible guess. I remember where you put your cup yesterday.", "vi": "Đoán tệ quá. Cốc hôm qua bạn đặt đâu tôi còn nhớ."}]}]}},
	{"id": "cat.t2.relic_memory", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "keeping_things", "kind": "QUESTION",
		"memory_key": "cat.keep_relic",
		"prompts": {
			"FULFILLED": [{"speaker": "cat", "en": "You kept {target} when I asked. Would you have kept it without me?", "vi": "Bạn giữ {target} khi tôi nhờ. Không có tôi, bạn có giữ không?"}],
			"BROKEN": [{"speaker": "cat", "en": "You let {target} go. Did you need to, or did you want to?", "vi": "Bạn đã bỏ {target}. Vì cần, hay vì muốn?"}],
			"REFUSED": [{"speaker": "cat", "en": "You said you might need the money. Do you regret saying no?", "vi": "Bạn nói có thể sẽ cần tiền. Bạn có tiếc vì đã từ chối không?"}]},
		"answers": [
			{"id": "A", "en": "It was my decision. I don't want to dress it up for you.", "vi": "Tôi đã quyết định. Tôi không muốn nói cho đẹp lòng bạn.", "delta": 1, "reaction": [{"speaker": "cat", "en": "Don't polish it for me. I liked talking to the unpolished one.", "vi": "Đừng đánh bóng câu trả lời. Tôi thích nói chuyện với bản chưa đánh bóng hơn."}]},
			{"id": "B", "en": "I'm still not sure how I feel about it.", "vi": "Tôi vẫn chưa biết mình cảm thấy thế nào.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Take your time. I've taken longer choosing a windowsill.", "vi": "Cứ từ từ. Tôi chọn bậu cửa để nằm còn lâu hơn."}]},
			{"id": "C", "en": "I'll say whatever makes this easier.", "vi": "Tôi sẽ nói điều gì khiến chuyện này dễ hơn.", "delta": -1, "reaction": [{"speaker": "cat", "en": "It might make it shorter. It won't make it better.", "vi": "Có thể ngắn chuyện hơn. Không hay hơn đâu."}]}
		]},
	{"id": "cat.t2.change_memory", "zodiac": "cat", "content_tier": "2", "relationship_required": 3, "topic": "transformed_card", "kind": "QUESTION",
		"memory_key": "cat.protect_card",
		"prompts": {
			"FULFILLED": [{"speaker": "cat", "en": "You left {target} as it was until I came back. Was that for me?", "vi": "Bạn giữ nguyên {target} đến khi tôi về. Vì tôi à?"}],
			"BROKEN": [{"speaker": "cat", "en": "You changed {target} after promising not to. Was it worth breaking the promise?", "vi": "Bạn đổi {target} sau khi hứa không đổi. Có đáng để thất hứa không?"}],
			"REFUSED": [{"speaker": "cat", "en": "You said it was your card. I know. What did you think I was asking for?", "vi": "Bạn nói đó là bài của bạn. Tôi biết. Bạn nghĩ tôi đang đòi gì?"}]},
		"answers": [
			{"id": "A", "en": "A choice that means something. Not just a better card.", "vi": "Một lựa chọn có ý nghĩa. Không chỉ một lá bài tốt hơn.", "delta": 1, "reaction": [{"speaker": "cat", "en": "There you are. I wondered when you'd look up from the numbers.", "vi": "Bạn đây rồi. Tôi cứ tự hỏi bao giờ bạn mới ngẩng lên khỏi mấy con số."}]},
			{"id": "B", "en": "I was thinking about the next game.", "vi": "Tôi đang nghĩ về ván tiếp theo.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Of course. Just don't tell me tomorrow chose for you.", "vi": "Dĩ nhiên. Chỉ đừng bảo ngày mai đã chọn thay bạn."}]},
			{"id": "C", "en": "It's a card. Why are we still talking about it?", "vi": "Chỉ là một lá bài. Sao mình vẫn nói về nó?", "delta": -1, "reaction": [{"speaker": "cat", "en": "Because you said you'd leave it. I heard you. That's the irritating part.", "vi": "Vì bạn đã bảo sẽ để yên. Tôi nghe thấy. Phiền là ở chỗ đó."}]}
		]}
]
