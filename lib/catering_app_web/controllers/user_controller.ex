defmodule CateringAppWeb.UserController do
  use CateringAppWeb, :controller

  alias CateringApp.Users
  alias CateringApp.Users.User

  plug CateringAppWeb.Plugs.CheckAdmin when action in [:update, :delete]

  def get_users(current_user) do
    if current_user == nil do
      Users.list_caterers()
    else
      cond do
        current_user.admin -> Users.list_users()
        current_user.is_caterer -> IO.inspect(Users.list_clients())
        true -> Users.list_caterers()
      end
    end
  end

  def index(conn, _params) do
    current_user = conn.assigns[:current_user]
    users = get_users(current_user)

    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Users.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Users.create_user(user_params) do
      {:ok, user} ->
        CateringAppWeb.Endpoint.broadcast!("tangerine:all", "add_user", user_params)
        conn
        |> put_flash(:info, "User created successfully.")
        |> put_session(:user_id, user.id)
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    IO.puts("in show")
    user = Users.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = Users.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Users.get_user!(id)

    case Users.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    {:ok, _user} = Users.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end
end
