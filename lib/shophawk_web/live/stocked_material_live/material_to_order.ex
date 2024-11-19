defmodule ShophawkWeb.StockedMaterialLive.MaterialToOrder do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  alias Shophawk.MaterialCache
  #import ShophawkWeb.StockedMaterialLive.Index

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-cyan-950 rounded-lg justify-center text-center text-white p-6">

      <div class="grid grid-cols-2">

        <div class="bg-cyan-800 rounded-lg mr-4 p-4">
          <div class="grid grid-cols-3 mt-2">
            <div></div>
            <div class="mb-4 text-2xl underline">Material To Order</div>
            <div><.button type="button" phx-click="set_all_to_waiting_on_quote">All -></.button></div>
          </div>
          <div class="grid grid-cols-4 text-lg underline">
            <div>Material</div>
            <div>Length Needed</div>
            <div>12 Month Usage</div>
            <div>Request sent</div>
          </div>
          <div :for={bar <- @bars_to_order_form}>
            <.form
              for={bar}
              id={"bar-#{bar.id}"}
            >
              <div class="grid grid-cols-4 p-1 place-items-center text-center text-lg bg-cyan-900 rounded-lg m-2">
                <div class="dark-tooltip-container">
                    <%= "#{bar.data.material}" %>
                    <!-- Loop through job assignments and display colored sections -->
                    <div class="relative h-full w-full">

                      <div class="tooltip ml-12 w-60" style="z-index: 12;">
                        <.fixed_widths_table_with_show_job
                        id="bar_assignments"
                        rows={Enum.reverse(bar.data.job_assignments)}
                        row_click={fn row_data -> "show_job" end}
                        >
                          <:col :let={bar} label="Job" width="w-20"><%= bar.job %></:col>
                          <:col :let={bar} label="Length" width="w-16"><%= bar.length_to_use %>"</:col>
                          <:col :let={bar} label="Parts" width="w-16"><%= bar.parts_from_bar %></:col>
                        </.fixed_widths_table_with_show_job>
                      </div>
                    </div>

                </div>
                  <%= "#{if bar.data.bar_length != nil, do: (Float.round((bar.data.bar_length / 12), 2)), else: 0} ft" %>
                <div>

                </div>
                <div class="px-2 text-center">
                  <.button type="button" phx-click="set_to_waiting_on_quote" phx-value-id={bar.data.id}>
                    ->
                  </.button>
                </div>
              </div>
            </.form>
          </div>
        </div>

        <div class="bg-cyan-800 rounded-lg ml-4 p-4">
          <div class="grid grid-cols-3 mt-2">
            <div></div>
            <div class="mb-4 text-2xl underline w-max">Material Wating on a Quote</div>
            <div><.button type="button" phx-click="set_all_to_material_to_recieve">Save All</.button></div>
          </div>
          <div class="grid grid-cols-5 text-lg underline">
            <div>Material</div>
            <div>Length Needed</div>
            <div>Vendor</div>
            <div>Price</div>
            <div>On Order</div>
          </div>
          <div :for={bar <- @bars_being_quoted_form}>
            <.form
              for={bar}
              id={"bar-#{bar.id}"}
              phx-change="validate_bar_waiting_on_quote"
              phx-submit="save_bar_waiting_on_quote"
            >
              <div class="grid grid-cols-5 p-1 place-items-center text-center text-lg bg-cyan-900 rounded-lg m-2">
                <div class="dark-tooltip-container">
                    <%= "#{bar.data.material}" %>
                    <!-- Loop through job assignments and display colored sections -->
                    <div class="relative h-full w-full">

                      <div class="tooltip ml-12 w-60" style="z-index: 12;">
                        <.fixed_widths_table_with_show_job
                        id="bar_assignments"
                        rows={Enum.reverse(bar.data.job_assignments)}
                        row_click={fn row_data -> "show_job" end}
                        >
                          <:col :let={bar} label="Job" width="w-20"><%= bar.job %></:col>
                          <:col :let={bar} label="Length" width="w-16"><%= bar.length_to_use %>"</:col>
                          <:col :let={bar} label="Parts" width="w-16"><%= bar.parts_from_bar %></:col>
                        </.fixed_widths_table_with_show_job>
                      </div>
                    </div>
                </div>

                <div>
                  <%= "#{if bar.data.bar_length != nil, do: (Float.round((bar.data.bar_length / 12), 2)), else: 0} ft" %>
                </div>

                <div class="mx-2">
                  <.input field={bar[:vendor]} type="text" phx-blur="autofill_vendor" phx-value-id={bar.data.id} />
                  <.input field={bar[:id]} type="hidden" />
                </div>

                <div class="mx-2">
                  <.input field={bar[:purchase_price]} type="number" step=".01" />
                </div>
                <div class="px-2 text-center">
                  <.button type="submit">
                      Save
                  </.button>
                </div>
              </div>
            </.form>
          </div>
        </div>

      </div>

    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    #IO.inspect(params)
    {:ok, update_material_forms(socket)}
  end

  def update_material_forms(socket) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    socket
    |> assign(bars_to_order_form: load_material_to_order(material_list))
    |> assign(bars_being_quoted_form: load_material_being_quoted(material_list))
    |> assign(bars_on_order_form: load_material_on_order(material_list))
  end

  def load_material_to_order(material_list) do
    material_to_order = Material.list_material_needed_to_order
    list_of_sizes =
      Enum.reduce(material_list, [], fn mat, acc ->
        [mat.sizes | acc]
      end)
      |> List.flatten

    material_with_assignments =
      Enum.map(material_to_order, fn mat ->
        found_assignments =
          Enum.find(list_of_sizes, fn size -> size.material_name == mat.material end).assigned_material_info
        Map.put(mat, :job_assignments, found_assignments)
      end)

    sorted_material_to_order =
      material_with_assignments
      |> Enum.map(fn material ->
      [size_str, material_name] =
        material.material
        |> String.split("X")
        |> Enum.map(&String.trim/1)

      size =
        case Float.parse(size_str) do
          {size, ""} -> size
          _ ->
            case Integer.parse(size_str) do
              {int_size, ""} -> int_size / 1
              _ -> 0.0
            end
        end

      {size, material_name, material}
      end)
      |> Enum.sort_by(fn {size, material_name, _} -> {material_name, size} end)
      |> Enum.map(fn {_, _, material} -> material end)

    bars_to_order_changeset = Enum.map(sorted_material_to_order, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
  end

  def load_material_being_quoted(material_list) do
    material_to_order = Material.list_material_being_quoted
    list_of_sizes =
      Enum.reduce(material_list, [], fn mat, acc ->
        [mat.sizes | acc]
      end)
      |> List.flatten

    material_with_assignments =
      Enum.map(material_to_order, fn mat ->
        found_assignments =
          Enum.find(list_of_sizes, fn size -> size.material_name == mat.material end).assigned_material_info
        Map.put(mat, :job_assignments, found_assignments)
      end)

    sorted_material_to_order =
      material_with_assignments
      |> Enum.map(fn material ->
      [size_str, material_name] =
        material.material
        |> String.split("X")
        |> Enum.map(&String.trim/1)

      size =
        case Float.parse(size_str) do
          {size, ""} -> size
          _ ->
            case Integer.parse(size_str) do
              {int_size, ""} -> int_size / 1
              _ -> 0.0
            end
        end

      {size, material_name, material}
      end)
      |> Enum.sort_by(fn {size, material_name, _} -> {material_name, size} end)
      |> Enum.map(fn {_, _, material} -> material end)

    bars_to_order_changeset = Enum.map(sorted_material_to_order, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
  end

  def load_material_on_order(material_list) do
    material_to_order = Material.list_material_on_order
    list_of_sizes =
      Enum.reduce(material_list, [], fn mat, acc ->
        [mat.sizes | acc]
      end)
      |> List.flatten

    material_with_assignments =
      Enum.map(material_to_order, fn mat ->
        found_assignments =
          Enum.find(list_of_sizes, fn size -> size.material_name == mat.material end).assigned_material_info
        Map.put(mat, :job_assignments, found_assignments)
      end)

    sorted_material_to_order =
      material_with_assignments
      |> Enum.map(fn material ->
      [size_str, material_name] =
        material.material
        |> String.split("X")
        |> Enum.map(&String.trim/1)

      size =
        case Float.parse(size_str) do
          {size, ""} -> size
          _ ->
            case Integer.parse(size_str) do
              {int_size, ""} -> int_size / 1
              _ -> 0.0
            end
        end

      {size, material_name, material}
      end)
      |> Enum.sort_by(fn {size, material_name, _} -> {material_name, size} end)
      |> Enum.map(fn {_, _, material} -> material end)

    bars_to_order_changeset = Enum.map(sorted_material_to_order, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
  end

  def handle_event("set_to_waiting_on_quote", %{"id" => id}, socket) do
    bar_struct = Material.get_stocked_material!(id)
    Material.update_stocked_material(bar_struct, %{being_quoted: true})

    MaterialCache.update_single_material_size_in_cache(bar_struct.material)
    {:noreply, update_material_forms(socket)}
  end

  def handle_event("set_all_to_waiting_on_quote", _params, socket) do
    bars = socket.assigns.bars_to_order_form
    Enum.each(bars, fn bar ->
      bar_struct = Material.get_stocked_material!(bar.data.id)
      Material.update_stocked_material(bar_struct, %{being_quoted: true})
    end)

    MaterialCache.update_single_material_size_in_cache(List.first(bars).data.material)
    {:noreply, update_material_forms(socket)}
  end

  def handle_event("set_all_to_material_to_recieve", params, socket) do
    Enum.each(socket.assigns.bars_being_quoted_form, fn bar ->
      case bar.source.valid? do
        true ->
          updated_params = Map.put(bar.params, "being_quoted", false) |> Map.put("ordered", true)
          Material.update_stocked_material(bar.data, updated_params, :waiting_on_quote)
        _ -> nil
      end
    end)
    {:noreply, update_material_forms(socket)}
  end

  def handle_event("save_bar_waiting_on_quote", params, socket) do
    params = params["stocked_material"]
    found_bar = Material.get_stocked_material!(params["id"])
    updated_params = Map.put(params, "being_quoted", false) |> Map.put("ordered", true)

    case Material.update_stocked_material(found_bar, updated_params, :waiting_on_quote) do
      {:ok, stocked_material} ->
        {:noreply, update_material_forms(socket)}

      {:error, changeset} ->
        bars = socket.assigns.bars_being_quoted_form
        updated_bars =
          Enum.map(bars, fn bar ->
            if bar.data.id == found_bar.id do
              #Map.put(bar, :errors, changeset.errors)
              #|> Map.put(:action, :validate)
              changeset =
                Material.change_stocked_material(found_bar, params, :waiting_on_quote)
                |> Map.put(:action, :validate)

              to_form(changeset)
            else
              bar
            end
          end)

        {:noreply, assign(socket, bars_being_quoted_form: updated_bars)}
    end

  end

  def handle_event("validate_bar_waiting_on_quote", %{"stocked_material" => params}, socket) do
    {:noreply, validate_bar_waiting_on_quote(params, socket)}
  end

  def handle_event("autofill_vendor", params, socket) do
    vendor_list =
      %{
        "as" => "Alro Steel",
        "ap" => "Alro Plastics",
        "c" => "Castle",
        "d" => "Durabar"
      }

    updated_value =
      case Enum.find(vendor_list, fn {key, value} -> key == params["value"] end) do
        {_key, value} -> value
        nil -> params["value"]
      end

      params = Map.put(params, "vendor", updated_value)

    {:noreply, validate_bar_waiting_on_quote(params, socket)}
  end

  def validate_bar_waiting_on_quote(params, socket) do
    bars = socket.assigns.bars_being_quoted_form
    # Determine the form being updated by matching the `id` hidden field
    form_id = Map.get(params, "id")

    updated_bars =
      Enum.map(bars, fn bar ->
        if Integer.to_string(bar.data.id) == form_id do
          changeset =
            Material.change_stocked_material(bar.data, params, :waiting_on_quote)
            |> Map.put(:action, :validate)

          to_form(changeset)
        else
          bar
        end
      end)
      assign(socket, :bars_being_quoted_form, updated_bars)
  end

end
