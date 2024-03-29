defmodule Api do
  defmodule Endpoint do
    import Plug.Conn

    @symbol "symbol"
    @interval "interval"

    def init(options) do
      options
    end

    def set_content_type(conn) do
      content_type =
        try do
          conn.path_info
          |> List.last()
          |> String.split(".")
          |> List.last()
          |> case do
            "html" ->
              "text/html"

            "css" ->
              "text/css"

            "js" ->
              "text/javascript"

            "prices" ->
              "application/json"

            _ ->
              "text/plain"
          end
        rescue
          FunctionClauseError ->
            "text/plain"
        end

      put_resp_content_type(conn, content_type)
    end

    def route(conn) do
      path_info =
        case conn.path_info do
          [] -> ["index.html"]
          _ -> conn.path_info
        end

      %Plug.Conn{
        conn
        | path_info: path_info
      }
    end

    def render(conn) do
      conn = Plug.Conn.fetch_query_params(conn)

      case conn.path_info do
        ["prices"] ->
          %{@symbol => symbol, @interval => interval} = conn.params

          Algo.run(symbol, interval)
          |> Jason.encode!()

        _ ->
          render_file(conn)
      end
    end

    def render_file(conn) do
      file =
        conn.path_info
        |> (&["web" | &1]).()
        |> Path.join()
        |> File.read()
        |> case do
          {:ok, file} -> file
          {:error, reason} -> :file.format_error(reason)
        end

      file
    end

    def call(conn, _opts) do
      try do
        case conn.request_path do
          _ ->
            conn
            |> route
            |> set_content_type
            |> render
            |> (&send_resp(conn, 200, &1)).()
        end
      rescue
        FunctionClauseError -> send_resp(conn, 404, "Not found")
      end
    end
  end
end
