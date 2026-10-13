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
			"en": "Snake rests the instrument against the chair. The green tassels stop moving. For once, the room is quiet without waiting for a command.",
			"vi": "Tỵ tựa nhạc cụ vào ghế. Những tua xanh ngừng đung đưa. Lần này, căn phòng yên mà không chờ một mệnh lệnh."
		},
		{
			"en": "\"You heard the words inside the music. You kept some, shortened some, and left some unpromised. I can set the song down with someone who knows their own answer.\"",
			"vi": "\"Bạn nghe được lời bên trong tiếng nhạc. Có lời bạn giữ, có lời rút ngắn, có lời không hứa. Tôi đặt bài nhạc xuống được bên người biết câu trả lời của mình.\""
		},
		{
			"en": "A small Snake Emblem settles beside your cup. \"Bring it on our day if you want to sit here again. It is an invitation. You may leave it quiet.\"",
			"vi": "Huy hiệu con rắn nhỏ nằm bên chén của bạn. \"Đến ngày của mình, muốn ngồi đây nữa thì mang theo nhé. Đây là lời mời. Bạn có thể để nó yên.\""
		}
	],
	"last_chance": {
		"id": "snake.last_chance.listen",
		"prompt": [
			{
				"speaker": "snake",
				"en": "The phrase has tightened. Before I stop listening, what do you actually want to say?",
				"vi": "Câu nhạc đã siết lại. Trước khi tôi thôi nghe, bạn thực sự muốn nói gì?"
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
						"en": "Then say it plainly. I am listening.",
						"vi": "Vậy nói rõ nhé. Tôi đang nghe."
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
						"en": "That is a voice I can hear.",
						"vi": "Đó là giọng tôi nghe được."
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
						"en": "Then we will leave the echo here.",
						"vi": "Vậy mình dừng tiếng vọng ở đây."
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
				"en": "When the tune catches your ear, what makes the next step yours?",
				"vi": "Khi giai điệu cuốn tai, điều gì khiến bước tiếp theo là của bạn?"
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
						"en": "Then you are listening, too.",
						"vi": "Vậy bạn cũng đang lắng nghe."
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
						"en": "A breath can change the whole phrase.",
						"vi": "Một hơi thở đổi được cả câu nhạc."
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
						"en": "I can hear the hurry in that answer.",
						"vi": "Tôi nghe được sự vội vàng trong câu đó."
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
				"en": "How do you know a sweet word is worth keeping?",
				"vi": "Làm sao biết một lời ngọt đáng giữ?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "It means the same thing after the music stops.",
				"vi": "Nó vẫn mang nghĩa ấy khi nhạc dừng.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Good. Listen to the quiet version.",
						"vi": "Tốt. Nghe cả lúc yên nhé."
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
						"en": "A soft voice can still name a price.",
						"vi": "Giọng nhẹ vẫn nói được một cái giá."
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
				"en": "There is a pause in the song. Who gets to fill it?",
				"vi": "Bài nhạc có khoảng nghỉ. Ai được lấp vào?"
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
						"en": "Then leave me room to hear it.",
						"vi": "Vậy chừa chỗ cho tôi nghe nhé."
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
						"en": "You would miss the note that is waiting.",
						"vi": "Bạn sẽ bỏ lỡ nốt đang chờ."
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
				"en": "Can you carry a phrase without changing its middle?",
				"vi": "Bạn giữ được một câu nhạc mà không đổi phần giữa chứ?"
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
						"en": "Then we would be remembering different songs.",
						"vi": "Vậy mình sẽ nhớ hai bài khác nhau."
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
						"en": "Three notes, in the order you chose. I will not rename a wrong note.",
						"vi": "Ba nốt, theo thứ tự bạn đã chọn. Tôi không đổi tên nốt sai đâu."
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
						"en": "I heard the phrase we agreed on, in order. The pauses belonged to you.",
						"vi": "Tôi đã nghe đúng câu mình thống nhất, đúng thứ tự. Những khoảng nghỉ thuộc về bạn."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "The phrase changed, or ended before the agreed notes. A later beginning did not erase it.",
						"vi": "Câu nhạc đã đổi, hoặc dừng trước đủ nốt đã hẹn. Khởi đầu sau không xóa được câu ấy."
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
						"en": "The quiet has ears, too.",
						"vi": "Khoảng yên cũng có tai."
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
						"en": "Both Phases, then. Choosing a Drink is still yours; actually recovering a card is the boundary.",
						"vi": "Vậy cả hai Hiệp nhé. Bạn vẫn được chọn Nước; thật sự lấy lại lá bài mới là ranh giới."
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
						"en": "The cards rested for the time you named. You kept the quiet without borrowing another note.",
						"vi": "Bài đã nghỉ đúng thời gian bạn chọn. Bạn giữ khoảng yên mà không mượn thêm nốt."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "A card came back before the agreed pause ended. I remember the boundary, not how softly it crossed.",
						"vi": "Một lá trở lại trước khi hết khoảng nghỉ đã hẹn. Tôi nhớ ranh giới, không nhớ bạn bước qua nhẹ đến đâu."
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
						"en": "I listen for the one you chose.",
						"vi": "Tôi nghe đúng nốt bạn đã chọn."
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
						"en": "That card, joining a song already playing. I have heard your choice.",
						"vi": "Lá ấy, nhập vào bài nhạc đang chơi. Tôi nghe lựa chọn của bạn rồi."
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
						"en": "Your chosen card joined through an Extension. Its place was small, but it was its own.",
						"vi": "Lá bạn chọn đã nhập vào bằng Nối Phỏm. Chỗ của nó nhỏ, nhưng đúng là chỗ của nó."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "snake",
						"en": "That exact card did not join through an Extension. A similar face or a new beginning was not the promise.",
						"vi": "Đúng lá ấy chưa nhập vào bằng Nối Phỏm. Mặt giống nhau hay khởi đầu mới không phải lời đã hứa."
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
				"en": "The order I actually agreed to, including a shorter counteroffer.",
				"vi": "Thứ tự tôi thực sự đồng ý, kể cả câu rút ngắn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "Then I can hear your word without guessing.",
						"vi": "Vậy tôi nghe được lời bạn mà không đoán."
					}
				]
			},
			{
				"id": "B",
				"en": "Check the next note before committing it.",
				"vi": "Xem nốt tiếp trước khi hạ.",
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
						"en": "A second phrase does not silence the first.",
						"vi": "Câu thứ hai không làm câu đầu im đi."
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
					"en": "You kept this phrase: {target} What let the middle stay where you chose it?",
					"vi": "Bạn đã giữ câu này: {target} Điều gì giữ phần giữa đúng chỗ bạn chọn?"
				}
			],
			"BROKEN": [
				{
					"speaker": "snake",
					"en": "This phrase changed: {target} What would you name before trying again?",
					"vi": "Câu này đã đổi: {target} Trước khi thử lại bạn sẽ nói rõ điều gì?"
				}
			],
			"REFUSED": [
				{
					"speaker": "snake",
					"en": "You left this phrase unpromised: {target} What tune did you need room for?",
					"vi": "Bạn chưa hứa câu này: {target} Bạn cần chỗ cho giai điệu nào?"
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
				"en": "The exact Phase boundary, with room to refuse it.",
				"vi": "Đúng ranh giới Hiệp, và có quyền từ chối.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "A chosen silence has a beginning and an end.",
						"vi": "Khoảng yên tự chọn có đầu có cuối."
					}
				]
			},
			{
				"id": "B",
				"en": "A shorter pause might suit the hand.",
				"vi": "Khoảng nghỉ ngắn hơn có thể hợp bài.",
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
						"en": "Quiet hands still move cards.",
						"vi": "Tay nhẹ vẫn di chuyển bài."
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
					"en": "You kept this pause: {target} What made leaving the cards alone possible?",
					"vi": "Bạn đã giữ khoảng nghỉ này: {target} Điều gì giúp bạn để bài yên?"
				}
			],
			"BROKEN": [
				{
					"speaker": "snake",
					"en": "A card crossed this pause: {target} What boundary would you choose now?",
					"vi": "Một lá đã bước qua khoảng nghỉ này: {target} Giờ bạn chọn ranh giới nào?"
				}
			],
			"REFUSED": [
				{
					"speaker": "snake",
					"en": "You did not promise this pause: {target} What needed to stay in reach?",
					"vi": "Bạn không hứa khoảng nghỉ này: {target} Bạn cần còn với tới điều gì?"
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
				"en": "A place for that physical card, not a substitute.",
				"vi": "Chỗ cho đúng lá vật lý ấy, không phải lá thay.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "snake",
						"en": "I can remember one voice among its echoes.",
						"vi": "Tôi nhớ được một giọng giữa những tiếng vọng."
					}
				]
			},
			{
				"id": "B",
				"en": "See what existing Meld can receive it.",
				"vi": "Xem Phỏm có sẵn nào nhận được nó.",
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
						"en": "We chose a card, not a resemblance.",
						"vi": "Mình chọn một lá, không chọn sự giống nhau."
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
					"en": "This card found its entrance: {target} Why did you choose that voice?",
					"vi": "Lá này đã tìm được lối vào: {target} Vì sao bạn chọn giọng ấy?"
				}
			],
			"BROKEN": [
				{
					"speaker": "snake",
					"en": "This card missed the entrance we named: {target} What would help you choose again?",
					"vi": "Lá này lỡ lối vào đã hẹn: {target} Điều gì giúp bạn chọn lại?"
				}
			],
			"REFUSED": [
				{
					"speaker": "snake",
					"en": "You left this card unpromised: {target} What place were you looking for?",
					"vi": "Bạn chưa hứa lá này: {target} Bạn đang tìm chỗ nào?"
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
				"en": "There is a tune I never play at the table. Would you ask to hear it?",
				"vi": "Có giai điệu tôi không bao giờ chơi ở bàn. Bạn có xin nghe không?"
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
						"en": "Then perhaps there is room for it here.",
						"vi": "Vậy có lẽ ở đây có chỗ cho nó."
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
						"en": "A visit is not a hand around the instrument.",
						"vi": "Một lần ghé không phải bàn tay nắm nhạc cụ."
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
				"en": "People keep the old skin and say it explains every step. What would you keep?",
				"vi": "Người ta giữ lớp da cũ rồi bảo nó giải thích mọi bước đi. Bạn giữ gì?"
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
						"en": "That is lighter to carry.",
						"vi": "Mang vậy nhẹ hơn."
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
						"en": "Then you would never hear the second verse.",
						"vi": "Vậy bạn chẳng nghe được đoạn thứ hai."
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
				"en": "If I set the instrument down, would you still sit here?",
				"vi": "Nếu tôi đặt nhạc cụ xuống, bạn còn ngồi đây chứ?"
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
						"en": "Then let the room be only a room for a while.",
						"vi": "Vậy cho căn phòng chỉ là căn phòng một lúc."
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
						"en": "You have put a price on the quiet already.",
						"vi": "Bạn đã đặt giá cho khoảng yên rồi."
					}
				]
			}
		]
	}
]
