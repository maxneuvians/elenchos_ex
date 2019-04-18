defmodule ElenchosEx.Repository do

  @code_dir Application.get_env(:elenchos_ex, :code_dir, "/tmp")

  def checkout(%{full_name: full_name, sha: sha}) do
    case System.cmd("git", ["clone", "https://github.com/#{full_name}", "#{sha}", "--quiet"], cd: @code_dir) do
      {_result, 0} -> {:ok, :checked_out}
      {error, code} -> {:error, "#{code}: " <> error}
    end
  end

  def cleanup(%{sha: sha}) do
    case System.cmd("rm", ["-rf", "#{sha}"], cd: @code_dir) do
      {_result, 0} -> {:ok, :cleaned_up}
      {error, code} -> {:error, "#{code}: " <> error}
    end
  end

  def validate_elenchos_config(%{sha: sha}) do
    with  {:ok, data} <- File.read(@code_dir <> "/" <> sha <> "/" <> "elenchos.json"),
          {:ok, parsed_data} <- Jason.decode(data),
          {true, true} <- {Map.has_key?(parsed_data, "dockerfiles"), Map.has_key?(parsed_data, "overlay")}
      do
        true
    else
      {:error, :enoent} -> {:error, "File does not exist"}
      {:error, %Jason.DecodeError{}} -> {:error, "Could not decode JSON"}
      {true, false} -> {:error, "Config is missing overlay key"}
      {false, true} -> {:error, "Config is missing dockerfiles key"}
      {false, false} -> {:error, "Config is missing dockerfiles and overlay keys"}
    end
  end
end
