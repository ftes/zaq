defmodule Zaq.E2EPw.Auth do
  @moduledoc """
  Port of `test/e2e/support/global-setup.js`: logs the admin in once per run and keeps the
  storage state for every test's context.
  """

  alias Playwright.{Browser, BrowserContext, Expect, Locator, Page}

  @required_assets ["/assets/js/app.js", "/assets/css/app.css"]
  @base_url System.get_env("E2E_BASE_URL") || "http://localhost:4002"
  @username System.get_env("E2E_ADMIN_USERNAME") || "e2e_admin"
  @password System.get_env("E2E_ADMIN_PASSWORD") || "StrongPass1!"

  @doc "The admin's storage state, logging in on first use (by whichever module gets here first)."
  def storage_state(browser) do
    case :persistent_term.get({__MODULE__, :state}, nil) do
      nil -> :global.trans({__MODULE__, self()}, fn -> login(browser) end)
      state -> state
    end
  end

  defp login(browser) do
    case :persistent_term.get({__MODULE__, :state}, nil) do
      nil ->
        verify_server!()

        context = Browser.new_context!(browser, base_url: @base_url)
        page = BrowserContext.new_page!(context)

        try do
          Page.goto!(page, "/bo/login")
          Page.wait_for_selector!(page, "[data-phx-main].phx-connected", timeout: 15_000)
          page |> Page.locator(~s|input[name="username"]|) |> Locator.fill!(@username)
          page |> Page.locator(~s|input[name="password"]|) |> Locator.fill!(@password)
          page |> Page.get_by_role(:button, name: "Sign In to Dashboard") |> Locator.click!()
          Expect.to_have_url!(page, ~r{/bo/(dashboard|change-password)}, timeout: 15_000)
          state = BrowserContext.storage_state!(context)
          :persistent_term.put({__MODULE__, :state}, state)
          state
        after
          BrowserContext.close!(context)
        end

      state ->
        state
    end
  end

  # Verifies compiled assets are served and the server booted with E2E=1.
  defp verify_server! do
    for path <- @required_assets ++ ["/e2e/health"] do
      case Req.get(@base_url <> path, retry: false) do
        {:ok, %{status: status}} when status in 200..299 ->
          :ok

        other ->
          raise "#{path} not available (#{inspect(other)}): run mix assets.build, E2E=1 server"
      end
    end
  end
end
