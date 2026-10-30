---
name: typescript-naming
description: Name TypeScript identifiers the way Google's TypeScript style guide does, except that nothing is CONSTANT_CASE, so constants are lowerCamelCase too. Use when writing, renaming, or reviewing the casing and form of TypeScript names, including variables, constants, functions, parameters, properties, classes, interfaces, types, enums, type parameters, and import aliases.
---

# TypeScript naming

Name identifiers by the [Naming](https://google.github.io/styleguide/tsguide.html#naming) section of Google's TypeScript style guide, with the one override below. Read the guide instead of recalling it: [Rules by identifier type](https://google.github.io/styleguide/tsguide.html#rules-by-identifier-type) gives the casing for each kind of identifier, while [Descriptive names](https://google.github.io/styleguide/tsguide.html#descriptive-names) and [Camel case](https://google.github.io/styleguide/tsguide.html#camel-case) cover length and abbreviations.

## No CONSTANT_CASE

Never write a name like `MAX_RETRIES`. Everywhere the guide asks for CONSTANT_CASE, including [module-level constants](https://google.github.io/styleguide/tsguide.html#constants), static readonly fields, and enum values, use lowerCamelCase as for any other value: `maxRetries`.

Turning an existing CONSTANT_CASE name into lowerCamelCase is a rename, so choose the name with clarify-code-names instead of lowercasing it: `FIELDS` beside a local `fields` becomes `fieldNames`, and `REFRESH_INTERVAL` passed to `setInterval` becomes `refreshIntervalMs`.

## Where it applies

- A project's own naming convention, documented or consistently followed, takes precedence. Use this skill where the project leaves naming open, or when the user asks to move code to it.
- Names fixed outside the code keep their spelling: environment variables, JSON, wire, and config fields, exports a framework looks up by name, third-party APIs, and generated code.
