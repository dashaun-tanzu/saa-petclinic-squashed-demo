# saa-petclinic-squashed-demo

A live demo of upgrading a Spring Boot application with Spring Application Advisor, done in one squashed step.

## What it does

The demo takes Spring Petclinic (Spring Boot 2.7.3, Java 8) and uses Spring Application Advisor to jump straight to the latest Spring Boot on Java 25. It then measures and compares memory usage and startup time before and after.

- **Before:** Spring Boot 2.7.3 with Java 8
- **After:** Spring Boot 4.x with Java 25

Along the way it shows the Advisor build configuration (dependency SBOM, git metadata, tools), the upgrade plan, the full diff of what changed, and a side-by-side memory/startup table.

## How the advisor runs

Advisor is invoked through the Tanzu Spring Maven plugin, not a downloaded CLI:

```bash
./mvnw tanzu-spring:advisor -DadvisorVersion=$ADVISOR_VERSION -Dcommand="<command>"
```

The plugin resolves the Application Advisor CLI binary from your configured Maven repositories, so there is nothing to download or extract. The upgrade plan is applied in one step with `--squash-all`.

The three Advisor steps in the demo map to:

| Demo step | Command |
| --- | --- |
| Show advisor version | `tanzu-spring:advisor -Dcommand="--version"` |
| Capture build metadata | `tanzu-spring:advisor -Dcommand="build-config get"` |
| Preview the plan | `tanzu-spring:advisor -Dcommand="upgrade-plan get"` |
| Apply all upgrades | `tanzu-spring:advisor -Dcommand="upgrade-plan apply --squash-all"` |

## Prerequisites

- [SDKMAN](https://sdkman.io) with Java 8 and Java 25 installed and listed in `.sdkmanrc`.
- Maven settings that reach the `com.vmware.tanzu.spring` artifacts and declare the plugin group. Your `~/.m2/settings.xml` needs:
  - `<pluginGroup>com.vmware.tanzu.spring</pluginGroup>`
  - A repository (or mirror) serving the `com.vmware.tanzu.spring` plugin and advisor CLI artifacts.
- [direnv](https://direnv.net) (or manually export) for `ADVISOR_VERSION`, set in `.envrc`.
- `vendir`, `httpie`, `bc`, `git`, `mvn`, `tar`, and `jq` on the path.

Run `vendir sync` to pull `demo-magic` (the script does this for you).

## Run it

```bash
direnv allow          # picks up ADVISOR_VERSION from .envrc
./demo.sh
```

The demo is interactive. Press enter to advance between talking points and let the presenter-driven prompts run.

## Notes

- The demo kills all running Java processes at the start (it owns port 8080). Do not run it on a machine with other JVMs you care about.
- The Maven plugin needs a modern JVM, so the advisor steps run under Java 25. The Java 8 baseline is built and measured first, before switching.
- `upgrade-example/` is scratch space; it is deleted and recreated each run.
