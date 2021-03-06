# imports
require("ggplot2") # for pretty plots
require("psd") # power spectrum distributions with fancy tapers
require("signal") # signal processing toolkit w/filters, etc
require("seewave") # time wave visualization (spectrograms!)
require("viridis") # viridis color palettes

source(".Rprofile")
source("packages/import_data.R")
source("packages/subsample.R")

# Read in interpolated CSV. Place your interpolated CSV file in the data subdirectory,
# then edit the following line to reference it.
data = import_data("data/tmp-data.csv", legacy=F)
myDates = data[[7]]

# this function lets you sample a vector obj at every nth point, 
# so long graphs don't take forever to render. 
# Make sure to update your sampling rate if you're using subsampling!
subsample = ss

## Simple scatterplot of one axis
# Which points to plot?
dataRange = 1:nrow(data)
# subsampling resolution?
ssres = 1
# dataset?
ds = 1
# plot with ggplot2
qplot(subsample(myDates[dataRange],ssres), subsample(data[[ds]][dataRange],ssres), geom="line") + #scale_y_continuous(breaks = -12:12/10) + 
  scale_x_datetime(breaks = date_breaks("10 sec"), labels = date_format("%S")) +
  labs(
    x="Time", 
    y="Accelerometer Z-Axis (Gs)", 
    title="Accelerometer Z Data for 07/28 Dataset (Sub-sampling: 1/5)")# + ylim(-2,1.5) #+ geom_line()  + scale_x_datetime(breaks = date_breaks("1 sec"), labels = date_format("%S"))qplot(1:100, (abs(fft(subsample(data[[1]][1:350000],50)))^2)[1:100], alpha = 0.25) +scale_y_log10() #+ geom_line()  + scale_x_datetime(breaks = date_breaks("1 sec"), labels = date_format("%S"))

## Aggregates -- not useful right now
#aggData = aggregate(data[1:6], list(myDates), mean)
#qplot(subsample(aggData[[1]][1:30],1), subsample(aggData[[2]][1:30],1)) + ylim(-2,1.5) + geom_line()

## Power spectrum distribution using PSD (sine multitaper)
# This is better for shorter time windows. I use spectrograms for longer data
dataRange = 360000:370000
ssres = 1
ds = 3
# Generate PSD. x.frqsamp = sampling rate
myps = pspectrum(subsample(data[[ds]][dataRange],ssres), x.frqsamp = 25/ssres)
# Plot with ggplot2
qplot(myps$freq, myps$spec, geom="line") + scale_x_log10() +scale_y_log10() + annotation_logticks(sides="l") +
      labs(x="Frequency (log10(Hz))", y="Spectrum", title="Power Spctrum Distribution for 7-28 Dataset")
# Plot with R's default plotter
 plot(myps)

## Filtering with signal
dataRange = 330000:530000 
ssres = 1
ds = 3
filtFreq = 0.5 # HPF freq in Hz

# 3rd order Butterworth HPF
myHPF = butter(type="high", 3, filtFreq/(25/ssres))
# Filter data. A HPF cuts out the high-energy LF data, making 
# subtleties in the higher frequencies easier to discern.
filtdat = filter(myHPF, subsample(data[[ds]][dataRange],ssres))
# Smooth data. This helps reduce noise in the upcoming spectrogram.
# The tradeoff is that spikes become harder to see.
filtdat = smooth(filtdat)

## Filtered, smoothed spectrogram using signal's "specgram"
# This uses data from the previous step
# plot spectrogram. n = window size, Fs = sampling rate
plot(specgram(filtdat, n=512, Fs = 25/ssres), col=inferno(512), ylim=c(0,10), main="Spectrogram of Filtered, Smoothed Data \n (07-28, Accel. Z, HPF 0.5Hz)")

## Spectrogram using seewave
dataRange = 330000:730000 # shark data window for the 07/28 dataset
ssres = 1
ds = 3
flim = c(0.0005,.005) # Frequency data range in kHz
# plot spectrogram. wl = window size, f = sampling rate
spectro(subsample(data[[ds]][dataRange],ssres)+.1, f=25/ssres, wl=2048, flim=flim)
