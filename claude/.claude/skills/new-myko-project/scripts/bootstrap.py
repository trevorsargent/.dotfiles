#!/usr/bin/env python3
"""Scaffold a new myko/flux/levi Rust workspace shaped like ~/Code/levi.

Deterministic generator: given a project name and which optional crates to
include, it writes a complete, compiling crate workspace. The point of doing
this in a script rather than freehand is that the workspace has a handful of
non-obvious invariants that are easy to get subtly wrong by hand — the wasm
dash must stay out of `default-members`, the hub must call `<core>::link()`
or myko's inventory registrations get dead-stripped, per-crate flux task
lists gate what runs where, and `mullion` must never be a crates.io dep. Those
are encoded here once.

Usage:
    bootstrap.py --name acme --dir ~/Code \
        [--with-cli] [--with-hub] [--with-dash] \
        [--myko-version 5.0.0] [--license AGPL-3.0-or-later] \
        [--license-file /path/to/AGPL.txt] [--repository https://github.com/org/acme]

The core library crate (`<name>-core`) is always generated. CLI / hub / dash
are opt-in. Writes into <dir>/<name> and refuses to clobber a non-empty dir.
"""
import argparse
import os
import sys
import textwrap

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    print(f"  wrote {path}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", required=True, help="project name (kebab-case), e.g. 'acme'")
    ap.add_argument("--dir", default=".", help="parent directory; workspace goes in <dir>/<name>")
    ap.add_argument("--with-cli", action="store_true", help="generate the <name> CLI binary crate")
    ap.add_argument("--with-hub", action="store_true", help="generate the <name>-hub server crate")
    ap.add_argument("--with-dash", action="store_true", help="generate the <name>-dash Leptos UI crate")
    ap.add_argument("--myko-version", default="5.0.0")
    ap.add_argument("--license", default="AGPL-3.0-or-later")
    ap.add_argument("--license-file", default=None, help="path to full license text to copy in as LICENSE")
    ap.add_argument("--repository", default="", help="repo URL for workspace.package.repository")
    a = ap.parse_args()

    name = a.name.strip()
    if not name or not all(c.isalnum() or c == "-" for c in name):
        sys.exit(f"invalid project name: {name!r} (use kebab-case alphanumerics)")
    snake = name.replace("-", "_")
    core = f"{name}-core"
    core_lib = f"{snake}_core"
    root = os.path.abspath(os.path.join(os.path.expanduser(a.dir), name))
    if os.path.isdir(root) and os.listdir(root):
        sys.exit(f"refusing to scaffold into non-empty directory: {root}")

    mv = a.myko_version
    repo_line = f'repository = "{a.repository}"\n' if a.repository else ""
    repo_inherit = "repository.workspace = true\n" if a.repository else ""

    # ---- workspace members / default-members --------------------------------
    members = [core]
    if a.with_cli:  members.append(name)
    if a.with_hub:  members.append(f"{name}-hub")
    if a.with_dash: members.append(f"{name}-dash")
    # default-members excludes the wasm-only dash so native build/test skip it.
    default_members = [m for m in members if m != f"{name}-dash"]

    def toml_list(xs): return "[" + ", ".join(f'"{x}"' for x in xs) + "]"

    print(f"Scaffolding {name} at {root}")
    print(f"  crates: {', '.join(members)}")

    # ---- workspace Cargo.toml -----------------------------------------------
    ws_deps = textwrap.dedent(f"""\
        [workspace.dependencies]
        myko = "{mv}"
        myko-server = "{mv}"
        myko-leptos = "{mv}"
        {core} = {{ version = "0.1.0", path = "{core}" }}
        serde = {{ version = "1", features = ["derive"] }}
        serde_json = "1"
        ciborium = "0.2"
        chrono = {{ version = "0.4", features = ["serde"] }}
        uuid = {{ version = "1", features = ["v4"] }}
        anyhow = "1"
        tokio = {{ version = "1", features = ["full"] }}
        log = "0.4"
        env_logger = "0.11"
    """)
    dash_note = ("# the dash is wasm-only (built with trunk); keep native builds/tests to the rest\n"
                 if a.with_dash else "")
    w(os.path.join(root, "Cargo.toml"), textwrap.dedent(f"""\
        [workspace]
        resolver = "2"
        members = {toml_list(members)}
        {dash_note}default-members = {toml_list(default_members)}

        [workspace.package]
        edition = "2024"
        license = "{a.license}"
        {repo_line}
        """) + "\n" + ws_deps)

    # ---- flux.toml ----------------------------------------------------------
    checkwasm = textwrap.dedent(f"""\

        [tasks.check-wasm]
        # wasm32 coverage for the dashboard ({name}-dash opts in via its
        # `[package.metadata.flux]` tasks list); `check` alone doesn't exercise
        # `#[cfg(target_arch = "wasm32")]` code paths.
        workspace_batchable = true
        cargo = ["cargo", "check", "--target", "wasm32-unknown-unknown", "--target-dir", "target/claude"]
    """) if a.with_dash else ""
    publish = textwrap.dedent("""\

        [tasks.publish]
        # Crates that opt in via their `[package.metadata.flux]` are published;
        # binaries like the hub/dash are not.
        cascade = "all"
        autoapply = "inherit"
        depends_on = ["build"]
        cargo = ["cargo", "publish"]
    """) if a.with_cli else ""
    w(os.path.join(root, "flux.toml"), textwrap.dedent("""\
        [channels]
        main = "production"

        [tasks.check]
        workspace_batchable = true
        cargo = ["cargo", "check", "--target-dir", "target/claude"]

        [tasks.build]
        workspace_batchable = true
        cargo = ["cargo", "build"]

        [tasks.test]
        workspace_batchable = true
        cargo = ["cargo", "test"]

        [tasks.lint]
        cargo = ["cargo", "clippy", "--all-targets", "--", "-D", "warnings"]
    """) + checkwasm + publish)

    # ---- .gitignore ---------------------------------------------------------
    gi = "target/\n.env\n"
    if a.with_dash:
        gi += f"{name}-dash/dist/\n"
    w(os.path.join(root, ".gitignore"), gi)

    # ---- LICENSE ------------------------------------------------------------
    if a.license_file and os.path.isfile(a.license_file):
        with open(a.license_file) as f:
            w(os.path.join(root, "LICENSE"), f.read())

    # ---- CLAUDE.md (levi init will append its own task-tracking block) ------
    w(os.path.join(root, "CLAUDE.md"), textwrap.dedent(f"""\
        # {name}

        Rust workspace built on the [myko](https://github.com/ignition-is-go/myko)
        framework (crates.io: `myko`, `myko-server`, `myko-leptos`).

        ## Gotchas

        - **myko dead-strip**: a binary that receives `{core_lib}` entities only
          over the wire (the hub) must call `{core_lib}::link()`, or the linker
          drops the crate's object files — including the inventory registrations
          for entities, commands, and sagas.
        - **Conventional commits are required** — `cargo flux version` derives the
          next semver from commit messages (`feat:` minor, `fix:` patch,
          `feat!:`/`BREAKING CHANGE:` major). `chore(release):` commits are stamps
          flux creates itself; never write one by hand.

        ## Build

        - `cargo flux run check` / `cargo flux run test` / `cargo flux run lint`.
        {"- `cargo flux run check-wasm` covers the wasm32 dashboard target." if a.with_dash else ""}
        {f"- Dashboard: `trunk build` (or `trunk serve`) inside `{name}-dash/`." if a.with_dash else ""}
        """))

    # ---- README -------------------------------------------------------------
    w(os.path.join(root, "README.md"), textwrap.dedent(f"""\
        # {name}

        A Rust workspace built on the [myko](https://github.com/ignition-is-go/myko)
        reactive-entity framework, task-tracked with
        [levi](https://github.com/ignition-is-go/levi) and built with
        [cargo-flux](https://crates.io/crates/cargo-flux).

        ## Crates

        - `{core}` — entities and core logic (myko items).
        {f"- `{name}` — command-line interface." if a.with_cli else ""}
        {f"- `{name}-hub` — myko `CellServer` aggregation hub (optional Postgres)." if a.with_hub else ""}
        {f"- `{name}-dash` — Leptos CSR dashboard (wasm, built with trunk)." if a.with_dash else ""}

        ## Develop

        ```sh
        cargo flux run check
        cargo flux run test
        ```
        """))

    # ---- .claude/settings.json ----------------------------------------------
    w(os.path.join(root, ".claude/settings.json"),
      '{\n  "enabledPlugins": {\n    "superpowers@claude-plugins-official": true\n  }\n}\n')

    # ---- .github/workflows/ci.yml -------------------------------------------
    ci_wasm_target = ("\n        with:\n          targets: wasm32-unknown-unknown"
                      if a.with_dash else "")
    ci_wasm_step = (textwrap.dedent("""\

              # wasm32 coverage for the dashboard (see its `[package.metadata.flux]`
              # tasks list) — native `check` alone won't catch a break in
              # `#[cfg(target_arch = "wasm32")]` code.
              - run: cargo flux run check-wasm
        """) if a.with_dash else "")
    w(os.path.join(root, ".github/workflows/ci.yml"), textwrap.dedent(f"""\
        name: CI

        on:
          push:
            branches: [main]
          pull_request:
            branches: [main]

        env:
          CARGO_TERM_COLOR: always

        jobs:
          check:
            runs-on: ubuntu-latest
            steps:
              - uses: actions/checkout@v4
                with:
                  fetch-depth: 0
                  fetch-tags: true
              - uses: dtolnay/rust-toolchain@stable{ci_wasm_target}
              - uses: Swatinem/rust-cache@v2

              - run: cargo install cargo-flux
              - run: cargo flux run check
              - run: cargo flux run lint
              - run: cargo flux run test
        """) + ci_wasm_step)

    # release.yml + publish.yml only make sense when there's a publishable CLI.
    if a.with_cli:
        w(os.path.join(root, ".github/workflows/release.yml"), textwrap.dedent("""\
            name: Release

            # cargo-flux derives the next semver from conventional-commit messages
            # and stamps a `chore(release):` commit + tag on every push to main.
            on:
              push:
                branches: [main]

            permissions:
              contents: write

            concurrency:
              group: release
              cancel-in-progress: false

            jobs:
              release:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v4
                    with:
                      fetch-depth: 0
                      fetch-tags: true
                      token: ${{ secrets.GITHUB_TOKEN }}
                  - uses: dtolnay/rust-toolchain@stable
                  - run: cargo install cargo-flux
                  - name: Version + tag from commit history
                    run: |
                      git config user.name  "github-actions[bot]"
                      git config user.email "github-actions[bot]@users.noreply.github.com"
                      cargo flux version --commit --tag --push
            """))
        w(os.path.join(root, ".github/workflows/publish.yml"), textwrap.dedent("""\
            name: Publish

            # Publishes crates that opt into the `publish` flux task when a
            # version tag is pushed. Requires a CARGO_REGISTRY_TOKEN secret.
            on:
              push:
                tags: ["v*"]

            jobs:
              publish:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v4
                    with:
                      fetch-depth: 0
                  - uses: dtolnay/rust-toolchain@stable
                  - run: cargo install cargo-flux
                  - run: cargo flux run publish
                    env:
                      CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}
            """))

    # ---- <name>-core --------------------------------------------------------
    core_flux = '["check", "build", "test", "lint"'
    core_flux += ', "publish"]' if a.with_cli else "]"
    w(os.path.join(root, core, "Cargo.toml"), textwrap.dedent(f"""\
        [package]
        name = "{core}"
        version = "0.1.0"
        edition.workspace = true
        license.workspace = true
        {repo_inherit}description = "Core entities and logic for {name}"

        [package.metadata.flux]
        tasks = {core_flux}

        [dependencies]
        myko = {{ workspace = true }}
        serde = {{ workspace = true }}
        serde_json = {{ workspace = true }}
        chrono = {{ workspace = true }}
        anyhow = {{ workspace = true }}
        ciborium = {{ workspace = true }}
        """))
    w(os.path.join(root, core, "src/lib.rs"), textwrap.dedent(f"""\
        pub mod entities;

        pub use entities::*;

        /// Binaries that only ever receive `{core}` entities over the wire (the
        /// hub) must call this. Without a referenced symbol from this crate the
        /// linker drops its object files — taking myko's inventory registrations
        /// for entities, commands, and sagas with them.
        pub fn link() {{}}
        """))
    w(os.path.join(root, core, "src/entities/mod.rs"), textwrap.dedent("""\
        mod note;

        pub use note::*;
        """))
    w(os.path.join(root, core, "src/entities/note.rs"), textwrap.dedent("""\
        //! A sample myko item. `#[myko_item]` derives the wire schema, the
        //! `PartialNote` update type, and registers the entity in myko's
        //! inventory so servers and clients can route it by type name.
        //!
        //! Field-naming caution carried over from levi: myko's query wire format
        //! reserves the keys `tx` and `createdAt`, and `Partial*` serializes
        //! `None` as an explicit `null`. Name timestamp fields `created`/
        //! `observed` (never `created_at`/`tx`) so a colliding key can't break a
        //! remote `Get*ByQuery`.

        use myko::prelude::*;

        #[myko_subtype(derive(Default, Eq, Hash, PartialOrd, Ord, Copy))]
        pub enum Priority {
            P0,
            P1,
            #[default]
            P2,
            P3,
        }

        #[myko_item]
        pub struct Note {
            #[searchable]
            pub title: String,
            #[serde(default)]
            #[searchable]
            pub body: String,
            #[serde(default)]
            pub priority: Priority,
            /// RFC3339 creation timestamp.
            pub created: String,
        }

        #[cfg(test)]
        mod tests {
            use super::*;
            use myko::wire::{MEvent, MEventType};

            #[test]
            fn note_event_cbor_roundtrip() {
                let n = Note {
                    id: "n1".into(),
                    title: "hello".into(),
                    body: String::new(),
                    priority: Priority::P1,
                    created: "2026-01-01T00:00:00Z".into(),
                };
                let ev = MEvent::from_item(&n, MEventType::SET, "machine");
                let mut buf = Vec::new();
                ciborium::into_writer(&ev, &mut buf).unwrap();
                let back: MEvent = ciborium::from_reader(buf.as_slice()).unwrap();
                let n2: Note = serde_json::from_value(back.item.clone()).unwrap();
                assert_eq!(n, n2);
                assert_eq!(back.item_type, "Note");
            }
        }
        """))

    # ---- <name> CLI ---------------------------------------------------------
    if a.with_cli:
        cli_flux = '["check", "build", "test", "lint", "publish"]'
        w(os.path.join(root, name, "Cargo.toml"), textwrap.dedent(f"""\
            [package]
            name = "{name}"
            version = "0.1.0"
            edition.workspace = true
            license.workspace = true
            {repo_inherit}description = "{name} command-line interface"

            [package.metadata.flux]
            tasks = {cli_flux}

            [[bin]]
            name = "{name}"
            path = "src/main.rs"

            [dependencies]
            {core} = {{ workspace = true }}
            myko = {{ workspace = true }}
            serde_json = {{ workspace = true }}
            anyhow = {{ workspace = true }}
            chrono = {{ workspace = true }}
            clap = {{ version = "4", features = ["derive"] }}
            """))
        w(os.path.join(root, name, "src/main.rs"), textwrap.dedent(f"""\
            use clap::{{Parser, Subcommand}};
            use {core_lib}::Note;

            #[derive(Parser)]
            #[command(name = "{name}", version, about = "{name} CLI")]
            struct Cli {{
                #[command(subcommand)]
                cmd: Cmd,
            }}

            #[derive(Subcommand)]
            enum Cmd {{
                /// Print a sample note as JSON.
                Demo {{
                    #[arg(default_value = "hello")]
                    title: String,
                }},
            }}

            fn main() -> anyhow::Result<()> {{
                match Cli::parse().cmd {{
                    Cmd::Demo {{ title }} => {{
                        let note = Note {{
                            id: "demo".into(),
                            title,
                            body: String::new(),
                            priority: Default::default(),
                            created: chrono::Utc::now().to_rfc3339(),
                        }};
                        println!("{{}}", serde_json::to_string_pretty(&note)?);
                        Ok(())
                    }}
                }}
            }}
            """))

    # ---- <name>-hub ---------------------------------------------------------
    if a.with_hub:
        w(os.path.join(root, f"{name}-hub", "Cargo.toml"), textwrap.dedent(f"""\
            [package]
            name = "{name}-hub"
            version = "0.1.0"
            edition.workspace = true
            license.workspace = true
            {repo_inherit}
            [package.metadata.flux]
            tasks = ["check", "build", "test", "lint"]

            [[bin]]
            name = "{name}-hub"
            path = "src/main.rs"

            [dependencies]
            {core} = {{ workspace = true }}
            myko = {{ workspace = true }}
            myko-server = {{ workspace = true }}
            anyhow = {{ workspace = true }}
            tokio = {{ workspace = true }}
            tracing = "0.1"
            clap = {{ version = "4", features = ["derive"] }}
            """))
        w(os.path.join(root, f"{name}-hub", "src/main.rs"), textwrap.dedent(f"""\
            //! {name}-hub: a myko CellServer (+ optional Postgres). Receives
            //! entity events from clients and serves aggregate reactive queries.

            use clap::{{Parser, Subcommand}};

            #[derive(Parser)]
            #[command(name = "{name}-hub", version, about = "{name} aggregation hub")]
            struct Cli {{
                #[command(subcommand)]
                cmd: Cmd,
            }}

            #[derive(Subcommand)]
            enum Cmd {{
                /// Run the hub.
                Serve {{
                    /// Address for the myko WebSocket endpoint (ws://<bind>/myko).
                    #[arg(long, default_value = "0.0.0.0:7377")]
                    bind: String,
                }},
            }}

            #[tokio::main]
            async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {{
                // myko logs through `tracing`; install the subscriber (honors RUST_LOG)
                // so server-side query/command errors are visible.
                let _telemetry = myko_server::telemetry::init_from_env();
                match Cli::parse().cmd {{
                    Cmd::Serve {{ bind }} => serve(bind).await,
                }}
            }}

            async fn serve(bind: String) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {{
                // Force the entity crate to link (see {core_lib}::link docs).
                {core_lib}::link();
                let mut builder = myko_server::CellServer::builder().with_bind_addr(bind.parse()?);
                match myko_server::postgres::PostgresConfig::from_env() {{
                    Some(pg) => builder = builder.with_postgres(pg),
                    None => tracing::warn!("MYKO_POSTGRES_URL not set: events are held in memory only"),
                }}
                builder.build().run().await
            }}
            """))

    # ---- <name>-dash --------------------------------------------------------
    if a.with_dash:
        w(os.path.join(root, f"{name}-dash", "Cargo.toml"), textwrap.dedent(f"""\
            [package]
            name = "{name}-dash"
            version = "0.1.0"
            edition.workspace = true
            license.workspace = true
            {repo_inherit}
            [package.metadata.flux]
            tasks = ["check", "check-wasm", "lint"]

            [[bin]]
            name = "{name}-dash"
            path = "src/main.rs"

            [dependencies]
            {core} = {{ workspace = true }}
            myko = {{ workspace = true }}
            myko-leptos = {{ workspace = true }}
            leptos = {{ version = "0.8", features = ["csr"] }}
            console_error_panic_hook = "0.1"
            wasm-bindgen = "0.2"
            serde = {{ workspace = true }}
            serde_json = {{ workspace = true }}
            # Optional design system + pane manager used by levi-dash:
            #   pulse-leptos-ui = "0.9"   # crates.io — BaseStyle + tokens
            #   mullion = {{ git = "https://github.com/ignition-is-go/mullion", branch = "main" }}
            # NOTE: `mullion` MUST stay a git dependency. The `mullion` name on
            # crates.io belongs to an unrelated terminal-UI crate; a version spec
            # here would silently pull the wrong library.
            """))
        w(os.path.join(root, f"{name}-dash", "src/main.rs"), textwrap.dedent("""\
            mod app;

            fn main() {
                console_error_panic_hook::set_once();
                leptos::mount::mount_to_body(app::App);
            }
            """))
        w(os.path.join(root, f"{name}-dash", "src/app.rs"), textwrap.dedent(f"""\
            //! Minimal Leptos CSR shell. Connect to the hub's `/myko` endpoint via
            //! `myko-leptos` to drive live reactive views; see levi-dash for the
            //! full mullion pane + pulse-leptos-ui design-system treatment.

            use leptos::prelude::*;

            #[component]
            pub fn App() -> impl IntoView {{
                view! {{
                    <main style="font-family: system-ui; padding: 2rem;">
                        <h1>"{name}"</h1>
                        <p>"Leptos CSR dashboard scaffold. Wire live data with myko-leptos."</p>
                    </main>
                }}
            }}
            """))
        w(os.path.join(root, f"{name}-dash", "Trunk.toml"), textwrap.dedent("""\
            [build]
            target = "index.html"
            release = true

            [serve]
            port = 1420
            """))
        w(os.path.join(root, f"{name}-dash", "index.html"), textwrap.dedent(f"""\
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>{name}</title>
              <link data-trunk rel="rust" data-wasm-opt="z" />
              <style>
                html, body {{ height: 100%; margin: 0; }}
              </style>
            </head>
            <body></body>
            </html>
            """))

    print(f"\nScaffold complete: {root}")
    print(f"members: {', '.join(members)}")

if __name__ == "__main__":
    main()
