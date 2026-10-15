extends RefCounted
## Tiger asks for chosen strength and a clear boundary, not an unowned yes.
const CONFIG := {
	"visit_limits": {
		"1": 3,
		"2": 1,
		"1+": 1
	},
	"progression": [
		{
			"from": 2,
			"to": 3,
			"kept": 3,
			"distinct": 2,
			"promises": [
				"tiger.high",
				"tiger.stand",
				"tiger.card"
			]
		}
	],
	"memory_button": {
		"en": "Tiger's word",
		"vi": "Lời của Dần"
	},
	"memory_title": {
		"en": "What Tiger remembers",
		"vi": "Điều Dần nhớ"
	},
	"memory_topics": {
		"tiger.high": {
			"en": "Stand behind the opening",
			"vi": "Giữ lời với khởi đầu"
		},
		"tiger.stand": {
			"en": "Commit the group",
			"vi": "Hạ nhóm cùng nhau"
		},
		"tiger.card": {
			"en": "Own the choice",
			"vi": "Giữ lựa chọn của mình"
		}
	},
	"emblem_unlock": {
		"relationship_tier": 3,
		"promises_kept": 3,
		"promise_kinds": 2,
		"promises_refused": 1,
		"pleased_victories": 1
	},
	"private_scene": [
		{
			"en": "Tiger eases into the little chair. It creaks. He freezes, then laughs when it holds. You've never heard that laugh without a challenge behind it.",
			"vi": "Dần từ từ ngồi xuống ghế nhỏ. Ghế kêu cót két. Anh khựng lại rồi bật cười khi nó vẫn vững. Lần đầu bạn nghe tiếng cười ấy không kèm lời thách."
		},
		{
			"en": "\"People clear a path when I arrive. I used to think that meant respect. You moved your cup and told me I was blocking the light.\"",
			"vi": "\"Tôi đến là người ta dạt đường. Tôi từng nghĩ thế là kính trọng. Còn bạn xích cốc, bảo tôi đang che mất ánh sáng.\""
		},
		{
			"en": "He sets down a tiger Emblem. \"Bring it on our day. Same chair. And tell me if I'm in the way. I like knowing you'll say it.\"",
			"vi": "Anh đặt Huy hiệu con hổ xuống. \"Đến ngày của mình thì mang. Ghế cũ nhé. Tôi chắn đường thì nói. Tôi thích biết bạn sẽ nói thật.\""
		}
	],
	"last_chance": {
		"id": "tiger.last_chance.stand",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "Look at me. You don't have to agree. You do have to mean your answer.",
				"vi": "Nhìn tôi. Không cần đồng ý. Nhưng trả lời thì phải thật lòng."
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "I need to choose a promise I can actually own.",
				"vi": "Tôi cần chọn lời hứa mình thực sự chịu trách nhiệm được.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then choose. I can wait longer than you think.",
						"vi": "Vậy chọn đi. Tôi chờ được lâu hơn bạn nghĩ."
					}
				]
			},
			{
				"id": "B",
				"en": "No more promises today. I can say that without hiding.",
				"vi": "Hôm nay không hứa thêm. Tôi nói điều đó mà không trốn.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Good. Hold that ground. Even with me.",
						"vi": "Tốt. Giữ vững câu ấy. Kể cả trước tôi."
					}
				]
			},
			{
				"id": "C",
				"en": "Whatever answer makes you stop testing me.",
				"vi": "Câu nào khiến bạn thôi thử tôi.",
				"recovery_success": false,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "I can't respect an answer you've already abandoned.",
						"vi": "Tôi không thể coi trọng câu trả lời chính bạn đã bỏ rơi."
					}
				]
			}
		]
	},
	"special": []
}
const NODES := [
	{
		"id": "tiger.t1.strength",
		"zodiac": "tiger",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "A room falls silent when someone enters. Does that tell you they're strong?",
				"vi": "Một người bước vào, cả phòng im bặt. Thế đủ biết họ mạnh chưa?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Only if they can choose what to use their strength for.",
				"vi": "Chỉ khi họ chọn được dùng sức mạnh vào việc gì.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Yes. A strong hand can open as well as close.",
						"vi": "Đúng. Tay mạnh phải mở được, không chỉ nắm."
					}
				]
			},
			{
				"id": "B",
				"en": "I'd need to see them face something difficult.",
				"vi": "Tôi cần thấy họ đối diện việc khó.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Perhaps. Some people hold a pose long after the strength is gone.",
						"vi": "Có thể. Có người hết sức rồi vẫn giữ dáng."
					}
				]
			},
			{
				"id": "C",
				"en": "Yes. Nobody dares to refuse them.",
				"vi": "Rồi. Chẳng ai dám từ chối họ.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "I've had that silence. It isn't company.",
						"vi": "Tôi từng có sự im lặng ấy. Nó không phải có người bên cạnh."
					}
				]
			}
		]
	},
	{
		"id": "tiger.t1.challenge",
		"zodiac": "tiger",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "I challenge you in front of everyone. What do you owe me?",
				"vi": "Tôi thách bạn trước mặt mọi người. Bạn nợ tôi điều gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "A yes I can own, or a no I can say clearly.",
				"vi": "Nhận mà chịu trách nhiệm, hoặc từ chối rõ ràng.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Good. Let them watch you choose, then.",
						"vi": "Tốt. Vậy cứ để họ nhìn bạn tự chọn."
					}
				]
			},
			{
				"id": "B",
				"en": "A look at what they're asking first.",
				"vi": "Xem họ đang yêu cầu gì trước.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "A yes, then an excuse if I lose.",
				"vi": "Nhận, rồi tìm cớ nếu thua.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "An excuse prepared before the fight. You're already looking away.",
						"vi": "Chưa đấu đã chuẩn bị cớ. Bạn quay mặt đi rồi."
					}
				]
			}
		]
	},
	{
		"id": "tiger.t1.space",
		"zodiac": "tiger",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "You step too close. Someone backs away. What do you do?",
				"vi": "Bạn bước quá gần. Người kia lùi lại. Bạn làm gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Give them room to choose where to stand.",
				"vi": "Chừa chỗ để họ chọn nơi đứng.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Yes. If I want someone beside me, I have to leave a place.",
						"vi": "Đúng. Muốn có người bên cạnh thì phải chừa chỗ."
					}
				]
			},
			{
				"id": "B",
				"en": "Ask if I've crowded them.",
				"vi": "Hỏi tôi có làm họ chật chỗ không.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Take the space they left.",
				"vi": "Chiếm luôn chỗ họ chừa.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "No. You haven't won that space. You've frightened someone out of it.",
						"vi": "Không. Bạn chưa giành được chỗ đó. Bạn làm người ta sợ mà bỏ đi."
					}
				]
			}
		]
	},
	{
		"id": "tiger.t1plus.high",
		"zodiac": "tiger",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "What do you do with the strongest card you begin with?",
				"vi": "Bạn làm gì với lá mạnh nhất lúc bắt đầu?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Find a real play instead of only naming its strength.",
				"vi": "Tìm nước hạ thật, không chỉ gọi nó mạnh.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "See whether the hand can support it.",
				"vi": "Xem bài có đỡ được nó không.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Keep talking until the chance passes.",
				"vi": "Nói mãi đến khi cơ hội qua.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "tiger",
				"en": "Next Deal, play one of your opening hand's highest-rank cards before the first mandatory discard. Let the strongest beginning take a step.",
				"vi": "Ván tới hạ một lá hạng cao nhất trong bài mở đầu trước lần bỏ bắt buộc đầu tiên. Cho khởi đầu mạnh nhất bước đi nhé."
			}
		],
		"promise": {
			"id": "tiger.high",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 1,
			"condition": "opening_high_rank",
			"before_first_discard": true,
			"en": "In Phase 1 of the next Deal, play at least one of the physical cards with the highest printed rank in your opening hand in a successful Meld or Extension before the first mandatory discard. The opening targets stay fixed; later draws and swaps do not replace them.",
			"vi": "Trong Hiệp 1 của Ván kế tiếp, hạ ít nhất một lá có hạng in cao nhất trong bài mở đầu vào Phỏm hoặc Nối thành công trước lần bỏ bắt buộc đầu tiên. Đối tượng mở đầu được giữ nguyên; rút hoặc đổi sau đó không thay thế chúng."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "The highest cards you open with. I won't move the mark after you've aimed.",
						"vi": "Những lá cao nhất lúc mở bài. Bạn ngắm rồi, tôi không dời đích."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Then don't give me a deadline you haven't chosen.",
						"vi": "Vậy đừng hứa hạn mà bạn chưa chọn."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "tiger.high",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 1,
					"condition": "opening_high_rank",
					"before_first_discard": false,
					"en": "In Phase 1 of the next Deal, play at least one of the physical cards with the highest printed rank in your opening hand in a successful Meld or Extension before Phase 1 settles. The opening targets stay fixed; later draws and swaps do not replace them.",
					"vi": "Trong Hiệp 1 của Ván kế tiếp, hạ ít nhất một lá có hạng in cao nhất trong bài mở đầu vào Phỏm hoặc Nối thành công trước khi chốt Hiệp 1. Đối tượng mở đầu được giữ nguyên; rút hoặc đổi sau đó không thay thế chúng."
				},
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Keep the opening targets, but take any Turn before Phase 1 settles. Confirm the later deadline if that is your answer.",
						"vi": "Giữ đối tượng mở đầu, nhưng Lượt nào trước khi chốt Hiệp 1 cũng được. Nếu chọn thế thì xác nhận hạn muộn hơn."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Then leave your word there. A smaller promise still needs to be yours.",
						"vi": "Vậy dừng lời ở đó. Lời hứa nhỏ hơn vẫn phải là của bạn."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "You used the strength you began with. In time. I saw.",
						"vi": "Bạn dùng được sức mạnh mình có lúc đầu. Kịp hẹn. Tôi thấy rồi."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "The opening chance passed. A stronger draw later doesn't change that.",
						"vi": "Cơ hội đầu đã qua. Bốc được lá mạnh hơn sau đó không đổi chuyện ấy."
					}
				]
			}
		}
	},
	{
		"id": "tiger.t1plus.stand",
		"zodiac": "tiger",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "What makes a group stand together?",
				"vi": "Điều gì khiến một nhóm đứng cùng nhau?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Each part arrives for the same commitment.",
				"vi": "Mỗi phần đến vì cùng một cam kết.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Knowing what each one can carry.",
				"vi": "Biết từng phần gánh được gì.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Calling them together after the work is done.",
				"vi": "Gọi họ là cùng nhau sau khi việc đã xong.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "tiger",
				"en": "Next Deal, commit a new Meld of at least four cards together. Don't borrow its size from a later Extension.",
				"vi": "Ván tới hạ cùng lúc Phỏm mới ít nhất bốn lá. Đừng mượn kích thước từ lần Nối sau."
			}
		],
		"promise": {
			"id": "tiger.stand",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"condition": "new_meld_size",
			"card_count": 4,
			"en": "In the next Deal, commit a new Meld containing at least four physical cards together. Growing a smaller Meld through an Extension does not fulfill this commitment.",
			"vi": "Trong Ván kế tiếp, hạ cùng lúc Phỏm mới có ít nhất bốn lá vật lý. Nối để làm Phỏm nhỏ lớn lên không hoàn thành cam kết này."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Together from the start. That's the challenge.",
						"vi": "Cùng nhau ngay từ đầu. Đó là lời thách."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Then keep your strength for a group you can choose.",
						"vi": "Vậy giữ sức cho nhóm bạn tự chọn được."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "tiger.stand",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 0,
					"condition": "new_meld_size",
					"card_count": 3,
					"en": "In the next Deal, commit a new Meld containing at least three physical cards together. An Extension does not replace the required new Meld.",
					"vi": "Trong Ván kế tiếp, hạ cùng lúc Phỏm mới có ít nhất ba lá vật lý. Nối không thay thế Phỏm mới đã yêu cầu."
				},
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "A new Meld of three cards will do instead of four. It still has to be new. Read that before you accept.",
						"vi": "Phỏm mới ba lá thay vì bốn cũng được. Vẫn phải là Phỏm mới. Đọc điều đó rồi hãy nhận."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Then leave your word there. A smaller promise still needs to be yours.",
						"vi": "Vậy dừng lời ở đó. Lời hứa nhỏ hơn vẫn phải là của bạn."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "They stood together from the first play. Good. No borrowed glory.",
						"vi": "Chúng cùng vào ngay nước đầu. Tốt. Không mượn hào quang về sau."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "The new Meld didn't begin at the promised size. Growth later is another achievement.",
						"vi": "Phỏm mới không đủ số lá đã hứa khi hạ. Lớn thêm sau đó là thành tích khác."
					}
				]
			}
		}
	},
	{
		"id": "tiger.t1plus.card",
		"zodiac": "tiger",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "If one card is yours to choose, how do you stand behind it?",
				"vi": "Nếu tự chọn một lá, bạn giữ lời với nó bằng cách nào?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Give that actual card a place in the group I promised.",
				"vi": "Cho chính lá đó chỗ trong nhóm tôi đã hứa.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Choose after seeing the possible company.",
				"vi": "Xem bạn đi cùng có thể có rồi chọn.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Substitute another card if nobody notices.",
				"vi": "Thay lá khác nếu không ai để ý.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "tiger",
				"en": "Pick one of these three. Next Deal, put it in a new Meld with at least three other cards. Your choice has to stand in that group.",
				"vi": "Chọn một trong ba lá. Ván tới cho nó vào Phỏm mới cùng ít nhất ba lá khác. Lựa chọn của bạn phải đứng trong nhóm đó."
			}
		],
		"promise": {
			"id": "tiger.card",
			"polarity": "DO",
			"interaction": "card_play",
			"target_kind": "CARD",
			"targeting": "ANY",
			"window": "NEXT_DEAL",
			"action": "new_meld",
			"minimum_cards": 4,
			"en": "Choose a card and commit that physical card together with at least three other cards in one successful new Meld during the next Deal. Extensions and a three-card new Meld do not count.",
			"vi": "Chọn một lá rồi hạ chính lá đó cùng ít nhất ba lá khác vào một Phỏm mới thành công trong Ván kế tiếp. Nối và Phỏm mới ba lá không được tính."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Your chosen card. Your group. Stand behind both.",
						"vi": "Lá bạn chọn. Nhóm bạn lập. Chịu trách nhiệm cho cả hai."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Then let your choice stay open.",
						"vi": "Vậy cứ để lựa chọn mở."
					}
				]
			}
		},
		"initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "That card, in the group you promised. You didn't hide it behind a stronger choice.",
						"vi": "Đúng lá ấy, trong nhóm đã hứa. Bạn không giấu nó sau lựa chọn mạnh hơn."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "Your card never stood in the promised group. I won't call a smaller challenge the same victory.",
						"vi": "Lá bạn chưa vào nhóm đã hứa. Tôi không gọi thử thách nhỏ hơn là cùng một chiến thắng."
					}
				]
			}
		}
	},
	{
		"id": "tiger.t2.high_memory",
		"zodiac": "tiger",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "tiger.high",
		"promise_from": "tiger.t1plus.high",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "tiger",
					"en": "You met the opening challenge: {target} Did it feel bold, or simply obvious once you saw the hand?",
					"vi": "Bạn đạt thử thách mở đầu: {target} Thấy táo bạo, hay nhìn bài rồi thấy hiển nhiên?"
				}
			],
			"BROKEN": [
				{
					"speaker": "tiger",
					"en": "The opening passed you by: {target} Tell me where you hesitated.",
					"vi": "Bạn lỡ thời điểm đầu: {target} Kể tôi nghe đã do dự ở đâu."
				}
			],
			"REFUSED": [
				{
					"speaker": "tiger",
					"en": "You refused this deadline: {target} Did you expect me to think less of you?",
					"vi": "Bạn từ chối hạn này: {target} Bạn có tưởng tôi sẽ coi thường không?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I'd be clear about which cards, and how much time.",
				"vi": "Tôi sẽ nói rõ lá nào, và trong bao lâu.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Good. A clear mark. Something worth aiming at.",
						"vi": "Tốt. Đích rõ ràng. Đáng để nhắm tới."
					}
				]
			},
			{
				"id": "B",
				"en": "I'd look at my hand before giving my word.",
				"vi": "Tôi xem tay bài trước khi hứa.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "A later high card should have replaced the opening one.",
				"vi": "Lá cao đến sau nên thay được lá mở đầu.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Later strength. Different card. We agreed on your opening hand.",
						"vi": "Sức mạnh về sau. Lá bài khác. Mình hẹn tay bài mở đầu."
					}
				]
			}
		]
	},
	{
		"id": "tiger.t2.stand_memory",
		"zodiac": "tiger",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "tiger.stand",
		"promise_from": "tiger.t1plus.stand",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "tiger",
					"en": "Together from the start: {target} Which card made the group possible?",
					"vi": "Cùng nhau từ đầu: {target} Lá nào giúp lập được nhóm ấy?"
				}
			],
			"BROKEN": [
				{
					"speaker": "tiger",
					"en": "The group wasn't there when promised: {target} What could you actually bring together?",
					"vi": "Chưa có nhóm như đã hứa: {target} Bạn thực sự tập hợp được gì?"
				}
			],
			"REFUSED": [
				{
					"speaker": "tiger",
					"en": "You didn't take this challenge: {target} Good to know when you're choosing, rather than flinching.",
					"vi": "Bạn không nhận thử thách này: {target} Biết mình đang chọn, không phải né vì sợ, là tốt."
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I'd count the cards it started with, not what I added later.",
				"vi": "Tôi đếm lá lúc mới hạ, không tính phần thêm sau.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Yes. Tell the beginning as it happened. It doesn't need dressing up.",
						"vi": "Đúng. Kể khởi đầu như nó đã xảy ra. Không cần tô vẽ."
					}
				]
			},
			{
				"id": "B",
				"en": "What I could put down together in one play.",
				"vi": "Những gì tôi hạ cùng lúc trong một nước.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "A later Extension should rewrite the first group.",
				"vi": "Lần Nối sau nên đổi được nhóm đầu tiên.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Let it grow. Don't make it lie about where it started.",
						"vi": "Cứ để nó lớn. Đừng bắt nó nói dối về lúc bắt đầu."
					}
				]
			}
		]
	},
	{
		"id": "tiger.t2.card_memory",
		"zodiac": "tiger",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "tiger.card",
		"promise_from": "tiger.t1plus.card",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "tiger",
					"en": "{target} stood in the group. Why that one? I want to hear your judgment.",
					"vi": "{target} đứng trong nhóm. Sao là lá ấy? Tôi muốn nghe cách bạn cân nhắc."
				}
			],
			"BROKEN": [
				{
					"speaker": "tiger",
					"en": "{target} missed the promised group. Don't look away. What happened?",
					"vi": "{target} chưa vào nhóm đã hứa. Đừng quay mặt. Chuyện gì xảy ra?"
				}
			],
			"REFUSED": [
				{
					"speaker": "tiger",
					"en": "You left {target} out of a promise. Was the choice unclear, or the company wrong?",
					"vi": "Bạn không nhận lời hứa cho {target}. Chưa rõ nên chọn gì, hay chưa đúng nhóm?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I'd tell you what happened to that card, not replace it in the story.",
				"vi": "Tôi kể chuyện xảy ra với lá ấy, không thay lá khác vào câu chuyện.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then I can judge your choice. I don't need a perfect story.",
						"vi": "Vậy tôi nhìn được lựa chọn của bạn. Không cần câu chuyện hoàn hảo."
					}
				]
			},
			{
				"id": "B",
				"en": "Seeing a group I could actually make.",
				"vi": "Thấy nhóm mình thực sự tạo được.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "A similar card should have counted as my choice.",
				"vi": "Lá giống nó nên được tính là lựa chọn của tôi.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "I challenged you to use a card. You can't meet it with a resemblance.",
						"vi": "Tôi thách bạn dùng một lá. Không thể đáp lại bằng thứ giống nó."
					}
				]
			}
		]
	},
	{
		"id": "tiger.t2.guard",
		"zodiac": "tiger",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "If I pick the wrong fight, will you tell me before it starts?",
				"vi": "Nếu tôi chọn sai trận để đấu, bạn có nói trước khi nó bắt đầu không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "No. I can stay beside you and say when something is wrong.",
				"vi": "Không. Tôi đứng cạnh được và nói khi có điều sai.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Good. I have enough people who cheer when I raise my voice.",
						"vi": "Tốt. Người hò reo lúc tôi lớn tiếng đã đủ nhiều rồi."
					}
				]
			},
			{
				"id": "B",
				"en": "I'd need to ask what we're standing for.",
				"vi": "Tôi cần hỏi mình đang đứng vì điều gì.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Yes, if your strength can protect me.",
				"vi": "Có, nếu sức của bạn che chở được tôi.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then you'd agree even when I shouldn't be protecting anything.",
						"vi": "Vậy dù tôi bảo vệ điều sai, bạn vẫn đồng ý."
					}
				]
			}
		]
	},
	{
		"id": "tiger.t2.rest",
		"zodiac": "tiger",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "I sat with my back to the door today. Kept wanting to turn around. What would make that easier?",
				"vi": "Hôm nay tôi ngồi quay lưng ra cửa. Cứ muốn ngoái lại. Làm sao để dễ chịu hơn nhỉ?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Knowing you can hear no without reaching for force.",
				"vi": "Biết bạn nghe được lời từ chối mà không dùng sức ép.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Yes. No enemy needed. I'm still learning that.",
						"vi": "Ừ. Không cần có kẻ địch. Tôi vẫn đang học điều ấy."
					}
				]
			},
			{
				"id": "B",
				"en": "Time to learn who is at the table.",
				"vi": "Thời gian để hiểu người ngồi cùng.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Knowing nobody is strong enough to oppose me.",
				"vi": "Biết chẳng ai đủ mạnh chống tôi.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then you'd have to measure every person who walked in. Exhausting.",
						"vi": "Vậy phải đo sức từng người bước vào. Mệt lắm."
					}
				]
			}
		]
	},
	{
		"id": "tiger.t2.ordinary",
		"zodiac": "tiger",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "No contest tonight. No proving anything. Would you find me dull?",
				"vi": "Tối nay không thi. Không chứng minh gì. Bạn có thấy tôi chán không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Yes. You don't have to prove yourself for the chair.",
				"vi": "Có. Bạn không phải chứng minh mình để được ngồi.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Good. I have a very ordinary story about a chair that broke.",
						"vi": "Tốt. Tôi có câu chuyện rất bình thường về cái ghế gãy."
					}
				]
			},
			{
				"id": "B",
				"en": "For a while. An ordinary evening would be good.",
				"vi": "Một lúc. Tối bình thường cũng tốt.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Only if you make the next victory easier.",
				"vi": "Chỉ khi bạn khiến trận thắng sau dễ hơn.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "I offered you an evening. You asked for an advantage.",
						"vi": "Tôi mời bạn một buổi tối. Bạn xin một lợi thế."
					}
				]
			}
		]
	}
]
