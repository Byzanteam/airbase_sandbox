defmodule AirbaseSandbox.Program.Hostcall.Networking.Response do
  @moduledoc """
  The response struct for Networking.
  """

  @statuses [
    {:ok, 0},
    {:invalid_json, 1},
    {:missing_parameter, 2},
    {:invalid_parameter, 3},
    {:bad_request, 4}
  ]

  @status_atoms Keyword.keys(@statuses)

  @type status() :: unquote(JetExt.Types.make_sum_type(@status_atoms))

  use TypedStruct

  typedstruct do
    field :status, status(), enforce: true
    field :error_message, String.t()
    field :response, Finch.Response.t()
  end

  @spec status(integer()) :: status()
  @spec code(status()) :: integer()

  for {status, code} <- @statuses do
    def status(unquote(code)), do: unquote(status)

    def code(unquote(status)), do: unquote(code)
  end

  @spec ok(Finch.Response.t()) :: t()
  def ok(response) when is_struct(response, Finch.Response) do
    %__MODULE__{status: :ok, response: response}
  end

  @spec error(status(), String.t()) :: t()
  def error(status, error_message \\ "") when status in @status_atoms do
    %__MODULE__{status: status, error_message: error_message}
  end

  defimpl Jason.Encoder do
    alias AirbaseSandbox.Program.Hostcall.Networking.Headers

    # credo:disable-for-next-line Credo.Check.Readability.Specs
    def encode(%{status: :ok, response: response}, opts) do
      response = %{
        status: response.status,
        headers: Headers.encode!(response.headers),
        body: response.body
      }

      Jason.Encode.map(
        %{
          code: @for.code(:ok),
          response: response
        },
        opts
      )
    end

    # credo:disable-for-next-line Credo.Check.Readability.Specs
    def encode(%{status: status, error_message: error_message}, opts) do
      Jason.Encode.map(
        %{
          code: @for.code(status),
          message: error_message
        },
        opts
      )
    end
  end
end
