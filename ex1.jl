using Reactive

include("utils.jl")

myform = @GtkBuilder(filename=joinpath(dirname(@__FILE__), "ex1.glade"))
win = GAccessor.object(myform, "window1")
showall(win)

engineswitch, audioswitch, videoswitch, sineswitch,
sineadjustment =
  map(["engineswitch", "audioswitch", "videoswitch", "sineswitch",
       "sineadjustment",]) do id
    GAccessor.object(myform, id)
  end

enginestate = Channel{Bool}(1)
@async while true
  if take!(enginestate)
    run(engine)
  else
    kill(engine)
  end
end

engine = Engine()

audiopid = nothing
videopid = nothing

ν = Signal(Float64, 440.0)
sineugen = sine(ν)

signal_connect(engineswitch, "state-set") do widget, state
  put!(enginestate, state)
  nothing # important to not corrupt Gtk state
end

signal_connect(audioswitch, "state-set") do widget, state
  if state
    global audiopid = addaudio()
  else
    if audiopid != nothing
      kill(audiopid)
      global audiopid = nothing
    end
  end
  nothing # important to not corrupt Gtk state
end

signal_connect(videoswitch, "state-set") do widget, state
  if state
    global videopid = addvideo()
  else
    if videopid != nothing
      kill(videopid)
      global videopid = nothing
    end
  end
  nothing # important to not corrupt Gtk state
end

signal_connect(sineswitch, "state-set") do widget, state
  if state
    push!(engine.root.audio, sineugen)
  else
    delete!(engine.root.audio, sineugen)
  end
  nothing # important to not corrupt Gtk state
end

signal_connect(sineadjustment, "value-changed") do widget
  push!(ν, getproperty(widget, :value, Float64))
  nothing # important to not corrupt Gtk state
end

eventloop(win)
