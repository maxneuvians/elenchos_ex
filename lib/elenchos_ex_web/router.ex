defmodule ElenchosExWeb.Router do
  use ElenchosExWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElenchosExWeb do
    pipe_through :api
    post "/", PayloadController, :index
  end
end
