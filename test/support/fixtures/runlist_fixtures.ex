defmodule Shophawk.RunlistFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shophawk.Runlist` context.
  """

  @doc """
  Generate a operation.
  """
  def operation_fixture(attrs \\ %{}) do
    {:ok, operation} =
      attrs
      |> Enum.into(%{
        complete_operations: 42,
        currentop: "some currentop",
        customer: "some customer",
        customer_po: "some customer_po",
        customer_po_line: 42,
        description: "some description",
        dots: 42,
        employee: "some employee",
        est_total_hrs: 42,
        extra_quantity: 42,
        job: "some job",
        job_operation: 42,
        job_sched_end: ~D[2023-11-12],
        job_sched_start: ~D[2023-11-12],
        make_quantity: 42,
        mat_description: "some mat_description",
        mat_vendor: "some mat_vendor",
        material: "some material",
        material_waiting: true,
        note_text: "some note_text",
        open_operations: 42,
        operation_service: "some operation_service",
        order_date: ~D[2023-11-12],
        order_quantity: 42,
        part_number: "some part_number",
        pick_quantity: 42,
        released_date: ~D[2023-11-12],
        rev: "some rev",
        sched_end: ~D[2023-11-12],
        sched_start: ~D[2023-11-12],
        sequence: 42,
        shipped_quantity: 42,
        status: "some status",
        vendor: "some vendor",
        wc_vendor: "some wc_vendor"
      })

    operation
  end
end
