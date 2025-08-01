local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")

return {
  -- Autosnippets for Greek letters and common symbols
  s({trig=";a", snippetType="autosnippet", desc="alpha", wordTrig=false},
    {t("\\alpha")}
  ),
  s({trig=";b", snippetType="autosnippet", desc="beta", wordTrig=false},
    {t("\\beta")}
  ),
  s({trig=";g", snippetType="autosnippet", desc="gamma", wordTrig=false},
    {t("\\gamma")}
  ),
  s({trig=";G", snippetType="autosnippet", desc="Gamma", wordTrig=false},
    {t("\\Gamma")}
  ),
  s({trig=";d", snippetType="autosnippet", desc="delta", wordTrig=false},
    {t("\\delta")}
  ),
  s({trig=";D", snippetType="autosnippet", desc="Delta", wordTrig=false},
    {t("\\Delta")}
  ),
  s({trig=";e", snippetType="autosnippet", desc="epsilon", wordTrig=false},
    {t("\\epsilon")}
  ),
  s({trig=";z", snippetType="autosnippet", desc="zeta", wordTrig=false},
    {t("\\zeta")}
  ),
  s({trig=";h", snippetType="autosnippet", desc="eta", wordTrig=false},
    {t("\\eta")}
  ),
  s({trig=";t", snippetType="autosnippet", desc="theta", wordTrig=false},
    {t("\\theta")}
  ),
  s({trig=";T", snippetType="autosnippet", desc="Theta", wordTrig=false},
    {t("\\Theta")}
  ),
  s({trig=";k", snippetType="autosnippet", desc="kappa", wordTrig=false},
    {t("\\kappa")}
  ),
  s({trig=";l", snippetType="autosnippet", desc="lambda", wordTrig=false},
    {t("\\lambda")}
  ),
  s({trig=";L", snippetType="autosnippet", desc="Lambda", wordTrig=false},
    {t("\\Lambda")}
  ),
  s({trig=";m", snippetType="autosnippet", desc="mu", wordTrig=false},
    {t("\\mu")}
  ),
  s({trig=";n", snippetType="autosnippet", desc="nu", wordTrig=false},
    {t("\\nu")}
  ),
  s({trig=";x", snippetType="autosnippet", desc="xi", wordTrig=false},
    {t("\\xi")}
  ),
  s({trig=";X", snippetType="autosnippet", desc="Xi", wordTrig=false},
    {t("\\Xi")}
  ),
  s({trig=";p", snippetType="autosnippet", desc="pi", wordTrig=false},
    {t("\\pi")}
  ),
  s({trig=";P", snippetType="autosnippet", desc="Pi", wordTrig=false},
    {t("\\Pi")}
  ),
  s({trig=";r", snippetType="autosnippet", desc="rho", wordTrig=false},
    {t("\\rho")}
  ),
  s({trig=";s", snippetType="autosnippet", desc="sigma", wordTrig=false},
    {t("\\sigma")}
  ),
  s({trig=";S", snippetType="autosnippet", desc="Sigma", wordTrig=false},
    {t("\\Sigma")}
  ),
  s({trig=";o", snippetType="autosnippet", desc="omega", wordTrig=false},
    {t("\\omega")}
  ),
  s({trig=";O", snippetType="autosnippet", desc="Omega", wordTrig=false},
    {t("\\Omega")}
  ),
  s({trig=";f", snippetType="autosnippet", desc="phi", wordTrig=false},
    {t("\\phi")}
  ),
  s({trig=";F", snippetType="autosnippet", desc="Phi", wordTrig=false},
    {t("\\Phi")}
  ),
  s({trig=";c", snippetType="autosnippet", desc="chi", wordTrig=false},
    {t("\\chi")}
  ),
  s({trig=";y", snippetType="autosnippet", desc="psi", wordTrig=false},
    {t("\\psi")}
  ),
  s({trig=";Y", snippetType="autosnippet", desc="Psi", wordTrig=false},
    {t("\\Psi")}
  ),

  -- Mathematical operators and symbols
  s({trig=";;", snippetType="autosnippet", desc="cdot", wordTrig=false},
    {t("\\cdot")}
  ),
  s({trig=";i", snippetType="autosnippet", desc="infty", wordTrig=false},
    {t("\\infty")}
  ),
  s({trig=";8", snippetType="autosnippet", desc="infty", wordTrig=false},
    {t("\\infty")}
  ),
  s({trig="=>", snippetType="autosnippet", desc="Rightarrow", wordTrig=false},
    {t("\\Rightarrow")}
  ),
  s({trig="<=", snippetType="autosnippet", desc="Leftarrow", wordTrig=false},
    {t("\\Leftarrow")}
  ),
  s({trig="<=>", snippetType="autosnippet", desc="Leftrightarrow", wordTrig=false},
    {t("\\Leftrightarrow")}
  ),

  -- Fractions
  s({ trig = "ff", desc = "Fraction" },
    {
      t("\\frac{"),
      i(1, "numerator"),
      t("}{"),
      i(2, "denominator"),
      t("}")
    }
  ),

  -- Your custom commands
  s({ trig = "theobox", desc = "Theorem box", name = "Theorem Box" },
    {
      t("\\theobox{"),
      i(1, "Title"),
      t("}{"),
      t({"", ""}),
      i(2, "Content"),
      t({"", "}"})
    }
  ),

  s({ trig = "schlagwort", desc = "Schlagwort (keyword)" },
    {
      t("\\schlagwort{"),
      i(1, "keyword"),
      t("}")
    }
  ),

  s({ trig = "citereference", desc = "Cite reference" },
    {
      t("\\citereference{"),
      i(1, "RefKey"),
      t("}")
    }
  ),

  -- Beamer frames
  s({ trig = "frame", desc = "Beamer frame", name = "Beamer Frame" },
    {
      t("\\begin{frame}["),
      i(1, "c"),
      t("]{"),
      i(2, "Title"),
      t("}"),
      t({"", ""}),
      i(3, "Content"),
      t({"", "\\end{frame}"})
    }
  ),

  s({ trig = "plainframe", desc = "Plain beamer frame", name = "Plain Frame" },
    {
      t("\\begin{frame}[plain]"),
      t({"", ""}),
      i(1, "Content"),
      t({"", "\\end{frame}"})
    }
  ),

  -- Math environments
  s({ trig = "equation", desc = "Equation environment" },
    {
      t("\\begin{equation}"),
      t({"", ""}),
      i(1, "equation"),
      t({"", "\\end{equation}"})
    }
  ),

  s({ trig = "align", desc = "Align environment" },
    {
      t("\\begin{align}"),
      t({"", ""}),
      i(1, "equations"),
      t({"", "\\end{align}"})
    }
  ),

  -- Lists
  s({ trig = "itemize", desc = "Itemize environment" },
    {
      t("\\begin{itemize}"),
      t({"", "\\item "}),
      i(1, "item"),
      t({"", "\\end{itemize}"})
    }
  ),

  s({ trig = "enumerate", desc = "Enumerate environment" },
    {
      t("\\begin{enumerate}"),
      t({"", "\\item "}),
      i(1, "item"),
      t({"", "\\end{enumerate}"})
    }
  ),

  -- Item autosnippet
  s({trig="ii", snippetType="autosnippet", desc="item", wordTrig=false},
    {
      t("\\item "),
      i(1, "content")
    }
  ),

  -- Columns (common in your slides)
  s({ trig = "columns", desc = "Columns environment", name = "Two Columns" },
    {
      t("\\begin{columns}["),
      i(1, "c"),
      t("]"),
      t({"", "\\begin{column}{"}),
      i(2, "0.5"),
      t("\\textwidth}"),
      t({"", ""}),
      i(3, "Left content"),
      t({"", "\\end{column}"}),
      t({"", "\\begin{column}{"}),
      i(4, "0.5"),
      t("\\textwidth}"),
      t({"", ""}),
      i(5, "Right content"),
      t({"", "\\end{column}"}),
      t({"", "\\end{columns}"})
    }
  ),

  -- Bold math
  s({ trig = "bm", desc = "Bold math" },
    {
      t("\\bm{"),
      i(1, "variable"),
      t("}")
    }
  ),

  -- Text formatting
  s({ trig = "textbf", desc = "Bold text" },
    {
      t("\\textbf{"),
      i(1, "text"),
      t("}")
    }
  ),

  s({ trig = "textit", desc = "Italic text" },
    {
      t("\\textit{"),
      i(1, "text"),
      t("}")
    }
  ),

  s({ trig = "emph", desc = "Emphasized text" },
    {
      t("\\emph{"),
      i(1, "text"),
      t("}")
    }
  ),

  -- Citations and references
  s({ trig = "addreferences", desc = "Add references", name = "Reference Block" },
    {
      t("\\addreferences{["),
      i(1, "RefKey"),
      t("]}{"),
      i(2, "Full reference"),
      t("}"),
      t({"", "\\endreferences"})
    }
  ),

  -- Math sets and operators
  s({trig="RR", snippetType="autosnippet", desc="Real numbers", wordTrig=false},
    {t("\\mathbb{R}")}
  ),
  s({trig="NN", snippetType="autosnippet", desc="Natural numbers", wordTrig=false},
    {t("\\mathbb{N}")}
  ),
  s({trig="ZZ", snippetType="autosnippet", desc="Integers", wordTrig=false},
    {t("\\mathbb{Z}")}
  ),
  s({trig="CC", snippetType="autosnippet", desc="Complex numbers", wordTrig=false},
    {t("\\mathbb{C}")}
  ),

  -- Quantum notation (specific to your thesis)
  s({trig="ket", desc="Quantum ket"},
    {
      t("\\ket{"),
      i(1, "state"),
      t("}")
    }
  ),
  s({trig="bra", desc="Quantum bra"},
    {
      t("\\bra{"),
      i(1, "state"),
      t("}")
    }
  ),
  s({trig="braket", desc="Quantum braket"},
    {
      t("\\braket{"),
      i(1, "bra"),
      t("}{"),
      i(2, "ket"),
      t("}")
    }
  ),

  -- Sections
  s({ trig = "section", desc = "Section" },
    {
      t("\\section{"),
      i(1, "Section Title"),
      t("}")
    }
  ),
  s({ trig = "subsection", desc = "Subsection" },
    {
      t("\\subsection{"),
      i(1, "Subsection Title"),
      t("}")
    }
  ),

  -- Spacing
  s({trig="vv", snippetType="autosnippet", desc="vspace", wordTrig=false},
    {
      t("\\vspace{"),
      i(1, "1"),
      t("em}")
    }
  ),

  -- Matrix environments
  s({ trig = "matrix", desc = "Matrix" },
    {
      t("\\begin{matrix}"),
      t({"", ""}),
      i(1, "elements"),
      t({"", "\\end{matrix}"})
    }
  ),

  s({ trig = "pmatrix", desc = "Parentheses matrix" },
    {
      t("\\begin{pmatrix}"),
      t({"", ""}),
      i(1, "elements"),
      t({"", "\\end{pmatrix}"})
    }
  ),

  -- Only/onslide for beamer
  s({ trig = "only", desc = "Only command" },
    {
      t("\\only<"),
      i(1, "1-"),
      t(">{"),
      i(2, "content"),
      t("}")
    }
  ),

  s({ trig = "onslide", desc = "Onslide command" },
    {
      t("\\onslide<"),
      i(1, "1-"),
      t(">{"),
      i(2, "content"),
      t("}")
    }
  ),

  -- Additional useful LaTeX snippets
  s({ trig = "includegraphics", desc = "Include graphics" },
    {
      t("\\includegraphics["),
      i(1, "width=0.8\\textwidth"),
      t("]{"),
      i(2, "filename"),
      t("}")
    }
  ),

  s({ trig = "tikzpicture", desc = "TikZ picture environment" },
    {
      t("\\begin{tikzpicture}"),
      t({"", ""}),
      i(1, "tikz code"),
      t({"", "\\end{tikzpicture}"})
    }
  ),

  -- Math operators
  s({trig="sum", desc="Sum"},
    {
      t("\\sum_{"),
      i(1, "i=1"),
      t("}^{"),
      i(2, "n"),
      t("}")
    }
  ),

  s({trig="int", desc="Integral"},
    {
      t("\\int_{"),
      i(1, "a"),
      t("}^{"),
      i(2, "b"),
      t("}")
    }
  ),

  s({trig="lim", desc="Limit"},
    {
      t("\\lim_{"),
      i(1, "x \\to \\infty"),
      t("}")
    }
  ),
}