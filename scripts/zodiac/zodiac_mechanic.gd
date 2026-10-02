extends RefCounted
## Boss-specific policy. All physical mutations go through the owning DealState.
func configure(_rule) -> void: pass
func begin_phase(_rule, _deal) -> void: pass
func before_refill(_rule, _deal) -> void: pass
func begin_turn(_rule, _phase: int, _hand: Array[CardData], _deal) -> void: pass
func legality(_rule, _action: String, _phase: int, _meld_id: int, _cards: Array[CardData]) -> String: return ""
func payout(_rule, _context: ScoringContext, _meld_id: int, _commit: bool) -> Dictionary: return {}
func after_action(_rule, _deal, _result: Dictionary) -> void: pass
func after_discard(_rule, _deal, _record: DiscardRecord) -> void: pass
func income(_rule, _deal, _amount: int, _reason: String) -> void: pass
func deadwood(_rule, _deal, _context: Dictionary) -> void: pass
func turn_discard(_rule, _deal, requested: CardData) -> CardData: return requested
func phase_limit(_rule, _phase: int, ordinary: int) -> int: return ordinary
func settle(_rule, _deal) -> void: pass
func presentation(_rule) -> Dictionary: return {}

# Dragon calls only these curated hooks, never configure/begin_phase/full mechanics.
func dragon_begin(_rule, _deal, _state: Dictionary) -> void: pass
func dragon_payout(_rule, _context: ScoringContext, _meld_id: int, _state: Dictionary, _commit: bool) -> Dictionary: return {}
func dragon_after(_rule, _deal, _result: Dictionary, _state: Dictionary) -> void: pass
func dragon_discard(_rule, _deal, _record: DiscardRecord, _state: Dictionary) -> void: pass
func dragon_income(_rule, _deal, _amount: int, _reason: String, _state: Dictionary) -> void: pass
func dragon_deadwood(_rule, _deal, _context: Dictionary, _state: Dictionary) -> void: pass
func dragon_turn_discard(_rule, _deal, requested: CardData, _state: Dictionary) -> CardData: return requested
