include("utils.jl")

myform = @GtkBuilder(filename=joinpath(dirname(@__FILE__), "ex1.glade"))

engineswitch, audioswitch, videoswitch, enginestatus, audiostatus, videostatus =
  map(["engineswitch", "audioswitch", "videoswitch", "enginestatus", "audiostatus", "videostatus"]) do id
    GAccessor.object(myform, id)
  end

win = GAccessor.object(myform, "window1")

showall(win)

signal_connect(engineswitch, "state-set") do widget, state
  if state
    setproperty!(enginestatus, :label, "Starting...")
    
  else
    setproperty!(enginestatus, :label, "Stopping...")
  end
end

eventloop(win)
