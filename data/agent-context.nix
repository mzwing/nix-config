{
  rules = ''
    NEVER try to rebuild the whole system!

    NEVER try to build any programs (especially Rust) locally, except the user explicitly approve it in the context. Ask the user to build it themselves instead.
  '';

  codegraph = ''
    <!-- CODEGRAPH_START -->
    ## CodeGraph

    In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

    - **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.

    If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
    <!-- CODEGRAPH_END -->
  '';
}
