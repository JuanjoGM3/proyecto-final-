defmodule Jason.Sigil do

  defmacro sigil_j(term, modifiers)

  defmacro sigil_j({:<<>>, _meta, [string]}, modifiers) when is_binary(string) do
    Macro.escape(Jason.decode!(string, mods_to_opts(modifiers)))
  end

  defmacro sigil_j(term, modifiers) do
    quote(do: Jason.decode!(unquote(term), unquote(mods_to_opts(modifiers))))
  end

  defmacro sigil_J(term, modifiers)

  defmacro sigil_J({:<<>>, _meta, [string]}, modifiers) when is_binary(string) do
    Macro.escape(Jason.decode!(string, mods_to_opts(modifiers)))
  end

  @spec mods_to_opts(charlist) :: [Jason.decode_opt()]
  defp mods_to_opts(modifiers) do
    modifiers
    |> Enum.map(fn
      ?a -> {:keys, :atoms}
      ?A -> {:keys, :atoms!}
      ?r -> {:strings, :reference}
      ?c -> {:strings, :copy}
      m -> raise ArgumentError, "unknown sigil modifier #{<<?", m, ?">>}"
    end)
  end
end
