using Reactive

include("utils.jl")

myform = @GtkBuilder(filename=joinpath(dirname(@__FILE__), "ex1.glade"))
win = GAccessor.object(myform, "window1")
showall(win)

engineswitch, sineswitch, sineadjustment =
  map(["engineswitch", "sineswitch", "sineadjustment",]) do id
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

ν = Signal(Float64, 440.0)
θ = sine(220.0)
#sineugen = sine(ν, θ)
sineugen = sine(sine(1.0), sine(ν))

signal_connect(engineswitch, "state-set") do widget, state
  put!(enginestate, state)
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
