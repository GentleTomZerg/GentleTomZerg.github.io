import remarkGemoji from "remark-gemoji"
import type { QuartzTransformerPlugin } from "@quartz-community/types"

const EmojiPlugin: QuartzTransformerPlugin = () => ({
  name: "emoji",
  markdownPlugins: () => [remarkGemoji],
})

export default EmojiPlugin
