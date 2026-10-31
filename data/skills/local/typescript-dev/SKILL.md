---
name: typescript-dev
description: Write, restructure, and review TypeScript. Covers naming identifiers the way Google's TypeScript style guide does, except that nothing is CONSTANT_CASE, and grouping source and test files into folders by responsibility instead of one flat directory. Use when writing, reviewing, or reorganizing TypeScript, including naming variables, constants, functions, parameters, properties, classes, interfaces, types, enums, type parameters, and import aliases, adding a module, and moving files between folders.
---

# TypeScript dev

## Naming

Name identifiers by the [Naming](https://google.github.io/styleguide/tsguide.html#naming) section of Google's TypeScript style guide, with the one override below. Read the guide instead of recalling it: [Rules by identifier type](https://google.github.io/styleguide/tsguide.html#rules-by-identifier-type) gives the casing for each kind of identifier, while [Descriptive names](https://google.github.io/styleguide/tsguide.html#descriptive-names) and [Camel case](https://google.github.io/styleguide/tsguide.html#camel-case) cover length and abbreviations.

### No CONSTANT_CASE

Never write a name like `MAX_RETRIES`. Everywhere the guide asks for CONSTANT_CASE, including [module-level constants](https://google.github.io/styleguide/tsguide.html#constants), static readonly fields, and enum values, use lowerCamelCase as for any other value: `maxRetries`.

Turning an existing CONSTANT_CASE name into lowerCamelCase is a rename, so choose the name with clarify-code-names instead of lowercasing it: `FIELDS` beside a local `fields` becomes `fieldNames`, and `REFRESH_INTERVAL` passed to `setInterval` becomes `refreshIntervalMs`.

## Folders

Group modules into folders by what they are responsible for, the way a frontend splits `components/` into `features/`, `charts/`, `layouts/`, and `ui/`. A directory full of sibling modules only looks modular: nothing in it shows which subsystem owns which file.

- Give each subsystem or kind of module a folder named after it, such as `catalog/`, `config/`, or `sessions/`, and put every module in the folder of the subsystem that owns it. Don't name a folder with a word the project already uses for something else, such as `completion/` in a package whose commands offer argument completions.
- Only entry points and the modules several folders share, such as shared types, stay at the source root.
- Inside a folder, drop a prefix the folder repeats: `catalog-sources.ts` becomes `catalog/sources.ts`, and several `user-*.ts` files mean a missing `user/`. A folder's main module may share its name, as in `config/config.ts`.
- Name a file after its main export. Keep a prefix when the bare name means something else: `catalog/index.ts` would read as the folder's entry point, so the module that builds the catalog index is `catalog/catalog-index.ts`.
- Tests follow their modules. A separate test tree mirrors the source folders and keeps shared helpers at its root; a test beside its module moves with it.
- When moving a file, update every reference to its path, including the ones the type checker does not see: path strings in scripts, CI workflows, and docs.

## Where it applies

- A project's own naming and layout conventions, documented or consistently followed, take precedence; use this skill where the project leaves them open, or when the user asks to move code to it. One flat directory of modules is not a layout convention: a new module still goes in a folder, and the existing ones move when the user asks.
- Names fixed outside the code keep their spelling: environment variables, JSON, wire, and config fields, exports a framework looks up by name, third-party APIs, and generated code.
- Files whose paths are fixed outside the code stay where they are: entry points a bundler config or package manifest names, since moving one can change a published path, and files a framework or tool finds by location.
