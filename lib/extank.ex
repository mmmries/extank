defmodule Extank do
  @behaviour :wx_object

  @title 'Elixir OpenGL'
  @size {600, 600}

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

    timer = :timer.send_interval(20, self(), :re_draw)

    {frame, %{frame: frame, bitmap: bitmap, timer: timer}}
  end

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

  def terminate(_, %{bitmap: bitmap, timer: timer}) do
    :wxBitmap.destroy(bitmap)
    :timer.cancel(timer)
  end

  defp draw(frame, bitmap) do
    IO.puts "start DRAW"
    graphics_context = :wxGraphicsContext.create(frame)
    #:wxWindow.clearBackground(frame)
    :wxGraphicsContext.drawBitmap(graphics_context, bitmap, 200, 200, 36, 38)
    # draw other stuff
    :wxGraphicsContext.destroy(graphics_context)
    IO.puts "finish DRAW"
  end
end
