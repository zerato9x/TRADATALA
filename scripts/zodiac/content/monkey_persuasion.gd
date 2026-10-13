extends RefCounted
## Curiosity with consent: Monkey wants a real attempt, not an audience.
const VARIETY := {
	"id": "monkey.variety", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "action_variety", "deal_phase": 0,
	"en": "Earn positive points from at least one new Meld and one Extension during the next Deal, in either order.",
	"vi": "Ghi điểm dương từ ít nhất một Phỏm mới và một lần Nối trong Ván kế tiếp, theo thứ tự tùy ý."
}
const EXTENSION := {
	"id": "monkey.extension", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "do_action", "action": "extension", "deal_phase": 0,
	"en": "Complete at least one Extension during either Phase of the next Deal.",
	"vi": "Nối ít nhất một lần trong một trong hai Hiệp của Ván kế tiếp."
}
const PICK := {
	"id": "monkey.pick", "polarity": "DO", "interaction": "card_play", "target_kind": "CARD",
	"targeting": "ANY", "window": "NEXT_DEAL",
	"en": "Play your selected card in a new Meld or Extension during the next Deal. Discarding or swapping it does not count.",
	"vi": "Hạ lá đã chọn vào Phỏm mới hoặc dùng nó để Nối trong Ván kế tiếp. Bỏ hoặc đổi lá đó không được tính."
}
const COUNTER_REFUSE := {"delta": 0, "dialogue": [
	{"speaker": "player", "en": "That doesn't work for me either.", "vi": "Việc đó tôi cũng không nhận được."},
	{"speaker": "monkey", "en": "Then no bet. We can still talk.", "vi": "Vậy không cược. Mình vẫn nói chuyện được mà."}
]}
const CONFIG := {
	"visit_limits": {"1": 3, "1+": 1, "2": 1},
	"progression": [{"from": 2, "to": 3, "kept": 3, "distinct": 2,
		"promises": ["monkey.variety", "monkey.extension", "monkey.pick"]}],
	"memory_button": {"en": "Monkey's experiments", "vi": "Thử nghiệm của Thân"},
	"memory_title": {"en": "What Monkey remembers", "vi": "Điều Thân nhớ"},
	"memory_topics": {
		"monkey.variety": {"en": "Change it up", "vi": "Thử cách khác"},
		"monkey.extension": {"en": "One more step", "vi": "Thêm một bước"},
		"monkey.pick": {"en": "Your pick", "vi": "Lá bạn chọn"}
	},
	"emblem_unlock": {"relationship_tier": 3, "promises_kept": 3, "promise_kinds": 2, "promises_refused": 1, "pleased_victories": 1},
	"private_scene": [
		{"en": "Monkey rolls a bottle cap across the table, then catches it before it reaches your glass. For once, he waits for you to speak.", "vi": "Thân lăn nắp chai trên bàn rồi chặn lại trước khi nó chạm ly của bạn. Lần này, anh đợi bạn lên tiếng."},
		{"en": "\"I like trying things with you. Even when you tell me to stop. Especially then, maybe.\"", "vi": "\"Tôi thích thử những điều mới cùng bạn. Kể cả lúc bạn bảo tôi dừng. Có khi chính lúc đó nữa.\""},
		{"en": "He leaves a small monkey Emblem beside the cap. \"Bring this next time. We'll find something neither of us has tried.\"", "vi": "Anh đặt Huy hiệu con khỉ nhỏ cạnh nắp chai. \"Lần tới mang theo nhé. Mình sẽ tìm việc mà cả hai chưa thử.\""}
	],
	"last_chance": {
		"id": "monkey.last_chance.stop",
		"prompt": [{"speaker": "monkey", "en": "Am I playing with you, or just making you sit through it?", "vi": "Tôi đang chơi cùng bạn, hay chỉ bắt bạn ngồi chịu trận?"}],
		"answers": [
			{"id": "A", "en": "With me. But let me choose what I try.", "vi": "Chơi cùng tôi. Nhưng để tôi chọn việc mình thử.", "recovery_success": true,
				"reaction": [{"speaker": "monkey", "en": "Fair. Your turn to set the dare.", "vi": "Được. Đến lượt bạn ra thử thách."}]},
			{"id": "B", "en": "I need a quieter game today.", "vi": "Hôm nay tôi cần một cuộc chơi yên hơn.", "recovery_success": true,
				"reaction": [{"speaker": "monkey", "en": "I can turn it down. You could've said.", "vi": "Tôi bớt ồn được mà. Bạn cứ nói."}]},
			{"id": "C", "en": "Just tell me what answer wins.", "vi": "Cứ nói đáp án nào giúp tôi thắng đi.", "recovery_success": false,
				"reaction": [{"speaker": "monkey", "en": "Then we're done playing for today.", "vi": "Vậy hôm nay chơi đến đây thôi."}]}
		]},
	"special": []
}
const NODES := [
	{"id": "monkey.t1.trick", "zodiac": "monkey", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "Want to see a trick, or work out how it goes?", "vi": "Muốn xem một trò, hay tìm hiểu nó làm thế nào?"}],
		"answers": [
			{"id": "A", "en": "Let me try after you show me.", "vi": "Bạn làm mẫu rồi để tôi thử.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Now it's a game.", "vi": "Vậy mới thành cuộc chơi chứ."}]},
			{"id": "B", "en": "I'll watch this one.", "vi": "Trò này tôi xem thôi.", "delta": 0, "reaction": [{"speaker": "monkey", "en": "Front row, then.", "vi": "Vậy ngồi hàng đầu nhé."}]},
			{"id": "C", "en": "Only if there's something in it for me.", "vi": "Chỉ xem nếu tôi được lợi gì đó.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "You charge admission to your own eyes?", "vi": "Bạn thu vé cả đôi mắt mình à?"}]}
		]},
	{"id": "monkey.t1.bored", "zodiac": "monkey", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "Same move worked twice. What now?", "vi": "Một nước đã hiệu quả hai lần. Giờ làm gì?"}],
		"answers": [
			{"id": "A", "en": "Try another way. See what I missed.", "vi": "Thử cách khác. Xem tôi đã bỏ sót gì.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "There you are.", "vi": "Đúng rồi đấy."}]},
			{"id": "B", "en": "Keep it until it stops working.", "vi": "Cứ dùng đến khi hết hiệu quả.", "delta": 0, "reaction": [{"speaker": "monkey", "en": "Useful. A little sleepy.", "vi": "Có ích. Hơi buồn ngủ."}]},
			{"id": "C", "en": "Make everyone else do it too.", "vi": "Bắt mọi người cũng làm như vậy.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "That sounds like work you found for them.", "vi": "Nghe như bạn kiếm việc cho người ta vậy."}]}
		]},
	{"id": "monkey.t1.stop", "zodiac": "monkey", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "I went too far with a joke. What would you say?", "vi": "Tôi đùa quá trớn. Bạn sẽ nói gì?"}],
		"answers": [
			{"id": "A", "en": "Stop. That one isn't fun for me.", "vi": "Dừng lại. Trò đó không vui với tôi.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Good. I need to hear where the edge is.", "vi": "Được. Tôi cần biết giới hạn ở đâu."}]},
			{"id": "B", "en": "I'd leave for a bit.", "vi": "Tôi sẽ đi chỗ khác một lúc.", "delta": 0, "reaction": [{"speaker": "monkey", "en": "Leave me a clue before you go.", "vi": "Trước khi đi, cho tôi biết một chút nhé."}]},
			{"id": "C", "en": "Laugh, then make you pay later.", "vi": "Cười trước, rồi bắt bạn trả giá sau.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "That's a trap, not a joke.", "vi": "Đó là cái bẫy, đâu phải trò đùa."}]}
		]},
	{"id": "monkey.t1plus.variety", "zodiac": "monkey", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "What could you learn from changing your next play?", "vi": "Đổi nước chơi tiếp theo thì bạn có thể học được gì?"}],
		"answers": [
			{"id": "A", "en": "Whether another route works too.", "vi": "Xem đường khác có hiệu quả không.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Depends on the cards I get.", "vi": "Còn tùy bài tôi nhận được.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Nothing. I've already got the best move.", "vi": "Chẳng có gì. Tôi đã có nước hay nhất rồi.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "monkey", "en": "Try both a scoring Meld and a scoring Extension next Deal. Either order. Or say no.", "vi": "Ván tới thử cả Phỏm ghi điểm lẫn Nối ghi điểm nhé. Thứ tự tùy bạn. Không nhận cũng được."}],
		"promise": VARIETY,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "Two ways through. I'll ask how it went when you return.", "vi": "Hai cách đi. Khi bạn quay lại, tôi sẽ hỏi kết quả."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "Then keep your options. No promise.", "vi": "Vậy cứ để ngỏ lựa chọn. Không hứa gì cả."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": EXTENSION, "dialogue": [{"speaker": "monkey", "en": "Smaller experiment: one Extension, either Phase. Will you take that?", "vi": "Thử nhỏ hơn nhé: Nối một lần, Hiệp nào cũng được. Bạn nhận việc đó chứ?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "monkey", "en": "You tried what we agreed. What surprised you?", "vi": "Bạn đã thử đúng điều mình thống nhất. Điều gì làm bạn bất ngờ?"}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "monkey", "en": "We agreed on the experiment. You didn't finish it.", "vi": "Mình đã thống nhất phép thử. Bạn chưa làm xong."}]}
		}},
	{"id": "monkey.t1plus.extension", "zodiac": "monkey", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "A Meld is down. Finished, or a place to start?", "vi": "Phỏm đã hạ. Xong rồi, hay mới là chỗ bắt đầu?"}],
		"answers": [
			{"id": "A", "en": "A place to start. I'll look for one more card.", "vi": "Chỗ bắt đầu. Tôi sẽ tìm thêm một lá.", "delta": 1, "reaction": []},
			{"id": "B", "en": "I'll see what turns up.", "vi": "Để xem có lá nào đến.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Finished. Don't ask me to think twice.", "vi": "Xong rồi. Đừng bắt tôi nghĩ lại.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "monkey", "en": "Then one Extension next Deal. Both Phases are open. Want to try?", "vi": "Vậy Nối một lần trong Ván tới nhé. Cả hai Hiệp đều được. Muốn thử không?"}],
		"promise": EXTENSION,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "One more step. Not just a preview.", "vi": "Thêm một bước. Phải làm thật nhé."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "Fine. Watching is allowed too.", "vi": "Được. Chỉ xem cũng được mà."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": VARIETY, "dialogue": [{"speaker": "monkey", "en": "Make it a different experiment: score with both a new Meld and an Extension. Only if you mean it.", "vi": "Đổi phép thử nhé: ghi điểm bằng cả Phỏm mới lẫn Nối. Chỉ nhận nếu bạn thật sự muốn."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "monkey", "en": "You followed the idea through. I like that.", "vi": "Bạn theo ý tưởng đến cùng. Tôi thích vậy."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "monkey", "en": "The idea stayed an idea. Next time, say you only want to watch.", "vi": "Ý tưởng vẫn chỉ là ý tưởng. Lần tới cứ nói bạn chỉ muốn xem."}]}
		}},
	{"id": "monkey.t1plus.pick", "zodiac": "monkey", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "Three cards. Who gets to decide which one matters?", "vi": "Ba lá bài. Ai quyết định lá nào đáng thử?"}],
		"answers": [
			{"id": "A", "en": "Me, if I'm the one trying it.", "vi": "Tôi, nếu tôi là người thử.", "delta": 1, "reaction": []},
			{"id": "B", "en": "You can suggest one.", "vi": "Bạn có thể gợi ý một lá.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Pick for me. I'll blame you if it fails.", "vi": "Chọn hộ đi. Hỏng thì tôi đổ lỗi cho bạn.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "monkey", "en": "Pick one of these three and put it into a Meld next Deal. A new Meld or an Extension. Your choice.", "vi": "Chọn một trong ba lá này rồi hạ vào Phỏm trong Ván tới. Phỏm mới hoặc Nối đều được. Bạn chọn."}],
		"promise": PICK, "initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "Your card, your attempt. I'll remember which one.", "vi": "Lá của bạn, lần thử của bạn. Tôi sẽ nhớ lá nào."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "No pressure. They're still your cards.", "vi": "Không ép đâu. Chúng vẫn là bài của bạn."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "monkey", "en": "You found a place for your pick. Show me that route again sometime.", "vi": "Bạn tìm được chỗ cho lá đã chọn. Khi khác chỉ tôi cách đó nữa nhé."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "monkey", "en": "Your pick never joined a Meld. I wanted the attempt you promised.", "vi": "Lá đã chọn chưa vào Phỏm nào. Tôi chờ lần thử bạn đã hứa."}]}
		}},
	{"id": "monkey.t2.variety_memory", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "monkey.variety", "promise_from": "monkey.t1plus.variety",
		"prompts": {
			"FULFILLED": [{"speaker": "monkey", "en": "You did it: {target} What made you change course?", "vi": "Bạn đã làm được: {target} Điều gì khiến bạn đổi cách?"}],
			"BROKEN": [{"speaker": "monkey", "en": "Our unfinished experiment: {target} What got in the way?", "vi": "Phép thử còn dang dở: {target} Điều gì đã cản bạn?"}],
			"REFUSED": [{"speaker": "monkey", "en": "You passed on this: {target} Was it the game, or the promise?", "vi": "Bạn không nhận việc này: {target} Vì cuộc chơi, hay vì lời hứa?"}]
		},
		"answers": [
			{"id": "A", "en": "I wanted to choose with the cards in front of me.", "vi": "Tôi muốn chọn dựa trên bài trước mặt.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Good. Look, then decide.", "vi": "Được. Nhìn kỹ rồi quyết định."}]},
			{"id": "B", "en": "I was weighing the risk.", "vi": "Tôi đang cân nhắc rủi ro.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Your rules are the only thing that matters.", "vi": "Chỉ luật của bạn mới quan trọng.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Where are you in that answer?", "vi": "Trong câu trả lời đó, bạn ở đâu?"}]}
		]},
	{"id": "monkey.t2.extension_memory", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "monkey.extension", "promise_from": "monkey.t1plus.extension",
		"prompts": {
			"FULFILLED": [{"speaker": "monkey", "en": "You followed this through: {target} Worth trying?", "vi": "Bạn đã làm đến cùng: {target} Có đáng thử không?"}],
			"BROKEN": [{"speaker": "monkey", "en": "We left this unfinished: {target} Still interested?", "vi": "Mình chưa làm xong việc này: {target} Bạn còn muốn thử không?"}],
			"REFUSED": [{"speaker": "monkey", "en": "You said no to this: {target} What would you try instead?", "vi": "Bạn đã từ chối việc này: {target} Thay vào đó bạn muốn thử gì?"}]
		},
		"answers": [
			{"id": "A", "en": "Something I can learn from, even if it goes badly.", "vi": "Việc giúp tôi học được điều gì, kể cả khi thất bại.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "That's the part I came for.", "vi": "Tôi đến vì phần đó đấy."}]},
			{"id": "B", "en": "Let me think about it.", "vi": "Để tôi nghĩ thêm.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Something you can do for me.", "vi": "Việc mà bạn làm hộ tôi được.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Then you'd miss the interesting bit.", "vi": "Vậy bạn bỏ lỡ phần thú vị rồi."}]}
		]},
	{"id": "monkey.t2.pick_memory", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "monkey.pick", "promise_from": "monkey.t1plus.pick",
		"prompts": {
			"FULFILLED": [{"speaker": "monkey", "en": "You gave {target} a place in a Meld. Why that card?", "vi": "Bạn đã cho {target} vào Phỏm. Sao lại chọn lá đó?"}],
			"BROKEN": [{"speaker": "monkey", "en": "{target} never made it into a Meld. What happened to your plan?", "vi": "{target} chưa vào Phỏm nào. Kế hoạch của bạn đã gặp chuyện gì?"}],
			"REFUSED": [{"speaker": "monkey", "en": "You left the three-card experiment open. What would make a choice yours?", "vi": "Bạn để ngỏ phép thử ba lá. Điều gì khiến lựa chọn thật sự là của bạn?"}]
		},
		"answers": [
			{"id": "A", "en": "Seeing a possibility and deciding to try it.", "vi": "Nhìn thấy cơ hội rồi quyết định thử.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Keep that part. Even when the cards disagree.", "vi": "Giữ lấy điều đó. Kể cả khi bài không chiều bạn."}]},
			{"id": "B", "en": "A little luck helps.", "vi": "Có chút may mắn thì dễ hơn.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Having someone else take the blame.", "vi": "Có người khác chịu lỗi.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "That's not a choice. That's an escape hatch.", "vi": "Đó không phải lựa chọn. Đó là đường thoát trách nhiệm."}]}
		]},
	{"id": "monkey.t2.quiet", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "If I stop making noise, will you still sit here?", "vi": "Nếu tôi thôi làm ồn, bạn vẫn ngồi đây chứ?"}],
		"answers": [
			{"id": "A", "en": "Yes. You don't have to earn the chair with a trick.", "vi": "Có. Bạn đâu phải diễn trò để được ngồi cùng.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Good. My hands could use a rest.", "vi": "Tốt. Tay tôi cũng cần nghỉ."}]},
			{"id": "B", "en": "For a while.", "vi": "Một lúc thôi.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Then what would I get out of it?", "vi": "Vậy tôi được gì?", "delta": -1, "reaction": [{"speaker": "monkey", "en": "A chair. And me.", "vi": "Một cái ghế. Và tôi."}]}
		]},
	{"id": "monkey.t2.miss", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "What if we try something and both look foolish?", "vi": "Nếu mình thử một việc rồi cả hai trông ngốc nghếch thì sao?"}],
		"answers": [
			{"id": "A", "en": "Laugh with me. Then help me work it out.", "vi": "Cười cùng tôi. Rồi giúp tôi tìm cách.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "That's a second attempt I can get behind.", "vi": "Lần thử thứ hai như vậy thì tôi theo."}]},
			{"id": "B", "en": "We'll choose something easier.", "vi": "Mình sẽ chọn việc dễ hơn.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I'll pretend it was your idea.", "vi": "Tôi sẽ giả vờ đó là ý của bạn.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Then I'd be trying alone.", "vi": "Vậy hóa ra chỉ mình tôi thử."}]}
		]},
	{"id": "monkey.t2.return", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "Same table, same faces. Can that still be fresh?", "vi": "Vẫn bàn này, vẫn những gương mặt này. Có còn mới mẻ được không?"}],
		"answers": [
			{"id": "A", "en": "We can notice something we missed yesterday.", "vi": "Mình có thể nhận ra điều hôm qua bỏ sót.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Then keep me a seat.", "vi": "Vậy giữ cho tôi một chỗ nhé."}]},
			{"id": "B", "en": "Depends on the day.", "vi": "Còn tùy ngày.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Only if you become someone else.", "vi": "Chỉ khi bạn thành người khác.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "I'd rather bring something new as myself.", "vi": "Tôi muốn mang điều mới đến mà vẫn là mình."}]}
		]}
]
