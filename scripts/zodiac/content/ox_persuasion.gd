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
	{"speaker": "ox", "en": "Then set the promise down here. No need to carry it.", "vi": "Vậy đặt lời hứa xuống đây. Không cần gánh nó đâu."}
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
		{"en": "Buffalo lets his shoulders drop as the street grows quiet. He sets a small buffalo Emblem on the table and leaves his hand beside it.", "vi": "Sửu thả lỏng vai khi phố dần yên. Anh đặt Huy hiệu con trâu nhỏ lên bàn, để bàn tay cạnh đó."},
		{"en": "\"I don't want to measure us by how much we can bear. I'd rather know when we can ask each other to stop.\"", "vi": "\"Tôi không muốn đo mình bằng sức chịu đựng. Tôi muốn biết lúc nào ta có thể xin nhau dừng lại hơn.\""},
		{"en": "He nudges the Emblem toward you. \"Bring it on our day. We can start with a lighter load.\"", "vi": "Anh đẩy Huy hiệu về phía bạn. \"Đến ngày của mình thì mang theo. Ta có thể bắt đầu với gánh nhẹ hơn.\""}
	],
	"last_chance": {
		"id": "ox.last_chance.load",
		"prompt": [{"speaker": "ox", "en": "One last thing. Are you agreeing because you can, or because you think you must?", "vi": "Hỏi lần cuối nhé. Bạn đồng ý vì làm được, hay vì nghĩ mình buộc phải làm?"}],
		"answers": [
			{"id": "A", "en": "Because I choose to. Let me say what I can carry.", "vi": "Vì tôi tự chọn. Để tôi nói phần mình gánh được.", "recovery_success": true, "reaction": [{"speaker": "ox", "en": "Then we'll begin with that much.", "vi": "Vậy mình bắt đầu với chừng đó."}]},
			{"id": "B", "en": "I can't carry another promise today.", "vi": "Hôm nay tôi không gánh thêm lời hứa nào được.", "recovery_success": true, "reaction": [{"speaker": "ox", "en": "Good to know. Keep the chair, not the obligation.", "vi": "Biết vậy là tốt. Cứ giữ ghế, không cần giữ nghĩa vụ."}]},
			{"id": "C", "en": "Say the right answer and I'll repeat it.", "vi": "Nói đáp án đúng đi, tôi sẽ nhắc lại.", "recovery_success": false, "reaction": [{"speaker": "ox", "en": "Then there's nothing left to build on today.", "vi": "Vậy hôm nay không còn gì để làm tiếp nữa."}]}
		]},
	"special": []
}
const NODES := [
	{"id": "ox.t1.load", "zodiac": "ox", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "You've picked up more than you can carry. What do you put down?", "vi": "Bạn đã nhấc nhiều hơn sức mình gánh được. Bạn đặt gì xuống?"}],
		"answers": [
			{"id": "A", "en": "The part I can't carry honestly.", "vi": "Phần tôi thật sự không gánh nổi.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Better now than after it falls.", "vi": "Đặt bây giờ còn hơn đợi nó rơi."}]},
			{"id": "B", "en": "I'd ask which part is urgent.", "vi": "Tôi sẽ hỏi phần nào cần làm gấp.", "delta": 0, "reaction": [{"speaker": "ox", "en": "That's a place to start.", "vi": "Đó là chỗ để bắt đầu."}]},
			{"id": "C", "en": "Nothing. Someone will catch it.", "vi": "Không đặt gì. Sẽ có người đỡ.", "delta": -1, "reaction": [{"speaker": "ox", "en": "Have you asked that person?", "vi": "Bạn đã hỏi người đó chưa?"}]}
		]},
	{"id": "ox.t1.help", "zodiac": "ox", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "When do you ask for help?", "vi": "Khi nào bạn nhờ giúp đỡ?"}],
		"answers": [
			{"id": "A", "en": "Before the work becomes somebody else's emergency.", "vi": "Trước khi việc thành chuyện gấp của người khác.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Then they get a choice too.", "vi": "Vậy họ cũng được quyền chọn."}]},
			{"id": "B", "en": "When I know which part I need help with.", "vi": "Khi biết mình cần giúp phần nào.", "delta": 0, "reaction": [{"speaker": "ox", "en": "Say that part clearly.", "vi": "Nói rõ phần đó nhé."}]},
			{"id": "C", "en": "Never. Asking would make me weak.", "vi": "Không bao giờ. Nhờ giúp là yếu đuối.", "delta": -1, "reaction": [{"speaker": "ox", "en": "That sounds heavier than the work.", "vi": "Nghe còn nặng hơn cả công việc."}]}
		]},
	{"id": "ox.t1.endure", "zodiac": "ox", "content_tier": "1", "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "Does finishing mean it was the right load to take?", "vi": "Làm xong có nghĩa là đã nhận gánh đúng sức không?"}],
		"answers": [
			{"id": "A", "en": "No. I still need to learn what it cost.", "vi": "Không. Tôi vẫn cần hiểu cái giá đã trả.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Good. Finishing isn't the only measure.", "vi": "Tốt. Làm xong đâu phải thước đo duy nhất."}]},
			{"id": "B", "en": "At least the work is done.", "vi": "Ít ra việc đã xong.", "delta": 0, "reaction": [{"speaker": "ox", "en": "And you're still here to look at it.", "vi": "Và bạn vẫn ở đây để nhìn lại."}]},
			{"id": "C", "en": "Yes. If I survived, I should take more.", "vi": "Có. Chịu được thì nên nhận thêm.", "delta": -1, "reaction": [{"speaker": "ox", "en": "I wouldn't ask that of you.", "vi": "Tôi sẽ không yêu cầu bạn như vậy."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "I'll look at the actual settlement, not the preview.", "vi": "Tôi sẽ xem lần chốt thực tế, không tính bản xem trước."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "Then leave that promise here.", "vi": "Vậy để lời hứa đó ở đây thôi."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": LOAD_SMALL, "dialogue": [{"speaker": "ox", "en": "A lighter promise: no more than 60 PTS of final Phase 1 Deadwood penalty. The same settlement rule. Will you take that?", "vi": "Lời hứa nhẹ hơn nhé: phạt Bài rác cuối Hiệp 1 không quá 60 PTS. Vẫn cùng cách tính lúc chốt. Bạn nhận được không?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "ox", "en": "You brought the load within the limit we agreed. That was something you could carry.", "vi": "Bạn đã đưa gánh về trong mức mình thống nhất. Đó là phần bạn gánh được."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "ox", "en": "The final penalty went past our limit. Next time, name the load you can manage.", "vi": "Mức phạt cuối đã vượt giới hạn mình nhận. Lần tới hãy nói gánh bạn thật sự lo được."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "We'll see what you build on when the second Phase comes.", "vi": "Đến Hiệp 2 mình sẽ xem bạn làm tiếp từ đâu."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "No need to carry a yes you don't mean.", "vi": "Không cần gánh lời có mà bạn không thật lòng."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": FINISH_ANY, "dialogue": [{"speaker": "ox", "en": "One Extension in either Phase instead. That's a different deadline. Is it manageable?", "vi": "Đổi thành Nối một lần trong Hiệp nào cũng được. Hạn đã khác rồi. Bạn lo được chứ?"}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "ox", "en": "You finished the step we agreed on. We can rest that promise now.", "vi": "Bạn đã làm xong bước mình nhận. Giờ có thể đặt lời hứa đó xuống."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "ox", "en": "The step wasn't finished within the agreed Phase. I'd rather hear a smaller promise next time.", "vi": "Bước đó chưa xong trong Hiệp mình thống nhất. Lần tới tôi muốn nghe lời hứa nhỏ hơn."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "Your choice. We'll look for that physical card in the work.", "vi": "Bạn chọn nhé. Mình sẽ xem đúng lá đó đã vào việc chưa."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "ox", "en": "Then keep your hands free to choose.", "vi": "Vậy cứ để tay mình được tự chọn."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "ox", "en": "You found a place for the card before the first Phase ended. One thing set down.", "vi": "Bạn đã tìm chỗ cho lá bài trước khi Hiệp đầu kết thúc. Đặt xuống được một phần rồi."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "ox", "en": "That card didn't join a Meld within the promised Phase. The later work can't change that deadline.", "vi": "Lá đó chưa vào Phỏm trong Hiệp đã hứa. Việc làm sau không đổi được hạn đó."}]}
		}},
	{"id": "ox.t2.load_memory", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "ox.load", "promise_from": "ox.t1plus.load",
		"prompts": {
			"FULFILLED": [{"speaker": "ox", "en": "You kept the load within this promise: {target} What helped you set it down?", "vi": "Bạn đã giữ gánh trong lời hứa này: {target} Điều gì giúp bạn đặt nó xuống?"}],
			"BROKEN": [{"speaker": "ox", "en": "The load grew beyond this promise: {target} Where would you ask for room?", "vi": "Gánh đã vượt lời hứa này: {target} Bạn sẽ xin thêm khoảng ở đâu?"}],
			"REFUSED": [{"speaker": "ox", "en": "You wouldn't take this load: {target} I'm glad you told me before carrying it.", "vi": "Bạn không nhận gánh này: {target} Tôi mừng vì bạn đã nói trước khi gánh."}]
		},
		"answers": [
			{"id": "A", "en": "Make the limit clear before I take the work.", "vi": "Nói rõ giới hạn trước khi nhận việc.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Then we both know what needs doing.", "vi": "Vậy cả hai đều biết việc cần làm."}]},
			{"id": "B", "en": "Look at what the hand actually left me.", "vi": "Nhìn phần bài thật sự còn trên tay.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Hide the weight until someone else carries it.", "vi": "Giấu sức nặng đến khi người khác gánh.", "delta": -1, "reaction": [{"speaker": "ox", "en": "That only moves the burden without asking.", "vi": "Vậy chỉ chuyển gánh mà không hỏi."}]}
		]},
	{"id": "ox.t2.finish_memory", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "ox.finish", "promise_from": "ox.t1plus.finish",
		"prompts": {
			"FULFILLED": [{"speaker": "ox", "en": "You followed this step through: {target} Did the second half feel different?", "vi": "Bạn đã làm đến cùng bước này: {target} Nửa sau có khác không?"}],
			"BROKEN": [{"speaker": "ox", "en": "This step was left unfinished: {target} What could you commit to now?", "vi": "Bước này còn dang dở: {target} Giờ bạn cam kết được điều gì?"}],
			"REFUSED": [{"speaker": "ox", "en": "You said no to this step: {target} We can start from the answer you gave.", "vi": "Bạn đã từ chối bước này: {target} Mình có thể bắt đầu từ câu bạn trả lời."}]
		},
		"answers": [
			{"id": "A", "en": "The next step I can take without pretending I'm finished.", "vi": "Bước tiếp tôi làm được mà không giả vờ đã xong.", "delta": 1, "reaction": [{"speaker": "ox", "en": "That's work we can see.", "vi": "Đó là việc mình nhìn thấy được."}]},
			{"id": "B", "en": "I need time to see where it joins.", "vi": "Tôi cần thời gian xem nối vào đâu.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Whatever lets me stop explaining.", "vi": "Bất cứ gì giúp tôi thôi phải giải thích.", "delta": -1, "reaction": [{"speaker": "ox", "en": "A promise would only give you more to explain.", "vi": "Lời hứa chỉ khiến bạn phải giải thích thêm."}]}
		]},
	{"id": "ox.t2.card_memory", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "memory_key": "ox.card", "promise_from": "ox.t1plus.card",
		"prompts": {
			"FULFILLED": [{"speaker": "ox", "en": "You set {target} into a Meld in time. Why choose that part of the load?", "vi": "Bạn đã hạ {target} vào Phỏm đúng hạn. Sao chọn phần gánh đó?"}],
			"BROKEN": [{"speaker": "ox", "en": "{target} didn't find its place within Phase 1. What made it hard to put down?", "vi": "{target} chưa tìm được chỗ trong Hiệp 1. Điều gì khiến nó khó đặt xuống?"}],
			"REFUSED": [{"speaker": "ox", "en": "You didn't pick a card to promise away. What freedom did you need to keep?", "vi": "Bạn không chọn lá nào để hứa sẽ hạ. Bạn cần giữ tự do làm gì?"}]
		},
		"answers": [
			{"id": "A", "en": "To choose a useful place, not just lose the weight.", "vi": "Được tìm chỗ có ích, không chỉ bỏ sức nặng.", "delta": 1, "reaction": [{"speaker": "ox", "en": "I understand that difference.", "vi": "Tôi hiểu khác biệt đó."}]},
			{"id": "B", "en": "To wait for the cards around it.", "vi": "Được đợi những lá quanh nó.", "delta": 0, "reaction": []},
			{"id": "C", "en": "To keep the promise until the deadline stops mattering.", "vi": "Giữ lời hứa đến khi hạn không còn quan trọng.", "delta": -1, "reaction": [{"speaker": "ox", "en": "The deadline was part of your word.", "vi": "Hạn cũng là một phần lời bạn hứa."}]}
		]},
	{"id": "ox.t2.rest", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "Would you still sit beside me if I rested?", "vi": "Nếu tôi nghỉ, bạn vẫn ngồi cạnh chứ?"}],
		"answers": [
			{"id": "A", "en": "Yes. You don't owe me work for the chair.", "vi": "Có. Bạn không phải làm việc để được ngồi cùng.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Then I'll let my shoulders down.", "vi": "Vậy tôi thả lỏng vai nhé."}]},
			{"id": "B", "en": "For a while. We both need it.", "vi": "Một lúc thôi. Cả hai đều cần.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Only if you make it up to me later.", "vi": "Chỉ khi sau đó bạn bù lại cho tôi.", "delta": -1, "reaction": [{"speaker": "ox", "en": "Then that wouldn't be rest.", "vi": "Vậy đâu còn là nghỉ."}]}
		]},
	{"id": "ox.t2.slow", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "If I ask you to go slower, what do you hear?", "vi": "Nếu tôi xin bạn đi chậm lại, bạn nghe thấy điều gì?"}],
		"answers": [
			{"id": "A", "en": "A pace we can choose together.", "vi": "Nhịp mà mình có thể cùng chọn.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Then I can keep walking beside you.", "vi": "Vậy tôi còn đi bên bạn được."}]},
			{"id": "B", "en": "Something I should ask about.", "vi": "Điều tôi nên hỏi thêm.", "delta": 0, "reaction": []},
			{"id": "C", "en": "An excuse I need to push past.", "vi": "Cái cớ tôi cần vượt qua.", "delta": -1, "reaction": [{"speaker": "ox", "en": "I was telling you where I am.", "vi": "Tôi đang nói mình ở đâu."}]}
		]},
	{"id": "ox.t2.place", "zodiac": "ox", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION",
		"prompt": [{"speaker": "ox", "en": "What would you leave at this table when you go?", "vi": "Khi đi, bạn muốn để lại điều gì ở bàn này?"}],
		"answers": [
			{"id": "A", "en": "Room for us to come back without another obligation.", "vi": "Chỗ để mình quay lại mà không thêm nghĩa vụ.", "delta": 1, "reaction": [{"speaker": "ox", "en": "Then let's leave that room clear.", "vi": "Vậy mình chừa khoảng đó nhé."}]},
			{"id": "B", "en": "Work I can return to when I'm ready.", "vi": "Việc tôi quay lại làm được khi sẵn sàng.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Anything I don't want to carry myself.", "vi": "Mọi thứ tôi không muốn tự gánh.", "delta": -1, "reaction": [{"speaker": "ox", "en": "Ask before you leave it in somebody's hands.", "vi": "Hỏi trước khi để vào tay người khác nhé."}]}
		]}
]
