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
	{"speaker": "monkey", "en": "No bet, then. I'll survive the suspense. Probably.", "vi": "Vậy khỏi cược. Tôi chịu nổi tò mò mà. Chắc thế."}
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
		{"en": "Monkey balances a bottle cap on his knuckle. It falls. He starts to turn it into a trick, then lets it lie.", "vi": "Thân giữ nắp chai trên khớp ngón tay. Nó rơi. Anh định biến cú vụng về thành trò diễn, rồi lại để mặc."},
		{"en": "\"My brother used to clap even when I dropped everything. Terrible audience. I miss that.\"", "vi": "\"Hồi nhỏ tôi đánh rơi hết đồ, anh tôi vẫn vỗ tay. Khán giả dở tệ. Tôi nhớ chuyện ấy.\""},
		{"en": "He slides you a monkey Emblem. \"Bring it next time. If I drop it, you're allowed to laugh. Just stay for the next try.\"", "vi": "Anh đẩy Huy hiệu con khỉ sang. \"Lần sau mang theo nhé. Tôi làm rơi thì cứ cười. Chỉ cần ở lại xem tôi thử tiếp.\""}
	],
	"last_chance": {
		"id": "monkey.last_chance.stop",
		"prompt": [{"speaker": "monkey", "en": "Wait. Are we both having fun, or have I been doing a very loud solo?", "vi": "Khoan. Cả hai đang vui, hay nãy giờ chỉ có tôi độc diễn om sòm?"}],
		"answers": [
			{"id": "A", "en": "With me. But let me choose what I try.", "vi": "Chơi cùng tôi. Nhưng để tôi chọn việc mình thử.", "recovery_success": true,
				"reaction": [{"speaker": "monkey", "en": "Deal. I surrender the imaginary microphone.", "vi": "Được. Xin trao lại chiếc micro tưởng tượng."}]},
			{"id": "B", "en": "I need a quieter game today.", "vi": "Hôm nay tôi cần một cuộc chơi yên hơn.", "recovery_success": true,
				"reaction": [{"speaker": "monkey", "en": "Right. Smaller tricks. Or no tricks. I can manage... no tricks.", "vi": "Rồi. Trò nhỏ thôi. Hoặc thôi diễn. Tôi làm được... thôi diễn."}]},
			{"id": "C", "en": "Just tell me what answer wins.", "vi": "Cứ nói đáp án nào giúp tôi thắng đi.", "recovery_success": false,
				"reaction": [{"speaker": "monkey", "en": "Oh. I thought we were playing together. Let's stop here.", "vi": "Ồ. Tôi tưởng mình đang chơi cùng nhau. Dừng ở đây nhé."}]}
		]},
	"special": []
}
const NODES := [
	{"id": "monkey.t1.trick", "zodiac": "monkey", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "See this cap? Want the trick, or the embarrassing secret behind it?", "vi": "Thấy nắp chai này không? Muốn xem trò diễn, hay biết bí mật đáng xấu hổ của nó?"}],
		"answers": [
			{"id": "A", "en": "Let me try after you show me.", "vi": "Bạn làm mẫu rồi để tôi thử.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Yes! A volunteer with terrible judgment. My favorite.", "vi": "Tuyệt! Một tình nguyện viên liều lĩnh. Đúng gu tôi."}]},
			{"id": "B", "en": "I'll watch this one.", "vi": "Trò này tôi xem thôi.", "delta": 0, "reaction": [{"speaker": "monkey", "en": "Front row. Splash zone. You've been warned.", "vi": "Hàng đầu nhé. Có thể bị văng nước. Báo trước rồi đấy."}]},
			{"id": "C", "en": "Only if there's something in it for me.", "vi": "Chỉ xem nếu tôi được lợi gì đó.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Astonishment. No refunds.", "vi": "Kinh ngạc. Không hoàn tiền."}]}
		]},
	{"id": "monkey.t1.bored", "zodiac": "monkey", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "Same move. Twice. We could do it again... or make an interesting mistake.", "vi": "Cùng một nước. Hai lần. Làm nữa cũng được... hoặc sai một lần cho thú vị."}],
		"answers": [
			{"id": "A", "en": "Try another way. See what I missed.", "vi": "Thử cách khác. Xem tôi đã bỏ sót gì.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "That's the dangerous little thought I was hoping for.", "vi": "Đúng cái ý nghĩ liều lĩnh nho nhỏ tôi đang chờ."}]},
			{"id": "B", "en": "Keep it until it stops working.", "vi": "Cứ dùng đến khi hết hiệu quả.", "delta": 0, "reaction": [{"speaker": "monkey", "en": "Efficient. So is a doorstop.", "vi": "Hiệu quả đấy. Cục chặn cửa cũng hiệu quả."}]},
			{"id": "C", "en": "Make everyone else do it too.", "vi": "Bắt mọi người cũng làm như vậy.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "You've invented a job. I was trying to avoid those.", "vi": "Bạn vừa phát minh ra công việc. Tôi đang cố tránh thứ ấy."}]}
		]},
	{"id": "monkey.t1.stop", "zodiac": "monkey", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "My joke lands badly. Everyone laughs except you. Do you tell me?", "vi": "Tôi đùa quá trớn. Ai cũng cười, trừ bạn. Bạn có nói không?"}],
		"answers": [
			{"id": "A", "en": "Stop. That one isn't fun for me.", "vi": "Dừng lại. Trò đó không vui với tôi.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Please do. A laugh can hide a lot. I'm not always good at telling.", "vi": "Nhớ nói nhé. Tiếng cười che được nhiều thứ. Tôi không phải lúc nào cũng nhận ra."}]},
			{"id": "B", "en": "I'd leave for a bit.", "vi": "Tôi sẽ đi chỗ khác một lúc.", "delta": 0, "reaction": [{"speaker": "monkey", "en": "Fair. One word before you go would help me stop being an idiot.", "vi": "Cũng được. Trước khi đi nói một câu, giúp tôi bớt ngốc với."}]},
			{"id": "C", "en": "Laugh, then make you pay later.", "vi": "Cười trước, rồi bắt bạn trả giá sau.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Ouch. I'd rather hear stop than wait for the revenge act.", "vi": "Ái. Tôi thà nghe bảo dừng còn hơn chờ màn trả đũa."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "Meld and Extend. Two acts! I'll save my applause until you've done both.", "vi": "Tạo rồi Nối Phỏm. Hai tiết mục! Xong cả hai tôi mới vỗ tay."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "Then keep your options. No promise.", "vi": "Vậy cứ để ngỏ lựa chọn. Không hứa gì cả."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": EXTENSION, "dialogue": [{"speaker": "monkey", "en": "Smaller experiment: one Extension, either Phase. Will you take that?", "vi": "Thử nhỏ hơn nhé: Nối một lần, Hiệp nào cũng được. Bạn nhận việc đó chứ?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "monkey", "en": "You did both! All right, which one nearly went wrong?", "vi": "Bạn làm được cả hai! Rồi, đoạn nào suýt hỏng?"}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "monkey", "en": "We didn't finish the experiment. No pretending the rehearsal was the show.", "vi": "Mình chưa làm xong thử nghiệm. Đừng tính buổi tập thành buổi diễn nhé."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "One Extension. I shall attempt the impossible: not interrupting.", "vi": "Một lần Nối Phỏm. Tôi sẽ thử việc bất khả thi: không chen ngang."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "monkey", "en": "Fine. Watching is allowed too.", "vi": "Được. Chỉ xem cũng được mà."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": VARIETY, "dialogue": [{"speaker": "monkey", "en": "Make it a different experiment: score with both a new Meld and an Extension. Only if you mean it.", "vi": "Đổi phép thử nhé: ghi điểm bằng cả Phỏm mới lẫn Nối. Chỉ nhận nếu bạn thật sự muốn."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "monkey", "en": "You took the extra step. That's where the good surprises hide.", "vi": "Bạn đi thêm một bước thật. Bất ngờ hay thường nằm ở đó."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "monkey", "en": "Still on the drawing board, then. Next time, tell me before I book the band.", "vi": "Vậy vẫn còn trên giấy. Lần sau báo tôi trước khi tôi thuê cả ban nhạc nhé."}]}
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
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "monkey", "en": "Ha! You found a way in for that card. I didn't see it at first.", "vi": "Ha! Bạn tìm được chỗ cho lá đó. Lúc đầu tôi chưa thấy đường ấy."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "monkey", "en": "Your chosen card never got its turn. I was watching for it, you know.", "vi": "Lá bạn chọn chưa được vào Phỏm. Tôi có chờ xem đấy."}]}
		}},
	{"id": "monkey.t2.variety_memory", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "monkey.variety", "promise_from": "monkey.t1plus.variety",
		"prompts": {
			"FULFILLED": [{"speaker": "monkey", "en": "Experiment completed: {target} Be honest. Which bit nearly made you abandon the whole thing?", "vi": "Thử nghiệm hoàn tất: {target} Nói thật nhé. Đoạn nào suýt khiến bạn bỏ cuộc?"}],
			"BROKEN": [{"speaker": "monkey", "en": "The experiment we didn't finish: {target} Bad hand, bad idea, or both?", "vi": "Thử nghiệm mình chưa xong: {target} Bài dở, ý tưởng dở, hay cả hai?"}],
			"REFUSED": [{"speaker": "monkey", "en": "You turned this down: {target} I keep wondering what you'd have tried without my big mouth involved.", "vi": "Bạn từ chối việc này: {target} Tôi cứ tò mò nếu không có cái miệng ồn ào của tôi, bạn sẽ thử gì."}]
		},
		"answers": [
			{"id": "A", "en": "I wanted to choose with the cards in front of me.", "vi": "Tôi muốn chọn dựa trên bài trước mặt.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Look first, leap second. I've been getting those backwards for years.", "vi": "Nhìn trước, nhảy sau. Tôi làm ngược bao năm rồi."}]},
			{"id": "B", "en": "I was weighing the risk.", "vi": "Tôi đang cân nhắc rủi ro.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Your rules are the only thing that matters.", "vi": "Chỉ luật của bạn mới quan trọng.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "That sounds like my answer wearing your hat. Where's yours?", "vi": "Nghe như câu trả lời của tôi đội mũ của bạn. Câu của bạn đâu?"}]}
		]},
	{"id": "monkey.t2.extension_memory", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "monkey.extension", "promise_from": "monkey.t1plus.extension",
		"prompts": {
			"FULFILLED": [{"speaker": "monkey", "en": "You finished this: {target} I'd call for an encore, but tell me if once was enough.", "vi": "Bạn làm xong việc này: {target} Tôi định đòi diễn lại, nhưng một lần đủ rồi thì cứ nói."}],
			"BROKEN": [{"speaker": "monkey", "en": "Still an unfinished trick: {target} Want to talk about the bit where it fell apart?", "vi": "Vẫn là trò diễn dở dang: {target} Muốn kể đoạn nó hỏng không?"}],
			"REFUSED": [{"speaker": "monkey", "en": "You said no to this: {target} Fair. What would have made you lean forward instead?", "vi": "Bạn từ chối việc này: {target} Cũng được. Thế điều gì mới khiến bạn háo hức muốn thử?"}]
		},
		"answers": [
			{"id": "A", "en": "Something I can learn from, even if it goes badly.", "vi": "Việc giúp tôi học được điều gì, kể cả khi thất bại.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Exactly! A spectacular flop can still teach us where the floor is.", "vi": "Chính xác! Ngã oạch vẫn giúp mình biết sàn ở đâu."}]},
			{"id": "B", "en": "Let me think about it.", "vi": "Để tôi nghĩ thêm.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Something you can do for me.", "vi": "Việc mà bạn làm hộ tôi được.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Then you'd only get the applause. The fun part happens before that.", "vi": "Thế bạn chỉ nhận tiếng vỗ tay thôi. Phần vui xảy ra trước đó cơ."}]}
		]},
	{"id": "monkey.t2.pick_memory", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"memory_key": "monkey.pick", "promise_from": "monkey.t1plus.pick",
		"prompts": {
			"FULFILLED": [{"speaker": "monkey", "en": "You got {target} into a Meld. I thought you'd pick a different card. What did you see?", "vi": "Bạn đưa {target} vào Phỏm. Tôi tưởng bạn chọn lá khác. Bạn thấy gì ở nó?"}],
			"BROKEN": [{"speaker": "monkey", "en": "No Meld for {target}. Was the trick harder from your side of the table?", "vi": "{target} chưa vào Phỏm. Nhìn từ phía bạn, trò này khó hơn à?"}],
			"REFUSED": [{"speaker": "monkey", "en": "Three cards and you said no. Were none of them interesting, or was I pushing too hard?", "vi": "Ba lá mà bạn từ chối. Không lá nào hay, hay tôi thúc quá?"}]
		},
		"answers": [
			{"id": "A", "en": "Seeing a possibility and deciding to try it.", "vi": "Nhìn thấy cơ hội rồi quyết định thử.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Keep doing that. The cards can heckle; they don't get to write your act.", "vi": "Cứ thế nhé. Bài có thể phá đám; không được viết hộ tiết mục của bạn."}]},
			{"id": "B", "en": "A little luck helps.", "vi": "Có chút may mắn thì dễ hơn.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Having someone else take the blame.", "vi": "Có người khác chịu lỗi.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Ah, the disappearing-responsibility trick. Never liked that one.", "vi": "À, trò làm biến mất trách nhiệm. Tôi chẳng thích trò ấy."}]}
		]},
	{"id": "monkey.t2.quiet", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "I tried being quiet yesterday. Lasted almost a minute. Would you have stayed for the second?", "vi": "Hôm qua tôi thử im. Gần được một phút. Bạn có ở lại phút thứ hai không?"}],
		"answers": [
			{"id": "A", "en": "Yes. You don't have to earn the chair with a trick.", "vi": "Có. Bạn đâu phải diễn trò để được ngồi cùng.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Good. Because I haven't got a second act today.", "vi": "May quá. Hôm nay tôi hết tiết mục thứ hai rồi."}]},
			{"id": "B", "en": "For a while.", "vi": "Một lúc thôi.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Then what would I get out of it?", "vi": "Vậy tôi được gì?", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Me. Admittedly, without the special effects.", "vi": "Tôi. Phải nhận là không kèm hiệu ứng đặc biệt."}]}
		]},
	{"id": "monkey.t2.miss", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "Suppose the trick fails. In public. Do we bow, run, or pretend we meant it?", "vi": "Giả sử trò diễn hỏng. Trước đám đông. Mình cúi chào, chạy, hay giả vờ cố ý?"}],
		"answers": [
			{"id": "A", "en": "Laugh with me. Then help me work it out.", "vi": "Cười cùng tôi. Rồi giúp tôi tìm cách.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "Bow first, then fix it. Excellent. We're professionals now.", "vi": "Cúi chào trước, sửa sau. Tuyệt. Giờ mình chuyên nghiệp rồi."}]},
			{"id": "B", "en": "We'll choose something easier.", "vi": "Mình sẽ chọn việc dễ hơn.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I'll pretend it was your idea.", "vi": "Tôi sẽ giả vờ đó là ý của bạn.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "Right. And I'd have to laugh so nobody noticed it hurt.", "vi": "Ừ. Rồi tôi phải cười để chẳng ai biết mình buồn."}]}
		]},
	{"id": "monkey.t2.return", "zodiac": "monkey", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "monkey", "en": "Same table tomorrow. Same old me. Still worth showing up?", "vi": "Mai vẫn bàn này. Vẫn tôi. Còn đáng ghé không?"}],
		"answers": [
			{"id": "A", "en": "We can notice something we missed yesterday.", "vi": "Mình có thể nhận ra điều hôm qua bỏ sót.", "delta": 1, "reaction": [{"speaker": "monkey", "en": "I was hoping you'd say that. There are scratches here I've never investigated.", "vi": "Tôi mong bạn nói vậy. Còn mấy vết xước ở đây tôi chưa điều tra."}]},
			{"id": "B", "en": "Depends on the day.", "vi": "Còn tùy ngày.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Only if you become someone else.", "vi": "Chỉ khi bạn thành người khác.", "delta": -1, "reaction": [{"speaker": "monkey", "en": "I've tried being other people. The hats never fit.", "vi": "Tôi thử làm người khác rồi. Mũ chẳng cái nào vừa."}]}
		]}
]
