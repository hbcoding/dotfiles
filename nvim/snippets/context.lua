local ls = require("luasnip")
local s  = ls.snippet
local i  = ls.insert_node
local t  = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

return {
  -- Trigger: `sec` → \startsection[title={...}] ... \stopsection
  s("sec", fmt([[
\startsection[title={<>}]
  <>
\stopsection
]], { i(1, "Title"), i(0) }, { delimiters = "<>" })),

  -- Trigger: `chap`
  s("chap", fmt([[
\startchapter[title={<>}]
  <>
\stopchapter
]], { i(1, "Title"), i(0) }, { delimiters = "<>" })),

  -- Trigger: `itm` for itemize
  s("itm", fmt([[
\startitemize
  \item <>
  \item <>
\stopitemize
]], { i(1), i(2) }, { delimiters = "<>" })),

  -- Trigger: `formula`
  s("formula", fmt([[
\startformula
  <>
\stopformula
]], { i(1) }, { delimiters = "<>" })),

  -- Trigger: `template` for a full document skeleton
  s("template", fmt([[
\setupbodyfont[<>]
\starttext

<>

\stoptext
]], { i(1, "modern"), i(0) }, { delimiters = "<>" })),
}

