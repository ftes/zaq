defmodule Zaq.E2EPw.Case do
  @moduledoc """
  Case template for the Playwright browser journeys: the port of the `journeys-<browser>`
  projects of `test/e2e/playwright.config.js`.

  Every test gets a context of the project's device that starts from the back-office admin's
  storage state (global setup logs in once), a `page` and a `request`. The device, and so the
  browser, comes from `E2E_AUTH_BROWSER` (chromium, firefox or webkit), as the CI matrix leg
  sets it, in `config/runtime.exs`.

  The journeys share one server and database (`POST /e2e/reset`), so modules are not async.
  """

  use ExUnit.CaseTemplate
  use Playwright.Test

  alias Playwright.{Browser, BrowserContext}
  alias Playwright.Test.BrowserPool
  alias Zaq.E2EPw.Auth

  using opts do
    quote do
      use Playwright.Test, unquote(opts)

      alias Playwright.{
        APIRequestContext,
        APIResponse,
        Browser,
        BrowserContext,
        Expect,
        Locator,
        Page,
        Test
      }

      alias Playwright.Test.BrowserPool
      alias Zaq.E2EPw.BO

      @moduletag :e2e
    end
  end

  setup_all do
    %{browser: BrowserPool.browser()}
  end

  setup %{browser: browser} do
    storage_state = Auth.storage_state(browser)
    context = Browser.new_context!(browser, storage_state: storage_state)
    page = BrowserContext.new_page!(context)
    %{context: context, page: page, request: BrowserContext.request(context)}
  end
end
