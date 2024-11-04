defmodule ExcisionWeb.Components.CopyButtonComponent do
  use Phoenix.Component

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
end
