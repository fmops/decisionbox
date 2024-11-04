defmodule ExcisionWeb.Components.CopyButtonComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def copy_button(assigns) do
    ~H"""
    <div class="relative group">
      <%= render_slot(@inner_block) %>
      <button
        type="button"
        id={"copy-button-#{@target_id}"}
        phx-hook="CopyToClipboard"
        data-target={@target_id}
        class="absolute top-2 right-2 flex items-center gap-2 p-2 bg-white/80 hover:bg-white rounded-md shadow-sm transition-all duration-200"
      >
        <svg
          class="w-5 h-5 text-gray-500 hover:text-gray-700 copy-icon"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"
          />
        </svg>
        <svg
          class="w-5 h-5 text-green-500 check-icon hidden"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <span class="text-sm copy-text">Copy</span>
        <span class="text-sm text-green-600 success-text hidden">Copied!</span>
      </button>
    </div>
    """
  end

  def inline_copy_button(assigns) do
    ~H"""
    <div class="inline-flex items-center gap-2 group">
      <span class="break-all" id={@target_id}><%= @text %></span>
      <button
        type="button"
        id={"copy-button-#{@target_id}"}
        phx-hook="CopyToClipboard"
        data-target={@target_id}
        class="shrink-0 inline-flex items-center p-1.5 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-md transition-colors duration-200"
      >
        <svg
          class="w-4 h-4 copy-icon"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"
          />
        </svg>
        <svg
          class="w-4 h-4 text-green-500 check-icon hidden"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
      </button>
    </div>
    """
  end

  def share_button(assigns) do
    ~H"""
    <span id={"permalink-#{@id}"} class="hidden"><%= @url %></span>
    <button
      type="button"
      id={"copy-button-permalink-#{@id}"}
      phx-hook="CopyToClipboard"
      data-target={"permalink-#{@id}"}
      phx-click={JS.push("share-clicked")}
      class="inline-flex items-center gap-2 text-gray-500 hover:text-gray-700"
    >
      <svg
        class="w-4 h-4 copy-icon"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"
        />
      </svg>
      <svg
        class="w-4 h-4 text-green-500 check-icon hidden"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
      <span class="copy-text">Share</span>
      <span class="text-green-600 success-text hidden">Copied!</span>
    </button>
    """
  end
end
