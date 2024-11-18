defmodule ExcisionWeb.Live.ClassifierLive.HelpModal do
  use Phoenix.Component

  def component(assigns) do
    ~H"""
    <h2 class="text-2xl font-bold mb-4 text-gray-800">Interpreting Classifier Performance</h2>

    <section>
      <h3 class="text-lg font-semibold mb-2 text-gray-700">Accuracy Trends</h3>

      <div class="space-y-4 text-gray-600">
        <div>
          <h4 class="font-medium">Rising Accuracy</h4>
          <ul class="list-disc pl-5 space-y-1">
            <li>Positive Sign: Model is learning effectively</li>
            <li>
              Watch for: Potential overfitting if validation accuracy decreases while training accuracy rises
            </li>
          </ul>
        </div>

        <div>
          <h4 class="font-medium">Plateauing Accuracy</h4>
          <ul class="list-disc pl-5 space-y-1">
            <li>If early: Learning rate may be too low</li>
            <li>If late: Model may have reached optimal performance</li>
            <li>Try increasing learning rate or model complexity</li>
          </ul>
        </div>
      </div>
    </section>

    <section>
      <h3 class="text-lg font-semibold mb-2 text-gray-700">Loss Patterns</h3>

      <div class="space-y-4 text-gray-600">
        <div>
          <h4 class="font-medium">Rising Loss</h4>
          <ul class="list-disc pl-5 space-y-1">
            <li>Sudden spikes: Learning rate too high</li>
            <li>Gradual increase: Possible overfitting</li>
            <li>Action: Lower learning rate or add regularization</li>
          </ul>
        </div>

        <div>
          <h4 class="font-medium">Flat Loss</h4>
          <ul class="list-disc pl-5 space-y-1">
            <li>From start: Learning rate too low</li>
            <li>After progress: Model may have converged</li>
            <li>Try increasing learning rate or adjusting architecture</li>
          </ul>
        </div>
      </div>
    </section>

    <section>
      <h3 class="text-lg font-semibold mb-2 text-gray-700">Common Issues</h3>

      <div class="space-y-4 text-gray-600">
        <div>
          <h4 class="font-medium">Overfitting Signs</h4>
          <ul class="list-disc pl-5 space-y-1">
            <li>High training accuracy, low validation accuracy</li>
            <li>Solutions: Add dropout, increase regularization, collect more data</li>
          </ul>
        </div>

        <div>
          <h4 class="font-medium">Underfitting Signs</h4>
          <ul class="list-disc pl-5 space-y-1">
            <li>Both accuracies are low</li>
            <li>Solutions: Increase model complexity, reduce regularization, train longer</li>
          </ul>
        </div>
      </div>
    </section>

    <div class="text-center mt-6">
      <button
        class="bg-slate-600 text-white px-4 py-2 rounded-lg hover:bg-slate-700"
        phx-click={@handle_dismiss}
      >
        OK
      </button>
    </div>
    """
  end
end
