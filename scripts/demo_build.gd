class_name DemoBuild
extends RefCounted

## Enabled by the demo export preset or a local smoke run.
static func enabled() -> bool:
	return OS.has_feature("tradatala_demo") or "--tradatala-demo" in OS.get_cmdline_user_args()
