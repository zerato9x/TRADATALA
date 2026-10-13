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
			"en": "Tiger puts both hands on the table, open. His shoulders settle against the chair, and he lets the silence stay without testing it.",
			"vi": "Dần đặt hai bàn tay mở lên bàn. Vai anh tựa xuống ghế, và anh để khoảng im ở lại mà không thử nó."
		},
		{
			"en": "\"You chose your word, and you gave it a boundary. You also said no. I can share a table with someone who stands on their own feet.\"",
			"vi": "\"Bạn tự chọn lời, và nói rõ ranh giới. Bạn cũng đã từ chối. Tôi ngồi chung bàn với người tự đứng bằng chân mình được.\""
		},
		{
			"en": "He places a small tiger Emblem between the open hands. \"Bring it when our day comes. You won't need to make yourself smaller to sit here.\"",
			"vi": "Anh đặt Huy hiệu con hổ nhỏ giữa hai bàn tay mở. \"Đến ngày của mình thì mang theo nhé. Bạn không phải thu mình lại để ngồi đây.\""
		}
	],
	"last_chance": {
		"id": "tiger.last_chance.stand",
		"prompt": [
			{
				"speaker": "tiger",
				"en": "Stand where you mean to stand. What is your answer now?",
				"vi": "Đứng đúng chỗ bạn muốn đứng nhé. Giờ câu trả lời của bạn là gì?"
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
						"en": "Then choose from there.",
						"vi": "Vậy chọn từ đó."
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
						"en": "Then keep your feet there. A clear no can stand.",
						"vi": "Vậy cứ đứng ở đó. Lời từ chối rõ ràng vẫn đứng vững."
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
						"en": "Then we'll leave the answer here.",
						"vi": "Vậy mình dừng câu trả lời ở đây."
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
				"en": "How do you know someone is strong?",
				"vi": "Làm sao bạn biết ai đó mạnh?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "They can choose what their strength is for.",
				"vi": "Họ chọn được sức mạnh dùng để làm gì.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then it belongs to them.",
						"vi": "Vậy nó mới thuộc về họ."
					}
				]
			},
			{
				"id": "B",
				"en": "They hold up when things get difficult.",
				"vi": "Họ đứng vững khi việc khó đi.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Ask what they're holding, too.",
						"vi": "Nhớ hỏi họ đang gánh gì."
					}
				]
			},
			{
				"id": "C",
				"en": "Nobody dares to refuse them.",
				"vi": "Chẳng ai dám từ chối họ.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Fear can make a room quiet. It doesn't make you strong.",
						"vi": "Sợ hãi làm phòng yên được. Nó không làm bạn mạnh."
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
				"en": "Someone offers you a challenge. What do you owe the answer?",
				"vi": "Có người thách bạn. Bạn cần trả lời thế nào?"
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
						"en": "Good. Both need a spine.",
						"vi": "Tốt. Cả hai đều cần bản lĩnh."
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
						"en": "Then you haven't chosen the challenge.",
						"vi": "Vậy bạn chưa chọn thử thách."
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
				"en": "Someone steps back when you enter. What do you do?",
				"vi": "Có người lùi lại khi bạn vào. Bạn làm gì?"
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
						"en": "Then they can meet you on their own feet.",
						"vi": "Vậy họ gặp bạn bằng bước chân của mình."
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
						"en": "A step back isn't an invitation.",
						"vi": "Lùi một bước không phải lời mời."
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
						"en": "I'll bind the actual opening cards. Later draws won't move the target.",
						"vi": "Tôi sẽ ghi những lá mở đầu thật. Lá rút sau không đổi đối tượng."
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
						"en": "An opening high card reached its play before the deadline we agreed. You stood behind the start.",
						"vi": "Một lá cao nhất lúc mở đầu đã vào nước hạ trước hạn thống nhất. Bạn đã giữ lời với khởi đầu."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "The opening high cards didn't reach a play by our deadline. A later card couldn't replace that start.",
						"vi": "Những lá cao nhất lúc mở đầu chưa vào nước hạ đúng hạn. Lá đến sau không thay khởi đầu đó được."
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
						"en": "A new group, committed together. That's the word I'm taking.",
						"vi": "Nhóm mới, hạ cùng nhau. Tôi nhận lời đó."
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
						"en": "You committed the new group at the size we agreed. Its strength was there when you gave it a place.",
						"vi": "Bạn đã hạ nhóm mới với số lá thống nhất. Sức của nó có sẵn lúc bạn cho nó chỗ."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "A new Meld of the promised size wasn't committed. Growing one afterward didn't change its beginning.",
						"vi": "Chưa hạ Phỏm mới với số lá đã hứa. Làm nó lớn sau đó không đổi khởi đầu."
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
						"en": "The chosen physical card, in the new group. I won't choose a substitute for you.",
						"vi": "Chính lá bạn chọn, trong nhóm mới. Tôi không chọn lá thay bạn đâu."
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
						"en": "Your chosen card stood in the new group you promised.",
						"vi": "Lá bạn chọn đã đứng trong nhóm mới bạn hứa."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "tiger",
						"en": "That card didn't enter the promised new group. An Extension or a smaller beginning couldn't replace it.",
						"vi": "Lá đó chưa vào nhóm mới đã hứa. Nối hoặc khởi đầu nhỏ hơn không thay được."
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
					"en": "You stood behind this opening: {target} What let you act in time?",
					"vi": "Bạn đã giữ lời với khởi đầu này: {target} Điều gì giúp bạn làm kịp?"
				}
			],
			"BROKEN": [
				{
					"speaker": "tiger",
					"en": "This opening missed our boundary: {target} What would you say before taking it on again?",
					"vi": "Khởi đầu này đã lỡ ranh giới: {target} Trước khi nhận lại bạn sẽ nói gì?"
				}
			],
			"REFUSED": [
				{
					"speaker": "tiger",
					"en": "You didn't take this deadline: {target} What needed a different answer?",
					"vi": "Bạn không nhận hạn này: {target} Điều gì cần câu trả lời khác?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "Name the actual cards and the deadline I chose.",
				"vi": "Nói rõ những lá thật và hạn tôi đã chọn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then your strength has somewhere to stand.",
						"vi": "Vậy sức của bạn có chỗ để đứng."
					}
				]
			},
			{
				"id": "B",
				"en": "Check the hand before giving my word.",
				"vi": "Xem bài trước khi hứa.",
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
						"en": "We named the beginning, not the card that arrived later.",
						"vi": "Mình đã nói khởi đầu, không nói lá đến sau."
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
					"en": "This group stood together: {target} What did you learn about its strength?",
					"vi": "Nhóm này đã đứng cùng nhau: {target} Bạn hiểu thêm gì về sức của nó?"
				}
			],
			"BROKEN": [
				{
					"speaker": "tiger",
					"en": "The group didn't begin as promised: {target} What would you change about the commitment?",
					"vi": "Nhóm chưa bắt đầu như hứa: {target} Bạn sẽ đổi gì trong cam kết?"
				}
			],
			"REFUSED": [
				{
					"speaker": "tiger",
					"en": "You left this group unpromised: {target} What did that let you choose?",
					"vi": "Bạn chưa hứa nhóm này: {target} Điều đó cho bạn chọn gì?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "The size it actually had when I first committed it.",
				"vi": "Số lá nó thực sự có lúc tôi hạ lần đầu.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then the story starts where the group did.",
						"vi": "Vậy lời kể bắt đầu đúng chỗ nhóm bắt đầu."
					}
				]
			},
			{
				"id": "B",
				"en": "What I could bring together in one play.",
				"vi": "Điều tôi gom được trong một nước.",
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
						"en": "It can grow the group. It can't change that first commitment.",
						"vi": "Nó làm nhóm lớn lên được. Nó không đổi lần hạ đầu tiên."
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
					"en": "This was your choice in the group: {target} Why did you stand behind it?",
					"vi": "Đây là lựa chọn của bạn trong nhóm: {target} Vì sao bạn giữ lời với nó?"
				}
			],
			"BROKEN": [
				{
					"speaker": "tiger",
					"en": "This choice didn't reach the promised group: {target} What place did it find?",
					"vi": "Lựa chọn này chưa vào nhóm đã hứa: {target} Nó tìm được chỗ nào?"
				}
			],
			"REFUSED": [
				{
					"speaker": "tiger",
					"en": "You left this choice free: {target} What company did you need to see?",
					"vi": "Bạn để lựa chọn này tự do: {target} Bạn cần thấy bạn đi cùng nào?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "The real card's place, without replacing it in the story.",
				"vi": "Chỗ của lá thật, không thay nó trong lời kể.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then I can see the choice you made.",
						"vi": "Vậy tôi thấy được lựa chọn bạn đã làm."
					}
				]
			},
			{
				"id": "B",
				"en": "A group I could commit honestly.",
				"vi": "Nhóm tôi hạ được thật.",
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
						"en": "You chose a card, not a description.",
						"vi": "Bạn chọn lá bài, không chọn lời tả nó."
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
				"en": "If I ask you to stand beside me, must you agree with everything I do?",
				"vi": "Nếu tôi xin bạn đứng cạnh, bạn phải đồng ý mọi việc tôi làm sao?"
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
						"en": "Then you're company, not an echo.",
						"vi": "Vậy bạn là người đi cùng, không phải tiếng vọng."
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
						"en": "Protection shouldn't buy your answer.",
						"vi": "Che chở không nên mua câu trả lời của bạn."
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
				"en": "What would let me lower my guard here?",
				"vi": "Điều gì giúp tôi thôi đề phòng ở đây?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Knowing I can hear no without reaching for force.",
				"vi": "Biết tôi nghe được lời từ chối mà không dùng sức.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "tiger",
						"en": "Then the room can stay open.",
						"vi": "Vậy căn phòng còn để mở được."
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
						"en": "That would keep the guard working all night.",
						"vi": "Vậy tôi phải đề phòng cả đêm rồi."
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
				"en": "Would you sit here if there were no challenge left to win?",
				"vi": "Nếu chẳng còn thử thách nào để thắng, bạn có ngồi đây không?"
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
						"en": "Then I'll let the chair hold some weight.",
						"vi": "Vậy tôi để ghế đỡ bớt sức nặng nhé."
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
						"en": "I was asking about this evening.",
						"vi": "Tôi đang hỏi chuyện tối nay mà."
					}
				]
			}
		]
	}
]
