defmodule ShophawkWeb.DashboardLive.Index do
  use ShophawkWeb, :live_view
  alias Shophawk.Jobboss_db
  import Number.Currency
  alias ShophawkWeb.CheckbookComponent
  alias ShophawkWeb.InvoicesComponent
  alias ShophawkWeb.RevenueComponent

  @impl true
  def mount(_params, _session, socket) do
      {:ok, socket
      |> assign(:checkbook_entries, [])
      |> assign(:current_balance, "Loading...")
      |> assign(:open_invoices, %{})
      |> assign(:selected_range, "")
      |>assign(:open_invoice_values, [])
      }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    #Process.send(self(), :load_data, [:noconnect])
    socket
    |> assign(:page_title, "Dashboard")
  end

  def handle_info(:load_data, socket) do
    {:noreply,
      socket
      |> load_checkbook()
      |> get_open_invoices()
    }
  end

  def load_checkbook(socket) do
    bank_statements =
      Jobboss_db.bank_statements
      |> Enum.reverse

    last_statement = List.first(bank_statements)
    ending_balance = last_statement.ending_balance


    {:ok, days_to_load} = NaiveDateTime.new(Date.add(last_statement.statement_date, -30), ~T[00:00:00.000])

    checkbook_entries = #journal entries from 30 days before last bank statement
      Jobboss_db.journal_entry(days_to_load, NaiveDateTime.utc_now())
      |> Enum.map(fn entry -> if entry.reference == "9999", do: Map.put(entry, :reference, "9999 - ACH Check"), else: entry end)
      |> Enum.reverse

    current_balance =
      Enum.filter(checkbook_entries, fn entry -> Date.after?(entry.transaction_date, last_statement.statement_date) end)
      |> Enum.reduce(ending_balance, fn entry, acc ->
        acc + entry.amount
      end)
      |> Float.round(2)
      |> number_to_currency

      socket
      |> assign(:current_balance, current_balance)
      |> assign(:checkbook_entries, checkbook_entries)
  end

  def get_open_invoices(socket) do
    open_invoices = Jobboss_db.open_invoices

    open_invoice_values = Enum.reduce(open_invoices, %{zero_to_thirty: 0, thirty_to_sixty: 0, sixty_to_ninety: 0, ninety_plus: 0, late: 0, all: 0}, fn inv, acc ->
        days_open = Date.diff(Date.utc_today(), inv.document_date)
        acc = cond do
          days_open > 0 and days_open <= 30 -> Map.put(acc, :zero_to_thirty, acc.zero_to_thirty + inv.open_invoice_amount)
          days_open > 30 and days_open <= 60 -> Map.put(acc, :thirty_to_sixty, acc.thirty_to_sixty + inv.open_invoice_amount)
          days_open > 60 and days_open <= 90 -> Map.put(acc, :sixty_to_ninety, acc.sixty_to_ninety + inv.open_invoice_amount)
          days_open > 90 -> Map.put(acc, :ninety_plus, acc.ninety_plus + inv.open_invoice_amount)
          true -> acc
        end
        acc = if inv.late == true, do: Map.put(acc, :late, acc.late + inv.open_invoice_amount), else: acc
        acc = Map.put(acc, :all, acc.all + inv.open_invoice_amount)

      end)

    socket =
      assign(socket, :open_invoices, open_invoices)
      |> assign(:open_invoice_storage, open_invoices) #used when changing range of invoices viewed
      |> assign(:open_invoice_values, open_invoice_values)
  end

  def handle_event("test_click", _params, socket) do
    jobs = Jobboss_db.active_jobs_with_cost()
    job_numbers = Enum.map(jobs, fn job -> job.job end)
    deliveries = Jobboss_db.load_deliveries(job_numbers)
    merged_deliveries = Enum.reduce(deliveries, [], fn d, acc ->
      job = Enum.find(jobs, fn job -> job.job == d.job end)
      acc ++ [Map.merge(d, job)]
    end)
    total_amount_due = Enum.reduce(merged_deliveries, 0, fn d, acc -> (d.promised_quantity * d.unit_price) + acc end)
    six_weeks_due = Enum.filter(merged_deliveries, fn d -> Date.before?(d.promised_date, Date.add(Date.utc_today(), 42)) end)
    six_weeks_amount_due = Enum.reduce(six_weeks_due, 0, fn d, acc -> (d.promised_quantity * d.unit_price) + acc end)

    IO.inspect(Enum.count(jobs))
    IO.inspect(Enum.count(six_weeks_due))
    IO.inspect(List.first(six_weeks_due))
    IO.inspect(six_weeks_amount_due)
    IO.inspect(total_amount_due)


    {:noreply, socket}
  end

  def handle_event("load_invoice_late_range", %{"range" => range}, socket) do
    open_invoices = socket.assigns.open_invoice_storage
    ranged_open_invoices =
      Enum.filter(open_invoices, fn inv ->
        case range do
          "0-30" -> inv.days_open > 0 and inv.days_open <= 30
          "31-60" -> inv.days_open > 30 and inv.days_open <= 60
          "61-90" -> inv.days_open > 60 and inv.days_open <= 90
          "90+" -> inv.days_open > 90
          "late" -> inv.late == true
          "all" -> true
          _ -> false
        end
      end)
    {:noreply, assign(socket, :open_invoices, ranged_open_invoices) |> assign(:selected_range, range)}
  end

end
