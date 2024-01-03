defmodule ShophawkWeb.RunlistLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shop
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop.Department
  alias Shophawk.Shop.Csvimport

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
      department_id: nil
      )
    socket = stream(socket, :runlists, [])
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do

        departments = ["Select a department" | Shop.list_departments() |> Enum.map(&(&1.department)) |> Enum.sort]
        IO.inspect(departments)
        socket
        |> assign(:page_title, "Listing Runlists")
        |> assign(:runlist, nil)
        |> assign(:departments, departments)
      end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Runlist")
    |> assign(:runlist, Shop.get_runlist!(id))
  end

#  defp apply_action(socket, :new, _params) do
#    socket
#    |> assign(:page_title, "New Runlist")
#    |> assign(:runlist, %Runlist{})
#  end

  defp apply_action(socket, :edit_department, %{"id" => id}) do
    Csvimport.update_workcenters()
    socket
    |> assign(:page_title, "Edit Department")
    |> assign(:department, Shop.get_department!(id))
  end

  defp apply_action(socket, :new_department, _params) do
    Csvimport.update_workcenters()

    socket
    |> assign(:page_title, "New Department")
    |> assign(:department, %Department{})
    |> assign(:workcenters, Shop.list_workcenters())
  end



  #@impl true
  #def handle_info({ShophawkWeb.RunlistLive.FormComponent, {:saved, runlist}}, socket) do
  #  {:noreply, stream_insert(socket, :runlists, runlist)}
  #end

  @impl true
  def handle_info({ShophawkWeb.DepartmentLive.FormComponent, {:saved, department}}, socket) do
    #{:noreply, stream_insert(socket, :departments, department)}
    department_list =
      Shop.list_departments()
      |> Enum.map(&(&1.department))
    IO.inspect(department_list)

    {:noreply, socket}
  end

#  @impl true
#  def handle_event("delete", %{"id" => id}, socket) do
#    runlist = Shop.get_runlist!(id)
#    {:ok, _} = Shop.delete_runlist(runlist)
#
#    {:noreply, stream_delete(socket, :runlists, runlist)}
#  end

  def handle_event("select_department", %{"my-input" => department}, socket) do
    IO.inspect(department)
    department_id =
      case department do
        "Select a department" -> nil
        _ -> Shop.get_department_by_name(department)
      end


      socket = assign(socket, department_id: department_id)


    {:noreply, socket}
  end

  def handle_event("importall", _, socket) do
    tempjobs = Csvimport.import_operations()
    count = Enum.count(tempjobs)
    IO.puts(count)
    socket

    {:noreply, stream(socket, :runlists, [])}
    #{:noreply, stream(socket, :runlists, Shop.list_runlists())}
  end



  def handle_event("5_minute_import", _, socket) do
    Csvimport.update_operations()
    #IO.puts(Enum.count(tempjobs))
    socket

    {:noreply, stream(socket, :runlists, [])}
    #{:noreply, stream(socket, :runlists, Shop.list_runlists())}
  end

end
