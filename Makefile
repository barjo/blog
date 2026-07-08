.PHONY: help build watch format clean post embed feed
.DEFAULT_GOAL := help

ELM        = npx elm
ELM_WATCH  = npx elm-watch
SERVE      = npx servor --browse
ELM_FORMAT = npx elm-format
TERSER     = npx terser
CLEANCSS   = npx cleancss
PRETTIER   = npx prettier

BUILD  = build
PUBLIC = public
POSTS  = $(PUBLIC)/posts
SRC    = src

TERSER_COMPRESS = pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,passes=2

help: ## help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

embed: ## generate post embeddings
	@$(ELM) make $(SRC)/Embed.elm --output=scripts/embed-worker.js
	@node scripts/embed.js
	@rm -f scripts/embed-worker.js

feed: ## generate rss feed
	@jq -r -f scripts/feed.jq $(POSTS)/index.json > $(PUBLIC)/feed.xml
	@python3 -c "import sys, xml.etree.ElementTree as ET; ET.parse(sys.argv[1])" $(PUBLIC)/feed.xml

build: clean embed feed ## compile, minify and output to build/
	@cp -r $(PUBLIC) $(BUILD)
	@$(ELM) make $(SRC)/Main.elm --optimize --output=$(BUILD)/elm.tmp.js
	@$(TERSER) $(BUILD)/elm.tmp.js --compress "$(TERSER_COMPRESS)" --mangle --output $(BUILD)/elm.js
	@rm $(BUILD)/elm.tmp.js
	@$(CLEANCSS) -o $(BUILD)/style.css $(PUBLIC)/style.css
	@du -sh $(BUILD)/elm.js $(BUILD)/style.css

watch: ## start dev server with hot reload
	@$(SERVE) $(PUBLIC) & $(ELM_WATCH) hot

format: ## format elm, css and html
	@$(ELM_FORMAT) $(SRC)/ --yes
	@$(PRETTIER) --write $(PUBLIC)/*.css $(PUBLIC)/*.html

clean: ## remove build artifacts
	@rm -rf $(BUILD)
	@rm -f $(PUBLIC)/elm.js $(PUBLIC)/feed.xml

post: ## create a new post
	@read -p "Title: " title; \
	slug=$$(echo "$$title" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$$//'); \
	date=$$(date +%Y-%m-%d); \
	file=$(POSTS)/$$slug.md; \
	if [ -f "$$file" ]; then echo "$$file already exists"; exit 1; fi; \
	echo "# $$title" > "$$file"; \
	jq --arg s "$$slug" --arg t "$$title" --arg d "$$date" \
		'. += [{"slug":$$s,"title":$$t,"date":$$d,"description":"","tags":[]}]' \
		$(POSTS)/index.json > $(POSTS)/index.tmp.json \
		&& mv $(POSTS)/index.tmp.json $(POSTS)/index.json; \
	echo "Created $$file"
