// Here is an example of a modular synthdef for generating DC control voltage to modular synths
// i use this a lot with Pmonos, see examples below

// Setup io & boot & add proxyspace
(
//SERVER and BUFFER
//increased buffers for samples
s.options.numBuffers = 1024 * 16;
//this is about 1GB, may vary based on RAM
s.options.memSize=2.pow(20);
2.pow(20).postln;
//boot server
s.boot;

// list audio io devices
ServerOptions.devices;
ServerOptions.inDevices;
ServerOptions.outDevices;
// CORM is my macOS aggregate device consisting of Audient iD4 + USBStreamer
// s.options.device = "CORM";
// s.options.outputStreamsEnabled = "1111111111";
// s.options.numInputBusChannels = 2;
// s.options.numOutputBusChannels = 10;

// built in output on macOS? comment above
s.options.device = "Built-in";

// confirm number of Ins and Outs
"INs".postln;
s.options.numInputBusChannels.postln;
"OUTs".postln;
s.options.numOutputBusChannels.postln;

///////////////// Here is another example with an RME Fireface 800 (which has ADAT out for ES-3)
// s.options.device="Fireface 800 (3EC)";
///////////////// Fireface w/ 8 ANALOG INS activated
// s.options.numInputBusChannels = 8;
// s.options.outputStreamsEnabled = "11111111";
///////////////// Fireface w/ ADAT OUTS activated
///////////////// 0-9=ANALOG 1-10
///////////////// 10-11=SPDIF 1-2(11-12)
///////////////// 12-19=ADAT OUT 1-8(13-20)
// s.options.numOutputBusChannels = 19;
// //////////////disable SPDIF outputs
// s.options.outputStreamsEnabled = "11111111110011111111";

//PROXYSPACE
//start proxyspace
p=ProxySpace.push(s);
//start tempo clock
p.makeTempoClock;
//give proxyspace a tempo
p.clock.tempo = 2;
)

// SynthDef for modular control
(
SynthDef(\dcev, { | note=60, octave = 0, stepsPerOctave = 12, t_trig, atk=0, sus=0, rel=3, ch = nil, port = 0, calibration = 0.1, midiTune = 0, amp = 1, ampCh = nil, dur = 1 |
	var level = amp;
	var env = Env([0, 1, 1, 0], [atk, sus, rel], [\lin, \lin, \lin]);
	var envGen = EnvGen.kr(env, t_trig, level, timeScale: dur);
	note = note;
	note = note + (octave * stepsPerOctave) + midiTune;
	note = (note / stepsPerOctave) * calibration;
	Out.ar(ch, K2A.ar(Lag.kr(note, port)));
	Out.ar(ampCh, K2A.ar(Lag.kr(envGen)));
}).add;
)

// Sine synth 'virtual sc' synth which can be used as a modulator for the modular
(
SynthDef(\sinOut, { | freq = 440, t_trig, ch = nil, atk=0, sus=0, rel=3, amp = 0.5, ampCh = nil, dur = 1, octave = 0, stepsPerOctave = 12 |
	var level = amp;
	var env = Env([0, 1, 1, 0], [atk, sus, rel], [\lin, \lin, \lin]);
	var envGen = EnvGen.kr(env, t_trig, level, timeScale: dur);
	var sig = SinOsc.ar(freq, 0, 1, 0);
	freq = freq + (octave * stepsPerOctave);
	freq = freq / stepsPerOctave;
	Out.ar(ch, sig * envGen);
	// Amp for audio rate modulation - USE IF YOU WANT TO MIRROR THE ENVELOPE
	// Out.ar(ampCh, K2A.ar(Lag.kr(amp * envGen)));
}).add;
)


Scale.directory;
Tuning.directory;
Scale.whole.degrees

// tempo clock, change temp
p.clock.tempo = 120/60;

~out.play;

// one instance of dcev synthdef (modular control synth) and
// one instance of sinOut, a virtual SC oscillator that can be used as an amped modulator
// but is also useful for tuning the modular to
(
// initial value Pmonos

// Modular synth
/*~mod1 = Pmono(\sinOut,
	\ch,0, // \ampCh,nil, // dc/cv channel out and amp channel out
	\trig, 1,
	\note, 40,
	\dur,1,
	\amp, 0.5,
	\atk, 0.001,
	\sus, 0.05,
	\rel, 0.4,
	\calibration, 0.0967, //0.0074, 0.10255,
	\midiTune, -24,
	\stepsPerOctave, 12,
	\octave, 0,
); */

// Sine wave synth from sc
~def1 = Pmono(\sinOut,
	\ch, [0,1], // \ampCh, nil, // audio channel out and amp channel out option
	\trig, 1,
	\note, 40,
	\dur, 0.5,
	\amp, 0.80,
	\atk, 0.001,
	\sus, 0.05,
	\rel, 0.4,
	\stepsPerOctave, 12,
	\octave, 0,
);

)

(
// variables for tuning modular to sc virtual sin oscillator
~baseNote = 40;
~speed = 1;
~steps = 12;
~octTune = {Pseq((1..2),inf).asStream};
)

(
~def1.set(\note, ~baseNote, \dur, ~speed, \stepsPerOctave, ~steps, \octave, ~octTune);
)

(
~def1.set(\note, nil, \dur, nil, \stepsPerOctave, nil, \octave, nil);
)

~mod1.play;
~mod1.free;
~def1.play;
~def1.stop;

//alter the state of the synth def with .set
~mod1.set(\octave, Pseq((0..4).mirror1,inf).asStream);
~def1.set(\octave, Pseq((0..3).mirror1,inf).asStream);
~mod1.set(\octave, 0);
~def1.set(\octave, 2.33);
~mod1.set(\note, Pseq((40..63).mirror1,inf).asStream, \dur, 0.3, \port, 0.05);
~def1.set(\note, Pseq((100..104).mirror1 * 0.333,inf).asStream, \dur, 4, \amp, 0.6, \atk, 0.001, \rel, 0.7);
~def1.set(\note, Pseq([50,55,60,65,70,75],inf).asStream, \dur, 0.33);
~mod1.set(\note, 25, \dur, 0.33);
~mod1.set(\note, Pseq([25,25/*32,33,35,37*/].mirror1,inf).asStream, \dur, Pbjorklund2(Pseq((2..16),inf),16,inf,0).asStream/8, \amp, Pexprand(0.5,0.9,inf).asStream, /*\sus, Pseq((2..9) * 0.03,inf).asStream*/);
~def1.set(\dur, Pbjorklund2(Pseq((2..16),inf),16,inf,0).asStream*4, \atk, 0.1, \rel, 0.1, \amp, 0.5);


//free the synths from the server when done
(
~def1.free;
~mod1.free;
)

// clear proxyspace
p.clear;

//three instances of dcev synthdef (modular control synth) set to different channels
(

// Modular voice 1 initial values
~mod1 = Pmono(\sinOut,
	\ch,3,\ampCh,4, // set your cv channel and your amp channel
	\trig, 1,
	\note, Pseq((23..37), inf),
	// try experimenting with degree, scale and tuning in place of note
	//\degree, Pseq((5..12).mirror1,inf), //5..12
	//\scale, Scale.major,
	\dur, Pseq([0.3, 0.1, 0.5, 0.1],inf) * 0.3,
	\amp, Pseq((15..85).mirror2, inf) * 0.01, //Pseq([0.20, 0.30, 0.35], inf),
	// here are set envelope values
	// try experimenting with sequenced envelope values!
	\atk, 0.001,
	\sus, 0.05,
	\rel, 0.5,
	\calibration, 0.1,
	\midiTune, -12.75,
	\spo, 12,
	\octave, Pshuf((0..4),inf),
	);

// Modular voice 2 initial values
~mod2 = Pmono(\dcev,
	\ch,5,\ampCh,6, // set your cv channel and your amp channel
	\trig, 1,
	\note, Pseq((23..37), inf),
	// try experimenting with degree, scale and tuning in place of note
	//\degree, Pseq((5..12).mirror1,inf), //5..12
	//\scale, Scale.major,
	\dur, Pseq([0.3, 0.1, 0.5, 0.1],inf) * 0.3,
	\amp, Pseq((15..85).mirror2, inf) * 0.01, //Pseq([0.20, 0.30, 0.35], inf),
	// here are set envelope values
	// try experimenting with sequenced envelope values!
	\atk, 0.001,
	\sus, 0.05,
	\rel, 0.5,
	\calibration, 0.1,
	\midiTune, -12.75,
	\spo, 12,
	\octave, Pshuf((1..2),inf),
	);

// Modular voice 3 initial values
~mod3 = Pmono(\dcev,
	\ch,7,\ampCh,8, // set your cv channel and your amp channel
	\trig, 1,
	\note, Pseq((23..37), inf),
	// try experimenting with degree, scale and tuning in place of note
	//\degree, Pseq((5..12).mirror1,inf), //5..12
	//\scale, Scale.major,
	\dur, Pseq([0.3, 0.1, 0.5, 0.1],inf) * 0.3,
	\amp, Pseq((15..85).mirror2, inf) * 0.01, //Pseq([0.20, 0.30, 0.35], inf),
	// here are set envelope values
	// try experimenting with sequenced envelope values!
	\atk, 0.001,
	\sus, 0.05,
	\rel, 0.5,
	\calibration, 0.1,
	\midiTune, -12.75,
	\spo, 12,
	\octave, Pshuf((1..3),inf),
	);
)

//free the mod1, mod2 & mod3 synths
(
~mod1.free;
~mod2.free;
~mod3.free;
)

// clear proxyspace and quit the server when done
(
p.clear;
s.quit;
)

////////// UTILITIES ////////////
s.queryAllNodes;
s.sendMsg("/n_free", 1008);

// with <3 from JEA