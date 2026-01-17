defmodule Playwright.Page do
  @moduledoc """
  `Page` provides methods to interact with a single tab in a
  `Playwright.Browser`, or an [extension background page](https://developer.chrome.com/extensions/background_pages)
  in Chromium.

  One `Playwright.Browser` instance might have multiple `Page` instances.

  ## Example

  Create a page, navigate it to a URL, and save a screenshot:

      page = Browser.new_page(browser)
      resp = Page.goto(page, "https://example.com")

      Page.screenshot(page, %{path: "screenshot.png"})
      :ok = Page.close(page)

  The Page module is capable of handling various emitted events (described below).

  ## Example

  Log a message for a single page load event (WIP: `once` is not yet implemented):

      Page.once(page, :load, fn e ->
        IO.puts("page loaded!")
      end)

  Unsubscribe from events with the `remove_lstener` function (WIP: `remove_listener` is not yet implemented):

      def log_request(request) do
        IO.inspect(label: "A request was made")
      end

      Page.on(page, :request, fn e ->
        log_request(e.pages.request)
      end)

      Page.remove_listener(page, log_request)
  """
  use Playwright.SDK.ChannelOwner

  alias Playwright.{BrowserContext, ElementHandle, Frame, Page, Response}
  alias Playwright.SDK.{Channel, ChannelOwner, Helpers}

  @property :bindings
  @property :is_closed
  @property :main_frame
  @property :owned_context
  @property :routes
  @property :viewport_size

  @valid_events ~w(
    close console crash dialog domcontentloaded download
    filechooser frameattached framedetached framenavigated
    load pageerror popup request response request_finished
    request_failed websocket worker
  )a

  # ---
  # @property :coverage
  # @property :keyboard
  # @property :mouse
  # @property :request
  # @property :touchscreen
  # ---

  @type dimensions :: map()
  @type expression :: binary()
  @type function_or_options :: fun() | options() | nil
  @type options :: map()
  @type selector :: binary()
  @type serializable :: any()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(%Page{session: session} = page, _intializer) do
    Channel.bind(session, {:guid, page.guid}, :close, fn event ->
      {:patch, %{event.target | is_closed: true}}
    end)

    Channel.bind(session, {:guid, page.guid}, :binding_call, fn %{params: %{binding: binding}, target: target} ->
      on_binding(target, binding)
    end)

    Channel.bind(session, {:guid, page.guid}, :route, fn %{target: target} = e ->
      on_route(target, e)
      # NOTE: will patch here
    end)

    Channel.bind(session, {:guid, page.guid}, :viewport_size_changed, fn %{params: params, target: target} ->
      {:patch, %{target | viewport_size: params.viewport_size}}
    end)

    {:ok, %{page | bindings: %{}, routes: []}}
  end

  # API
  # ---------------------------------------------------------------------------

  @doc """
  Adds a script to be evaluated before other scripts.

  The script is evaluated in the following scenarios:

  - Whenever the page is navigated.
  - Whenever a child frame is attached or navigated. In this case, the script
    is evaluated in the context of the newly attached frame.

  The script is evaluated after the document is created but before any of its
  scripts are run. This is useful to amend the JavaScript environment, e.g. to
  seed `Math.random`.

  ## Returns

    - `:ok`

  ## Arguments

  | key/name    | type   |                       | description |
  | ----------- | ------ | --------------------- | ----------- |
  | `script`    | param  | `binary()` or `map()` | As `binary()`: an inlined script to be evaluated; As `%{path: path}`: a path to a JavaScript file. |

  ## Example

  Overriding `Math.random` before the page loads:

      # preload.js
      Math.random = () => 42;

      Page.add_init_script(page, %{path: "preload.js"})

  ## Notes

  > While the official Node.js Playwright implementation supports an optional
  > `param: arg` for this function, the official Python implementation does
  > not. This implementation matches the Python for now.

  > The order of evaluation of multiple scripts installed via
  > `Playwright.BrowserContext.add_init_script/2` and
  > `Playwright.Page.add_init_script/2` is not defined.
  """
  @spec add_init_script(t(), binary() | map()) :: :ok
  def add_init_script(%Page{session: session} = page, script) when is_binary(script) do
    params = %{source: script}

    case Channel.post(session, {:guid, page.guid}, :add_init_script, params) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        {:error, error}
    end
  end

  def add_init_script(%Page{} = page, %{path: path} = script) when is_map(script) do
    add_init_script(page, File.read!(path))
  end

  # ---

  # @spec add_locator_handler(t(), Locator.t(), (Locator.t() -> any()), options()) :: :ok
  # def add_locator_handler(page, locator, func, options \\ %{})

  # @spec add_script_tag(Page.t(), options()) :: ElementHandle.t()
  # def add_script_tag(page, options \\ %{})

  # @spec add_style_tag(Page.t(), options()) :: ElementHandle.t()
  # def add_style_tag(page, options \\ %{})

  @doc """
  Brings the page to front (activates the tab).

  ## Returns

    - `:ok`
  """
  @spec bring_to_front(t()) :: :ok
  def bring_to_front(%Page{session: session} = page) do
    Channel.post(session, {:guid, page.guid}, :bring_to_front, %{})
    :ok
  end

  # ---

  @spec click(t(), binary(), options()) :: :ok
  def click(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.click(selector, options)
  end

  @doc """
  Closes the `Page`.

  If the `Page` has an "owned context" (1-to-1 co-dependency with a
  `Playwright.BrowserContext`), that context is closed as well.

  If `option: run_before_unload` is false, does not run any unload handlers and
  waits for the page to be closed. If `option: run_before_unload` is `true`
  the function will run unload handlers, but will not wait for the page to
  close. By default, `Playwright.Page.close/1` does not run `:beforeunload`
  handlers.

  ## Returns

    - `:ok`

  ## Arguments

  | key/name            | type   |             | description |
  | ------------------- | ------ | ----------- | ----------- |
  | `run_before_unload` | option | `boolean()` | Whether to run the before unload page handlers. `(default: false)` |

  ## NOTE

  > if `option: run_before_unload` is passed as `true`, a `:beforeunload`
  > dialog might be summoned and should be handled manually via
  > `Playwright.Page.on/3`.
  """
  @spec close(t(), options()) :: :ok
  def close(%Page{session: session} = page, options \\ %{}) do
    # A call to `close` will remove the item from the catalog. `Catalog.find`
    # here ensures that we do not `post` a 2nd `close`.
    case Channel.find(session, {:guid, page.guid}, %{timeout: 10}) do
      %Page{} = latest_page ->
        Channel.post(session, {:guid, page.guid}, :close, options)

        # NOTE: this *might* prefer to be done on `__dispose__`
        # ...OR, `.on(_, "close", _)`
        # Use latest_page to get patched owned_context field
        if latest_page.owned_context do
          context(latest_page) |> BrowserContext.close()
        end

        :ok

      {:error, _} ->
        :ok
    end
  end

  # ---

  # @spec content(Page.t()) :: binary()
  # def content(page)

  # ---

  # @doc """
  # Get the full HTML contents of the page, including the doctype.
  # """
  # @spec content(t()) :: binary()
  # def content(%Page{session: session} = page) do
  #   Channel.post(session, {:guid, page.guid}, :content)
  # end

  @doc """
  Get the `Playwright.BrowserContext` that the page belongs to.
  """
  @spec context(t()) :: BrowserContext.t()
  def context(page)

  def context(%Page{session: session} = page) do
    Channel.find(session, {:guid, page.parent.guid})
  end

  @spec content(t()) :: binary() | {:error, term()}
  def content(%Page{} = page) do
    main_frame(page) |> Frame.content()
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.dblclick/3`.
  """
  @spec dblclick(t(), binary(), options()) :: :ok
  def dblclick(page, selector, options \\ %{})

  def dblclick(%Page{} = page, selector, options) do
    main_frame(page) |> Frame.dblclick(selector, options)
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.dispatch_event/5`.
  """
  @spec dispatch_event(t(), binary(), atom() | binary(), Frame.evaluation_argument(), options()) :: :ok
  def dispatch_event(%Page{} = page, selector, type, event_init \\ nil, options \\ %{}) do
    main_frame(page) |> Frame.dispatch_event(selector, type, event_init, options)
  end

  @spec drag_and_drop(Page.t(), binary(), binary(), options()) :: Page.t()
  def drag_and_drop(page, source, target, options \\ %{}) do
    with_latest(page, fn page ->
      main_frame(page) |> Frame.drag_and_drop(source, target, options)
    end)
  end

  # ---

  # @spec emulate_media(t(), options()) :: :ok
  # def emulate_media(page, options \\ %{})

  # ---

  @spec eval_on_selector(t(), binary(), binary(), term(), map()) :: term()
  def eval_on_selector(%Page{} = page, selector, expression, arg \\ nil, options \\ %{}) do
    main_frame(page)
    |> Frame.eval_on_selector(selector, expression, arg, options)
  end

  @spec evaluate(t(), expression(), any()) :: serializable()
  def evaluate(page, expression, arg \\ nil)

  def evaluate(%Page{} = page, expression, arg) do
    main_frame(page) |> Frame.evaluate(expression, arg)
  end

  @spec evaluate_handle(t(), expression(), any()) :: serializable()
  def evaluate_handle(%Page{} = page, expression, arg \\ nil) do
    main_frame(page) |> Frame.evaluate_handle(expression, arg)
  end

  # @spec expect_event(t(), atom() | binary(), function(), any(), any()) :: Playwright.SDK.Channel.Event.t()
  # def expect_event(page, event, trigger, predicate \\ nil, options \\ %{})

  # def expect_event(%Page{} = page, event, trigger, predicate, options) do
  #   context(page) |> BrowserContext.expect_event(event, trigger, predicate, options)
  # end

  def expect_event(page, event, options \\ %{}, trigger \\ nil)

  def expect_event(%Page{} = page, event, options, trigger) do
    context(page) |> BrowserContext.expect_event(event, options, trigger)
  end

  # ---

  # @spec expect_request(t(), binary() | function(), options()) :: :ok
  # def expect_request(page, url_or_predicate, options \\ %{})
  # ...defdelegate wait_for_request

  # @spec expect_response(t(), binary() | function(), options()) :: :ok
  # def expect_response(page, url_or_predicate, options \\ %{})
  # ...defdelegate wait_for_response

  @doc """
  Adds a function called `param:name` on the `window` object of every frame in
  this page.

  When called, the function executes `param:callback` and resolves to the return
  value of the `callback`.

  The first argument to the `callback` function includes the following details
  about the caller:

      %{
        context: %Playwright.BrowserContext{},
        frame:   %Playwright.Frame{},
        page:    %Playwright.Page{}
      }

  See `Playwright.BrowserContext.expose_binding/4` for a similar,
  context-scoped version.
  """
  @spec expose_binding(t(), binary(), function(), options()) :: Page.t()
  def expose_binding(%Page{session: session} = page, name, callback, options \\ %{}) do
    Channel.patch(session, {:guid, page.guid}, %{bindings: Map.merge(page.bindings, %{name => callback})})
    post!(page, :expose_binding, Map.merge(%{name: name, needs_handle: false}, options))
  end

  @doc """
  Adds a function called `param:name` on the `window` object of every frame in
  the page.

  When called, the function executes `param:callback` and resolves to the return
  value of the `callback`.

  See `Playwright.BrowserContext.expose_function/3` for a similar,
  context-scoped version.
  """
  @spec expose_function(Page.t(), String.t(), function()) :: Page.t()
  def expose_function(page, name, callback) do
    expose_binding(page, name, fn _, args ->
      callback.(args)
    end)
  end

  # ---

  @spec fill(t(), binary(), binary(), options()) :: :ok
  def fill(%Page{} = page, selector, value, options \\ %{}) do
    main_frame(page) |> Frame.fill(selector, value, options)
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.focus/3`.
  """
  @spec focus(t(), binary(), options()) :: :ok
  def focus(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.focus(selector, options)
  end

  # ---

  # @spec frame(t(), binary()) :: Frame.t() | nil
  # def frame(page, selector)

  # ---

  @spec frames(t()) :: [Frame.t()]
  def frames(%Page{} = page) do
    Channel.list(page.session, {:guid, page.guid}, "Frame")
  end

  # ---

  # @spec frame_locator(t(), binary()) :: FrameLocator.t()
  # def frame_locator(page, selector)

  # ---

  @spec get_attribute(t(), binary(), binary(), map()) :: binary() | nil
  def get_attribute(%Page{} = page, selector, name, options \\ %{}) do
    main_frame(page) |> Frame.get_attribute(selector, name, options)
  end

  # ---

  @doc """
  Allows locating elements by their alt text.

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `text`     | param  | `binary()` | Alt text to locate. |
  | `:exact`   | option | `boolean()`| Whether to find an exact match. Default to false. |
  """
  @spec get_by_alt_text(t(), binary(), %{optional(:exact) => boolean()}) :: Playwright.Locator.t()
  def get_by_alt_text(page, text, options \\ %{}) when is_binary(text) do
    main_frame(page) |> Frame.get_by_alt_text(text, options)
  end

  @doc """
  Allows locating elements by their associated label text.

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `text`     | param  | `binary()` | Label text to locate. |
  | `:exact`   | option | `boolean()`| Whether to find an exact match. Default to false. |
  """
  @spec get_by_label(t(), binary(), %{optional(:exact) => boolean()}) :: Playwright.Locator.t()
  def get_by_label(page, text, options \\ %{}) when is_binary(text) do
    main_frame(page) |> Frame.get_by_label(text, options)
  end

  @doc """
  Allows locating input elements by their placeholder text.

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `text`     | param  | `binary()` | Placeholder text to locate. |
  | `:exact`   | option | `boolean()`| Whether to find an exact match. Default to false. |
  """
  @spec get_by_placeholder(t(), binary(), %{optional(:exact) => boolean()}) :: Playwright.Locator.t()
  def get_by_placeholder(page, text, options \\ %{}) when is_binary(text) do
    main_frame(page) |> Frame.get_by_placeholder(text, options)
  end

  @doc """
  Allows locating elements by ARIA role.

  ## Arguments

  | key/name         | type   |            | description |
  | ---------------- | ------ | ---------- | ----------- |
  | `role`           | param  | `binary()` | ARIA role (e.g., "button", "heading"). |
  | `:name`          | option | `binary()` | Filter by accessible name. |
  | `:exact`         | option | `boolean()`| Exact name match. Default to false. |
  | `:checked`       | option | `boolean()`| Filter by checked state. |
  | `:disabled`      | option | `boolean()`| Filter by disabled state. |
  | `:expanded`      | option | `boolean()`| Filter by expanded state. |
  | `:include_hidden`| option | `boolean()`| Include hidden elements. |
  | `:level`         | option | `integer()`| Heading level (1-6). |
  | `:pressed`       | option | `boolean()`| Filter by pressed state. |
  | `:selected`      | option | `boolean()`| Filter by selected state. |
  """
  @spec get_by_role(t(), binary(), map()) :: Playwright.Locator.t()
  def get_by_role(page, role, options \\ %{}) when is_binary(role) do
    main_frame(page) |> Frame.get_by_role(role, options)
  end

  @doc """
  Allows locating elements by their test id attribute (data-testid by default).

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `test_id`  | param  | `binary()` | The test id to locate. |
  """
  @spec get_by_test_id(t(), binary()) :: Playwright.Locator.t()
  def get_by_test_id(page, test_id) when is_binary(test_id) do
    main_frame(page) |> Frame.get_by_test_id(test_id)
  end

  @doc """
  Allows locating elements that contain given text.

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `text`     | param  | `binary()` | Text to locate the element for. |
  | `:exact`   | option | `boolean()`| Whether to find an exact match: case-sensitive and whole-string. Default to false. Ignored when locating by a regular expression. Note that exact match still trims whitespace. |
  """
  @spec get_by_text(Page.t(), binary(), %{optional(:exact) => boolean()}) :: Playwright.Locator.t() | nil
  def get_by_text(page, text, options \\ %{}) do
    main_frame(page) |> Frame.get_by_text(text, options)
  end

  @doc """
  Allows locating elements by their title attribute.

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `text`     | param  | `binary()` | Title text to locate. |
  | `:exact`   | option | `boolean()`| Whether to find an exact match. Default to false. |
  """
  @spec get_by_title(t(), binary(), %{optional(:exact) => boolean()}) :: Playwright.Locator.t()
  def get_by_title(page, text, options \\ %{}) when is_binary(text) do
    main_frame(page) |> Frame.get_by_title(text, options)
  end

  @doc """
  Navigate to the previous page in history.

  ## Options

  - `:timeout` - Maximum time in milliseconds. Defaults to 30000 (30 seconds).
  - `:wait_until` - When to consider navigation succeeded. Defaults to `"load"`.
    - `"load"` - wait for the load event
    - `"domcontentloaded"` - wait for DOMContentLoaded event
    - `"networkidle"` - wait until no network connections for 500ms
    - `"commit"` - wait for network response and document started loading

  ## Returns

  - `Playwright.Response.t()` - Response of the main resource
  - `nil` - if navigation did not happen (e.g., no previous page)
  """
  @spec go_back(t(), options()) :: Response.t() | nil
  def go_back(%Page{session: session} = page, options \\ %{}) do
    case Channel.post(session, {:guid, page.guid}, :goBack, options) do
      %{response: nil} -> nil
      %{response: %{guid: _} = response} -> Channel.find(session, {:guid, response.guid})
      other -> other
    end
  end

  @doc """
  Navigate to the next page in history.

  ## Options

  - `:timeout` - Maximum time in milliseconds. Defaults to 30000 (30 seconds).
  - `:wait_until` - When to consider navigation succeeded. Defaults to `"load"`.

  ## Returns

  - `Playwright.Response.t()` - Response of the main resource
  - `nil` - if navigation did not happen (e.g., no next page)
  """
  @spec go_forward(t(), options()) :: Response.t() | nil
  def go_forward(%Page{session: session} = page, options \\ %{}) do
    case Channel.post(session, {:guid, page.guid}, :goForward, options) do
      %{response: nil} -> nil
      %{response: %{guid: _} = response} -> Channel.find(session, {:guid, response.guid})
      other -> other
    end
  end

  # ---

  @spec goto(t(), binary(), options()) :: Response.t() | nil | {:error, term()}
  def goto(%Page{} = page, url, options \\ %{}) do
    main_frame(page) |> Frame.goto(url, options)
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.hover/2`.
  """
  def hover(%Page{} = page, selector) do
    main_frame(page) |> Frame.hover(selector)
  end

  # ---

  # @spec is_closed(t()) :: boolean()
  # def is_closed(page)

  # ---

  @spec locator(t(), selector()) :: Playwright.Locator.t()
  def locator(%Page{} = page, selector) do
    Playwright.Locator.new(page, selector)
  end

  @doc """
  Returns a FrameLocator for a frame on the page.

  When working with iframes, you can create a frame locator that will enter the iframe
  and allow locating elements in that iframe.

  ## Example

      page
      |> Page.frame_locator("#my-frame")
      |> FrameLocator.get_by_role("button", name: "Submit")
      |> Locator.click()
  """
  @spec frame_locator(t(), selector()) :: Playwright.Page.FrameLocator.t()
  def frame_locator(%Page{} = page, selector) do
    Playwright.Page.FrameLocator.new(main_frame(page), selector)
  end

  # @spec main_frame(t()) :: Frame.t()
  # def main_frame(page)

  # @spec opener(t()) :: Frame.t() | nil
  # def opener(page)

  # @spec pause(t()) :: :ok
  # def pause(page)

  # ---

  # on(...):
  #   - close
  #   - console
  #   - crash
  #   - dialog
  #   - domcontentloaded
  #   - download
  #   - filechooser
  #   - frameattached
  #   - framedetached
  #   - framenavigated
  #   - load
  #   - pageerror
  #   - popup
  #   - requestfailed
  #   - websocket
  #   - worker

  def on(%Page{} = page, event, callback) when is_binary(event) do
    atom = String.to_atom(event)

    if atom in @valid_events do
      on(page, atom, callback)
    else
      {:error, %ArgumentError{message: "Invalid Page event: #{event}"}}
    end
  end

  # NOTE: These events are recv'd from Playwright server via the parent
  # BrowserContext channel. So, we need to add our handlers there.
  #
  # For :update_subscription, :event is one of:
  # (console|dialog|request|response|requestFinished|requestFailed)
  def on(%Page{session: session} = page, event, callback)
      when event in [:console, :dialog, :request, :response, :request_finished, :request_failed] do
    e = Atom.to_string(event) |> Recase.to_camel()

    Channel.post(session, {:guid, page.guid}, :update_subscription, %{event: e, enabled: true})
    Channel.bind(session, {:guid, context(page).guid}, event, callback)
  end

  # NOTE: FileChooser events are recv'd directly on the Page channel.
  def on(%Page{session: session} = page, :file_chooser, callback) do
    Channel.post(session, {:guid, page.guid}, :update_subscription, %{event: "fileChooser", enabled: true})
    Channel.bind(session, {:guid, page.guid}, :file_chooser, callback)
  end

  def on(%Page{session: session} = page, event, callback) when is_atom(event) do
    Channel.bind(session, {:guid, page.guid}, event, callback)
  end

  # ---

  # @spec pdf(t(), options()) :: binary() # ?
  # def pdf(page, options \\ %{})

  # ---

  @spec press(t(), binary(), binary(), options()) :: :ok
  def press(%Page{} = page, selector, key, options \\ %{}) do
    main_frame(page) |> Frame.press(selector, key, options)
  end

  @spec query_selector(t(), selector(), options()) :: ElementHandle.t() | nil | {:error, :timeout}
  def query_selector(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.query_selector(selector, options)
  end

  defdelegate q(page, selector, options \\ %{}), to: __MODULE__, as: :query_selector

  @spec query_selector_all(t(), binary(), map()) :: [ElementHandle.t()]
  def query_selector_all(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.query_selector_all(selector, options)
  end

  defdelegate qq(page, selector, options \\ %{}), to: __MODULE__, as: :query_selector_all

  @doc """
  Reloads the current page.

  Reloads in the same way as if the user had triggered a browser refresh.

  Returns the main resource response. In case of multiple redirects, the
  navigation will resolve with the response of the last redirect.

  ## Returns

    - `Playwright.Response.t() | nil`

  ## Arguments

  | key/name      | type   |            | description |
  | ------------- | ------ | ---------- | ----------- |
  | `:timeout`    | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via BrowserContext or Page timeout settings. `(default: 30 seconds)` |
  | `:wait_until` | option | `binary()` | "load", "domcontentloaded", "networkidle", or "commit". When to consider the operation as having succeeded. `(default: "load")` |

  ## On Wait Events

  - `domcontentloaded` - consider operation to be finished when the `DOMContentLoaded` event is fired.
  - `load` - consider operation to be finished when the `load` event is fired.
  - `networkidle` - consider operation to be finished when there are no network connections for at least `500 ms`.
  - `commit` - consider operation to be finished when network response is received and the document started loading.
  """
  @spec reload(t(), options()) :: Response.t() | nil
  def reload(%Page{session: session} = page, options \\ %{}) do
    Channel.post(session, {:guid, page.guid}, :reload, options)
  end

  # ---

  # @spec remove_locator_handler(t(), Locator.t()) :: :ok
  # def remove_locator_handler(page, locator)

  # ---

  @spec request(t()) :: Playwright.APIRequestContext.t()
  def request(%Page{session: session} = page) do
    # Fetch latest page state to get patched owned_context field
    fresh_page = Channel.find(session, {:guid, page.guid})

    Channel.list(session, {:guid, fresh_page.owned_context.browser.guid}, "APIRequestContext")
    |> List.first()
  end

  @spec route(t(), binary() | Regex.t(), function(), map()) :: t() | {:error, term()}
  def route(page, pattern, handler, options \\ %{})

  def route(%Page{session: session} = page, pattern, handler, _options) do
    with_latest(page, fn page ->
      matcher = Helpers.URLMatcher.new(pattern)
      handler = Helpers.RouteHandler.new(matcher, handler)

      routes = [handler | page.routes]
      patterns = Helpers.RouteHandler.prepare(routes)

      Channel.patch(session, {:guid, page.guid}, %{routes: routes})
      Channel.post(session, {:guid, page.guid}, :set_network_interception_patterns, %{patterns: patterns})
    end)
  end

  # ---

  # @spec route_from_har(t(), binary(), map()) :: :ok
  # def route_from_har(page, har, options \\ %{})

  # ---

  @spec screenshot(t(), options()) :: binary()
  def screenshot(%Page{session: session} = page, options \\ %{}) do
    case Map.pop(options, :path) do
      {nil, params} ->
        Channel.post(session, {:guid, page.guid}, :screenshot, params)

      {path, params} ->
        [_, filetype] = String.split(path, ".")

        data = Channel.post(session, {:guid, page.guid}, :screenshot, Map.put(params, :type, filetype))
        File.write!(path, Base.decode64!(data))
        data
    end
  end

  @doc """
  Generates a PDF of the page.

  Only supported in Chromium headless mode.

  ## Options

  - `:scale` - Scale of the webpage rendering. Default: `1`.
  - `:display_header_footer` - Display header and footer. Default: `false`.
  - `:header_template` - HTML template for the print header.
  - `:footer_template` - HTML template for the print footer.
  - `:print_background` - Print background graphics. Default: `false`.
  - `:landscape` - Paper orientation. Default: `false`.
  - `:page_ranges` - Paper ranges to print, e.g., `"1-5, 8, 11-13"`.
  - `:format` - Paper format. If set, takes priority over width/height.
  - `:width` - Paper width, accepts values labeled with units.
  - `:height` - Paper height, accepts values labeled with units.
  - `:prefer_css_page_size` - Prefer page size as defined by CSS. Default: `false`.
  - `:margin` - Paper margins as map with `:top`, `:right`, `:bottom`, `:left` keys.
  - `:tagged` - Generate tagged (accessible) PDF. Default: `false`.
  - `:outline` - Generate document outline. Default: `false`.
  - `:path` - File path to save the PDF to.
  """
  @spec pdf(t(), options()) :: binary()
  def pdf(%Page{session: session} = page, options \\ %{}) do
    {path, params} = Map.pop(options, :path)

    params =
      params
      |> rename_key(:display_header_footer, :displayHeaderFooter)
      |> rename_key(:header_template, :headerTemplate)
      |> rename_key(:footer_template, :footerTemplate)
      |> rename_key(:print_background, :printBackground)
      |> rename_key(:page_ranges, :pageRanges)
      |> rename_key(:prefer_css_page_size, :preferCSSPageSize)

    data = Channel.post(session, {:guid, page.guid}, :pdf, params)

    if path do
      File.write!(path, Base.decode64!(data))
    end

    data
  end

  defp rename_key(map, old_key, new_key) do
    case Map.pop(map, old_key) do
      {nil, map} -> map
      {value, map} -> Map.put(map, new_key, value)
    end
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.select_option/4`.
  """
  @spec select_option(t(), binary(), any(), options()) :: [binary()]
  def select_option(%Page{} = page, selector, values \\ nil, options \\ %{}) do
    main_frame(page) |> Frame.select_option(selector, values, options)
  end

  # ---

  # @spec set_checked(t(), binary(), boolean(), options()) :: :ok
  # def set_checked(page, selector, checked, options \\ %{})

  # ---

  @spec set_content(t(), binary(), options()) :: :ok
  def set_content(%Page{} = page, html, options \\ %{}) do
    main_frame(page) |> Frame.set_content(html, options)
  end

  # NOTE: these 2 are good examples of functions that should `cast` instead of `call`.
  # ...
  # @spec set_default_navigation_timeout(t(), number()) :: nil (???)
  # def set_default_navigation_timeout(page, timeout)

  # @spec set_default_timeout(t(), number()) :: nil (???)
  # def set_default_timeout(page, timeout)

  # @spec set_extra_http_headers(t(), map()) :: :ok
  # def set_extra_http_headers(page, headers)

  # ---

  @spec set_viewport_size(t(), dimensions()) :: :ok
  def set_viewport_size(%Page{session: session} = page, dimensions) do
    Channel.post(session, {:guid, page.guid}, :set_viewport_size, %{viewport_size: dimensions})
    Channel.patch(session, {:guid, page.guid}, %{viewport_size: dimensions})
    :ok
  end

  @spec text_content(t(), binary(), map()) :: binary() | nil
  def text_content(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.text_content(selector, options)
  end

  @spec inner_text(t(), binary(), map()) :: binary()
  def inner_text(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.inner_text(selector, options)
  end

  @spec inner_html(t(), binary(), map()) :: binary()
  def inner_html(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.inner_html(selector, options)
  end

  @spec input_value(t(), binary(), map()) :: binary()
  def input_value(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.input_value(selector, options)
  end

  @spec is_checked(t(), binary(), map()) :: boolean()
  def is_checked(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.is_checked(selector, options)
  end

  @spec is_disabled(t(), binary(), map()) :: boolean()
  def is_disabled(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.is_disabled(selector, options)
  end

  @spec is_editable(t(), binary(), map()) :: boolean()
  def is_editable(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.is_editable(selector, options)
  end

  @spec is_enabled(t(), binary(), map()) :: boolean()
  def is_enabled(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.is_enabled(selector, options)
  end

  @spec is_hidden(t(), binary(), map()) :: boolean()
  def is_hidden(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.is_hidden(selector, options)
  end

  @spec is_visible(t(), binary(), map()) :: boolean()
  def is_visible(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.is_visible(selector, options)
  end

  @spec title(t()) :: binary()
  def title(%Page{} = page) do
    main_frame(page) |> Frame.title()
  end

  # ---

  # @spec unroute(t(), function()) :: :ok
  # def unroute(page, handler \\ nil)

  # @spec unroute_all(t(), map()) :: :ok
  # def unroute_all(page, options \\ %{})

  # ---

  @spec url(t()) :: binary()
  def url(%Page{} = page) do
    main_frame(page) |> Frame.url()
  end

  # ---

  # @spec video(t()) :: Video.t() | nil
  # def video(page, handler \\ nil)

  # @spec wait_for_event(t(), binary(), map()) :: map()
  # def wait_for_event(page, event, options \\ %{})

  # @spec wait_for_function(Page.t(), expression(), any(), options()) :: JSHandle.t()
  # def wait_for_function(page, expression, arg \\ nil, options \\ %{})

  # ---

  @spec wait_for_load_state(t(), binary(), options()) :: Page.t()
  def wait_for_load_state(page, state \\ "load", options \\ %{})

  def wait_for_load_state(%Page{} = page, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    main_frame(page) |> Frame.wait_for_load_state(state)
    page
  end

  def wait_for_load_state(%Page{} = page, state, options) when is_binary(state) do
    wait_for_load_state(page, state, options)
  end

  def wait_for_load_state(%Page{} = page, options, _) when is_map(options) do
    wait_for_load_state(page, "load", options)
  end

  @doc """
  Waits for the main frame to navigate to a new URL.

  Returns when the page navigates and reaches the required load state.
  This is a shortcut for `Frame.wait_for_navigation/3` on the page's main frame.

  ## Options

  - `:timeout` - Maximum time in milliseconds. Defaults to 30000 (30 seconds).
  - `:wait_until` - When to consider navigation succeeded. Defaults to `"load"`.
  - `:url` - URL pattern to wait for (glob, regex, or function).

  ## Examples

      # With a trigger function (recommended)
      Page.wait_for_navigation(page, fn -> Page.click(page, "a") end)

      # With options and trigger
      Page.wait_for_navigation(page, %{url: "**/success"}, fn -> Page.click(page, "a") end)

  ## Returns

  - `Page.t()` - The page after navigation
  - `{:error, term()}` - If timeout occurs or navigation fails
  """
  @spec wait_for_navigation(t(), options() | function(), function() | nil) :: t() | {:error, term()}
  def wait_for_navigation(page, options_or_trigger \\ %{}, trigger \\ nil)

  def wait_for_navigation(%Page{} = page, trigger, nil) when is_function(trigger) do
    wait_for_navigation(page, %{}, trigger)
  end

  def wait_for_navigation(%Page{} = page, options, trigger) when is_map(options) do
    case main_frame(page) |> Frame.wait_for_navigation(options, trigger) do
      {:error, _} = error -> error
      _frame -> page
    end
  end

  @spec wait_for_selector(t(), binary(), map()) :: ElementHandle.t() | nil
  def wait_for_selector(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.wait_for_selector(selector, options)
  end

  # ---

  @doc """
  Wait until the page URL matches the given pattern.

  The pattern can be:
  - A string with glob patterns (e.g., `"**/login"`)
  - A regex (e.g., `~r/\\/login$/`)
  - A function that receives URL and returns boolean

  ## Options

  - `:timeout` - Maximum time in milliseconds. Defaults to 30000 (30 seconds).
  - `:wait_until` - When to consider navigation succeeded. Defaults to `"load"`.

  ## Examples

      Page.wait_for_url(page, "**/login")
      Page.wait_for_url(page, ~r/\\/dashboard$/)
      Page.wait_for_url(page, fn url -> String.contains?(url, "success") end)

  ## Returns

  - `Page.t()` - The page after URL matches
  - `{:error, term()}` - If timeout occurs
  """
  @spec wait_for_url(t(), binary() | Regex.t() | function(), options()) :: t() | {:error, term()}
  def wait_for_url(%Page{} = page, url_pattern, options \\ %{}) do
    case main_frame(page) |> Frame.wait_for_url(url_pattern, options) do
      {:error, _} = error -> error
      _frame -> page
    end
  end

  # @spec workers(t()) :: [Worker.t()]
  # def workers(page)

  # ---

  # ... (like Locator?)
  # def accessibility(page)
  # def coverage(page)
  # def keyboard(page)
  # def mouse(page)
  # def request(page)
  # def touchscreen(page)

  # ---

  # private
  # ---------------------------------------------------------------------------

  defp on_binding(page, binding) do
    Playwright.BindingCall.call(binding, Map.get(page.bindings, binding.name))
  end

  # Do not love this.
  # It's good enough for now (to deal with v1.26.0 changes). However, it feels
  # dirty for API resource implementations to be reaching into Catalog.
  defp on_route(page, %{params: %{route: %{request: request} = route} = _params} = _event) do
    Enum.reduce_while(page.routes, [], fn handler, acc ->
      catalog = Channel.Session.catalog(page.session)
      request = Channel.Catalog.get(catalog, request.guid)

      if Helpers.RouteHandler.matches(handler, request.url) do
        Helpers.RouteHandler.handle(handler, %{request: request, route: route})
        # break
        {:halt, acc}
      else
        {:cont, [handler | acc]}
      end
    end)
  end
end
