defmodule ExcisionWeb.Live.DecisionSiteLive.QuickstartModal do
  use Phoenix.Component

  def component(assigns) do
    assigns = assign(assigns, :base_uri, compute_base_uri(assigns.current_uri))

    ~H"""
    <h2 class="text-2xl font-bold mb-4 text-gray-800">Your Decision Site is Ready!</h2>
    <p class="text-gray-600 mb-6">
      You're all set to start making informed decisions using our powerful platform. Here's a quick guide to get you started:
    </p>

    <h3 class="text-lg font-semibold mb-2 text-gray-700">1. Use the API to Submit Data</h3>
    <p class="text-gray-600 mb-4">
      Use our API to send your data directly to the decision engine. Here’s a simple example:
    </p>

    <div class="bg-gray-100 p-4 rounded-md mb-6">
      <ExcisionWeb.Components.CopyButtonComponent.copy_button target_id="quickstart-code-sample">
        <pre class="text-sm text-gray-800 whitespace-pre-wrap">
          <code id={"quickstart-code-sample"}>
    import json
    import os

    import requests

    url = '<%= @base_uri %>/api/decision_sites/<%= @decision_site.id %>/invoke'
    headers = {'Authorization': f'Bearer {os.environ.get("OPENAI_API_KEY")}'}
    data = {
      "messages": [
        {
          "role": "user",
          "content": "Is this transaction fraudulent? user_age=15, purchase=yacht"
        }
      ],
      "model": "gpt-4o-mini",
      "response_format": {
        "type": "json_schema",
        "json_schema": {
          "name": "Decision",
          "schema": {
            "type": "object",
            "properties": {
              "value": {
                "enum": <%= inspect(@decision_site.choices |> Enum.map(& &1.name)) %>
              }
            },
          }
        }
      }
    }

    response = requests.post(url, json=data, headers=headers)

    if response.status_code == 200:
        decision = json.loads((response.json())['choices'][0]['message']['content'])['value']
        print(f"Decision: {decision}")
    else:
        print(f"Error: {response.status_code}")
        </code>
        </pre>
      </ExcisionWeb.Components.CopyButtonComponent.copy_button>
    </div>

    <h3 class="text-lg font-semibold mb-2 text-gray-700">2. Review the API Documentation</h3>
    <p class="text-gray-600 mb-4">
      For more detailed information on how to use our APIs, check out the <a
        href="https://github.com/fmops/decisionbox/wiki"
        class="text-slate-600 hover:text-slate-700 underline"
      >API documentation</a>.
    </p>

    <h3 class="text-lg font-semibold mb-2 text-gray-700">3. Monitor Decisions</h3>
    <p class="text-gray-600 mb-6">
      Stay informed on decision outcomes by visiting the <strong>Decision Dashboard</strong>
      where you can review analytics and insights.
    </p>

    <div class="text-center">
      <button
        class="bg-slate-600 text-white px-4 py-2 rounded-lg hover:bg-slate-700"
        phx-click={@handle_dismiss}
      >
        OK
      </button>
    </div>
    """
  end

  defp compute_base_uri(uri) do
    %{scheme: scheme, host: host, port: port} = URI.parse(uri)
    "#{scheme}://#{host}#{if port, do: ":#{port}", else: ""}"
  end
end
