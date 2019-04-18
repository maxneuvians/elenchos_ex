defmodule ElenchosExWeb.PayloadControllerTest do
  use ElenchosExWeb.ConnCase

  import ElenchosExWeb.PayloadSample

  describe "post a payload returns a HTTP message and 200 status code" do
    test "POST / with an empty payload", %{conn: conn} do
      conn = post(conn, "/", %{})
      assert response(conn, 200) == "No action taken"
    end

    test "POST / with a closed a PR payload", %{conn: conn} do
      conn = post(conn, "/", closed_a_pr())
      assert response(conn, 200) == "PR closed"
    end

    test "POST / with a create a PR payload", %{conn: conn} do
      conn = post(conn, "/", create_a_pr())
      assert response(conn, 200) == "PR open"
    end

    test "POST / with a push to initial branch", %{conn: conn} do
      conn = post(conn, "/", push_to_initial_branch())
      assert response(conn, 200) == "Initial Push"
    end

    test "POST / with a a push to master", %{conn: conn} do
      conn = post(conn, "/", push_to_master())
      assert response(conn, 200) == "Ignoring push to master"
    end

    test "POST / with a reopen a PR payload", %{conn: conn} do
      conn = post(conn, "/", reopen_a_pr())
      assert response(conn, 200) == "PR repoened"
    end

    test "POST / with a push to a branch", %{conn: conn} do
      conn = post(conn, "/", update_to_branch())
      assert response(conn, 200) == "Push"
    end

  end
end
