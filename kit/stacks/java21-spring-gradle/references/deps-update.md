# Deps-Update Playbook: Gradle / Spring Boot

Loaded only by the deps-update skill, only for modules on this pack. Follows
the skill's hard constraints; where this playbook is more specific, follow it.

## Anchor

Spring Boot is the framework anchor: latest minor/patch within the current
major, **never** across the major boundary. Companions must match the Boot
version per the official compatibility matrix — `spring-cloud` release train
and `io.spring.dependency-management` especially; if the matching version
cannot be determined locally, escalate.

## Inventory

Read only build configuration:

```bash
cat build.gradle settings.gradle
cat gradle.properties 2>/dev/null
ls gradle/*.versions.toml 2>/dev/null && cat gradle/*.versions.toml
```

Record: Boot version (plugin or BOM) → major ceiling; every explicit pin;
which pins shadow a BOM-managed version:

```bash
./gradlew dependencyManagement 2>/dev/null | head -100   # if plugin present
./gradlew dependencies --configuration compileClasspath > /tmp/deps-before.txt
```

## Discover latest versions

Use the versions plugin via an **init script** — never add a plugin to the
build file:

```bash
cat > /tmp/versions-init.gradle <<'EOG'
initscript {
  repositories { gradlePluginPortal() }
  dependencies { classpath 'com.github.ben-manes:gradle-versions-plugin:+' }
}
allprojects {
  apply plugin: com.github.benmanes.gradle.versions.VersionsPlugin
}
EOG
./gradlew --init-script /tmp/versions-init.gradle dependencyUpdates -DoutputFormatter=plain
```

If the plugin portal is unreachable, fall back to resolving `latest.release`
per dependency, or escalate for target versions.

## Target selection (Gradle-specific)

- **Boot:** if `dependencyUpdates` only reports the next major, find the
  latest within the current major line and use that.
- **BOM-managed libs with explicit pins:** target = *remove the pin* (the
  Boot BOM supplies the version) — unless git blame/comments suggest the pin
  overrides a known issue; then escalate.
- Skip `-RC`, `-M`, `-alpha`, `-beta`, `-SNAPSHOT`.
- Never change the Java toolchain / `sourceCompatibility`.

## Apply

Edit version strings only, in: `build.gradle` (plugin + dependency literals,
`ext` version variables), `gradle.properties` (version properties),
`gradle/libs.versions.toml` (`[versions]` entries). Do not reorder
dependencies or change configurations (`implementation` vs `api`).

## Verify

```bash
./gradlew build     # compile + test + checkstyle + PMD + JaCoCo
```

- Non-Boot library breaks the build → step it back one major at a time (max
  2 attempts), then defer with a reason.
- Boot minor bump breaks the build → escalate with the failure output; code
  migration is implement-skill territory.

After passing:

```bash
./gradlew dependencies --configuration compileClasspath > /tmp/deps-after.txt
diff /tmp/deps-before.txt /tmp/deps-after.txt | head -200
```

## Commit scope

```bash
git add build.gradle gradle.properties settings.gradle gradle/ 2>/dev/null
```

Never `git add -A` — version files only.
