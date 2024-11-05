defmodule ExcisionWeb.Components.BreadcrumbComponent do
  use Phoenix.Component

  def breadcrumbs(assigns) do
    path_parts =
      assigns.current_path
      |> String.split("/", trim: true)
      |> Enum.chunk_every(2)

    paths = build_paths(path_parts)

    assigns = assign(assigns, :breadcrumb_items, paths)

    ~H"""
    <nav class="flex ml-8" aria-label="Breadcrumb">
      <ol role="list" class="flex items-center space-x-2">
        <li>
          <div>
            <a href="/" class="text-gray-400 hover:text-gray-500">
              Home
            </a>
          </div>
        </li>
        <%= for {label, path, is_last} <- @breadcrumb_items do %>
          <li>
            <div class="flex items-center">
              <svg
                class="h-5 w-5 flex-shrink-0 text-gray-300"
                fill="currentColor"
                viewBox="0 0 20 20"
                aria-hidden="true"
              >
                <path d="M5.555 17.776l8-16 .894.448-8 16-.894-.448z" />
              </svg>
              <%= if is_last do %>
                <span class="ml-2 text-sm font-medium text-gray-500">
                  <%= format_label(label) %>
                </span>
              <% else %>
                <a href={path} class="ml-2 text-sm font-medium text-gray-500 hover:text-gray-700">
                  <%= format_label(label) %>
                </a>
              <% end %>
            </div>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  defp build_paths(path_parts) do
    path_parts
    |> Enum.reduce({[], ""}, fn
      [resource, id], {acc, current_path} ->
        new_path = current_path <> "/" <> resource <> "/" <> id
        {acc ++ [{resource, new_path, false}], new_path}

      [resource], {acc, current_path} ->
        new_path = current_path <> "/" <> resource
        {acc ++ [{resource, new_path, false}], new_path}
    end)
    |> elem(0)
    |> List.update_at(-1, fn {resource, path, _} -> {resource, path, true} end)
  end

  defp format_label(label) do
    label
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
