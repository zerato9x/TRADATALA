extends RefCounted
## Rooster values a usable answer and a finished job. No personality scores.
const EARLY_SCORE := {
	"id": "rooster.early_score", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "early_score", "deal_phase": 1,
	"en": "Earn positive points from a Meld or Extension in Phase 1 before the first mandatory discard of the next Deal.",
	"vi": "Ghi điểm dương từ Phỏm hoặc Nối trong Hiệp 1, trước lần bỏ bắt buộc đầu tiên của Ván kế tiếp."
}
const FIRST_MELD := {
	"id": "rooster.first_meld", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "do_action", "action": "new_meld", "deal_phase": 1,
	"en": "Play at least one new Meld during Phase 1 of the next Deal.",
	"vi": "Hạ ít nhất một Phỏm mới trong Hiệp 1 của Ván kế tiếp."
}
const EXTENSION := {
	"id": "rooster.extension", "polarity": "DO", "interaction": "deal_action", "target_kind": "ACTION",
	"window": "NEXT_DEAL", "condition": "do_action", "action": "extension", "deal_phase": 0,
	"en": "Complete at least one Extension during either Phase of the next Deal.",
	"vi": "Nối ít nhất một lần trong một trong hai Hiệp của Ván kế tiếp."
}
const COUNTER_REFUSE := {"delta": 0, "dialogue": [
	{"speaker": "player", "en": "No. I can't commit to that either.", "vi": "Không. Việc đó tôi cũng không cam kết được."},
	{"speaker": "rooster", "en": "Good. An empty line is better than a false entry.", "vi": "Được. Để trống một dòng còn hơn ghi sai."}
]}
const CONFIG := {
	"visit_limits": {"1": 3, "1+": 1, "2": 1},
	"progression": [{"from": 2, "to": 3, "kept": 3, "distinct": 2,
		"promises": ["rooster.early_score", "rooster.first_meld", "rooster.extension"]}],
	"memory_button": {"en": "Rooster's ledger", "vi": "Sổ của Dậu"},
	"memory_title": {"en": "What Rooster remembers", "vi": "Điều Dậu nhớ"},
	"memory_topics": {
		"rooster.early_score": {"en": "Before the bell", "vi": "Trước tiếng chuông"},
		"rooster.first_meld": {"en": "The first job", "vi": "Việc đầu tiên"},
		"rooster.extension": {"en": "Finish the work", "vi": "Làm cho xong"}
	},
	# Existing earned scene eligibility remains valid; this is the new story route.
	"emblem_unlock": {"relationship_tier": 3, "promises_kept": 3, "promise_kinds": 2, "promises_refused": 1, "pleased_victories": 1},
	"last_chance": {
		"id": "rooster.last_chance.plain_answer",
		"prompt": [{"speaker": "rooster", "en": "Last question. When you say you'll come, should I put the kettle on?", "vi": "Câu cuối. Khi bạn bảo sẽ đến, tôi có nên đun nước chờ không?"}],
		"answers": [
			{"id": "A", "en": "Only when I actually promise. Ask me plainly.", "vi": "Chỉ khi tôi thật sự hứa. Cứ hỏi thẳng đi.", "recovery_success": true,
				"reaction": [{"speaker": "rooster", "en": "Good. I can work with that. I can't work with guessing.", "vi": "Được. Biết rõ thì tôi thu xếp được. Đoán mò thì chịu."}]},
			{"id": "B", "en": "Of course. Whatever gets this over with.", "vi": "Dĩ nhiên. Sao cho xong chuyện là được.", "recovery_success": false,
				"reaction": [{"speaker": "rooster", "en": "We're finished, then.", "vi": "Vậy xong rồi đấy."}]},
			{"id": "C", "en": "No. I can't commit to anything today.", "vi": "Không. Hôm nay tôi không thể cam kết gì cả.", "recovery_success": true,
				"reaction": [{"speaker": "rooster", "en": "Right. I'll put the kettle away.", "vi": "Rồi. Tôi cất ấm đây."}]}
		]},
	"special": []
}

const NODES := [
	{"id": "rooster.t1.waiting", "zodiac": "rooster", "content_tier": "1", "kind": "QUESTION", "topic": "time",
		"prompt": [{"speaker": "rooster", "en": "You're late. Should I have kept the chair?", "vi": "Bạn đến muộn. Tôi có nên giữ ghế không?"}],
		"answers": [
			{"id": "A", "en": "No. I didn't ask you to wait.", "vi": "Không. Tôi đâu có nhờ bạn đợi.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "No, you didn't. Sit. I kept it anyway.", "vi": "Ừ, bạn không nhờ. Ngồi đi. Tôi vẫn giữ đấy."}]},
			{"id": "B", "en": "I hoped you would.", "vi": "Tôi đã mong bạn giữ.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Next time, ask. I don't charge for the chair.", "vi": "Lần sau cứ hỏi. Tôi có thu tiền ghế đâu."}]},
			{"id": "C", "en": "Obviously. You knew I was coming.", "vi": "Dĩ nhiên. Bạn biết tôi sẽ đến mà.", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "I knew what you said. That's what I had to go on.", "vi": "Tôi chỉ biết lời bạn nói. Tôi dựa vào đó mà chờ."}]}
		]},
	{"id": "rooster.t1.no", "zodiac": "rooster", "content_tier": "1", "kind": "QUESTION", "topic": "boundaries",
		"prompt": [{"speaker": "rooster", "en": "A neighbor needs a hand before dawn. You can't go. When do you tell them?", "vi": "Hàng xóm nhờ phụ trước lúc trời sáng. Bạn không đi được. Bao giờ bạn báo?"}],
		"answers": [
			{"id": "A", "en": "No. While they still have time to ask someone else.", "vi": "Không. Khi họ vẫn còn thời gian nhờ người khác.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Before they've hauled everything outside. Yes.", "vi": "Trước khi người ta khuân hết đồ ra ngoài. Đúng."}]},
			{"id": "B", "en": "I'll see what I can do.", "vi": "Để tôi xem làm được gì.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Lovely. Shall they wait until lunch to find out?", "vi": "Hay thật. Để họ chờ đến trưa mới biết nhé?"}]},
			{"id": "C", "en": "Yes. I'll work something out later.", "vi": "Có. Rồi tính cách sau.", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "And now they'll set out two cups instead of asking someone else.", "vi": "Thế là họ bày hai cái cốc, thay vì tìm người khác giúp."}]}
		]},
	{"id": "rooster.t1.finished", "zodiac": "rooster", "content_tier": "1", "kind": "QUESTION", "topic": "work",
		"prompt": [{"speaker": "rooster", "en": "Everyone wants credit for opening the stall. Who stays to sweep?", "vi": "Ai cũng muốn được khen vì mở hàng sớm. Còn ai ở lại quét dọn?"}],
		"answers": [
			{"id": "A", "en": "Me, if closing up was my job.", "vi": "Tôi, nếu việc đóng hàng là phần của tôi.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Good. A broom won't applaud you. Do it anyway.", "vi": "Được. Cái chổi chẳng vỗ tay khen đâu. Vẫn phải làm."}]},
			{"id": "B", "en": "I'll open. Someone else can close.", "vi": "Tôi mở hàng. Người khác lo đóng cửa.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "As long as that someone knows.", "vi": "Miễn người đó biết phần của mình."}]},
			{"id": "C", "en": "Depends who's watching.", "vi": "Còn tùy ai đang nhìn.", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "Dust doesn't leave with the audience.", "vi": "Khách về rồi bụi vẫn còn đấy."}]}
		]},
	{"id": "rooster.t1plus.before_bell", "zodiac": "rooster", "content_tier": "1+", "kind": "QUESTION", "topic": "time",
		"prompt": [{"speaker": "rooster", "en": "You keep saying there's time. What will you do before the first discard?", "vi": "Bạn cứ nói còn thời gian. Trước lần bỏ đầu tiên, bạn sẽ làm gì?"}],
		"answers": [
			{"id": "A", "en": "Look for a scoring play before I let a card go.", "vi": "Tìm nước ghi điểm trước khi bỏ một lá.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Depends on my opening hand.", "vi": "Còn tùy bài đầu ván.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Relax. I'll make it up later.", "vi": "Cứ thong thả. Sau đó tôi gỡ lại.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "Then say what you're committing to.", "vi": "Vậy nói rõ bạn cam kết điều gì."}],
		"promise": EARLY_SCORE,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "Before the first discard. I promise.", "vi": "Trước lần bỏ đầu tiên. Tôi hứa."}, {"speaker": "rooster", "en": "Before the first discard. I'll keep that line open.", "vi": "Trước lần bỏ bắt buộc đầu tiên. Tôi để dòng này chờ bạn."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "I can't promise that opening.", "vi": "Tôi không hứa được nước mở đầu đó."}, {"speaker": "rooster", "en": "Sensible. Even I can't put tomorrow's cards in order tonight.", "vi": "Biết vậy là tốt. Tôi cũng chẳng xếp được bài ngày mai từ tối nay."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": FIRST_MELD,
				"dialogue": [{"speaker": "player", "en": "Give me Phase 1 to make a Meld.", "vi": "Cho tôi cả Hiệp 1 để hạ Phỏm."}, {"speaker": "rooster", "en": "One new Meld by the end of Phase 1. Is that your word?", "vi": "Một Phỏm mới trước khi Hiệp 1 kết thúc. Bạn hứa vậy chứ?"}]},
			"COUNTER_ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "Yes. One new Meld in Phase 1.", "vi": "Ừ. Một Phỏm mới trong Hiệp 1."}, {"speaker": "rooster", "en": "Different deadline. Same responsibility.", "vi": "Hạn khác. Trách nhiệm vẫn vậy."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "rooster", "en": "On time. Tea's still hot.", "vi": "Đúng hẹn. Trà vẫn còn nóng."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "rooster", "en": "I waited for the play you promised. Next time, tell me no while I can still use it.", "vi": "Tôi đã chờ nước đi bạn hứa. Lần sau, cứ từ chối khi tôi còn kịp thu xếp."}]}
		}},
	{"id": "rooster.t1plus.first_job", "zodiac": "rooster", "content_tier": "1+", "kind": "QUESTION", "topic": "work",
		"prompt": [{"speaker": "rooster", "en": "The first job is yours. Are you waiting for someone else to start it?", "vi": "Việc đầu tiên là của bạn. Bạn còn đợi ai bắt đầu hộ à?"}],
		"answers": [
			{"id": "A", "en": "No. I'll put something of my own on the table.", "vi": "Không. Tôi sẽ tự hạ bài của mình.", "delta": 1, "reaction": []},
			{"id": "B", "en": "I'll start when I can make it work.", "vi": "Tôi sẽ bắt đầu khi có cách làm được.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Someone usually does.", "vi": "Thường sẽ có người làm hộ.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "A new Meld in Phase 1. Can you commit to that?", "vi": "Một Phỏm mới trong Hiệp 1. Bạn cam kết được không?"}],
		"promise": FIRST_MELD,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "One new Meld in Phase 1.", "vi": "Một Phỏm mới trong Hiệp 1."}, {"speaker": "rooster", "en": "That's the job.", "vi": "Đó là việc cần làm."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "I won't commit before I see the hand.", "vi": "Chưa thấy bài thì tôi chưa cam kết."}, {"speaker": "rooster", "en": "Fair. You can still play it without promising me.", "vi": "Hợp lý. Không hứa với tôi thì bạn vẫn hạ được."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": EXTENSION,
				"dialogue": [{"speaker": "player", "en": "What if I finish a Meld with an Extension instead?", "vi": "Thay vào đó tôi Nối để làm xong một Phỏm thì sao?"}, {"speaker": "rooster", "en": "One Extension in either Phase. Confirm it if you mean it.", "vi": "Một lần Nối trong một trong hai Hiệp. Muốn hứa thì xác nhận đi."}]},
			"COUNTER_ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "One Extension before the Deal ends.", "vi": "Một lần Nối trước khi hết Ván."}, {"speaker": "rooster", "en": "Agreed.", "vi": "Đồng ý."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "rooster", "en": "Done. Put the pencil down and have a drink.", "vi": "Xong. Đặt bút xuống, uống nước đi."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "rooster", "en": "I left a line for that job. It's still empty.", "vi": "Tôi chừa một dòng cho việc ấy. Giờ vẫn trống."}]}
		}},
	{"id": "rooster.t1plus.finish_work", "zodiac": "rooster", "content_tier": "1+", "kind": "QUESTION", "topic": "follow_through",
		"prompt": [{"speaker": "rooster", "en": "A Meld is on the table. Do you leave the next piece for somebody else?", "vi": "Phỏm đã nằm trên bàn. Bạn để phần tiếp theo cho người khác à?"}],
		"answers": [
			{"id": "A", "en": "If I have the piece, I'll add it.", "vi": "Có lá phù hợp thì tôi Nối.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Depends what I need it for.", "vi": "Còn tùy tôi cần lá đó làm gì.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I've already done enough.", "vi": "Tôi đã làm đủ rồi.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "One Extension next Deal. Both Phases count. Your choice.", "vi": "Một lần Nối trong Ván kế. Cả hai Hiệp đều tính. Bạn chọn."}],
		"promise": EXTENSION,
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "I'll complete an Extension.", "vi": "Tôi sẽ Nối một lần."}, {"speaker": "rooster", "en": "I'll look for the work, then.", "vi": "Vậy tôi sẽ nhìn việc bạn làm."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "Not a promise I can make today.", "vi": "Hôm nay tôi không hứa được việc đó."}, {"speaker": "rooster", "en": "Good to know before I count on it.", "vi": "Biết trước còn hơn trông chờ rồi mới biết."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": FIRST_MELD,
				"dialogue": [{"speaker": "player", "en": "Let me make a new Meld in Phase 1 instead.", "vi": "Cho tôi hạ Phỏm mới trong Hiệp 1 thay vào đó."}, {"speaker": "rooster", "en": "One new Meld in Phase 1. I'll hold you to that if you accept.", "vi": "Một Phỏm mới trong Hiệp 1. Đồng ý thì tôi sẽ nhớ lời đó."}]},
			"COUNTER_ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "That's my commitment.", "vi": "Tôi cam kết vậy."}, {"speaker": "rooster", "en": "Then we're clear.", "vi": "Vậy đã rõ rồi."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "rooster", "en": "Finished without a reminder. You've saved me a whole speech.", "vi": "Xong mà không cần nhắc. Bạn giúp tôi khỏi phải nói cả bài rồi."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "rooster", "en": "I can move a chair. I can't move the end of a Deal.", "vi": "Tôi dời ghế được. Không dời được lúc hết Ván."}]}
		}},
	{"id": "rooster.t2.bell_memory", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "time",
		"memory_key": "rooster.early_score",
		"prompts": {
			"FULFILLED": [{"speaker": "rooster", "en": "Before the first discard, just as you said. Do you always make people put their reminders away?", "vi": "Trước lần bỏ đầu tiên, đúng lời bạn. Bạn luôn khiến người ta khỏi cần nhắc thế à?"}],
			"BROKEN": [{"speaker": "rooster", "en": "You promised points before the first discard. The discard came first. What happened?", "vi": "Bạn hứa ghi điểm trước lần bỏ đầu tiên. Nhưng lại bỏ trước. Chuyện gì vậy?"}],
			"REFUSED": [{"speaker": "rooster", "en": "You said no to the early score. Saved me some waiting. Was it hard to say?", "vi": "Bạn từ chối ghi điểm sớm. Đỡ cho tôi một lần chờ. Nói ra có khó không?"}]},
		"answers": [
			{"id": "A", "en": "I chose the answer. I own what followed.", "vi": "Tôi đã chọn câu trả lời. Chuyện sau đó là trách nhiệm của tôi.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Right. No erasing the old entry. We start a new line.", "vi": "Rồi. Không tẩy dòng cũ. Mình viết dòng mới."}]},
			{"id": "B", "en": "The hand mattered more than I expected.", "vi": "Bài trên tay ảnh hưởng nhiều hơn tôi nghĩ.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Cards rarely read the schedule. Account for that.", "vi": "Bài có đọc lịch đâu. Phải tính cả chuyện ấy."}]},
			{"id": "C", "en": "It's only a game. Why keep track?", "vi": "Chỉ là một ván bài. Nhớ làm gì?", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "The points are a game. Waiting for someone isn't.", "vi": "Điểm số là trò chơi. Chờ một người thì không."}]}
		]},
	{"id": "rooster.t2.meld_memory", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "work",
		"memory_key": "rooster.first_meld",
		"prompts": {
			"FULFILLED": [{"speaker": "rooster", "en": "You put down a new Meld in Phase 1, just as agreed. Quiet work. Do you prefer it that way?", "vi": "Bạn hạ Phỏm mới trong Hiệp 1, đúng thỏa thuận. Làm lặng lẽ. Bạn thích vậy à?"}],
			"BROKEN": [{"speaker": "rooster", "en": "Phase 1 ended without the new Meld you promised. What should I count on next time?", "vi": "Hiệp 1 hết mà không có Phỏm mới bạn đã hứa. Lần sau tôi nên trông vào điều gì?"}],
			"REFUSED": [{"speaker": "rooster", "en": "You said no to the first job. I remember. Was saying it difficult?", "vi": "Bạn từ chối việc đầu tiên. Tôi nhớ. Nói vậy có khó không?"}]},
		"answers": [
			{"id": "A", "en": "Count on me saying what I can actually do.", "vi": "Cứ trông vào việc tôi nói đúng điều mình làm được.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Good. I can stop planning for two versions of you.", "vi": "Được. Tôi khỏi phải tính sẵn hai kiểu câu trả lời của bạn."}]},
			{"id": "B", "en": "Ask me again when the cards are dealt.", "vi": "Chia bài rồi hỏi tôi lại.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Fair. Until then, I won't count it done.", "vi": "Hợp lý. Trước lúc đó tôi chưa tính là xong."}]},
			{"id": "C", "en": "You could lower your expectations.", "vi": "Bạn bớt trông chờ đi là được.", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "They're yours. I wrote them down exactly.", "vi": "Đó là điều bạn hứa. Tôi ghi nguyên văn."}]}
		]},
	{"id": "rooster.t2.extension_memory", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "follow_through",
		"memory_key": "rooster.extension",
		"prompts": {
			"FULFILLED": [{"speaker": "rooster", "en": "You finished the Extension you promised. Nobody had to remind you. Is that how you work?", "vi": "Bạn Nối như đã hứa. Không ai phải nhắc. Bạn vẫn làm việc như vậy à?"}],
			"BROKEN": [{"speaker": "rooster", "en": "Both Phases passed without the Extension you promised. Were you waiting for another chance?", "vi": "Cả hai Hiệp hết mà bạn chưa Nối như đã hứa. Bạn còn đợi cơ hội khác à?"}],
			"REFUSED": [{"speaker": "rooster", "en": "You wouldn't promise an Extension. You left me a clear answer. Do you always do that?", "vi": "Bạn không hứa Nối. Bạn đã trả lời rõ ràng. Lúc nào cũng vậy à?"}]},
		"answers": [
			{"id": "A", "en": "I'm trying to leave fewer loose ends.", "vi": "Tôi đang cố bớt để việc dở dang.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Yes. Someone always has to shut the door after everyone else.", "vi": "Ừ. Lúc mọi người về hết, vẫn phải có ai đóng cửa."}]},
			{"id": "B", "en": "Depends on the day.", "vi": "Còn tùy hôm.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Tell me which sort of day before you promise.", "vi": "Trước khi hứa thì nói tôi biết hôm đó thế nào."}]},
			{"id": "C", "en": "You got an answer. Isn't that enough?", "vi": "Bạn có câu trả lời rồi. Chưa đủ sao?", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "When the answer's no, yes.", "vi": "Nếu câu trả lời là không thì đủ."}]}
		]},
	{"id": "rooster.t2.trust_clock", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "trust",
		"prompt": [{"speaker": "direction", "en": "Rooster turns his watch face down, then reaches to straighten it. He catches himself.", "vi": "Dậu úp đồng hồ xuống, rồi lại đưa tay định chỉnh cho ngay. Anh khựng lại."}, {"speaker": "rooster", "en": "I nearly asked what time you'd leave. Habit. Would you like the early deadline again?", "vi": "Suýt nữa tôi hỏi mấy giờ bạn về. Quen miệng. Bạn có muốn nhận lại hạn sớm không?"}],
		"answers": [
			{"id": "A", "en": "Ask me. Trust doesn't make the choice for me.", "vi": "Cứ hỏi tôi. Tin nhau đâu có chọn hộ nhau.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Let's see the terms.", "vi": "Xem điều kiện đã.", "delta": 0, "reaction": []},
			{"id": "C", "en": "You trust me, so stop checking.", "vi": "Tin tôi thì đừng kiểm tra nữa.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "Before the first discard, as before. Say no if you need to. The tea won't disappear.", "vi": "Vẫn trước lần bỏ bắt buộc đầu tiên. Cần thì cứ từ chối. Trà có chạy mất đâu."}],
		"promise_from": "rooster.t1plus.before_bell"},
	{"id": "rooster.t2.own_table", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "company",
		"prompt": [{"speaker": "rooster", "en": "I saved you a chair. Don't look so alarmed; it doesn't come with a job. What are you planning?", "vi": "Tôi giữ ghế cho bạn. Đừng nhìn thế; ngồi không phải làm công đâu. Bạn tính chơi thế nào?"}],
		"answers": [
			{"id": "A", "en": "My own play. I'll tell you if I can't make it.", "vi": "Nước bài của tôi. Không làm được thì tôi sẽ nói.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Whatever the hand allows.", "vi": "Bài cho phép gì thì làm nấy.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Something impressive enough to keep the chair.", "vi": "Thứ đủ ấn tượng để bạn giữ ghế.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "Sit because you want to. Promise the first Meld only if you mean it.", "vi": "Muốn thì ngồi. Còn Phỏm đầu tiên, chắc lời hãy hứa."}],
		"promise_from": "rooster.t1plus.first_job"},
	{"id": "rooster.t2.stay_after", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "company",
		"prompt": [{"speaker": "rooster", "en": "The stall's shut. Ledger's balanced. I seem to have run out of reasons to stay. You're still here, though.", "vi": "Hàng đóng rồi. Sổ cũng khớp. Hình như tôi hết cớ ở lại rồi. Mà bạn vẫn còn đây."}],
		"answers": [
			{"id": "A", "en": "Yes. You didn't check your watch once.", "vi": "Có. Bạn không nhìn đồng hồ lần nào.", "delta": 1, "reaction": []},
			{"id": "B", "en": "I thought you had another job.", "vi": "Tôi tưởng bạn còn việc khác.", "delta": 0, "reaction": []},
			{"id": "C", "en": "So you'll go easy on me tonight?", "vi": "Vậy tối nay bạn sẽ nhẹ tay chứ?", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "One more Extension, if you'd like. Or we could just finish the tea.", "vi": "Thêm một lần Nối Phỏm, nếu bạn muốn. Hoặc mình uống nốt trà thôi."}],
		"promise_from": "rooster.t1plus.finish_work"}
]
