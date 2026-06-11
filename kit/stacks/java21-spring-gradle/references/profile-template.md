# Profile Template: Java / Spring Boot / Gradle

Loaded only by context-sync when profiling a module on this pack. Extract the
following (targeted reads only) and render the profile in this shape, ≤60
lines.

## What to extract

- **Versions:** Spring Boot (plugin block or BOM in `build.gradle`), Java
  toolchain (`java.toolchain.languageVersion` or `sourceCompatibility`).
- **Base package:** `find src/main/java -mindepth 3 -maxdepth 4 -type d | head -1`.
- **Package layout:** directories one level under the base package, with a
  word each on purpose (controllers, services, repository, dtos, entities,
  mappers, configs, handler, exceptions, util, …).
- **Patterns:** skim one representative controller, service, entity, and test
  for: response wrapper, logging style, retry/transaction annotations, entity
  ID strategy, test annotations and naming.
- **Quality gates:** checkstyle/PMD notable limits (line length, method
  length, complexity caps) from their config files — summarize, never copy.

## Render

```markdown
# Profile: {module-name}

**Path:** `{module-path}`
**Base package:** `{base.package}`
**Stack:** Spring Boot {x.y} / Java {n} / Gradle

## Package Layout
{one line per package: name → purpose}

## Key Patterns
**Controller:** {annotations, wrapper, validation}
**Service:** {annotations, logging, retry/transactions}
**Entity:** {lombok usage, ID strategy, relationship rules}
**Repository:** {spring-data style, custom query approach}
**Tests:** {unit + integration annotations, DB strategy, naming}

## Build
{gradle commands incl. single-test invocation}

## Static Analysis
{notable checkstyle/PMD limits — only if constraints are unusual}
```
