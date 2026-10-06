class_name CampaignText
extends RefCounted
## Localized labels derived from committed campaign facts.

static func day_name(campaign: CampaignManager) -> String:
	if campaign == null: return ""
	if campaign.endless:
		return GameGlossary.words("ENDLESS · DAY %d", "VÔ TẬN · NGÀY %d") % (campaign.current_day_index + 1)
	return TranslationServer.translate(String(campaign.current_day().get("name_key", "")))


static func period_key(period: String) -> String:
	return {"morning": "PERIOD_MORNING", "noon": "PERIOD_NOON", "afternoon": "PERIOD_AFTERNOON", "evening": "PERIOD_EVENING"}.get(period, "")
