defmodule Extank do
  @behaviour :wx_object

  def start(_type, _args) do
    {_, _, _, pid} = :wx_object.start_link(__MODULE__, [], [name: :extank])
    {:ok, pid}
  end

  def init(config) do
    title = 'ExTanks'
    size = {600, 600}
    wx = :wx.new(config)
    frame = :wxFrame.new(wx, :wx_const.wxID_ANY(), title, [{:size, size}])
    true = :wxWindow.setBackgroundColour(frame, :wx_const.wxBLACK())
    :wxWindow.connect(frame, :close_window)
    :wxWindow.connect(frame, :size)
    :wxFrame.show(frame)

    # once we know how many tanks there are load images for them
    bitmap = :wxBitmap.new()
    true = :wxBitmap.loadFile(bitmap, "blue_body000.jpg", [type: :wx_const.wxBITMAP_TYPE_JPEG()])

    timer = :timer.send_interval(1_000, self(), :re_draw)

    {frame, %{frame: frame, bitmap: bitmap, timer: timer}}
  end

  def code_change(_, _, state), do: {:stop, :not_implemented, state}

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def handle_event({:wx, _, _, _, {:wxSize, :size, {width, height}, _}}, state) do
    IO.puts "RESIZE: #{width}x#{height}"
    draw(state.frame, state.bitmap)
    {:noreply, state}
  end

  def handle_info(:re_draw, state) do
    draw(state.frame, state.bitmap)
    {:noreply, state}
  end

  def handle_info(:update, state) do
    IO.puts "UPDATE"
    draw(state.frame, state.bitmap)
    {:noreply, state}
  end

  def handle_cast(msg, state) do
    IO.puts "Cast: #{inspect msg}"
    {:noreply, state}
  end

  def handle_call(msg, _from, state) do
    IO.puts "Call: #{inspect msg}"
    {:reply, :ok, state}
  end

  def terminate(_, %{bitmap: bitmap, timer: timer}) do
    :wxBitmap.destroy(bitmap)
    :timer.cancel(timer)
  end

  defp draw(frame, bitmap) do
    :wx.batch(fn ->
      :wxWindow.clearBackground(frame)
      graphics_context = :wxGraphicsContext.create(frame)
      angle = :math.sin(rem(:erlang.system_time(:millisecond), 20_000)) * 2 * :math.pi()
      IO.puts "painting at #{angle}rad"
      :wxGraphicsContext.translate(graphics_context, 300, 300)
      :wxGraphicsContext.rotate(graphics_context, angle)
      :wxGraphicsContext.drawBitmap(graphics_context, bitmap, -18, -19, 36, 38)
      :wxGraphicsContext.destroy(graphics_context)
    end)
  end
end
