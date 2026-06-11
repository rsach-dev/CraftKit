# Triage Heuristics: Java / Spring Boot

Loaded only by the triage skill, only for modules on this pack. These sharpen
the skill's narrowing strategy — its token budgets still apply.

## Reading JVM stack traces

- Scan top-down for the **first frame in the module's base package** — frames
  above it are usually framework plumbing, frames below it are the call
  context. `... N more` sections repeat the cause chain; the **root cause is
  the last `Caused by:`**.
- `ClassName.methodName(ClassName.java:42)` → search
  `src/main/java -name "ClassName.java"`, then read around line 42 only.
- Proxied frames (`$$SpringCGLIB`, `$Proxy`) mean AOP is involved — check
  `@Transactional`, `@Retryable`, `@Async` on the target method.

## Signal → where to look

| Signal | First scan |
|--------|-----------|
| HTTP endpoint in trace | `grep -rn '"{path-segment}"' src/main/java --include="*.java" -l` for `@GetMapping`/`@PostMapping`/`@RequestMapping` |
| `MethodArgumentNotValidException` / 400 | inbound DTO validation annotations + the `@ControllerAdvice` handler |
| `DataIntegrityViolationException`, SQL column in message | the entity mapping that column + recent migrations (`src/main/resources/db/`) |
| `LazyInitializationException` | entity accessed outside the transaction — the mapper or controller touching a LAZY relation |
| `NullPointerException` in a mapper | Optional-vs-null contract of the source DTO/entity field |
| Bean creation / `NoSuchBeanDefinitionException` | `@Configuration` classes + conditional annotations + `application*.yml` |
| Timeout / connection errors | config first, not code: `application*.yml` client/pool settings |

## Configuration scan

```bash
ls src/main/resources/application*.yml src/main/resources/application*.properties 2>/dev/null
grep -n "{relevant-key}" src/main/resources/application*.yml
```

Profile-specific overrides (`application-prod.yml`) are a frequent source of
environment-only bugs — diff the profile against the default.

## Tests

Related tests live at the mirrored path: `src/test/java/.../{ClassName}Test.java`.
A missing `{ClassName}Test` for the failing class is itself a finding for the
Test Gaps section.
