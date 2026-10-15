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
			"en": "Horse draws a road in the condensation on the table. At its end he adds a small square, then a second chair.",
			"vi": "Ngọ vẽ con đường trên vệt nước đọng trên bàn. Cuối đường, anh vẽ một ô vuông nhỏ, rồi thêm chiếc ghế thứ hai."
		},
		{
			"en": "\"I tell people I know every way out of town. Never mention how often I take the long way back. This corner's better after sunset.\"",
			"vi": "\"Tôi hay khoe biết mọi đường ra khỏi phố. Chẳng kể mình hay đi vòng thật xa để quay lại. Góc này sau hoàng hôn đẹp hơn.\""
		},
		{
			"en": "He puts a horse Emblem at the end of the road. \"Our day. Here. No race. I'll try being the one who arrives early and waits.\"",
			"vi": "Anh đặt Huy hiệu con ngựa ở cuối đường. \"Ngày của mình. Chỗ này. Không đua. Tôi thử làm người đến sớm ngồi chờ.\""
		}
	],
	"last_chance": {
		"id": "horse.last_chance.pause",
		"prompt": [
			{
				"speaker": "horse",
				"en": "Hold up. We're running in circles. Where do you actually want to go?",
				"vi": "Khoan. Mình đang chạy vòng. Bạn thật sự muốn đi đâu?"
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
						"en": "Good. Your pace. I can match it once you tell me.",
						"vi": "Được. Nhịp của bạn. Nói rồi tôi mới theo được."
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
						"en": "Then stop here. A road doesn't vanish because you sit down.",
						"vi": "Vậy dừng đây. Bạn ngồi xuống thì đường có biến mất đâu."
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
						"en": "That's an answer looking for the nearest exit. Use it.",
						"vi": "Câu ấy chỉ tìm cửa gần nhất để thoát. Cứ đi đi."
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
				"en": "Two roads out. One's quick, one's interesting. What gets your feet moving?",
				"vi": "Hai đường ra. Một nhanh, một hay. Điều gì khiến bạn bước đi?"
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
						"en": "Good. Don't blame the signpost halfway there.",
						"vi": "Được. Đi nửa đường đừng trách biển chỉ lối."
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
						"en": "Fair. I've followed worse maps than my own eyes.",
						"vi": "Cũng được. Tôi từng theo những bản đồ còn tệ hơn mắt mình."
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
						"en": "Fastest to where? The crowd won't carry your bags.",
						"vi": "Nhanh nhất đến đâu? Đám đông đâu có xách đồ hộ bạn."
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
				"en": "You're flying along. I'm falling behind. What do you do?",
				"vi": "Bạn đi vùn vụt. Tôi tụt lại. Bạn làm gì?"
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
						"en": "Together, then. I'd rather share the road than send you a postcard.",
						"vi": "Vậy cùng đi. Tôi thà chung đường còn hơn gửi bưu thiếp cho bạn."
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
						"en": "Which corner? I've waited at the wrong one before.",
						"vi": "Góc nào? Tôi từng chờ nhầm góc rồi."
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
						"en": "Then call it a race next time. I'd like to know before we set off.",
						"vi": "Vậy lần sau gọi là đua nhé. Tôi muốn biết trước khi khởi hành."
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
				"en": "I stopped halfway across a bridge once. Lovely view. Does that count as getting lost?",
				"vi": "Có lần tôi dừng giữa cầu. Cảnh đẹp lắm. Thế có tính là lạc đường không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "No. Stopping can help you choose the next step.",
				"vi": "Không. Dừng lại có thể giúp chọn bước tiếp.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Exactly. You can't read a sign at full gallop.",
						"vi": "Chính xác. Phi hết tốc lực thì đọc biển thế nào."
					}
				]
			},
			{
				"id": "B",
				"en": "Depends why you stopped.",
				"vi": "Còn tùy vì sao bạn dừng.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Yes. Resting and being stuck look alike from a distance.",
						"vi": "Ừ. Nhìn xa thì nghỉ chân với mắc kẹt giống nhau."
					}
				]
			},
			{
				"id": "C",
				"en": "Yes. Keep moving, whatever it costs.",
				"vi": "Có. Cứ đi tiếp, bất kể giá nào.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "I've done that. Arrived miles away from anywhere I wanted to be.",
						"vi": "Tôi làm rồi. Đến nơi cách xa chỗ mình muốn hàng dặm."
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
						"en": "Two matching actions, one Turn. A stride, not two lonely footsteps.",
						"vi": "Hai hành động cùng loại trong một Lượt. Một sải bước, không phải hai bước rời."
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
						"en": "Both in one Turn. Now that had some pace to it!",
						"vi": "Cả hai trong một Lượt. Thế mới ra nhịp chứ!"
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "The pair got split across the road. One Turn was the agreement.",
						"vi": "Cặp bước bị tách giữa đường rồi. Mình đã hẹn trong một Lượt."
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
						"en": "Your first Meld, before that Turn ends. I'll wait at that corner.",
						"vi": "Phỏm đầu tiên, trước khi hết Lượt ấy. Tôi chờ đúng góc đó."
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
						"en": "Started it, came back to it, finished in time. A route worth knowing.",
						"vi": "Bắt đầu, quay lại, làm kịp. Đường ấy đáng nhớ."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "The first Meld was still waiting when time ran out. Another road doesn't lead back to it.",
						"vi": "Hết giờ, Phỏm đầu vẫn chờ nối. Đường khác không dẫn ngược về nó được."
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
						"en": "That card has to join through an Extension. No waving from a passing carriage.",
						"vi": "Lá đó phải vào bằng Nối Phỏm. Vẫy tay từ xe ngang qua không tính nhé."
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
						"en": "There it goes! Your card joined the Extension. I like seeing a route become real.",
						"vi": "Đi rồi! Lá bạn vào Phỏm bằng lần nối. Tôi thích thấy đường vẽ thành đường đi."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "horse",
						"en": "That card never made the Extension. Standing near the road isn't travelling it.",
						"vi": "Lá đó chưa được nối vào. Đứng cạnh đường không phải đã đi đường."
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
					"en": "A pair in one Turn: {target} Was that a sprint, or did the second step come naturally?",
					"vi": "Một cặp trong một Lượt: {target} Phải chạy nước rút, hay bước thứ hai tự đến?"
				}
			],
			"BROKEN": [
				{
					"speaker": "horse",
					"en": "The pair got separated: {target} Where did you have to slow down?",
					"vi": "Cặp bước bị tách rồi: {target} Bạn phải chậm lại ở đâu?"
				}
			],
			"REFUSED": [
				{
					"speaker": "horse",
					"en": "You left this route open: {target} Did you find a better one once the cards arrived?",
					"vi": "Bạn để ngỏ đường này: {target} Có bài rồi, bạn tìm được đường tốt hơn không?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "Knowing what I could finish before ending the Turn.",
				"vi": "Biết mình làm xong được gì trước khi kết Lượt.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Good. Now I know which corner you mean.",
						"vi": "Được. Giờ tôi biết bạn nói góc nào."
					}
				]
			},
			{
				"id": "B",
				"en": "Working with the hand I had, not the one I wanted.",
				"vi": "Dùng tay bài đang có, không phải tay bài tôi muốn.",
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
						"en": "Two separate walks. You can't tie their ends together afterward.",
						"vi": "Hai chuyến riêng. Xong rồi không buộc đầu đuôi lại thành một được."
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
					"en": "You stayed with your start: {target} I always want to know what's around the next corner. How did you resist?",
					"vi": "Bạn theo đến cùng khởi đầu: {target} Tôi luôn tò mò góc kế có gì. Sao bạn cưỡng được?"
				}
			],
			"BROKEN": [
				{
					"speaker": "horse",
					"en": "We missed the meeting point: {target} Don't give me a faster time yet. Tell me what happened.",
					"vi": "Mình lỡ chỗ hẹn: {target} Khoan hứa giờ nhanh hơn. Kể tôi chuyện đã xảy ra."
				}
			],
			"REFUSED": [
				{
					"speaker": "horse",
					"en": "You didn't take this route: {target} Felt good to keep the first turn yours, didn't it?",
					"vi": "Bạn không nhận đường này: {target} Giữ được lượt đầu cho mình quyết, cũng dễ chịu nhỉ?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I need to know where I'm going, not just how to start.",
				"vi": "Tôi cần biết mình đi đâu, không chỉ biết bắt đầu.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Yes. Name the finish before your feet leave the ground.",
						"vi": "Ừ. Nói rõ đích đến trước khi nhấc chân."
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
						"en": "Different start. I was waiting by the first one.",
						"vi": "Điểm xuất phát khác rồi. Tôi chờ ở cái đầu tiên."
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
					"en": "An Extension for {target}. A little further than it could go alone. Planned, or a lucky turn?",
					"vi": "{target} được nối vào. Đi xa hơn một chút so với đứng riêng. Bạn tính trước hay may gặp ngã rẽ?"
				}
			],
			"BROKEN": [
				{
					"speaker": "horse",
					"en": "No Extension for {target}. Did it end up somewhere you hadn't expected?",
					"vi": "{target} chưa được nối vào. Nó có đến chỗ bạn không ngờ không?"
				}
			],
			"REFUSED": [
				{
					"speaker": "horse",
					"en": "No promise for {target}. Sometimes I keep a road on the map without taking it.",
					"vi": "Không nhận lời hứa cho {target}. Có đường tôi vẫn giữ trên bản đồ mà không đi."
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I'd tell you where it went, even if that wasn't the plan.",
				"vi": "Tôi sẽ nói nó đã đi đâu, dù không đúng kế hoạch.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Good. I'd rather hear where it went than where it ought to have gone.",
						"vi": "Tốt. Tôi muốn nghe nó đã đi đâu, hơn là lẽ ra phải đi đâu."
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
						"en": "Walk the same bridge twice. Lovely. Still the same bridge.",
						"vi": "Qua cùng cây cầu hai lần. Đẹp đấy. Vẫn là cây cầu đó."
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
				"en": "When you tell this journey later, will I be in it, or just the arrival time?",
				"vi": "Sau này kể chuyến này, bạn nhắc tôi hay chỉ nhắc giờ đến?"
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
						"en": "Then I'll remember the bit where we slowed down. Probably my favorite bit.",
						"vi": "Vậy tôi sẽ nhớ đoạn mình đi chậm lại. Chắc là đoạn tôi thích nhất."
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
						"en": "I know you could. I was asking whether you liked the company.",
						"vi": "Tôi biết bạn đến trước được. Tôi hỏi có thích người đi cùng không."
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
				"en": "Funny thing. I promise to be somewhere and suddenly the whole road feels chosen. Do you get that?",
				"vi": "Lạ nhỉ. Hứa đến một nơi, tự dưng cả con đường thành điều mình chọn. Bạn hiểu không?"
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
						"en": "Yes! A destination. I kept mistaking those for fences.",
						"vi": "Đúng! Một điểm đến. Tôi cứ nhầm nó với hàng rào."
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
						"en": "Then I'd reach the meeting place and find nobody there.",
						"vi": "Vậy tôi đến chỗ hẹn mà chẳng thấy ai."
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
				"en": "Stay for the sunset? I know a faster road home, but I'd rather take it later.",
				"vi": "Ở xem hoàng hôn nhé? Tôi biết đường về nhanh hơn, nhưng muốn đi muộn chút."
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Yes. The road home can wait a little.",
				"vi": "Có. Đường về chờ thêm chút được.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "horse",
						"en": "Good. For once I won't be telling you what the view looked like over my shoulder.",
						"vi": "Tốt. Lần này tôi khỏi kể cảnh đẹp qua một cái ngoái đầu."
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
						"en": "The sunset, mostly. And an hour with me. I thought that was something.",
						"vi": "Chủ yếu là hoàng hôn. Với một giờ bên tôi. Tôi tưởng thế cũng đáng."
					}
				]
			}
		]
	}
]
