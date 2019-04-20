defmodule ElenchosEx.Repository do

  @code_dir Application.get_env(:elenchos_ex, :code_dir, "/tmp")

  @doc """
  Checks out the code from the repository specified by the sha
  """
  def checkout(%{sha: sha}) do
    case System.cmd("git", ["checkout", sha, "--quiet"], cd: "#{@code_dir}/#{sha}") do
      {_result, 0} -> {:ok, :checked_out}
      {error, code} -> {:error, "#{code}: " <> error}
    end
  end

  @doc """
  Clones the repository in the release
  """
  def clone(%{full_name: full_name, sha: sha}) do
    case System.cmd("git", ["clone", "https://github.com/#{full_name}", sha, "--quiet"], cd: @code_dir) do
      {_result, 0} -> {:ok, :cloned}
      {error, code} -> {:error, "#{code}: " <> error}
    end
  end

  @doc """
  Deletes the repository for a release
  """
  def cleanup(%{sha: sha}) do
    case System.cmd("rm", ["-rf", sha], cd: @code_dir) do
      {_result, 0} -> {:ok, :cleaned_up}
      {error, code} -> {:error, "#{code}: " <> error}
    end
  end

  @doc """
  Validates that the release has an elenchos config file
  """
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
