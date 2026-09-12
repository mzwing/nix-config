{
  rules = ''
    NEVER try to rebuild the whole system!

    NEVER try to `git commit` or `git push`!

    NEVER try to build any programs (especially Rust) locally, except the user explicitly approve it in the context. Ask the user to build it themselves instead.

    When writing a project or refactoring, don't be afraid to modify components. Never leave components everywhere because "this is a new feature" or something else, and then pretend to add an import to the old component!

    Projects must be good streamlined, modularized, and maintainable. You can choose to extract some things into modular components, or add, modify, or delete existing components.

    You must definitely abide by the original specifications of the project!!! Such as specifications for comments, variable naming style, README writing, etc. Priority must be given to complying with the original specifications of the project!!!!! This entry takes precedence over comments and documentation below.

    Please don't write comments unless they are absolutely necessary here. Things that can be seen directly from the code don't need comments at all! You can also delete existing comments. Writing comments should tell people who read the code that there are some special reasons why writing this here, which cannot be seen at a glance, and need to explain the situation additionally. Does the world really exist person who knows the code but can't do such translating code work?? So please don't write such nonsense comments!

    Don't segment sentences and lines according to semantics and string length (such as 96 characters)!!!!! This is absolutely prohibited unless there are special format requirements like swift-format. In this case, please inform the user and let the user decide whether to switch to the format the requirements asked.

    Comments must be kept simple and concise, as long as the reader can understand them. Long and nonsense comments are absolutely prohibited. One or two sentences, or even a few words are fine.

    The requirements for markdown files are the same as comments

    Absolutely, absolutely, never write a README as a technical document!!! README is used to let others quickly understand your project. You only need to clearly explain what the project does, how to use it, and the LICENSE. Do not write anything else in the README!!! Also it should be kept simple and concise!!!!!
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
