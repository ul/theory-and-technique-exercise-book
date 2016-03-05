using Gtk, Violet

# example of using GtkBuilder
#b = @GtkBuilder(filename=joinpath(dirname(@__FILE__), "ex1.glade"))
#w = GAccessor.object(b, "window1")

"If not in REPL, hang until given window isn't destroyed.
Place this function in the end of your script which uses Gtk."
function eventloop(win)
  if !isinteractive()
    @async Gtk.gtk_main()
    c = Condition()
    signal_connect(win, :destroy) do widget
      Gtk.gtk_quit()
      notify(c)
    end
    wait(c)
  end
end

# useful formulæ from The Theory and Technique of Electronic Music

typealias Frequency Real
typealias AngularFrequency Real
typealias Phase Real
typealias Amplitude Real
typealias SampleRate Real
typealias SampleNumber Integer
typealias Sample Real
typealias Samples Vector{Sample}
typealias Pitch Real # in real MIDI it's Integer
typealias Time Real

sinusoid(a::Amplitude, ω::AngularFrequency, ϕ::Phase) =
  (n::SampleNumber) -> a*cos(ω*n + ϕ)

freq(ω::AngularFrequency, R::SampleRate) = ω * R / 2π

A_peak(xs::Samples) = norm(xs, Inf)
A_RMS(xs::Samples) = norm(xs, 2)
P(xs::Samples) =  mean(map(abs2, xs))

dB(a::Amplitude, a₀::Amplitude=1e-5) = 20log10(a/a₀)

freq_to_pitch(f::Frequency) = 69 + 12log2(f/440)
pitch_to_freq(m::Pitch) = 440exp2((m - 69)/12)

# note, that MP uses sample numbers as the argument to dsp functions
# as far as Violet uses time, I'll convert formulas to time-based

# REVIEW use clamp?
env(a, b, Δτ::Time) = (τ₀::Time) -> (τ::Time) -> a + (b - a)(τ-τ₀)/Δτ

# Exercise: make sine generator with amplitude control with gradual change by envelope
