# :paradedb tests need a ParadeDB-enabled Postgres; the test-paradedb CI job
# re-includes them via `mix test --include paradedb`.
# :real_browser runs explicitly with the pinned agent-browser CLI and Chromium.
# :e2e is the Playwright browser suite (test/e2e_pw); run it with E2E=1 against a bootstrapped
# database: `E2E=1 mix test --only e2e`.
e2e? = System.get_env("E2E") == "1"

if e2e? do
  # The app runs for real (E2E=1 config: server on :4002, no SQL sandbox), as the Playwright
  # webServer did; modules share its state and run serially.
  Logger.configure(level: :warning)
  ExUnit.start(exclude: [:integration, :paradedb, :real_browser], timeout: 30_000)
else
  ExUnit.start(exclude: [:integration, :paradedb, :real_browser, :e2e], capture_log: true)
  Ecto.Adapters.SQL.Sandbox.mode(Zaq.Repo, :manual)
  Registry.start_link(keys: :unique, name: Zaq.Engine.Workflows.RunRegistry)
  Logger.put_module_level(Postgrex.Protocol, :none)
  Logger.put_module_level(Task.Supervised, :none)
end
