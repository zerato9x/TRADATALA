extends RefCounted
## Snake hears precise agreements, chosen pauses and one physical voice.
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
				"snake.cadence",
				"snake.still",
				"snake.card"
			]
		}
	],
	"memory_button": {
		"en": "Snake's refrain",
		"vi": "Điệp khúc của Tỵ"
	},
	"memory_title": {
		"en": "What Snake remembers",
		"vi": "Điều Tỵ nhớ"
	},
	"memory_topics": {
		"snake.cadence": {
			"en": "The chosen phrase",
			"vi": "Câu nhạc đã chọn"
		},
		"snake.still": {
			"en": "The chosen pause",
			"vi": "Khoảng nghỉ đã chọn"
		},
		"snake.card": {
			"en": "One voice joins",
			"vi": "Một giọng nhập vào"
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
			"en": "Snake lets a sour note trail off. She winces, then lowers her flute without trying again. The green tassels are still.",
			"vi": "Tỵ để nốt chênh tan đi. Cô nhăn mặt, rồi hạ sáo xuống mà không thổi lại. Những tua xanh đứng yên."
		},
		{
			"en": "\"My teacher could make a demand sound like a compliment. I admired that for years. Sometimes I hear her in my own mouth and have to begin again.\"",
			"vi": "\"Thầy tôi biến mệnh lệnh thành lời khen rất khéo. Tôi ngưỡng mộ suốt nhiều năm. Đôi khi nghe giọng thầy trong miệng mình, tôi phải nói lại từ đầu.\""
		},
		{
			"en": "She places a Snake Emblem beside your cup. \"I'd like you to come back on our day. There. No melody to carry the request for me.\"",
			"vi": "Cô đặt Huy hiệu con rắn cạnh cốc. \"Tôi muốn bạn quay lại vào ngày của mình. Đấy. Không có giai điệu nói đỡ lời nhờ.\""
		}
	],
	"last_chance": {
		"id": "snake.last_chance.listen",
		"prompt": [
			{
				"speaker": "snake",
				"en": "My voice is making this sound easier than it is. Shall we try the plain words?",
				"vi": "Giọng tôi khiến việc này nghe dễ hơn thực tế. Mình thử nói thẳng nhé?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Let me name a boundary I can choose and keep.",
				"vi": "Để tôi nói rõ ranh giới mình chọn và giữ được.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Then name it. I won't play over you.",
						"vi": "Vậy nói rõ đi. Tôi không đàn lấn lời bạn."
					}
				]
			},
			{
				"id": "B",
				"en": "I cannot promise more today. I can be clear about that.",
				"vi": "Hôm nay tôi không hứa thêm được. Tôi có thể nói rõ điều đó.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Very clear. No accompaniment needed.",
						"vi": "Rất rõ. Không cần nhạc đệm."
					}
				]
			},
			{
				"id": "C",
				"en": "Tell me the words and I'll repeat them until you're pleased.",
				"vi": "Cho tôi câu chữ, tôi lặp lại đến khi bạn hài lòng.",
				"recovery_success": false,
				"reaction": [
					{
						"speaker": "snake",
						"en": "How convenient. And how little of you is in it. Enough for today.",
						"vi": "Tiện thật. Và chẳng có mấy phần là bạn. Hôm nay đủ rồi."
					}
				]
			}
		]
	},
	"special": []
}
const NODES := [
	{
		"id": "snake.t1.tune",
		"zodiac": "snake",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "Your foot follows the tune before you notice. What would make the next step yours?",
				"vi": "Chân bạn theo nhạc trước khi bạn nhận ra. Điều gì khiến bước kế là do bạn chọn?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Knowing I can stop and still say what I heard.",
				"vi": "Biết mình có thể dừng và vẫn nói được điều đã nghe.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Yes. The way out matters as much as the invitation.",
						"vi": "Ừ. Lối ra cũng quan trọng như lời mời."
					}
				]
			},
			{
				"id": "B",
				"en": "Taking a moment before moving.",
				"vi": "Chờ một chút trước khi bước.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "snake",
						"en": "A breath. Such a small thing to deny someone, isn't it?",
						"vi": "Một hơi thở. Tước nó đi nghe nhỏ nhặt quá nhỉ?"
					}
				]
			},
			{
				"id": "C",
				"en": "Following before anyone notices I am afraid.",
				"vi": "Đi theo trước khi ai thấy tôi sợ.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Then stop. I don't want fear keeping time for me.",
						"vi": "Vậy dừng lại. Tôi không muốn nỗi sợ giữ nhịp hộ mình."
					}
				]
			}
		]
	},
	{
		"id": "snake.t1.sweet",
		"zodiac": "snake",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "Someone calls you generous just before asking a favor. How do you know the sweetness is sincere?",
				"vi": "Ai đó khen bạn hào phóng ngay trước khi nhờ vả. Sao biết lời ngọt ấy thật lòng?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "It still means the same thing if I refuse.",
				"vi": "Tôi từ chối rồi, lời ấy vẫn giữ nghĩa cũ.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Good. Take away the sweetness and read it again.",
						"vi": "Tốt. Bỏ lớp ngọt đi rồi đọc lại."
					}
				]
			},
			{
				"id": "B",
				"en": "I ask what it is asking of me.",
				"vi": "Tôi hỏi nó đang đòi mình điều gì.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "If it sounds kind, the terms cannot matter.",
				"vi": "Nghe tử tế thì điều kiện không quan trọng.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Kindness has excellent manners. So does a well-written invoice.",
						"vi": "Lòng tốt rất lịch thiệp. Hóa đơn viết khéo cũng thế."
					}
				]
			}
		]
	},
	{
		"id": "snake.t1.pause",
		"zodiac": "snake",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "I leave a pause in the song. Who gets to fill it?",
				"vi": "Tôi để một khoảng nghỉ trong bài. Ai được lấp vào?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Whoever has something to offer, with room for an answer.",
				"vi": "Ai có điều muốn trao, và chừa chỗ cho câu trả lời.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Yes. A pause isn't permission to choose somebody else's answer.",
						"vi": "Ừ. Khoảng lặng không cho phép mình chọn hộ câu trả lời của người khác."
					}
				]
			},
			{
				"id": "B",
				"en": "I wait to see whether it is finished.",
				"vi": "Tôi chờ xem đã hết chưa.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "The loudest person. Silence is wasted space.",
				"vi": "Người to tiếng nhất. Im lặng chỉ phí chỗ.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Or perhaps the silence was asking nothing at all.",
						"vi": "Hoặc có khi im lặng chẳng đòi hỏi gì cả."
					}
				]
			}
		]
	},
	{
		"id": "snake.t1plus.cadence",
		"zodiac": "snake",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "Three notes. Can you keep the phrase you chose when a different tune starts sounding sweeter?",
				"vi": "Ba nốt. Bạn giữ được câu đã chọn khi giai điệu khác bắt đầu nghe ngọt hơn không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "If I choose the phrase before beginning.",
				"vi": "Nếu tôi chọn câu ấy trước khi bắt đầu.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Tell me the notes first.",
				"vi": "Cho tôi biết các nốt trước.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "I'll call whatever I play the same tune.",
				"vi": "Hạ gì tôi cũng gọi là cùng giai điệu.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Then why agree on a tune? We could simply admit we wanted different things.",
						"vi": "Vậy sao phải hẹn một giai điệu? Cứ nhận là mình muốn khác nhau cũng được."
					}
				]
			}
		],
		"followup": [
			{
				"speaker": "snake",
				"en": "A new Meld, an Extension, then another new Meld. Make those your first three scoring plays next Deal. Take a breath between them if you need one.",
				"vi": "Tạo Phỏm, Nối Phỏm, rồi Tạo Phỏm nữa. Đó là ba nước hạ đầu Ván tới nhé. Cần thì nghỉ một hơi giữa chúng."
			}
		],
		"promise": {
			"id": "snake.cadence",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"condition": "ordered_scoring",
			"sequence": [
				"new_meld",
				"extension",
				"new_meld"
			],
			"en": "In the next Deal, make your first three successful Meld or Extension actions in this exact order: new Meld, Extension, new Meld. Other actions may happen between them. A different scoring action in the sequence breaks the promise; later plays cannot restart it.",
			"vi": "Trong Ván kế tiếp, thực hiện ba nước Tạo hoặc Nối Phỏm thành công đầu tiên theo đúng thứ tự: Tạo Phỏm, Nối Phỏm, Tạo Phỏm. Các hành động khác được xen giữa. Nước hạ khác thứ tự làm vỡ lời hứa; hạ sau không bắt đầu lại được."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "In order, then. The pauses are yours; the sequence is our agreement.",
						"vi": "Theo thứ tự nhé. Khoảng nghỉ là của bạn; chuỗi nốt là thỏa thuận chung."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Then keep your own tune today.",
						"vi": "Vậy hôm nay cứ giữ giai điệu riêng."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "snake.cadence",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 0,
					"condition": "ordered_scoring",
					"sequence": [
						"new_meld",
						"extension"
					],
					"en": "In the next Deal, make your first two successful Meld or Extension actions in this exact order: new Meld, Extension. Other actions may happen between them. A different scoring action in the sequence breaks the promise; later plays cannot restart it.",
					"vi": "Trong Ván kế tiếp, thực hiện hai nước Tạo hoặc Nối Phỏm thành công đầu tiên theo đúng thứ tự: Tạo Phỏm, Nối Phỏm. Các hành động khác được xen giữa. Nước hạ khác thứ tự làm vỡ lời hứa; hạ sau không bắt đầu lại được."
				},
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Two notes instead: new Meld, then Extension. Confirm the shorter phrase if that is the one you want.",
						"vi": "Hai nốt thôi: Tạo Phỏm rồi Nối Phỏm. Nếu muốn câu ngắn ấy thì xác nhận nhé."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Shorter does not mean already agreed. We can leave it there.",
						"vi": "Ngắn hơn chưa có nghĩa là đã đồng ý. Mình dừng ở đó được."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Exactly the phrase you chose. You let the pauses breathe without changing the notes.",
						"vi": "Đúng câu bạn chọn. Bạn để khoảng nghỉ thở mà không đổi nốt."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "That wasn't the whole phrase we agreed. A lovely variation is still a different song.",
						"vi": "Đó chưa phải trọn câu mình hẹn. Biến tấu hay đến đâu vẫn là bài khác."
					}
				]
			}
		}
	},
	{
		"id": "snake.t1plus.still",
		"zodiac": "snake",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "Can a card stay where you left it while you choose the next note?",
				"vi": "Lá bài có thể ở chỗ bạn đã để trong lúc bạn chọn nốt kế chứ?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Yes, if I agree how long to leave it.",
				"vi": "Được, nếu tôi đồng ý để nó đến bao giờ.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Let me hear the length of the pause.",
				"vi": "Cho tôi nghe khoảng nghỉ dài bao lâu.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "I'll take it back and pretend nobody heard.",
				"vi": "Tôi lấy lại rồi giả vờ không ai nghe thấy.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "You could. I would still hear the card come back.",
						"vi": "Bạn làm được. Tôi vẫn nghe lá bài quay về."
					}
				]
			}
		],
		"followup": [
			{
				"speaker": "snake",
				"en": "For the next whole Deal, leave Drink recoveries alone. Nhân Trần, Đen Đá, Nước Vối, Nâu Đá: let those cards rest until both Phases settle.",
				"vi": "Cả Ván tới, để yên việc lấy lại bài bằng Nước. Nhân Trần, Đen Đá, Nước Vối, Nâu Đá: cho bài nghỉ đến khi chốt cả hai Hiệp."
			}
		],
		"promise": {
			"id": "snake.still",
			"polarity": "DONT",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"condition": "no_recovery",
			"en": "For both Phases of the next Deal, do not recover cards through Nhân Trần, Đen Đá, Nước Vối, or Nâu Đá. Only a successful recovery breaks the promise; opening, previewing, or cancelling a Drink does not. The commitment is complete when Phase 2 settles.",
			"vi": "Trong cả hai Hiệp của Ván kế tiếp, không lấy lại bài bằng Nhân Trần, Đen Đá, Nước Vối hoặc Nâu Đá. Chỉ lấy lại thành công mới làm vỡ lời hứa; mở, xem trước hoặc hủy Nước không tính. Cam kết hoàn thành khi chốt Hiệp 2."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Both Phases. You may look at the Drink. Only a completed recovery crosses the line.",
						"vi": "Cả hai Hiệp. Bạn được xem Nước. Chỉ lấy bài về thành công mới vượt giới hạn."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Then leave the pause unnamed. I will not call it a promise.",
						"vi": "Vậy đừng đặt tên khoảng nghỉ. Tôi không gọi đó là lời hứa."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "snake.still",
					"polarity": "DONT",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 1,
					"condition": "no_recovery",
					"en": "In Phase 1 of the next Deal, do not recover cards through Nhân Trần, Đen Đá, Nước Vối, or Nâu Đá. Only a successful recovery breaks the promise; opening, previewing, or cancelling a Drink does not. The commitment ends when Phase 1 settles; Phase 2 is unrestricted.",
					"vi": "Trong Hiệp 1 của Ván kế tiếp, không lấy lại bài bằng Nhân Trần, Đen Đá, Nước Vối hoặc Nâu Đá. Chỉ lấy lại thành công mới làm vỡ lời hứa; mở, xem trước hoặc hủy Nước không tính. Cam kết kết thúc khi chốt Hiệp 1; Hiệp 2 không bị ràng buộc."
				},
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Only Phase 1, then. After it settles, you may recover cards again. Confirm that shorter boundary.",
						"vi": "Vậy chỉ Hiệp 1. Chốt xong bạn lại được lấy bài. Hãy xác nhận ranh giới ngắn hơn ấy."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Even one Phase needs an answer. No is an answer.",
						"vi": "Một Hiệp cũng cần câu trả lời. Từ chối cũng là trả lời."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "You left the recoveries alone for the agreed time. Even when the old notes called you back.",
						"vi": "Bạn không lấy bài về trong đúng thời gian đã hẹn. Kể cả khi nốt cũ gọi lại."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "You recovered a card before the pause ended. Softly done is still done.",
						"vi": "Bạn lấy một lá về trước khi hết khoảng nghỉ. Làm nhẹ tay vẫn là đã làm."
					}
				]
			}
		}
	},
	{
		"id": "snake.t1plus.card",
		"zodiac": "snake",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "Which note would you bring into a song that has already begun?",
				"vi": "Bạn mang nốt nào vào bài nhạc đã bắt đầu?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "One I choose, with a place to join.",
				"vi": "Nốt tôi tự chọn, có chỗ để nhập vào.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Show me three and let me listen.",
				"vi": "Cho tôi xem ba nốt rồi nghe đã.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Any lookalike will do. You won't hear the difference.",
				"vi": "Nốt giống giống là được. Bạn chẳng nghe ra đâu.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "I would. I was listening to that one.",
						"vi": "Tôi nghe ra. Tôi đang nghe đúng lá ấy."
					}
				]
			}
		],
		"initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"followup": [
			{
				"speaker": "snake",
				"en": "Choose one of these three cards. Next Deal, join that very card to an existing Meld with an Extension. A new Meld is a different entrance.",
				"vi": "Chọn một trong ba lá này. Ván tới, cho đúng lá ấy nhập vào Phỏm có sẵn bằng Nối Phỏm. Tạo Phỏm mới là một cách vào khác."
			}
		],
		"promise": {
			"id": "snake.card",
			"polarity": "DO",
			"interaction": "card_play",
			"target_kind": "CARD",
			"targeting": "ANY",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"action": "extension",
			"en": "Choose one of the three offered physical cards. In the next Deal, add that exact card to an existing Meld through a successful Extension. Playing it in a new Meld, drawing it, swapping it, or playing another copy of its rank does not fulfill this promise.",
			"vi": "Chọn một trong ba lá vật lý được đưa ra. Trong Ván kế tiếp, thêm đúng lá đó vào Phỏm có sẵn bằng Nối Phỏm thành công. Hạ nó trong Phỏm mới, rút, đổi, hoặc hạ lá khác cùng hạng không hoàn thành lời hứa."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "That card, through an Extension. A precise entrance; no need to make it grand.",
						"vi": "Đúng lá ấy, qua Nối Phỏm. Vào đúng chỗ; không cần phô trương."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Then keep the three possibilities. None has become your word.",
						"vi": "Vậy giữ ba khả năng. Chưa lá nào thành lời của bạn."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "There it is. Your card joined the existing Meld. Quietly exact.",
						"vi": "Đây rồi. Lá bạn nối vào Phỏm có sẵn. Lặng lẽ mà chính xác."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "Your card didn't make that entrance. Another voice can't answer in its place.",
						"vi": "Lá bạn chưa vào đúng lối ấy. Giọng khác không trả lời thay được."
					}
				]
			}
		}
	},
	{
		"id": "snake.t2.cadence_memory",
		"zodiac": "snake",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"answers": [
			{
				"id": "A",
				"en": "I'd follow the order I agreed to, even if we shortened it.",
				"vi": "Tôi theo đúng thứ tự đã nhận, dù mình rút ngắn lại.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Good. I don't have to guess where the music ends and your answer begins.",
						"vi": "Tốt. Tôi khỏi phải đoán nhạc hết chỗ nào, lời bạn bắt đầu chỗ nào."
					}
				]
			},
			{
				"id": "B",
				"en": "I'd check the next note before playing it.",
				"vi": "Tôi xem nốt tiếp theo trước khi chơi.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Start again until the first attempt disappears.",
				"vi": "Làm lại đến khi lần đầu biến mất.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Play again, by all means. The first attempt doesn't become unheard.",
						"vi": "Cứ chơi lại. Lần đầu không vì thế mà thành chưa từng được nghe."
					}
				]
			}
		],
		"memory_key": "snake.cadence",
		"promise_from": "snake.t1plus.cadence",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "snake",
					"en": "The exact phrase: {target} Did choosing the order make it easier to resist another tune?",
					"vi": "Đúng câu nhạc: {target} Chọn sẵn thứ tự có giúp bạn cưỡng giai điệu khác không?"
				}
			],
			"BROKEN": [
				{
					"speaker": "snake",
					"en": "The phrase didn't hold: {target} Which note sounded more inviting than your promise?",
					"vi": "Câu nhạc chưa trọn: {target} Nốt nào hấp dẫn hơn lời hứa của bạn?"
				}
			],
			"REFUSED": [
				{
					"speaker": "snake",
					"en": "You wouldn't sing this phrase: {target} I wonder what you heard that I didn't.",
					"vi": "Bạn không nhận câu nhạc này: {target} Tôi tự hỏi bạn nghe ra điều gì tôi chưa nghe."
				}
			]
		}
	},
	{
		"id": "snake.t2.still_memory",
		"zodiac": "snake",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"answers": [
			{
				"id": "A",
				"en": "I'd want to know exactly when the pause ends.",
				"vi": "Tôi muốn biết rõ khoảng nghỉ kết thúc lúc nào.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Yes. A rest with edges. Otherwise I could keep you silent forever.",
						"vi": "Ừ. Dấu lặng có giới hạn. Không thì tôi có thể bắt bạn im mãi."
					}
				]
			},
			{
				"id": "B",
				"en": "A shorter pause might fit my hand better.",
				"vi": "Khoảng nghỉ ngắn hơn có thể hợp tay bài tôi.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Return the card quietly and call that restraint.",
				"vi": "Lấy lại nhẹ tay rồi gọi đó là giữ mình.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Quietly isn't the same as never.",
						"vi": "Lặng lẽ không có nghĩa là chưa từng."
					}
				]
			}
		],
		"memory_key": "snake.still",
		"promise_from": "snake.t1plus.still",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "snake",
					"en": "You kept the pause: {target} Was it quiet, or full of things you nearly did?",
					"vi": "Bạn giữ khoảng nghỉ: {target} Nó yên lặng, hay đầy những việc bạn suýt làm?"
				}
			],
			"BROKEN": [
				{
					"speaker": "snake",
					"en": "The pause broke: {target} What called the card back before our time was up?",
					"vi": "Khoảng nghỉ bị phá: {target} Điều gì gọi lá bài về trước giờ mình hẹn?"
				}
			],
			"REFUSED": [
				{
					"speaker": "snake",
					"en": "You didn't promise this pause: {target} Perhaps you heard how much I was asking under the gentle voice.",
					"vi": "Bạn không hứa khoảng nghỉ này: {target} Có lẽ bạn nghe được giọng nhẹ nhàng ấy đòi hỏi nhiều thế nào."
				}
			]
		}
	},
	{
		"id": "snake.t2.card_memory",
		"zodiac": "snake",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"answers": [
			{
				"id": "A",
				"en": "I'd find a place for that exact card, not one that looks like it.",
				"vi": "Tôi tìm chỗ cho đúng lá ấy, không phải lá giống nó.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Yes. I remember the voice, not just the pitch.",
						"vi": "Ừ. Tôi nhớ giọng, không chỉ nhớ cao độ."
					}
				]
			},
			{
				"id": "B",
				"en": "I'd look for a Meld it could join.",
				"vi": "Tôi tìm Phỏm nó nối vào được.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Any card of the same rank should count.",
				"vi": "Lá nào cùng hạng cũng nên tính.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Same pitch, different voice. I asked for the one you chose.",
						"vi": "Cùng cao độ, khác giọng. Tôi hỏi đúng lá bạn chọn."
					}
				]
			}
		],
		"memory_key": "snake.card",
		"promise_from": "snake.t1plus.card",
		"initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "snake",
					"en": "{target} made its entrance. I knew which voice to listen for. Did you?",
					"vi": "{target} vào đúng lối. Tôi biết cần nghe giọng nào. Bạn thì sao?"
				}
			],
			"BROKEN": [
				{
					"speaker": "snake",
					"en": "{target} missed that entrance. Was there another song you wanted it in?",
					"vi": "{target} lỡ lối vào ấy. Bạn muốn nó ở bài hát khác à?"
				}
			],
			"REFUSED": [
				{
					"speaker": "snake",
					"en": "No promise for {target}. You let my invitation pass without mistaking it for an order.",
					"vi": "Không nhận lời hứa cho {target}. Bạn để lời mời của tôi đi qua, không nhầm thành mệnh lệnh."
				}
			]
		}
	},
	{
		"id": "snake.t2.unplayed",
		"zodiac": "snake",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "There's a song I won't play for a crowd. I can't make it sound effortless. Would you ask for it?",
				"vi": "Có bài tôi không chơi trước đám đông. Tôi không làm nó nghe nhẹ nhàng được. Bạn có xin nghe không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "I would ask, and leave you room not to play.",
				"vi": "Tôi sẽ xin, và chừa chỗ để bạn không chơi.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Perhaps. I might need you to hear where my hands shake.",
						"vi": "Có lẽ. Tôi có thể cần bạn nghe cả đoạn tay mình run."
					}
				]
			},
			{
				"id": "B",
				"en": "Only if you wanted to tell me about it.",
				"vi": "Chỉ khi bạn muốn kể về nó.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "You owe it to me after all these visits.",
				"vi": "Gặp bao lần rồi, bạn nợ tôi bài ấy.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "You bought no ticket to that part of me.",
						"vi": "Bạn chưa mua vé vào phần ấy của tôi."
					}
				]
			}
		]
	},
	{
		"id": "snake.t2.shed",
		"zodiac": "snake",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "You know what they say about my tongue and my heart. When I speak kindly, do you search for the trick?",
				"vi": "Bạn biết người ta nói gì về miệng và lòng tôi. Tôi nói tử tế, bạn có tìm mưu mẹo không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "The memory, with space to notice what changes.",
				"vi": "Ký ức, và chỗ để thấy điều đang đổi.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Keep watching, then. I'd rather earn a new story than demand one.",
						"vi": "Vậy cứ quan sát. Tôi thà tự tạo chuyện mới còn hơn đòi người ta kể khác."
					}
				]
			},
			{
				"id": "B",
				"en": "What you have actually shown me.",
				"vi": "Điều bạn thực sự cho tôi thấy.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "The first story. New words cannot change it.",
				"vi": "Câu chuyện đầu. Lời mới không đổi được.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Then every word I say has been sentenced before it leaves my mouth.",
						"vi": "Vậy lời nào của tôi cũng bị kết án trước khi ra khỏi miệng."
					}
				]
			}
		]
	},
	{
		"id": "snake.t2.rest",
		"zodiac": "snake",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "snake",
				"en": "I'm putting the instrument away. I don't quite know what to do with my hands. Stay?",
				"vi": "Tôi cất đàn đây. Chưa biết để tay đâu cho phải. Ở lại nhé?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Yes. You do not have to keep the room enchanted.",
				"vi": "Có. Bạn không cần giữ cả phòng mê nhạc.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "All right. Tea first. I'll try asking for the sugar without making it sound like destiny.",
						"vi": "Được. Uống trà đã. Tôi thử xin đường mà không nói như định mệnh xem."
					}
				]
			},
			{
				"id": "B",
				"en": "We could share a quiet cup.",
				"vi": "Mình có thể uống một chén yên tĩnh.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Only if you promised a better song afterwards.",
				"vi": "Chỉ khi bạn hứa chơi bài hay hơn sau đó.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "You do bargain beautifully. I was hoping you wouldn't, just this once.",
						"vi": "Bạn mặc cả khéo thật. Tôi đã mong chỉ lần này thôi, bạn đừng làm vậy."
					}
				]
			}
		]
	}
]
