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
	{"speaker": "rooster", "en": "Then that's settled. No promise to collect.", "vi": "Vậy đã rõ. Không có lời hứa nào để đòi."}
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
		"prompt": [{"speaker": "rooster", "en": "One last answer. Can I plan around your word?", "vi": "Trả lời lần cuối. Tôi có thể trông vào lời bạn không?"}],
		"answers": [
			{"id": "A", "en": "Only when I actually promise. Ask me plainly.", "vi": "Chỉ khi tôi thật sự hứa. Cứ hỏi thẳng đi.", "recovery_success": true,
				"reaction": [{"speaker": "rooster", "en": "Then stop answering a question I didn't ask.", "vi": "Vậy đừng trả lời câu tôi không hỏi nữa."}]},
			{"id": "B", "en": "Of course. Whatever gets this over with.", "vi": "Dĩ nhiên. Sao cho xong chuyện là được.", "recovery_success": false,
				"reaction": [{"speaker": "rooster", "en": "We're finished, then.", "vi": "Vậy xong rồi đấy."}]},
			{"id": "C", "en": "No. I can't commit to anything today.", "vi": "Không. Hôm nay tôi không thể cam kết gì cả.", "recovery_success": true,
				"reaction": [{"speaker": "rooster", "en": "Good. That's an answer I can use.", "vi": "Tốt. Câu đó còn giúp tôi tính được việc."}]}
		]},
	"special": []
}

const NODES := [
	{"id": "rooster.t1.waiting", "zodiac": "rooster", "content_tier": "1", "kind": "QUESTION", "topic": "time",
		"prompt": [{"speaker": "rooster", "en": "You're late. Should I have kept the chair?", "vi": "Bạn đến muộn. Tôi có nên giữ ghế không?"}],
		"answers": [
			{"id": "A", "en": "No. I didn't ask you to wait.", "vi": "Không. Tôi đâu có nhờ bạn đợi.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Fine. Sit down. It's still empty.", "vi": "Được. Ngồi đi. Ghế vẫn trống."}]},
			{"id": "B", "en": "I hoped you would.", "vi": "Tôi đã mong bạn giữ.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Hope doesn't reserve a chair.", "vi": "Mong thôi thì không giữ được ghế."}]},
			{"id": "C", "en": "Obviously. You knew I was coming.", "vi": "Dĩ nhiên. Bạn biết tôi sẽ đến mà.", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "I knew you said you were coming.", "vi": "Tôi biết bạn đã nói sẽ đến."}]}
		]},
	{"id": "rooster.t1.no", "zodiac": "rooster", "content_tier": "1", "kind": "QUESTION", "topic": "boundaries",
		"prompt": [{"speaker": "rooster", "en": "Someone asks for a favor you can't do. What do you tell them?", "vi": "Có người nhờ việc bạn không làm được. Bạn nói sao?"}],
		"answers": [
			{"id": "A", "en": "No. While they still have time to ask someone else.", "vi": "Không. Khi họ vẫn còn thời gian nhờ người khác.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Exactly. A no can be useful.", "vi": "Đúng vậy. Nói không cũng có ích."}]},
			{"id": "B", "en": "I'll see what I can do.", "vi": "Để tôi xem làm được gì.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "And when do they stop waiting?", "vi": "Vậy đến lúc nào họ mới hết phải đợi?"}]},
			{"id": "C", "en": "Yes. I'll work something out later.", "vi": "Có. Rồi tính cách sau.", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "You've just made your problem theirs.", "vi": "Bạn vừa biến rắc rối của mình thành của họ."}]}
		]},
	{"id": "rooster.t1.finished", "zodiac": "rooster", "content_tier": "1", "kind": "QUESTION", "topic": "work",
		"prompt": [{"speaker": "rooster", "en": "First to start, or first to finish?", "vi": "Bắt đầu trước, hay xong trước?"}],
		"answers": [
			{"id": "A", "en": "Finished when I said it would be.", "vi": "Xong đúng lúc tôi đã nói.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Good. Nobody eats a head start.", "vi": "Tốt. Bắt đầu sớm đâu có làm ai no."}]},
			{"id": "B", "en": "First to start. It gives me room.", "vi": "Bắt đầu trước. Như vậy có dư thời gian.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Use the room, then.", "vi": "Vậy dùng thời gian đó đi."}]},
			{"id": "C", "en": "Depends who's watching.", "vi": "Còn tùy ai đang nhìn.", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "The work's still there when they leave.", "vi": "Họ đi rồi thì việc vẫn còn đó."}]}
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
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "Before the first discard. I promise.", "vi": "Trước lần bỏ đầu tiên. Tôi hứa."}, {"speaker": "rooster", "en": "I'll remember the deadline.", "vi": "Tôi sẽ nhớ hạn đó."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "I can't promise that opening.", "vi": "Tôi không hứa được nước mở đầu đó."}, {"speaker": "rooster", "en": "Then don't. The cards haven't been dealt.", "vi": "Vậy đừng hứa. Bài còn chưa chia."}]},
			"HAGGLE": {"delta": 0, "strategy": "ALTERNATE_ACTION", "terms": FIRST_MELD,
				"dialogue": [{"speaker": "player", "en": "Give me Phase 1 to make a Meld.", "vi": "Cho tôi cả Hiệp 1 để hạ Phỏm."}, {"speaker": "rooster", "en": "One new Meld by the end of Phase 1. Is that your word?", "vi": "Một Phỏm mới trước khi Hiệp 1 kết thúc. Bạn hứa vậy chứ?"}]},
			"COUNTER_ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "Yes. One new Meld in Phase 1.", "vi": "Ừ. Một Phỏm mới trong Hiệp 1."}, {"speaker": "rooster", "en": "Different deadline. Same responsibility.", "vi": "Hạn khác. Trách nhiệm vẫn vậy."}]},
			"COUNTER_REFUSE": COUNTER_REFUSE
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "rooster", "en": "You did what we agreed. I can plan around that.", "vi": "Bạn làm đúng điều mình đã thống nhất. Vậy tôi còn tính được việc."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "rooster", "en": "The deadline passed. Next time, give me the answer you can keep.", "vi": "Quá hạn rồi. Lần sau, hãy trả lời điều bạn làm được."}]}
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
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "rooster", "en": "Work finished. Better than an explanation.", "vi": "Việc xong rồi. Còn hơn lời giải thích."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "rooster", "en": "I kept time for it. You didn't do it.", "vi": "Tôi đã dành thời gian cho việc đó. Bạn không làm."}]}
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
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "rooster", "en": "You followed through. I didn't have to chase you.", "vi": "Bạn đã làm tới nơi tới chốn. Tôi không phải thúc."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "rooster", "en": "Still waiting. The Deal isn't.", "vi": "Tôi vẫn đợi. Ván thì đã hết."}]}
		}},
	{"id": "rooster.t2.bell_memory", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "time",
		"memory_key": "rooster.early_score",
		"prompts": {
			"FULFILLED": [{"speaker": "rooster", "en": "You scored before the first discard. Did you need me watching the clock?", "vi": "Bạn ghi điểm trước lần bỏ đầu tiên. Có cần tôi canh giờ không?"}],
			"BROKEN": [{"speaker": "rooster", "en": "You promised points before the first discard. The discard came first. What happened?", "vi": "Bạn hứa ghi điểm trước lần bỏ đầu tiên. Nhưng lại bỏ trước. Chuyện gì vậy?"}],
			"REFUSED": [{"speaker": "rooster", "en": "You wouldn't promise an early score. I didn't wait for one. Was that the right answer?", "vi": "Bạn không hứa ghi điểm sớm. Tôi đã không đợi. Câu trả lời đó đúng chứ?"}]},
		"answers": [
			{"id": "A", "en": "I chose the answer. I own what followed.", "vi": "Tôi đã chọn câu trả lời. Chuyện sau đó là trách nhiệm của tôi.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Then we can talk about the next job.", "vi": "Vậy mình còn nói được về việc tiếp theo."}]},
			{"id": "B", "en": "The hand mattered more than I expected.", "vi": "Bài trên tay ảnh hưởng nhiều hơn tôi nghĩ.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "It usually does. Leave room for that.", "vi": "Thường là vậy. Nhớ tính cả điều đó."}]},
			{"id": "C", "en": "It's only a game. Why keep track?", "vi": "Chỉ là một ván bài. Nhớ làm gì?", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "I was keeping track of your word.", "vi": "Tôi nhớ lời bạn nói."}]}
		]},
	{"id": "rooster.t2.meld_memory", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "work",
		"memory_key": "rooster.first_meld",
		"prompts": {
			"FULFILLED": [{"speaker": "rooster", "en": "You put down a new Meld in Phase 1, just as agreed. Quiet work. Do you prefer it that way?", "vi": "Bạn hạ Phỏm mới trong Hiệp 1, đúng thỏa thuận. Làm lặng lẽ. Bạn thích vậy à?"}],
			"BROKEN": [{"speaker": "rooster", "en": "Phase 1 ended without the new Meld you promised. What should I count on next time?", "vi": "Hiệp 1 hết mà không có Phỏm mới bạn đã hứa. Lần sau tôi nên trông vào điều gì?"}],
			"REFUSED": [{"speaker": "rooster", "en": "You said no to the first job. I remember. Was saying it difficult?", "vi": "Bạn từ chối việc đầu tiên. Tôi nhớ. Nói vậy có khó không?"}]},
		"answers": [
			{"id": "A", "en": "Count on me saying what I can actually do.", "vi": "Cứ trông vào việc tôi nói đúng điều mình làm được.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "That's enough to start.", "vi": "Vậy là đủ để bắt đầu."}]},
			{"id": "B", "en": "Ask me again when the cards are dealt.", "vi": "Chia bài rồi hỏi tôi lại.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Fair. Until then, I won't count it done.", "vi": "Hợp lý. Trước lúc đó tôi chưa tính là xong."}]},
			{"id": "C", "en": "You could lower your expectations.", "vi": "Bạn bớt trông chờ đi là được.", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "I used the ones you gave me.", "vi": "Tôi trông vào điều bạn đã nói."}]}
		]},
	{"id": "rooster.t2.extension_memory", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "follow_through",
		"memory_key": "rooster.extension",
		"prompts": {
			"FULFILLED": [{"speaker": "rooster", "en": "You finished the Extension you promised. Nobody had to remind you. Is that how you work?", "vi": "Bạn Nối như đã hứa. Không ai phải nhắc. Bạn vẫn làm việc như vậy à?"}],
			"BROKEN": [{"speaker": "rooster", "en": "Both Phases passed without the Extension you promised. Were you waiting for another chance?", "vi": "Cả hai Hiệp hết mà bạn chưa Nối như đã hứa. Bạn còn đợi cơ hội khác à?"}],
			"REFUSED": [{"speaker": "rooster", "en": "You wouldn't promise an Extension. You left me a clear answer. Do you always do that?", "vi": "Bạn không hứa Nối. Bạn đã trả lời rõ ràng. Lúc nào cũng vậy à?"}]},
		"answers": [
			{"id": "A", "en": "I'm trying to leave fewer loose ends.", "vi": "Tôi đang cố bớt để việc dở dang.", "delta": 1,
				"reaction": [{"speaker": "rooster", "en": "Good. Loose ends make work for other people.", "vi": "Tốt. Việc dở dang bắt người khác làm tiếp."}]},
			{"id": "B", "en": "Depends on the day.", "vi": "Còn tùy hôm.", "delta": 0,
				"reaction": [{"speaker": "rooster", "en": "Tell me which sort of day before you promise.", "vi": "Trước khi hứa thì nói tôi biết hôm đó thế nào."}]},
			{"id": "C", "en": "You got an answer. Isn't that enough?", "vi": "Bạn có câu trả lời rồi. Chưa đủ sao?", "delta": -1,
				"reaction": [{"speaker": "rooster", "en": "When the answer's no, yes.", "vi": "Nếu câu trả lời là không thì đủ."}]}
		]},
	{"id": "rooster.t2.trust_clock", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "trust",
		"prompt": [{"speaker": "direction", "en": "Rooster turns his watch face down.", "vi": "Dậu úp mặt đồng hồ xuống."}, {"speaker": "rooster", "en": "I don't need to watch every second with you. Still want the early deadline?", "vi": "Với bạn, tôi không cần canh từng giây nữa. Vẫn muốn hạn sớm chứ?"}],
		"answers": [
			{"id": "A", "en": "Ask me. Trust doesn't make the choice for me.", "vi": "Cứ hỏi tôi. Tin nhau đâu có chọn hộ nhau.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Let's see the terms.", "vi": "Xem điều kiện đã.", "delta": 0, "reaction": []},
			{"id": "C", "en": "You trust me, so stop checking.", "vi": "Tin tôi thì đừng kiểm tra nữa.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "Same early score. An honest no still works.", "vi": "Vẫn là ghi điểm sớm. Nói không thật lòng vẫn được."}],
		"promise_from": "rooster.t1plus.before_bell"},
	{"id": "rooster.t2.own_table", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "company",
		"prompt": [{"speaker": "rooster", "en": "I've left room on the table. You don't owe me a performance. What will you bring?", "vi": "Tôi chừa chỗ trên bàn rồi. Bạn không nợ tôi màn trình diễn nào cả. Bạn sẽ mang gì tới?"}],
		"answers": [
			{"id": "A", "en": "My own play. I'll tell you if I can't make it.", "vi": "Nước bài của tôi. Không làm được thì tôi sẽ nói.", "delta": 1, "reaction": []},
			{"id": "B", "en": "Whatever the hand allows.", "vi": "Bài cho phép gì thì làm nấy.", "delta": 0, "reaction": []},
			{"id": "C", "en": "Something impressive enough to keep the chair.", "vi": "Thứ đủ ấn tượng để bạn giữ ghế.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "The chair isn't a prize. The first Meld is still your choice.", "vi": "Cái ghế đâu phải phần thưởng. Phỏm đầu tiên vẫn do bạn chọn."}],
		"promise_from": "rooster.t1plus.first_job"},
	{"id": "rooster.t2.stay_after", "zodiac": "rooster", "content_tier": "2", "relationship_required": 3, "kind": "QUESTION", "topic": "company",
		"prompt": [{"speaker": "rooster", "en": "I usually leave when the work's done. Today I stayed. Did you notice?", "vi": "Xong việc là tôi thường về. Hôm nay tôi ngồi lại. Bạn có để ý không?"}],
		"answers": [
			{"id": "A", "en": "Yes. You didn't check your watch once.", "vi": "Có. Bạn không nhìn đồng hồ lần nào.", "delta": 1, "reaction": []},
			{"id": "B", "en": "I thought you had another job.", "vi": "Tôi tưởng bạn còn việc khác.", "delta": 0, "reaction": []},
			{"id": "C", "en": "So you'll go easy on me tonight?", "vi": "Vậy tối nay bạn sẽ nhẹ tay chứ?", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "rooster", "en": "I'm here for the company. Shall we finish one more piece of work?", "vi": "Tôi ngồi đây vì có bạn. Mình làm xong thêm một việc nhé?"}],
		"promise_from": "rooster.t1plus.finish_work"}
]
