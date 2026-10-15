extends RefCounted
## Buffalo carries work, not a duty to suffer. A smaller load can be an honest one.
const LOAD := {
	"id": "ox.load", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "settlement_deadwood", "deal_phase": 1, "point_limit": 30,
	"en": "At Phase 1 settlement of the next Deal, keep the final loose-card Deadwood penalty at or below 30 PTS. Earlier Turn penalties are excluded; Black Ink profit does not offset this penalty.",
	"vi": "Khi chốt Hiệp 1 của Ván kế tiếp, giữ phạt Bài rác của số bài lẻ cuối Hiệp không quá 30 PTS. Không tính phạt các Lượt trước; lời Mực Đen không bù vào mức phạt này."
}
const LOAD_SMALL := {
	"id": "ox.load", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "settlement_deadwood", "deal_phase": 1, "point_limit": 60,
	"en": "At Phase 1 settlement of the next Deal, keep the final loose-card Deadwood penalty at or below 60 PTS. Earlier Turn penalties are excluded; Black Ink profit does not offset this penalty.",
	"vi": "Khi chốt Hiệp 1 của Ván kế tiếp, giữ phạt Bài rác của số bài lẻ cuối Hiệp không quá 60 PTS. Không tính phạt các Lượt trước; lời Mực Đen không bù vào mức phạt này."
}
const FINISH := {
	"id": "ox.finish", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "do_action", "action": "extension", "deal_phase": 2,
	"en": "Complete at least one Extension during Phase 2 of the next Deal. An Extension in Phase 1 does not count.",
	"vi": "Nối ít nhất một lần trong Hiệp 2 của Ván kế tiếp. Nối trong Hiệp 1 không được tính."
}
const FINISH_ANY := {
	"id": "ox.finish", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "do_action", "action": "extension", "deal_phase": 0,
	"en": "Complete at least one Extension during either Phase of the next Deal.",
	"vi": "Nối ít nhất một lần trong một trong hai Hiệp của Ván kế tiếp."
}
const CARD := {
	"id": "ox.card", "polarity": "DO", "interaction": "card_play", "target_kind": "CARD",
	"targeting": "ANY", "window": "NEXT_DEAL", "deal_phase": 1,
	"en": "Choose a card and commit it into a new Meld or Extension during Phase 1 of the next Deal. Discarding, swapping, or playing it in Phase 2 does not count.",
	"vi": "Chọn một lá rồi hạ vào Phỏm mới hoặc dùng để Nối trong Hiệp 1 của Ván kế tiếp. Bỏ, đổi hoặc hạ lá đó trong Hiệp 2 không được tính."
}
const COUNTER_REFUSE := {"delta": 0, "dialogue": [
	{"speaker": "player", "en": "Even the smaller load is more than I can promise.", "vi": "Ngay cả phần nhẹ hơn tôi cũng không hứa được."},
	{"speaker": "ox", "en": "Put it down. No point straining before the work even starts.", "vi": "Đặt xuống đi. Việc chưa bắt đầu, gắng quá làm gì."}
]}
const CONFIG := {
	"visit_limits": {"1": 3, "1+": 1, "2": 1},
	"progression": [{"from": 2, "to": 3, "kept": 3, "distinct": 2, "promises": ["ox.load", "ox.finish", "ox.card"]}],
	"memory_button": {"en": "Buffalo's burdens", "vi": "Gánh của Sửu"},
	"memory_title": {"en": "What Buffalo remembers", "vi": "Điều Sửu nhớ"},
	"memory_topics": {
		"ox.load": {"en": "A manageable load", "vi": "Gánh vừa sức"},
		"ox.finish": {"en": "Finish with help", "vi": "Cùng làm cho xong"},
		"ox.card": {"en": "Set it down", "vi": "Đặt xuống"}
	},
	"emblem_unlock": {"relationship_tier": 3, "promises_kept": 3, "promise_kinds": 2, "promises_refused": 1, "pleased_victories": 1},
	"private_scene": [
		{"en": "Buffalo rolls a stiff shoulder. He starts to lift the stacked chairs, then sits back down and leaves them for morning.", "vi": "Sửu xoay bên vai cứng. Anh định nhấc chồng ghế, rồi ngồi xuống, để việc ấy đến sáng."},
		{"en": "\"My father used to say: one more trip. I still hear him when there's nothing left to carry. Tonight I'm staying in this chair.\"", "vi": "\"Cha tôi hay bảo: thêm một chuyến nữa. Hết đồ để gánh rồi tôi vẫn nghe câu ấy. Tối nay tôi cứ ngồi ghế này.\""},
		{"en": "He pushes a buffalo Emblem toward you. \"Bring it on our day. And if I get up to find another job, tell me the tea's not finished.\"", "vi": "Anh đẩy Huy hiệu con trâu sang. \"Đến ngày của mình thì mang. Nếu tôi đứng dậy tìm việc nữa, nhắc là trà chưa uống xong.\""}
	],
	"last_chance": {
		"id": "ox.last_chance.load",
		"prompt": [{"speaker": "ox", "en": "Stop a moment. Is that your yes, or just the sound you make when someone's waiting?", "vi": "Dừng chút. Bạn muốn đồng ý thật, hay có người chờ là bạn cứ nói thế?"}],
		"answers": [
			{"id": "A", "en": "Because I choose to. Let me say what I can carry.", "vi": "Vì tôi tự chọn. Để tôi nói phần mình gánh được.", "recovery_success": true, "reaction": [{"speaker": "ox", "en": "All right. Show me where your hands fit.", "vi": "Được. Chỉ tôi chỗ bạn cầm vừa sức."}]},
			{"id": "B", "en": "I can't carry another promise today.", "vi": "Hôm nay tôi không gánh thêm lời hứa nào được.", "recovery_success": true, "reaction": [{"speaker": "ox", "en": "Then sit. A chair doesn't need you to earn it.", "vi": "Vậy ngồi đi. Cái ghế đâu cần bạn làm công mới cho ngồi."}]},
			{"id": "C", "en": "Say the right answer and I'll repeat it.", "vi": "Nói đáp án đúng đi, tôi sẽ nhắc lại.", "recovery_success": false, "reaction": [{"speaker": "ox", "en": "Words won't lift it. That's enough for today.", "vi": "Lời nói không nâng được đâu. Hôm nay vậy đủ rồi."}]}
		]},
	"special": []
}
const NODES := [
	{"id": "ox.t1.load", "zodiac": "ox", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "Two sacks. One bad shoulder. Do you tell anyone, or make the second trip anyway?", "vi": "Hai bao hàng. Một bên vai đau. Bạn báo ai, hay cứ đi chuyến thứ hai?"}],
		"answers": [
			{"id": "A", "en": "I'd say the second sack needs another pair of hands.", "vi": "Tôi sẽ nói bao thứ hai cần người khác phụ.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Good. The sack won't thank you for tearing yourself apart.", "vi": "Tốt. Bạn rách cả vai, bao hàng cũng chẳng cảm ơn."}]},
			{"id": "B", "en": "I'd ask which sack needs moving first.", "vi": "Tôi hỏi bao nào cần chuyển trước.", "delta": 0, "reaction": [{"speaker": "ox", "en": "Yes. Urgent and heavy aren't always the same thing.", "vi": "Ừ. Gấp với nặng không phải lúc nào cũng là một."}]},
			{"id": "C", "en": "I'd carry both. Someone will help if I fall.", "vi": "Tôi mang cả hai. Ngã rồi sẽ có người đỡ.", "delta": -1, "reaction": [{"speaker": "ox", "en": "Someone gets a sack and you to catch, then.", "vi": "Vậy người ta phải đỡ cả bao hàng lẫn bạn."}]}
		]},
	{"id": "ox.t1.help", "zodiac": "ox", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "Your end of the table's slipping. When do you call me over?", "vi": "Đầu bàn phía bạn sắp tuột tay. Bao giờ bạn gọi tôi?"}],
		"answers": [
			{"id": "A", "en": "Before the work becomes somebody else's emergency.", "vi": "Trước khi việc thành chuyện gấp của người khác.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Before it lands on a foot. That's the time.", "vi": "Trước khi nó đè lên chân. Đúng lúc đấy."}]},
			{"id": "B", "en": "When I know which part I need help with.", "vi": "Khi biết mình cần giúp phần nào.", "delta": 0, "reaction": [{"speaker": "ox", "en": "Which corner, how high. I can use that.", "vi": "Góc nào, nâng bao nhiêu. Nói vậy tôi giúp được."}]},
			{"id": "C", "en": "Never. Asking would make me weak.", "vi": "Không bao giờ. Nhờ giúp là yếu đuối.", "delta": -1, "reaction": [{"speaker": "ox", "en": "I've tried that. My shoulder still remembers.", "vi": "Tôi thử rồi. Vai tôi vẫn nhớ."}]}
		]},
	{"id": "ox.t1.endure", "zodiac": "ox", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "The work's done, but your hands won't stop shaking. A good day's work?", "vi": "Việc xong mà tay vẫn run không dừng. Thế là một ngày làm việc tốt à?"}],
		"answers": [
			{"id": "A", "en": "No. I still need to learn what it cost.", "vi": "Không. Tôi vẫn cần hiểu cái giá đã trả.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Yes. Count yourself among the things that need to last.", "vi": "Ừ. Nhớ tính cả bản thân vào những thứ cần giữ cho bền."}]},
			{"id": "B", "en": "At least the work is done.", "vi": "Ít ra việc đã xong.", "delta": 0, "reaction": [{"speaker": "ox", "en": "Done today. What about lifting a cup tomorrow?", "vi": "Hôm nay xong. Mai nâng nổi cốc không?"}]},
			{"id": "C", "en": "Yes. If I survived, I should take more.", "vi": "Có. Chịu được thì nên nhận thêm.", "delta": -1, "reaction": [{"speaker": "ox", "en": "No. I won't praise you into breaking yourself.", "vi": "Không. Tôi không khen để bạn tự làm mình gãy đâu."}]}
		]},
	{"id": "ox.t1plus.load", "zodiac": "ox", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "How do you keep a small burden from growing?", "vi": "Làm sao để gánh nhỏ không thành gánh lớn?"}],
		"answers": [
			{"id": "A", "en": "Give it a place before I keep carrying it.", "vi": "Tìm chỗ cho nó trước khi cứ gánh tiếp.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Watch what stays in my hand.", "vi": "Nhìn kỹ phần còn trên tay.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Stop looking at the weight.", "vi": "Thôi nhìn trọng lượng nữa.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "ox", "en": "Next Deal, keep the final Phase 1 Deadwood penalty at 30 PTS or less. Read the settlement rule first. Can you take that load?", "vi": "Ván tới giữ phạt Bài rác cuối Hiệp 1 từ 30 PTS trở xuống nhé. Đọc cách tính lúc chốt trước. Bạn nhận gánh đó được không?"}],
		"promise": LOAD,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "The final Phase 1 penalty. We'll weigh it when the Phase settles.", "vi": "Điểm phạt cuối Hiệp 1. Chốt Hiệp rồi mình cân."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "Then leave that promise here.", "vi": "Vậy để lời hứa đó ở đây thôi."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": LOAD_SMALL, "dialogue": [{"speaker": "ox", "en": "A lighter promise: no more than 60 PTS of final Phase 1 Deadwood penalty. The same settlement rule. Will you take that?", "vi": "Lời hứa nhẹ hơn nhé: phạt Bài rác cuối Hiệp 1 không quá 60 PTS. Vẫn cùng cách tính lúc chốt. Bạn nhận được không?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "ox", "en": "Within the limit. Put it down now. You don't need to prove it twice.", "vi": "Trong mức đã hẹn. Đặt xuống đi. Không cần chứng minh hai lần."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "ox", "en": "Too much at settlement. We agreed on a limit for a reason.", "vi": "Đến lúc chốt thì quá mức. Có lý do mình mới đặt giới hạn."}]}
		}},
	{"id": "ox.t1plus.finish", "zodiac": "ox", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "What gets you through the second half of the work?", "vi": "Điều gì giúp bạn làm qua nửa sau công việc?"}],
		"answers": [
			{"id": "A", "en": "Building on something that's already there.", "vi": "Làm tiếp từ điều đã có.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Taking the next step I can see.", "vi": "Làm bước tiếp theo tôi nhìn thấy.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Pretending the first half finished everything.", "vi": "Giả vờ nửa đầu đã giải quyết hết.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "ox", "en": "Then one Extension in Phase 2 of the next Deal. The second half, not an early substitute. Can you promise that?", "vi": "Vậy Nối một lần trong Hiệp 2 của Ván tới nhé. Nửa sau, không tính việc làm sớm thay thế. Bạn hứa được không?"}],
		"promise": FINISH,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "Phase 2. Keep enough in you for the second half.", "vi": "Hiệp 2 nhé. Chừa sức cho nửa sau."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "No need to carry a yes you don't mean.", "vi": "Không cần gánh lời có mà bạn không thật lòng."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": FINISH_ANY, "dialogue": [{"speaker": "ox", "en": "One Extension in either Phase instead. That's a different deadline. Is it manageable?", "vi": "Đổi thành Nối một lần trong Hiệp nào cũng được. Hạn đã khác rồi. Bạn lo được chứ?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "ox", "en": "Done. Leave it done. There's no extra prize for carrying it home.", "vi": "Xong. Để nó xong đi. Gánh về nhà cũng chẳng thêm thưởng."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "ox", "en": "That step missed its time. A smaller yes would have helped us both.", "vi": "Bước ấy trễ hẹn rồi. Hứa ít hơn thì cả hai đã dễ hơn."}]}
		}},
	{"id": "ox.t1plus.card", "zodiac": "ox", "content_tier": "1+", "relationship_required": 2, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "Is a card lighter when you find somewhere to put it?", "vi": "Tìm được chỗ hạ thì một lá bài có nhẹ hơn không?"}],
		"answers": [
			{"id": "A", "en": "Yes, if I really put it there.", "vi": "Có, nếu tôi thật sự hạ nó xuống.", "delta": 1, "reaction": []},
			{"id": "B", "en": "I need to see what it can join.", "vi": "Tôi cần xem nó ghép được với gì.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I'll just say it's been dealt with.", "vi": "Tôi cứ nói đã xử lý nó rồi.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "ox", "en": "Choose one of these three. Put it into a new Meld or Extension before Phase 1 of the next Deal ends. A discard isn't the same thing.", "vi": "Chọn một trong ba lá này. Hạ vào Phỏm mới hoặc dùng để Nối trước khi Hiệp 1 của Ván tới kết thúc. Bỏ đi không được tính như vậy."}],
		"promise": CARD, "initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "That card. Give it a place, not just a shove out of your hand.", "vi": "Lá đó. Tìm chỗ cho nó, không phải chỉ đẩy khỏi tay."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "Then keep your hands free to choose.", "vi": "Vậy cứ để tay mình được tự chọn."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "ox", "en": "In place before Phase 1 ended. Feel the difference in your hands?", "vi": "Vào chỗ trước khi hết Hiệp 1. Tay nhẹ hơn rồi chứ?"}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "ox", "en": "Still without its promised place when Phase 1 ended. Later is another job.", "vi": "Hết Hiệp 1 vẫn chưa vào chỗ đã hứa. Việc sau là việc khác."}]}
		}},
	{"id": "ox.t2.load_memory", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "ox.load", "promise_from": "ox.t1plus.load",
		"prompts": {
			"FULFILLED": [{"speaker": "ox", "en": "Within the limit: {target} Which part of the load was hardest to put down?", "vi": "Trong giới hạn: {target} Phần nào của gánh nặng khó đặt xuống nhất?"}],
			"BROKEN": [{"speaker": "ox", "en": "Past the limit: {target} Did you notice it growing, or only feel it at the end?", "vi": "Quá giới hạn: {target} Bạn thấy nó tăng dần, hay đến cuối mới nhận ra?"}],
			"REFUSED": [{"speaker": "ox", "en": "You wouldn't carry this: {target} Took me a long time to learn to say that.", "vi": "Bạn không nhận gánh này: {target} Tôi mất lâu lắm mới học nói được thế."}]
		},
		"answers": [
			{"id": "A", "en": "Say how much I can carry before I pick it up.", "vi": "Nói rõ mang nổi bao nhiêu trước khi nhấc.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Good. I'd rather make two trips than drop everything on the first.", "vi": "Tốt. Tôi thà đi hai chuyến còn hơn chuyến đầu rơi hết."}]},
			{"id": "B", "en": "Look at what was actually left in my hand.", "vi": "Xem tay tôi thực sự còn lại gì.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Hide the weight until someone else carries it.", "vi": "Giấu sức nặng đến khi người khác gánh.", "delta": -1, "reaction": [{"speaker": "ox", "en": "And now somebody else's shoulder hurts. Ask first.", "vi": "Thế là vai người khác đau. Hỏi trước đã."}]}
		]},
	{"id": "ox.t2.finish_memory", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "ox.finish", "promise_from": "ox.t1plus.finish",
		"prompts": {
			"FULFILLED": [{"speaker": "ox", "en": "You finished this step: {target} Enough left in you for a cup of tea?", "vi": "Bạn làm xong bước này: {target} Còn đủ sức uống chén trà không?"}],
			"BROKEN": [{"speaker": "ox", "en": "This part's unfinished: {target} No, don't pick up another promise yet. Tell me about this one.", "vi": "Phần này chưa xong: {target} Khoan, đừng nhận lời hứa khác vội. Kể tôi nghe phần này."}],
			"REFUSED": [{"speaker": "ox", "en": "You said no here: {target} I hope you didn't spend the whole Deal feeling you should have said yes.", "vi": "Bạn từ chối ở đây: {target} Mong là bạn không dành cả Ván để nghĩ mình lẽ ra phải đồng ý."}]
		},
		"answers": [
			{"id": "A", "en": "I'd promise one step I can take, not the whole road.", "vi": "Tôi hứa một bước mình đi nổi, không hứa cả đường.", "delta": 1, "reaction": [{"speaker": "ox", "en": "One sound step. That's how a long job gets done.", "vi": "Một bước chắc chân. Việc dài cũng xong từ đó."}]},
			{"id": "B", "en": "I need a moment to see where I can help.", "vi": "Cho tôi chút thời gian xem giúp được chỗ nào.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Whatever lets me stop explaining.", "vi": "Bất cứ gì giúp tôi thôi phải giải thích.", "delta": -1, "reaction": [{"speaker": "ox", "en": "Then don't use a promise to put the conversation down.", "vi": "Vậy đừng dùng lời hứa để trút cho xong cuộc nói chuyện."}]}
		]},
	{"id": "ox.t2.card_memory", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "ox.card", "promise_from": "ox.t1plus.card",
		"prompts": {
			"FULFILLED": [{"speaker": "ox", "en": "You found a place for {target} in time. Did you feel your hand get lighter?", "vi": "Bạn tìm chỗ cho {target} kịp hẹn. Có thấy tay nhẹ đi không?"}],
			"BROKEN": [{"speaker": "ox", "en": "{target} missed its place in Phase 1. What were you carrying it toward?", "vi": "{target} chưa vào chỗ trong Hiệp 1. Bạn định giữ nó để chờ điều gì?"}],
			"REFUSED": [{"speaker": "ox", "en": "You didn't promise a card. Sensible to feel the weight before you say you'll lift it.", "vi": "Bạn không hứa lá nào. Biết cân sức trước khi nhận nâng là tốt."}]
		},
		"answers": [
			{"id": "A", "en": "I wanted to use it, not just get it out of my hand.", "vi": "Tôi muốn dùng nó, không chỉ đẩy khỏi tay.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Yes. Putting something down isn't the same as dumping it.", "vi": "Ừ. Đặt xuống khác với quẳng đi."}]},
			{"id": "B", "en": "I needed the other cards around it first.", "vi": "Tôi cần những lá xung quanh nó trước đã.", "delta": 0, "reaction": []},
			{"id": "C", "en": "To keep the promise until the deadline stops mattering.", "vi": "Giữ lời hứa đến khi hạn không còn quan trọng.", "delta": -1, "reaction": [{"speaker": "ox", "en": "The bell was part of the job. We both heard it.", "vi": "Giờ hẹn cũng là một phần việc. Cả hai đều nghe mà."}]}
		]},
	{"id": "ox.t2.rest", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "I haven't done a useful thing for ten minutes. You don't mind?", "vi": "Mười phút rồi tôi chẳng làm gì có ích. Bạn không thấy phiền à?"}],
		"answers": [
			{"id": "A", "en": "Yes. You don't owe me work for the chair.", "vi": "Có. Bạn không phải làm việc để được ngồi cùng.", "delta": 1, "reaction": [{"speaker": "ox", "en": "All right. I'll try another ten.", "vi": "Được. Tôi thử thêm mười phút nữa."}]},
			{"id": "B", "en": "For a while. We both need it.", "vi": "Một lúc thôi. Cả hai đều cần.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Only if you make it up to me later.", "vi": "Chỉ khi sau đó bạn bù lại cho tôi.", "delta": -1, "reaction": [{"speaker": "ox", "en": "That's a loan with a chair attached.", "vi": "Thế là cho vay kèm cái ghế."}]}
		]},
	{"id": "ox.t2.slow", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "Walk slower with me today. I keep wanting to apologize for asking.", "vi": "Hôm nay đi chậm với tôi nhé. Cứ nhờ là tôi lại muốn xin lỗi."}],
		"answers": [
			{"id": "A", "en": "You don't need to apologize. We'll find a pace together.", "vi": "Không cần xin lỗi. Mình tìm nhịp đi cùng nhau.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Good. There's a tree on this road I've never had time to look at.", "vi": "Tốt. Đường này có cái cây mà tôi chưa từng có thời gian ngắm."}]},
			{"id": "B", "en": "I'd want to know why you needed to slow down.", "vi": "Tôi muốn biết vì sao bạn cần chậm lại.", "delta": 0, "reaction": []},
			{"id": "C", "en": "An excuse I need to push past.", "vi": "Cái cớ tôi cần vượt qua.", "delta": -1, "reaction": [{"speaker": "ox", "en": "I told you I was tired. I wasn't asking to be tested.", "vi": "Tôi nói mình mệt. Không phải xin bạn thử sức."}]}
		]},
	{"id": "ox.t2.place", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "Before we go... can we leave tomorrow's work until tomorrow?", "vi": "Trước khi về... mình để việc ngày mai đến mai được không?"}],
		"answers": [
			{"id": "A", "en": "Room for us to come back without another obligation.", "vi": "Chỗ để mình quay lại mà không thêm nghĩa vụ.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Good. My shoulders had started lifting it already.", "vi": "Tốt. Vai tôi đã bắt đầu gánh nó rồi."}]},
			{"id": "B", "en": "Work I can return to when I'm ready.", "vi": "Việc tôi quay lại làm được khi sẵn sàng.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Anything I don't want to carry myself.", "vi": "Mọi thứ tôi không muốn tự gánh.", "delta": -1, "reaction": [{"speaker": "ox", "en": "Ask whose hands they'll land in.", "vi": "Hỏi xem nó rơi vào tay ai đã."}]}
		]}
]
