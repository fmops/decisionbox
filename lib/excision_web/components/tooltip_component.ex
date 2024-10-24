defmodule ExcisionWeb.Components.TooltipComponent do
  use Phoenix.Component
  import ExcisionWeb.CoreComponents

  attr :text, :string, required: true
  attr :class, :string, default: ""

  attr :icon_class, :string,
    default: "h-5 w-5 text-gray-500 hover:text-gray-600 transition-colors"

  # Wider default
  attr :width, :string, default: "w-64"

  def tooltip(assigns) do
    assigns =
      assign(assigns, :tooltip_classes, """
        absolute z-10 invisible opacity-0 group-hover:visible group-hover:opacity-100
        #{assigns.width} min-h-[40px] max-h-[200px] overflow-y-auto
        bottom-full left-1/2 -translate-x-1/2 mb-3
        bg-gray-900/95 backdrop-blur-sm
        text-white/90 text-sm
        rounded-lg shadow-lg
        border border-white/10
        p-3
        transition-all duration-200 ease-in-out
      """)

    ~H"""
    <div class="relative inline-block group">
      <div class="cursor-help">
        <.icon name="hero-question-mark-circle" class={@icon_class <> " " <> @class} />
      </div>
      <div class={@tooltip_classes}>
        <%= @text %>
        <div class="absolute -bottom-2 left-1/2 -translate-x-1/2 transform">
          <div class="
            border-8 border-transparent border-t-gray-900/95
            filter drop-shadow-sm
          ">
          </div>
        </div>
      </div>
    </div>
    """
  end

  def passthrough_classifier_tooltip(assigns) do
    ~H"""
    <.tooltip text='When a Decision Site is created, an associated "Passthrough" entity is also automatically created, which replicates the same behavior as making a function call to a model provider, with the added benefit that decisions coming from the LLM are recorded in your DecisionBox database.   Those decisions can now be inspected and labeled, establishing a baseline for accuracy before you replace it with a newly created, purpose-built classifier which can be trained through labeling for even greater accuracy.  Note that a Passthrough cannot be trained.' />
    """
  end
end
