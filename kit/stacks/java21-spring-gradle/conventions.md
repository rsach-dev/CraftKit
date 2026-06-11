# Conventions: Java 21 / Spring Boot / Gradle

Applied by implement, review, and feedback on top of the module profile.
Module-profile or repo coding-standards entries win on conflict.

## Dependency Injection

- Constructor injection via Lombok `@RequiredArgsConstructor` — never
  `@Autowired` field injection, never setter injection.
- `private final` for all injected collaborators.

## Layering

- `controller → service → repository`; controllers contain no business
  logic, repositories contain no orchestration.
- DTOs for transport, entities for persistence — never expose entities from
  controllers. Map with a dedicated mapper (MapStruct or a mapper class).

## Controllers

- `@RestController @RequestMapping("/api/v1") @RequiredArgsConstructor`.
- Return `ResponseEntity<T>` (or the module's documented wrapper).
- Validate inbound DTOs with `jakarta.validation` annotations + `@Valid`.
- Centralize error responses in a `@ControllerAdvice` handler.

## Services

- `@Service @RequiredArgsConstructor @Slf4j`.
- Structured logging: `log.info("...", StructuredArguments.kv("orderId", id))`
  — never string-concatenate values into messages.
- Throw specific custom exceptions; no `catch (Exception e)` swallowing.

## Entities & Repositories

- Entities: Lombok `@Data`/`@Getter @Setter` + `@Builder(toBuilder = true)`;
  relationships `FetchType.LAZY` with `@ToString.Exclude` and
  `@EqualsAndHashCode.Exclude`.
- Repositories: Spring Data interfaces; custom JPQL in text blocks;
  `@Transactional(readOnly = true)` defaults, write methods opt in.

## Tests

- JUnit 5. Unit: `@ExtendWith(MockitoExtension.class)` with
  `@Mock`/`@InjectMocks`. Integration: `@SpringBootTest`.
- AssertJ assertions only (`assertThat`, `assertThatThrownBy`) — no JUnit
  `assertEquals`, no `@Test(expected=...)`.
- DB tests: embedded Postgres (zonky `@AutoConfigureEmbeddedDatabase`) with
  `@Transactional` rollback cleanup — never H2 for Postgres-targeted code.
- Test names: `test{Action}{Scenario}`. Keep assertions per test focused.

## Build & Quality Gates

- `./gradlew build` runs compile + tests + checkstyle + PMD + JaCoCo; it must
  pass before any commit. Single class:
  `./gradlew test --tests "com.example.SomeTest"`.
- JaCoCo minimum per `project.yaml` `rules.coverage_min`.
- Never modify checkstyle/PMD/JaCoCo configuration — refactor the code to
  satisfy the rule (split long methods, reduce nesting, remove star imports,
  no `System.out.println`).
