defmodule ShophawkWeb.RunlistLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shop
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop.Department
  alias Shophawk.Shop.Csvimport
  alias Shophawk.Shop.Assignment

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, socket |> assign(department_id: nil) |> assign(workcenter_id: nil) |> stream(:runlists, []) |> assign(:department, %{}) |> assign(:department_name, "") |> assign(:department_loads, get_runlist_loads()) |> assign(show_runlist_table: false) |> assign(show_workcenter_table: false) |> assign(show_department_loads: true) |> assign(updated: 0)}
    else
     {:ok, socket |> assign(department_id: nil) |> assign(workcenter_id: nil) |> stream(:runlists, []) |> assign(:department, %{}) |> assign(:department_name, "") |> assign(:department_loads, nil) |> assign(show_runlist_table: false) |> assign(show_workcenter_table: false) |> assign(show_department_loads: false)|> assign(updated: 0)}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:departments,  ["Select Department" | Shop.list_departments() |> Enum.map(&(&1.department)) |> Enum.sort])
      |> assign(:workcenters, ["Select Workcenter" | Shop.list_workcenters() |> Enum.map(&(&1.workcenter)) |> Enum.sort])
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def get_runlist_loads() do
    [data: data] = :ets.lookup(:runlist_loads, :data)
    data
  end

  defp apply_action(socket, :index, _params) do
    cond do
      socket.assigns.department_id != nil ->
        socket
        |> assign(:page_title, "Listing Runlists")
      socket.assigns.workcenter_id != nil ->
        socket
        |> assign(:page_title, "Listing Runlists")
      true ->
        socket
        |> assign(:page_title, "Listing Runlists")
        |> assign(:runlist, nil)
        |> load_runlist(socket.assigns.department_id)
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Runlist")
    |> assign(:runlist, Shop.get_runlist!(id))
  end

  defp apply_action(socket, :edit_department, _) do
    Csvimport.update_workcenters()
    socket =
      socket
      |> assign(:page_title, "Edit Department")
  end

  defp apply_action(socket, :new_department, _) do
    Csvimport.update_workcenters()
    socket =
        socket
      |> assign(:page_title, "New Department")
      |> assign(:department, %Department{})
  end

  defp apply_action(socket, :new_assignment, _) do
    socket =
      socket
      |> assign(:page_title, "New Assignment")
      |> assign(:assignment, %Assignment{})
  end

  defp apply_action(socket, :assignments, %{"id" => id}) do
      socket
      |> assign(:page_title, "View Assignments")
      |> load_runlist(id)
  end

  #@impl true
  #def handle_info({ShophawkWeb.RunlistLive.FormComponent, {:saved, runlist}}, socket) do
  #  {:noreply, stream_insert(socket, :runlists, runlist)}
  #end

  @impl true
  def handle_info({ShophawkWeb.RunlistLive.DepartmentForm, {:saved, department}}, socket) do
    socket = load_runlist(socket, Shop.get_department_by_name(department.department).id)



    {:noreply, apply_action(socket, :index, nil)}
  end

  def handle_info({ShophawkWeb.RunlistLive.DepartmentForm, {:destroyed, department}}, socket) do
    {:noreply, socket}
  end

  def handle_info({ShophawkWeb.RunlistLive.AssignmentForm, {:saved, assignment}}, socket) do
    socket =
      case socket.assigns.department_id do
        nil -> socket
        _ -> load_runlist(socket, socket.assigns.department_id)
      end
    {:noreply, socket}
  end

  def handle_info({ShophawkWeb.RunlistLive.ViewAssignments, {:delete}}, socket) do
    {:noreply, socket}
  end

  def handle_event("select_department", %{"selection" => department}, socket) do
    case department do
      "Select Department" ->
        #IO.inspect(get_runlist_loads())
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          socket =
            socket
            |> assign(department_id: nil)
            |> assign(show_runlist_table: false)
            |> assign(show_workcenter_table: false)
            |> assign(show_department_loads: true)
            |> assign(department_loads: get_runlist_loads())
            |> stream(:runlists, [], reset: true)
          Process.send(process, {:send_runlist, socket}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
      _ ->
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          Process.send(process, {:send_runlist, load_runlist(socket, Shop.get_department_by_name(department).id)}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
    end
  end

  def handle_event("select_workcenter", %{"choice" => workcenter}, socket) do
    case workcenter do
      "Select Workcenter" ->
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          socket =
            socket
            |> assign(workcenter_id_id: nil)
            |> assign(show_runlist_table: false)
            |> assign(show_workcenter_table: false)
            |> assign(show_department_loads: true)
            |> assign(department_loads: get_runlist_loads())
            |> stream(:runlists, [], reset: true)
          Process.send(process, {:send_runlist, socket}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
      _ ->
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          Process.send(process, {:send_runlist, load_workcenter(socket, Shop.get_workcenter_by_name(workcenter))}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
    end
  end

  defp operation_alteration(operation) do
    new_value =
      if operation == "NULL" do
        ""
      else
        operation
      end
  end

  def handle_event("color_key", _, socket) do
    {:noreply, assign(socket, :live_action, :color_key)}
  end

  def handle_event("mat_waiting_toggle", %{"id" => id}, socket) do
    Shop.toggle_mat_waiting(id)
    {:noreply, socket}
  end

  def handle_event("change_assignment", %{"id" => id, "selection" => selection } = params, socket) do
    Shop.update_runlist(Shop.get_runlist!(id), %{assignment: selection})
    {:noreply, socket}
  end

  def handle_event("assignments_name_change", %{"target" => assignment}, socket) do
    {:noreply, socket}
  end

  def handle_event("show_job", %{"job" => job}, socket) do

    {job_ops, job_info} = Shop.list_job(job)
    socket =
      socket
      |> assign(id: job)
      |> assign(page_title: "Job #{job}")
      |> assign(:live_action, :show_job)
      |> assign(:job_ops, job_ops) #Load job data here and send as a list of ops in order
      |> assign(:job_info, job_info)

      #IO.inspect(socket)

    {:noreply, socket}
  end

  def handle_event("importall", _, socket) do
    Csvimport.import_all_history
    socket
    {:noreply, stream(socket, :runlists, [])}
  end

  def handle_event("time_based_import", _, socket) do
    Csvimport.update_operations(nil, 0)
    {:noreply, stream(socket, :runlists, [])}
  end

  def handle_event("rework_to_do", _, socket) do
    Csvimport.rework_to_do()
  {:noreply, socket}
  end

  defp load_runlist(socket, department_id) do
    socket =
      case department_id do
        nil ->
            socket
            |> assign(department_id: nil)
            |> stream(:runlists, [], reset: true)

        _ ->
        department = Shop.get_department!(department_id)
        workcenter_list = for %Shophawk.Shop.Workcenter{workcenter: wc} <- department.workcenters, do: wc
        {runlist, weekly_load} = Shop.list_runlists(workcenter_list, department)
        if runlist != [] do
          assignment_list = for %Shophawk.Shop.Assignment{assignment: a} <- department.assignments, do: a
          started_assignment_list =
            Enum.filter(runlist, fn op ->
              if Map.has_key?(op, :assignment) do
                op.assignment != "" and op.assignment != nil and not Enum.member?(assignment_list, op.assignment)
              else
                false
              end
            end)
            |> Enum.map(fn op -> op.assignment end)
            |> Enum.uniq

          dots =
            runlist
            |> Enum.reject(fn %{id: id} -> id == 0 end)
            |> Enum.reduce(%{}, fn row, acc ->
              case row.dots do
                1 -> Map.put_new(acc, :one, "bg-cyan-500 text-stone-950")  |> Map.update(:ops, [row], fn list -> list ++ [row] end)
                2 -> Map.put_new(acc, :two, "bg-amber-500 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
                3 -> Map.put_new(acc, :three, "bg-red-600 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
                _ -> acc
              end
            end)
          dots = case Map.size(dots) do
            2 -> Map.put_new(dots, :dot_columns, "grid-cols-1")
            3 -> Map.put_new(dots, :dot_columns, "grid-cols-2")
            4 -> Map.put_new(dots, :dot_columns, "grid-cols-3")
            _ -> dots
          end
          dots =
            if dots[:ops] != nil do
              unique_ops_list =
                Enum.reduce(dots[:ops], %{}, fn runlist, acc ->
                  if Map.has_key?(acc, runlist.job) do
                    acc
                  else
                    Map.put(acc, runlist.job, runlist)
                  end
                end)
                |> Map.values
                |> Enum.reverse
              dots = Map.put(dots, :ops, unique_ops_list)
            else
              dots
            end
          socket =
            socket
            |> assign(show_runlist_table: true)
            |> assign(show_workcenter_table: false)
            |> assign(show_department_loads: false)
            |> assign(dots: dots)
            |> assign(name: department.department)
            |> assign(department: department)
            |> assign(department_id: department.id)
            |> assign(workcenter_id: nil)
            |> assign(assignments: [""] ++ assignment_list ++ started_assignment_list)
            |> assign(saved_assignments: assignment_list)
            |> assign(started_assignment_list: started_assignment_list)
            |> assign(weekly_load: weekly_load)
            |> stream(:runlists, runlist, reset: true)
        else
          socket
          |> assign(show_runlist_table: false)
          |> assign(show_workcenter_table: false)
          |> assign(show_department_loads: false)
          |> assign(dots: %{dot_columns: ""})
          |> assign(name: department.department)
          |> assign(department: department)
          |> assign(department_id: department.id)
          |> assign(workcenter_id: nil)
          |> assign(assignments: [""] )
          |> assign(saved_assignments: [])
          |> assign(started_assignment_list: [])
          |> assign(weekly_load: [])
          |> stream(:runlists, [], reset: true)
        end
      end
  end

  defp load_workcenter(socket, workcenter) do
    workcenter_name = workcenter.workcenter
    socket =
      case workcenter do
        nil ->
            socket
            |> assign(department_id: nil)
            |> stream(:runlists, [], reset: true)

        _ ->
        runlist = Shop.list_workcenter(workcenter_name)
        if runlist != [] do
          started_assignment_list =
            Enum.filter(runlist, fn op ->
              if Map.has_key?(op, :assignment) do
                op.assignment != "" and op.assignment != nil
              else
                false
              end
            end)
            |> Enum.map(fn op -> op.assignment end)
            |> Enum.uniq

          dots =
            runlist
            |> Enum.reject(fn %{id: id} -> id == 0 end)
            |> Enum.reduce(%{}, fn row, acc ->
              case row.dots do
                1 -> Map.put_new(acc, :one, "bg-cyan-500 text-stone-950")  |> Map.update(:ops, [row], fn list -> list ++ [row] end)
                2 -> Map.put_new(acc, :two, "bg-amber-500 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
                3 -> Map.put_new(acc, :three, "bg-red-600 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
                _ -> acc
              end
            end)
          dots = case Map.size(dots) do
            2 -> Map.put_new(dots, :dot_columns, "grid-cols-1")
            3 -> Map.put_new(dots, :dot_columns, "grid-cols-2")
            4 -> Map.put_new(dots, :dot_columns, "grid-cols-3")
            _ -> dots
          end
          dots =
            if dots[:ops] != nil do
              unique_ops_list =
                Enum.reduce(dots[:ops], %{}, fn runlist, acc ->
                  if Map.has_key?(acc, runlist.job) do
                    acc
                  else
                    Map.put(acc, runlist.job, runlist)
                  end
                end)
                |> Map.values
                |> Enum.reverse
              dots = Map.put(dots, :ops, unique_ops_list)
            else
              dots
            end
          socket =
            socket
            |> assign(show_runlist_table: false)
            |> assign(show_workcenter_table: true)
            |> assign(show_department_loads: false)
            |> assign(dots: dots)
            |> assign(name: workcenter.workcenter)
            |> assign(department: workcenter)
            |> assign(department_id: nil)
            |> assign(workcenter_id: workcenter.id)
            |> assign(assignments: [""] ++ started_assignment_list)
            |> assign(saved_assignments: [])
            |> assign(started_assignment_list: started_assignment_list)
            |> assign(weekly_load: nil)
            |> stream(:runlists, runlist, reset: true)
        else
          socket
          |> assign(show_runlist_table: false)
          |> assign(show_workcenter_table: false)
          |> assign(show_department_loads: false)
          |> assign(dots: %{dot_columns: ""})
          |> assign(name: workcenter.workcenter)
          |> assign(department: workcenter)
          |> assign(department_id: nil)
          |> assign(workcenter_id: workcenter.id)
          |> assign(assignments: [""])
          |> assign(saved_assignments: [])
          |> assign(started_assignment_list: [])
          |> assign(weekly_load: nil)
          |> stream(:runlists, [], reset: true)
        end
      end
  end

  def handle_event("refresh_department", _, socket) do
    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      :timer.sleep(300)
      Process.send(process, {:send_runlist, load_runlist(socket, socket.assigns.department_id)}, [])
    end)
    update_number = socket.assigns.updated + 1
    {:noreply, assign(socket, :updated, update_number) |> assign(department_loads: nil)}
  end

  def handle_event("refresh_workcenter", _, socket) do
    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      :timer.sleep(300)
      Process.send(process, {:send_runlist, load_workcenter(socket, Shop.get_workcenter_by_name(socket.assigns.name))}, [])
    end)
    update_number = socket.assigns.updated + 1
    {:noreply, assign(socket, :updated, update_number) |> assign(department_loads: nil)}
  end

  def handle_info({:send_runlist, updated_socket}, socket) do
    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      Process.send_after(process, :clear_updated, 0)
    end)
    {:noreply, updated_socket}
  end

  def handle_info(:clear_updated, socket) do
    update_number = socket.assigns.updated + 2
    {:noreply, assign(socket, :updated, update_number)}
  end

  def calculate_color(load) do
    cond do
      load < 90 -> "bg-stone-300"
      load >= 90 and load < 100 -> "bg-amber-300"
      load >= 100 -> "bg-red-500"
    end
  end

end
