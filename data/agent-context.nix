{
  rules = ''
    NEVER try to rebuild the whole system!

    NEVER try to `git commit` or `git push`!

    NEVER try to build any programs (especially Rust) locally, except the user explicitly approve it in the context. Ask the user to build it themselves instead. This also holds when a skill asks for a build: give the user the exact command, and never claim it passed.

    You must definitely abide by the original specifications of the project!!! Such as specifications for comments, variable naming style, README writing, etc. Priority must be given to complying with the original specifications of the project!!!!! This entry takes precedence over the code, comment, and documentation rules below, and over any skill's defaults.

    Projects must be good streamlined, modularized, and maintainable. When writing a project or refactoring, don't be afraid to extract, add, modify, or delete components. Never leave components everywhere because "this is a new feature" or something else, and then pretend to add an import to the old component!

    NEVER defensive programming! Trust the code's own invariants and contracts; validate only where data comes from outside, such as user input, files, the network, or another process.

    Please don't write comments unless they are absolutely necessary here. Things that can be seen directly from the code don't need comments at all! You can also delete existing comments that only restate the code. Writing comments should tell people who read the code that there are some special reasons why writing this here, which cannot be seen at a glance, and need to explain the situation additionally. Comments must be kept simple and concise, as long as the reader can understand them: one or two sentences, or even a few words are fine. Long and nonsense comments are absolutely prohibited!

    Don't segment sentences and lines according to semantics and string length (such as 96 characters)!!!!! This is absolutely prohibited unless there are special format requirements like swift-format. In this case, please inform the user and let the user decide whether to switch to the format the requirements asked.

    The requirements for markdown files are the same as comments

    Absolutely, absolutely, never write a README as a technical document!!! README is used to let others quickly understand your project. You only need to clearly explain what the project does, how to use it, the credits (if any), and the LICENSE. A few special points worth knowing can be mentioned briefly, but do not write anything else in the README!!! Long-winded, verbose, wordy READMEs are absolutely prohibited, keep it simple and concise!!!!!

    Skills carry the details of their domain; these rules apply everywhere and win when a skill disagrees. Load the matching skill before the work, even when it is only part of a bigger task: write-docs before writing or editing a README or other project docs, design-ui before adding or restyling any UI.

    After writing code and before reporting back, load find-code-simplifications and refactor-for-simplicity and review your own change with them: find what you did poorly, then refactor and fix it. This standing instruction is the explicit request both skills wait for. Review only what you changed in this task and fix what you find without asking, except changes to behavior or interfaces the task didn't ask for, which you report instead. Sum up the fixes in a line or two rather than the skills' full reports.
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
