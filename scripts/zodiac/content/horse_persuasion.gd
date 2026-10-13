extends RefCounted
## Horse values a chosen pace and the freedom to stop honestly.
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
				"horse.pair",
				"horse.pace",
				"horse.card"
			]
		}
	],
	"memory_button": {
		"en": "Horse's routes",
		"vi": "Đường của Ngọ"
	},
	"memory_title": {
		"en": "What Horse remembers",
		"vi": "Điều Ngọ nhớ"
	},
	"memory_topics": {
		"horse.pair": {
			"en": "A pair of steps",
			"vi": "Cặp bước"
		},
		"horse.pace": {
			"en": "Stay with the start",
			"vi": "Ở lại với khởi đầu"
		},
		"horse.card": {
			"en": "A card's next step",
			"vi": "Bước tiếp của lá bài"
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
			"en": "Horse pulls his chair back from the edge of the table. For once, his feet aren't looking for the next road.",
			"vi": "Ngọ kéo ghế khỏi mép bàn. Lần này chân anh không tìm đường kế tiếp."
		},
		{
			"en": "\"You stayed with a pace, and you told me when you couldn't. I can sit with someone who knows where their word ends.\"",
			"vi": "\"Bạn đã giữ một nhịp, và nói với tôi lúc không làm được. Tôi ngồi cùng người biết lời mình dừng ở đâu được.\""
		},
		{
			"en": "He lays a small horse Emblem beside your hand. \"Bring it on our day. I'll know which road you chose back here.\"",
			"vi": "Anh đặt Huy hiệu con ngựa nhỏ cạnh tay bạn. \"Mang theo vào ngày của mình nhé. Tôi sẽ biết bạn đã chọn đường về đây.\""
		}
	],
	"last_chance": {
		"id": "horse.last_chance.pause",
		"prompt": [
			{
				"speaker": "horse",
				"en": "Pause here with me. Can you say what you actually mean to do?",
				"vi": "Dừng đây với tôi nhé. Bạn nói được điều mình thực sự định làm không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "I need a pace I can choose and keep.",
				"vi": "Tôi cần nhịp mình tự chọn và giữ được.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then begin from there.",
						"vi": "Vậy bắt đầu từ đó."
					}
				]
			},
			{
				"id": "B",
				"en": "I can't promise another step today.",
				"vi": "Hôm nay tôi không hứa thêm bước nào được.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "horse",
						"en": "A clear stop is a place we can stand.",
						"vi": "Dừng rõ ràng là chỗ mình đứng được."
					}
				]
			},
			{
				"id": "C",
				"en": "I'll say anything if it gets me past this.",
				"vi": "Tôi nói gì cũng được nếu qua được lúc này.",
				"recovery_success": false,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then we'll leave the road here.",
						"vi": "Vậy mình dừng đường đi ở đây."
					}
				]
			}
		]
	},
	"special": []
}
const NODES := [
	{
		"id": "horse.t1.road",
		"zodiac": "horse",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "The road opens in two directions. What makes you choose?",
				"vi": "Đường mở ra hai hướng. Điều gì khiến bạn chọn?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "A direction I can take responsibility for.",
				"vi": "Hướng mà tôi có thể chịu trách nhiệm.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Good. Your feet should know whose choice it is.",
						"vi": "Tốt. Bước chân nên biết đó là lựa chọn của ai."
					}
				]
			},
			{
				"id": "B",
				"en": "What I can see from here.",
				"vi": "Điều tôi nhìn được từ đây.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Leave room to learn further down.",
						"vi": "Chừa chỗ để đi xa hơn rồi hiểu thêm."
					}
				]
			},
			{
				"id": "C",
				"en": "Whichever makes me look fastest.",
				"vi": "Hướng khiến tôi trông nhanh nhất.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "A crowd isn't a compass.",
						"vi": "Đám đông không phải la bàn."
					}
				]
			}
		]
	},
	{
		"id": "horse.t1.pace",
		"zodiac": "horse",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "Someone beside you is falling behind. What do you do?",
				"vi": "Người đi cạnh bạn đang tụt lại. Bạn làm gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Ask what pace we can both keep.",
				"vi": "Hỏi nhịp nào cả hai đều theo được.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then we're travelling together.",
						"vi": "Vậy mới là cùng đi."
					}
				]
			},
			{
				"id": "B",
				"en": "Wait at the next corner.",
				"vi": "Đợi ở góc đường kế tiếp.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Make sure they know which corner.",
						"vi": "Nhớ cho họ biết góc đường nào."
					}
				]
			},
			{
				"id": "C",
				"en": "Tell them not to slow me down.",
				"vi": "Bảo họ đừng làm tôi chậm lại.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then you were already travelling alone.",
						"vi": "Vậy bạn vốn đã đi một mình."
					}
				]
			}
		]
	},
	{
		"id": "horse.t1.rest",
		"zodiac": "horse",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "Does stopping mean you've lost your way?",
				"vi": "Dừng lại có nghĩa là lạc đường không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Sometimes it lets me choose the next step.",
				"vi": "Đôi khi nó giúp tôi chọn bước tiếp theo.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "A pause can have a direction.",
						"vi": "Khoảng dừng cũng có thể có hướng."
					}
				]
			},
			{
				"id": "B",
				"en": "It depends on why I stopped.",
				"vi": "Tùy lý do tôi dừng.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then look at the reason.",
						"vi": "Vậy hãy nhìn vào lý do."
					}
				]
			},
			{
				"id": "C",
				"en": "Yes. I need to keep moving, whatever the cost.",
				"vi": "Có. Giá nào tôi cũng phải đi tiếp.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Speed can carry you past yourself.",
						"vi": "Đi nhanh có thể khiến bạn bỏ lại chính mình."
					}
				]
			}
		]
	},
	{
		"id": "horse.t1plus.pair",
		"zodiac": "horse",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "What turns two steps into a stride?",
				"vi": "Điều gì nối hai bước thành một nhịp?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Following through on a pace I chose.",
				"vi": "Theo đến cùng nhịp tôi đã chọn.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Taking the next step when it comes.",
				"vi": "Bước tiếp khi đến lúc.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Calling any movement progress.",
				"vi": "Gọi mọi cử động là tiến bộ.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "horse",
				"en": "Try two Melds or two Extensions in one Turn next Deal. Can you keep the pair together?",
				"vi": "Ván tới thử hai Phỏm hoặc hai lần Nối trong một Lượt nhé. Bạn giữ được cặp đó cùng nhau chứ?"
			}
		],
		"promise": {
			"id": "horse.pair",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"condition": "same_turn_actions",
			"action_count": 2,
			"same_action": true,
			"en": "In the next Deal, complete two new Melds or two Extensions within one Turn. Mandatory discards and Phase changes separate Turns; optional extra discards do not. Only successful committed plays count.",
			"vi": "Trong Ván kế tiếp, hoàn thành hai Phỏm mới hoặc hai lần Nối trong cùng một Lượt. Bỏ bắt buộc và đổi Hiệp ngăn cách các Lượt; bỏ thêm tùy chọn thì không. Chỉ tính nước chơi đã thực hiện thành công."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "I'll watch the committed pair, not your hurry.",
						"vi": "Tôi sẽ xem cặp nước đã thực hiện, không xem bạn vội ra sao."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "Then choose your own stride.",
						"vi": "Vậy cứ chọn nhịp của mình."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "horse.pair",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 0,
					"condition": "same_turn_actions",
					"action_count": 2,
					"same_action": false,
					"en": "In the next Deal, complete two successful Meld or Extension actions within one Turn, in any combination. Mandatory discards and Phase changes separate Turns; optional extra discards do not.",
					"vi": "Trong Ván kế tiếp, thực hiện thành công hai nước Phỏm hoặc Nối trong cùng một Lượt, kết hợp tùy ý. Bỏ bắt buộc và đổi Hiệp ngăn cách các Lượt; bỏ thêm tùy chọn thì không."
				},
				"dialogue": [
					{
						"speaker": "horse",
						"en": "Two actions in one Turn, any mixture of Meld and Extension. Confirm that version if it fits your hand.",
						"vi": "Hai nước trong một Lượt, kết hợp Phỏm và Nối tùy ý. Nếu hợp bài thì xác nhận điều kiện đó nhé."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "Then leave the route open. Don't promise it to please me.",
						"vi": "Vậy cứ để ngỏ đường đi. Đừng hứa chỉ để làm tôi vui."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "You finished the pair we agreed in one Turn. The pace had a shape.",
						"vi": "Bạn đã hoàn thành cặp đã thống nhất trong một Lượt. Nhịp đi đã có hình."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "The agreed pair didn't arrive within one Turn. Tell me a pace you can keep next time.",
						"vi": "Cặp đã thống nhất chưa đến trong một Lượt. Lần tới hãy nói nhịp bạn giữ được."
					}
				]
			}
		}
	},
	{
		"id": "horse.t1plus.pace",
		"zodiac": "horse",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "When you begin something, what keeps you beside it?",
				"vi": "Khi bắt đầu một việc, điều gì khiến bạn ở lại với nó?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Giving the first step a real follow-through.",
				"vi": "Thực sự tiếp nối bước đầu.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Seeing whether there's room to continue.",
				"vi": "Xem có chỗ để tiếp tục không.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Starting something else when anyone notices.",
				"vi": "Bắt đầu việc khác khi có người chú ý.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "horse",
				"en": "In Phase 1, make your first Meld and extend it before that Turn ends. Stay with the thing you started.",
				"vi": "Trong Hiệp 1, tạo Phỏm đầu tiên rồi Nối nó trước khi Lượt đó hết. Ở lại với điều bạn đã bắt đầu nhé."
			}
		],
		"promise": {
			"id": "horse.pace",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 1,
			"condition": "extend_first_meld",
			"same_turn": true,
			"en": "During Phase 1 of the next Deal, create your first new Meld and extend that same Meld before its Turn ends. A mandatory discard closes that Turn. A later Meld cannot replace the first one.",
			"vi": "Trong Hiệp 1 của Ván kế tiếp, tạo Phỏm mới đầu tiên rồi Nối chính Phỏm đó trước khi Lượt ấy kết thúc. Bỏ bắt buộc kết thúc Lượt đó. Phỏm tạo sau không thay thế được Phỏm đầu tiên."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "The first Meld, in its own Turn. I'll remember that boundary.",
						"vi": "Phỏm đầu tiên, ngay trong Lượt của nó. Tôi sẽ nhớ ranh giới đó."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "Then don't bind your first step to mine.",
						"vi": "Vậy đừng buộc bước đầu của bạn vào tôi."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "horse.pace",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 1,
					"condition": "extend_first_meld",
					"same_turn": false,
					"en": "During Phase 1 of the next Deal, create your first new Meld and extend that same Meld, in any Turn before Phase 1 settles. A later Meld cannot replace the first one.",
					"vi": "Trong Hiệp 1 của Ván kế tiếp, tạo Phỏm mới đầu tiên rồi Nối chính Phỏm đó ở Lượt nào cũng được trước khi chốt Hiệp 1. Phỏm tạo sau không thay thế được Phỏm đầu tiên."
				},
				"dialogue": [
					{
						"speaker": "horse",
						"en": "Keep the first Meld, but any Turn of Phase 1 will do for its Extension. Read the later deadline before accepting.",
						"vi": "Vẫn là Phỏm đầu tiên, nhưng Nối ở Lượt nào của Hiệp 1 cũng được. Đọc hạn muộn hơn rồi hãy nhận."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "Then leave the route open. Don't promise it to please me.",
						"vi": "Vậy cứ để ngỏ đường đi. Đừng hứa chỉ để làm tôi vui."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "You stayed with the first Meld and extended it in time.",
						"vi": "Bạn đã ở lại với Phỏm đầu tiên và Nối kịp lúc."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "The first Meld didn't get its promised Extension in time. A different start doesn't replace it.",
						"vi": "Phỏm đầu tiên chưa được Nối đúng hạn đã hứa. Bắt đầu việc khác không thay thế được nó."
					}
				]
			}
		}
	},
	{
		"id": "horse.t1plus.card",
		"zodiac": "horse",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "A card has waited in your hand. What would count as its next step?",
				"vi": "Một lá đã đợi trong tay bạn. Điều gì được xem là bước tiếp của nó?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Adding it where something has already begun.",
				"vi": "Thêm nó vào nơi đã có khởi đầu.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Seeing what the table can hold.",
				"vi": "Xem bàn có thể nhận được gì.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Calling it used because it's near a Meld.",
				"vi": "Gọi nó là đã dùng vì ở gần một Phỏm.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "horse",
				"en": "Pick one of these three. Add it through an Extension next Deal. The card itself has to make the step.",
				"vi": "Chọn một trong ba lá này. Ván tới thêm nó bằng Nối nhé. Chính lá đó phải bước đi."
			}
		],
		"promise": {
			"id": "horse.card",
			"polarity": "DO",
			"interaction": "card_play",
			"target_kind": "CARD",
			"targeting": "ANY",
			"window": "NEXT_DEAL",
			"action": "extension",
			"en": "Choose a card and add that physical card to an existing Meld through a successful Extension in the next Deal. Playing it in a new Meld, discarding it, or extending a Meld that already holds it does not count.",
			"vi": "Chọn một lá rồi thêm chính lá đó vào Phỏm có sẵn bằng một lần Nối thành công trong Ván kế tiếp. Hạ nó vào Phỏm mới, bỏ nó, hoặc Nối Phỏm đã chứa nó không được tính."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "Your chosen card has to be newly added. I'll follow its actual place.",
						"vi": "Lá bạn chọn phải được thêm mới. Tôi sẽ theo chỗ thực sự của nó."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "Keep your hand free, then.",
						"vi": "Vậy cứ để tay mình tự do."
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
						"speaker": "horse",
						"en": "Your chosen card joined an existing Meld through an Extension. You made room for its next step.",
						"vi": "Lá bạn chọn đã vào Phỏm có sẵn bằng Nối. Bạn đã chừa chỗ cho bước tiếp của nó."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "That card didn't make the promised Extension. Being in a Meld already wasn't the same step.",
						"vi": "Lá đó chưa thực hiện lần Nối đã hứa. Vốn nằm trong Phỏm không phải bước ấy."
					}
				]
			}
		}
	},
	{
		"id": "horse.t2.pair_memory",
		"zodiac": "horse",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "horse.pair",
		"promise_from": "horse.t1plus.pair",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "horse",
					"en": "I remember this pair: {target} What kept its steps together?",
					"vi": "Tôi nhớ cặp này: {target} Điều gì giữ hai bước cùng nhau?"
				}
			],
			"BROKEN": [
				{
					"speaker": "horse",
					"en": "This pair didn't hold: {target} Where did the pace change?",
					"vi": "Cặp này chưa giữ được: {target} Nhịp đã đổi ở đâu?"
				}
			],
			"REFUSED": [
				{
					"speaker": "horse",
					"en": "You left this pair open: {target} What pace did you need instead?",
					"vi": "Bạn để ngỏ cặp này: {target} Thay vào đó bạn cần nhịp nào?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "Naming what I could finish in one Turn.",
				"vi": "Nói rõ điều tôi hoàn thành được trong một Lượt.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then we can hear the same pace.",
						"vi": "Vậy mình nghe cùng một nhịp."
					}
				]
			},
			{
				"id": "B",
				"en": "Leaving room for the hand I actually had.",
				"vi": "Chừa chỗ cho bài tôi thực sự có.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Counting steps from different Turns as one.",
				"vi": "Gộp bước ở các Lượt khác nhau thành một.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "That changes the boundary we agreed.",
						"vi": "Điều đó đổi ranh giới mình đã thống nhất."
					}
				]
			}
		]
	},
	{
		"id": "horse.t2.pace_memory",
		"zodiac": "horse",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "horse.pace",
		"promise_from": "horse.t1plus.pace",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "horse",
					"en": "You followed through here: {target} What made you stay with that first Meld?",
					"vi": "Bạn đã tiếp nối ở đây: {target} Điều gì khiến bạn ở lại với Phỏm đầu tiên?"
				}
			],
			"BROKEN": [
				{
					"speaker": "horse",
					"en": "The first Meld waited past this promise: {target} What would you say before starting again?",
					"vi": "Phỏm đầu tiên đã đợi quá lời hứa này: {target} Trước khi bắt đầu lại bạn sẽ nói gì?"
				}
			],
			"REFUSED": [
				{
					"speaker": "horse",
					"en": "You didn't bind yourself to this: {target} Did leaving it open help?",
					"vi": "Bạn không buộc mình vào điều này: {target} Để ngỏ có giúp được không?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "The boundary matters as much as the start.",
				"vi": "Ranh giới quan trọng như khởi đầu.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then I'll believe the next step you name.",
						"vi": "Vậy tôi sẽ tin bước tiếp bạn nói."
					}
				]
			},
			{
				"id": "B",
				"en": "I need to check the hand before promising.",
				"vi": "Tôi cần xem bài trước khi hứa.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Any later Meld should have counted instead.",
				"vi": "Phỏm nào tạo sau cũng nên được tính thay.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "It wasn't the first one we named.",
						"vi": "Đó không phải Phỏm đầu tiên mình đã nói."
					}
				]
			}
		]
	},
	{
		"id": "horse.t2.card_memory",
		"zodiac": "horse",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "horse.card",
		"promise_from": "horse.t1plus.card",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "horse",
					"en": "You gave this card its next step: {target} Did its place surprise you?",
					"vi": "Bạn đã cho lá này bước tiếp: {target} Chỗ của nó có khiến bạn bất ngờ không?"
				}
			],
			"BROKEN": [
				{
					"speaker": "horse",
					"en": "This card didn't take the promised step: {target} What place did you find for it?",
					"vi": "Lá này chưa bước như đã hứa: {target} Bạn tìm được chỗ nào cho nó?"
				}
			],
			"REFUSED": [
				{
					"speaker": "horse",
					"en": "You kept the choice open for this card: {target} What did that leave possible?",
					"vi": "Bạn giữ lựa chọn mở cho lá này: {target} Điều đó để lại khả năng gì?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "A place I can name without pretending I made the Extension.",
				"vi": "Chỗ tôi nói rõ được mà không giả vờ đã Nối.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Good. Let the card's actual path stay visible.",
						"vi": "Tốt. Giữ đường thực sự của lá bài rõ ràng nhé."
					}
				]
			},
			{
				"id": "B",
				"en": "I needed a different hand for that step.",
				"vi": "Tôi cần bài khác để thực hiện bước đó.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Its old place should count as a new step.",
				"vi": "Chỗ cũ của nó cũng nên tính là bước mới.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Old ground doesn't become new because we rename it.",
						"vi": "Đổi tên không khiến chỗ cũ thành chỗ mới."
					}
				]
			}
		]
	},
	{
		"id": "horse.t2.arrival",
		"zodiac": "horse",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "If we arrive together, what do you hope I remember?",
				"vi": "Nếu mình cùng đến nơi, bạn muốn tôi nhớ điều gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "That I kept room for your pace.",
				"vi": "Rằng tôi đã chừa chỗ cho nhịp của bạn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then the road was ours for a while.",
						"vi": "Vậy con đường đã là của mình một lúc."
					}
				]
			},
			{
				"id": "B",
				"en": "The turns we chose along the way.",
				"vi": "Những ngã rẽ mình đã chọn.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "That I could have arrived first.",
				"vi": "Rằng tôi có thể đến trước.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "I asked about arriving together.",
						"vi": "Tôi hỏi chuyện cùng đến mà."
					}
				]
			}
		]
	},
	{
		"id": "horse.t2.freedom",
		"zodiac": "horse",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "Can a promise leave you free?",
				"vi": "Lời hứa có thể để bạn tự do không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "If I choose it and say its limits clearly.",
				"vi": "Nếu tôi tự chọn và nói rõ giới hạn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then it's a route, not a leash.",
						"vi": "Vậy đó là đường đi, không phải dây buộc."
					}
				]
			},
			{
				"id": "B",
				"en": "Sometimes. I need to think before giving it.",
				"vi": "Đôi khi. Tôi cần nghĩ trước khi hứa.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Only if I can change it without telling you.",
				"vi": "Chỉ khi tôi đổi mà không cần nói với bạn.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then I couldn't walk beside it.",
						"vi": "Vậy tôi không thể đi cùng nó."
					}
				]
			}
		]
	},
	{
		"id": "horse.t2.stillness",
		"zodiac": "horse",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "horse",
				"en": "Will you sit here with me for a moment? There isn't a next step yet.",
				"vi": "Bạn ngồi đây với tôi một lát nhé? Chưa có bước tiếp đâu."
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Yes. We can choose it when we're ready.",
				"vi": "Được. Sẵn sàng rồi mình chọn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Then let the road wait.",
						"vi": "Vậy để đường đợi nhé."
					}
				]
			},
			{
				"id": "B",
				"en": "For a moment. I still need to go later.",
				"vi": "Một lát thôi. Sau đó tôi vẫn cần đi.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Only if waiting gets me something.",
				"vi": "Chỉ khi chờ có lợi cho tôi.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "I was asking for your company.",
						"vi": "Tôi đang xin bạn ngồi cùng."
					}
				]
			}
		]
	}
]
