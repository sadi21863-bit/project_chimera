extends RefCounted

static var catalog_dir_override: String = ""

const TARGET_DIR := "user://models"
const PART_SUFFIX := ".part"

const DEFAULT_KEY := "Llama-3.2-1B-Instruct-Q4_K_M"

const REQUIREMENTS := {
	DEFAULT_KEY: {
		"url": "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
		"size_bytes": 807694464,
		"sha256": "6f85a640a97cf2bf5b8e764087b1e83da0fdb51d7c9fab7d0fece9385611df83",
		"source": "bartowski/Llama-3.2-1B-Instruct-GGUF (community quant of meta-llama/Llama-3.2-1B-Instruct)",
		"license": "Llama 3.2 Community License (Meta)",
	},
	"gemma-2-2b-it-Q8_0": {
		"url": "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q8_0.gguf",
		"size_bytes": 2784495456,
		"sha256": "2d448a9aab894b8e8e18168cf3f490cb9f65632222f29f93514ac9ecc754debe",
		"source": "bartowski/gemma-2-2b-it-GGUF (community quant of google/gemma-2-2b-it)",
		"license": "Gemma Terms of Use (Google)",
	},
}


static func model_dir() -> String:
	if not catalog_dir_override.is_empty():
		return catalog_dir_override
	return TARGET_DIR


static func model_file_path(key: String) -> String:
	return model_dir().path_join(key + ".gguf")


static func human_size(size_bytes: int) -> String:
	var mib := 1024.0 * 1024.0
	var gib := 1024.0 * 1024.0 * 1024.0
	if size_bytes >= gib:
		return "%0.2f GB" % (float(size_bytes) / gib)
	return "%0.0f MB" % (float(size_bytes) / mib)
