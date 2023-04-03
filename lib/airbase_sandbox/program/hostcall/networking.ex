defmodule AirbaseSandbox.Program.Hostcall.Networking do
  @moduledoc """
  The Networking.
  """

  alias AirbaseSandbox.Program.Hostcall.Networking.Headers
  alias AirbaseSandbox.Program.Hostcall.Networking.Response

  @spec request(binary(), Keyword.t()) :: binary()
  def request(request_binary, opts \\ []) when is_binary(request_binary) do
    response =
      with(
        {:ok, request_params} <- Jason.decode(request_binary),
        {:ok, request} <- build_finch_request(request_params),
        {:ok, finch_response} <- Finch.request(request, JetSandboxFinch, opts)
      ) do
        Response.ok(finch_response)
      else
        {:error, exception} when is_exception(exception) ->
          Response.error(:bad_request, Exception.message(exception))

        {:error, response} ->
          response
      end

    Jason.encode!(response)
  end

  defp build_finch_request(params) when is_map(params) do
    with(
      {:ok, method} <- fetch_method(params),
      {:ok, url} <- fetch_url(params),
      {:ok, headers} <- get_headers(params),
      {:ok, body} <- get_body(params)
    ) do
      {:ok, Finch.build(method, url, headers, body, [])}
    end
  end

  defp build_finch_request(params) do
    {:error, Response.error(:invalid_json, "Expected a map json, got #{inspect(params)}")}
  end

  @atom_methods ~w[get post put patch delete head options]a

  defp fetch_method(params) do
    case Map.fetch(params, "method") do
      {:ok, method} ->
        with(:error <- build_method(method)) do
          {:error,
           Response.error(
             :invalid_parameter,
             "The method parameter is invalid, expected one of #{inspect(@atom_methods)}, but got #{inspect(method)}."
           )}
        end

      :error ->
        missing_parameter_error(:method)
    end
  end

  for method <- @atom_methods do
    str_method = Atom.to_string(method)
    upcase_str_method = String.upcase(str_method)

    defp build_method(unquote(str_method)), do: {:ok, unquote(method)}
    defp build_method(unquote(upcase_str_method)), do: {:ok, unquote(method)}
  end

  defp build_method(_term), do: :error

  defp fetch_url(params) do
    with(
      {:ok, url} <- Map.fetch(params, "url"),
      {:ok, uri} <- URI.new(url)
    ) do
      {:ok, uri}
    else
      :error ->
        missing_parameter_error(:url)

      {:error, part} ->
        {:error,
         Response.error(
           :invalid_parameter,
           "The url parameter is not a valid uri, the bad part is #{inspect(part)}."
         )}
    end
  end

  @spec get_headers(params :: map()) ::
          {:error, AirbaseSandbox.Program.Hostcall.Networking.Response.t()}
          | {:ok, [{binary, binary}]}
  def get_headers(params) do
    params
    |> Map.get("headers")
    |> case do
      nil ->
        {:ok, []}

      headers when is_list(headers) ->
        with(:error <- Headers.decode(headers)) do
          {:error, headers}
        end

      other ->
        {:error, other}
    end
    |> case do
      {:ok, headers} ->
        {:ok, headers}

      {:error, value} ->
        {:error,
         Response.error(
           :invalid_parameter,
           """
           The headers parameter is not valid, expected a nested array (eg: `[["Connection", "keep-alive"], ["Cache-Control", "no-cache"]]`), got #{inspect(value)}.
           """
         )}
    end
  end

  defp get_body(params) do
    case Map.get(params, "body") do
      nil ->
        {:ok, nil}

      body when is_binary(body) ->
        {:ok, body}

      other ->
        {:error,
         Response.error(
           :invalid_parameter,
           "The body parameter is expected to be a binary, got #{inspect(other)}."
         )}
    end
  end

  defp missing_parameter_error(parameter) do
    {:error,
     Response.error(
       :missing_parameter,
       "The #{to_string(parameter)} parameter is required."
     )}
  end
end
