defmodule Extank do
  @behaviour :wx_object
  use Bitwise
  import :gl_const

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

    canvas = setup_gl_canvas(frame, size)

    timer = :timer.send_interval(20, self(), :update)

    {frame, %{frame: frame, canvas: canvas, timer: timer}}
  end

  def code_change(_, _, state), do: {:stop, :not_implemented, state}

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def handle_event({:wx, _, _, _, {:wxSize, :size, {width, height}, _}}, state) do
    if width != 0 and height != 0 do
      setup_gl_canvas(state.frame, {width, height})
    end
    {:noreply, state}
  end

  def handle_info(:update, state) do
    :wx.batch(fn -> render(state) end)
    {:noreply, state}
  end

  def handle_info(:stop, state) do
    :timer.cancel(state.timer)
    :wxGLCanvas.destroy(state.canvas)
    {:stop, :normal, state}
  end

  def handle_cast(msg, state) do
    IO.puts "Cast: #{inspect msg}"
    {:noreply, state}
  end

  def handle_call(msg, _from, state) do
    IO.puts "Call: #{inspect msg}"
    {:reply, :ok, state}
  end

  def terminate(_, %{canvas: canvas, timer: timer}) do
    IO.puts "TERMINATE: CLEANUP TIME"
    :wxGLCanvas.destroy(canvas)
    :timer.cancel(timer)
    :timer.sleep(300)
  end

  defp setup_gl_canvas(frame, size) do
    opts = [{:size, size}]
    gl_attrib = [{:attribList, [:wx_const.wx_GL_RGBA(),
                                :wx_const.wx_GL_DOUBLEBUFFER(),
                                :wx_const.wx_GL_MIN_RED, 8,
                                :wx_const.wx_GL_MIN_GREEN, 8,
                                :wx_const.wx_GL_MIN_BLUE, 8,
                                :wx_const.wx_GL_DEPTH_SIZE, 24, 0]}]
    canvas = :wxGLCanvas.new(frame, opts ++ gl_attrib)

    :wxGLCanvas.connect(canvas, :size)
    :wxWindow.reparent(canvas, frame)
    :wxGLCanvas.setCurrent(canvas)
    setup_gl(canvas)
    canvas
  end

  defp setup_gl(win) do
    {w, h} = :wxWindow.getClientSize(win)
    resize_gl_scene(w, h)
    :gl.enable(gl_depth_test())
    :gl.depthFunc(gl_lequal())
    :gl.hint(gl_perspective_correction_hint(), gl_nicest())
    :ok
  end

  defp resize_gl_scene(width, height) do
    :gl.viewport(0, 0, width, height)
    :gl.shadeModel(gl_smooth())
    :gl.clearColor(0.0, 0.0, 0.0, 0.0)
    :gl.clearDepth(1.0)
    :ok
  end

  defp draw() do
    :gl.clear(Bitwise.bor(gl_color_buffer_bit, gl_depth_buffer_bit))

    period = 10_000
    angle = 360.0 * rem(:erlang.system_time(:millisecond), period) / period

    :gl.loadIdentity()
    :gl.translatef(0.0, 0.0, 0.0)
    :gl.rotatef(angle, 0.0, 0.0, 1.0)
    :gl.'begin'(gl_polygon())
    :gl.vertex3f(-0.25, 0.25, 0.0)
    :gl.vertex3f(0.0, 0.25, 0.0)
    :gl.vertex3f(0.0, 0.0, 0.0)
    :gl.vertex3f(-0.25, 0.0, 0.0)
    :gl.'end'()
    :ok
  end

  defp render(%{canvas: canvas} = _state) do
    draw()
    :wxGLCanvas.swapBuffers(canvas)
    :ok
  end
end
