include tinysite.mk

BLOG_FILES = $(shell find ${CONTENT_ROOT}/blog -type f -a -name \*.html.md -a -not -path "*/_*/*" | sort)
POST_DATA  = ${BLOG_FILES:$(CONTENT_ROOT)/blog/%.md=$(BUILD_ROOT)/post/%.json}


# Build the post index file before anything else.

pages : | $(CONTENT_ROOT)/_include/posts.json

deps  : | $(CONTENT_ROOT)/_include/posts.json

$(CONTENT_ROOT)/_include/posts.json : $(POST_DATA)
	@ cat $^ | jq -s 'sort_by(.post.date) | reverse | {posts:[.[].post]}' > "${@:%=%.tmp}"
	@ cmp -s "${@:%=%.tmp}" "$@" && rm "${@:%=%.tmp}" || mv "${@:%=%.tmp}" "$@"

$(BUILD_ROOT)/post/%.json : $(CONTENT_ROOT)/blog/%.md
	@ mkdir -p `dirname "$@"`
	@ $(HIGHLIGHT_SCAN) post "$(@:${BUILD_ROOT}/post/%.json=/blog/%)"
	@ tinysite render --template $(TEMPLATE_ROOT)/blog/post.json "$(<:${CONTENT_ROOT}/%.md=/%)" > "$@"

