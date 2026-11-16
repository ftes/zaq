defmodule Zaq.E2EPw.Case do
  @moduledoc """
  Case template for the Playwright browser journeys: the port of the `journeys-<browser>`
  projects of `test/e2e/playwright.config.js`.

  Every test gets a context of the project's device that starts from the back-office admin's
  storage state (global setup logs in once), a `page` and a `request`. The browser comes from
  `E2E_AUTH_BROWSER` (chromium, firefox or webkit), as the CI matrix leg sets it.

  The journeys share one server and database (`POST /e2e/reset`), so modules are not async.
  """

  use ExUnit.CaseTemplate
  use Playwright.Test

  alias Playwright.{Browser, BrowserContext}
  alias Playwright.Test.BrowserPool

  @devices %{
    chromium: "Desktop Chrome",
    firefox: "Desktop Firefox",
    webkit: "Desktop Safari"
  }

  def browser_name do
    case System.get_env("E2E_AUTH_BROWSER", "chromium") do
      "chromium" -> :chromium
      "firefox" -> :firefox
      "webkit" -> :webkit
      other -> raise "Unsupported E2E_AUTH_BROWSER=#{other}"
    end
  end

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
    %{browser: BrowserPool.browser(browser_name: browser_name())}
  end

  setup %{browser: browser} do
    device =
      browser
      |> BrowserPool.playwright()
      |> Playwright.devices()
      |> Map.fetch!(Map.fetch!(@devices, browser_name()))

    context_options =
      Map.put(device, :storage_state, Zaq.E2EPw.Auth.storage_state(browser, device))

    context = Browser.new_context!(browser, context_options)
    page = BrowserContext.new_page!(context)
    %{context: context, page: page, request: BrowserContext.request(context), device: device}
  end
end
