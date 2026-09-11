<CsoundSynthesizer>
<CsOptions>
; The FastAPI backend supplies adc/dac flags so Sample Mode can run without input.
</CsOptions>
<CsInstruments>

sr     = 44100
ksmps  = 64
nchnls = 2
nchnls_i = 2
0dbfs  = 1

giAtsSine ftgen 1, 0, 16384, 10, 1

gaSampleL init 0
gaSampleR init 0
gaSampleDryL init 0
gaSampleDryR init 0
gaSamplePitchL init 0
gaSamplePitchR init 0
gaSampleRingL init 0
gaSampleRingR init 0
gaSampleBlurL init 0
gaSampleBlurR init 0
gaSampleFlangerL init 0
gaSampleFlangerR init 0
gaSampleAtsL init 0
gaSampleAtsR init 0
gkSampleLoop0 init 0
gkSampleLoop1 init 0
gkSampleLoop2 init 0
gkSampleLoop3 init 0
gkSampleLoop4 init 0
gkSampleLoop5 init 0
gkSampleLoop6 init 0
gkSampleLoop7 init 0
gkSampleToken0 init 0
gkSampleToken1 init 0
gkSampleToken2 init 0
gkSampleToken3 init 0
gkSampleToken4 init 0
gkSampleToken5 init 0
gkSampleToken6 init 0
gkSampleToken7 init 0


;;channels

; Sample Mode is exclusive: 0 routes microphone input, 1 routes the 8-pad sample bank.
chn_k "sample_mode", 1
chn_k "transport_bpm", 1
chn_k "transport_sync", 1
chn_k "transport_warp", 1
chn_k "sample_loop_0", 1
chn_k "sample_loop_1", 1
chn_k "sample_loop_2", 1
chn_k "sample_loop_3", 1
chn_k "sample_loop_4", 1
chn_k "sample_loop_5", 1
chn_k "sample_loop_6", 1
chn_k "sample_loop_7", 1
chn_k "sample_gain_0", 1
chn_k "sample_gain_1", 1
chn_k "sample_gain_2", 1
chn_k "sample_gain_3", 1
chn_k "sample_gain_4", 1
chn_k "sample_gain_5", 1
chn_k "sample_gain_6", 1
chn_k "sample_gain_7", 1
chn_k "sample_send_pitch_0", 1
chn_k "sample_send_pitch_1", 1
chn_k "sample_send_pitch_2", 1
chn_k "sample_send_pitch_3", 1
chn_k "sample_send_pitch_4", 1
chn_k "sample_send_pitch_5", 1
chn_k "sample_send_pitch_6", 1
chn_k "sample_send_pitch_7", 1
chn_k "sample_send_ring_0", 1
chn_k "sample_send_ring_1", 1
chn_k "sample_send_ring_2", 1
chn_k "sample_send_ring_3", 1
chn_k "sample_send_ring_4", 1
chn_k "sample_send_ring_5", 1
chn_k "sample_send_ring_6", 1
chn_k "sample_send_ring_7", 1
chn_k "sample_send_blur_0", 1
chn_k "sample_send_blur_1", 1
chn_k "sample_send_blur_2", 1
chn_k "sample_send_blur_3", 1
chn_k "sample_send_blur_4", 1
chn_k "sample_send_blur_5", 1
chn_k "sample_send_blur_6", 1
chn_k "sample_send_blur_7", 1
chn_k "sample_send_flanger_0", 1
chn_k "sample_send_flanger_1", 1
chn_k "sample_send_flanger_2", 1
chn_k "sample_send_flanger_3", 1
chn_k "sample_send_flanger_4", 1
chn_k "sample_send_flanger_5", 1
chn_k "sample_send_flanger_6", 1
chn_k "sample_send_flanger_7", 1
chn_k "sample_send_ats_0", 1
chn_k "sample_send_ats_1", 1
chn_k "sample_send_ats_2", 1
chn_k "sample_send_ats_3", 1
chn_k "sample_send_ats_4", 1
chn_k "sample_send_ats_5", 1
chn_k "sample_send_ats_6", 1
chn_k "sample_send_ats_7", 1

; Effect variant selectors: 0 is the current branch. Add new numeric branches
; in the matching effect block below when adding same-category Csound effects.
chn_k "pitch_variant", 1
chn_k "pitch_on", 1
chn_k "pitch_wet", 1
chn_k "pitch_semitone", 1

chn_k "ring_variant", 1
chn_k "ring_on", 1
chn_k "ring_wet", 1

chn_k "blur_variant", 1
chn_k "blur_on", 1 
chn_k "blur_len", 1         
chn_k "blur_wet", 1


chn_k "flanger_variant", 1
chn_k "flanger_on", 1
chn_k "flanger_wet", 1
chn_k "lfo_rate", 1 

chn_k "ats_variant", 1
chn_k "ats_on", 1
chn_k "ats_wet", 1
chn_k "ats_morph", 1
chn_k "ats_speed", 1

;EQ
chn_k "highEQ", 1
chn_k "midEQ", 1
chn_k "lowEQ", 1
chn_k "master_volume", 1
chn_k "limiter_threshold", 1
chn_k "limiter_ceiling", 1
chn_k "limiter_attack", 1
chn_k "limiter_release", 1


; Initialize channel defaults so effects use the same values before any OSC snapshot arrives.
instr InitDefaults
    chnset 0, "sample_mode"
    chnset 120, "transport_bpm"
    chnset 0, "transport_sync"
    chnset 1, "transport_warp"
    chnset 0, "sample_loop_0"
    chnset 0, "sample_loop_1"
    chnset 0, "sample_loop_2"
    chnset 0, "sample_loop_3"
    chnset 0, "sample_loop_4"
    chnset 0, "sample_loop_5"
    chnset 0, "sample_loop_6"
    chnset 0, "sample_loop_7"
    chnset 1, "sample_gain_0"
    chnset 1, "sample_gain_1"
    chnset 1, "sample_gain_2"
    chnset 1, "sample_gain_3"
    chnset 1, "sample_gain_4"
    chnset 1, "sample_gain_5"
    chnset 1, "sample_gain_6"
    chnset 1, "sample_gain_7"
    ; Default sends preserve the old behavior until the web matrix changes a pad row.
    chnset 1, "sample_send_pitch_0"
    chnset 1, "sample_send_pitch_1"
    chnset 1, "sample_send_pitch_2"
    chnset 1, "sample_send_pitch_3"
    chnset 1, "sample_send_pitch_4"
    chnset 1, "sample_send_pitch_5"
    chnset 1, "sample_send_pitch_6"
    chnset 1, "sample_send_pitch_7"
    chnset 1, "sample_send_ring_0"
    chnset 1, "sample_send_ring_1"
    chnset 1, "sample_send_ring_2"
    chnset 1, "sample_send_ring_3"
    chnset 1, "sample_send_ring_4"
    chnset 1, "sample_send_ring_5"
    chnset 1, "sample_send_ring_6"
    chnset 1, "sample_send_ring_7"
    chnset 1, "sample_send_blur_0"
    chnset 1, "sample_send_blur_1"
    chnset 1, "sample_send_blur_2"
    chnset 1, "sample_send_blur_3"
    chnset 1, "sample_send_blur_4"
    chnset 1, "sample_send_blur_5"
    chnset 1, "sample_send_blur_6"
    chnset 1, "sample_send_blur_7"
    chnset 1, "sample_send_flanger_0"
    chnset 1, "sample_send_flanger_1"
    chnset 1, "sample_send_flanger_2"
    chnset 1, "sample_send_flanger_3"
    chnset 1, "sample_send_flanger_4"
    chnset 1, "sample_send_flanger_5"
    chnset 1, "sample_send_flanger_6"
    chnset 1, "sample_send_flanger_7"
    chnset 1, "sample_send_ats_0"
    chnset 1, "sample_send_ats_1"
    chnset 1, "sample_send_ats_2"
    chnset 1, "sample_send_ats_3"
    chnset 1, "sample_send_ats_4"
    chnset 1, "sample_send_ats_5"
    chnset 1, "sample_send_ats_6"
    chnset 1, "sample_send_ats_7"
    gkSampleLoop0 = 0
    gkSampleLoop1 = 0
    gkSampleLoop2 = 0
    gkSampleLoop3 = 0
    gkSampleLoop4 = 0
    gkSampleLoop5 = 0
    gkSampleLoop6 = 0
    gkSampleLoop7 = 0
    gkSampleToken0 = 0
    gkSampleToken1 = 0
    gkSampleToken2 = 0
    gkSampleToken3 = 0
    gkSampleToken4 = 0
    gkSampleToken5 = 0
    gkSampleToken6 = 0
    gkSampleToken7 = 0

    chnset 0, "pitch_variant"
    chnset 0, "pitch_on"
    chnset 0.5, "pitch_wet"
    chnset 0, "pitch_semitone"

    chnset 0, "ring_variant"
    chnset 0, "ring_on"
    chnset 0.5, "ring_wet"

    chnset 0, "blur_variant"
    chnset 0, "blur_on"
    chnset 50, "blur_len"
    chnset 0.5, "blur_wet"

    chnset 0, "flanger_variant"
    chnset 0, "flanger_on"
    chnset 0.5, "flanger_wet"
    chnset 0.5, "lfo_rate"

    chnset 0, "ats_variant"
    chnset 0, "ats_on"
    chnset 0.35, "ats_wet"
    chnset 0.65, "ats_morph"
    chnset 1, "ats_speed"

    chnset 0, "lowEQ"
    chnset 0, "midEQ"
    chnset 0, "highEQ"
    chnset 1, "master_volume"
    chnset -3, "limiter_threshold"
    chnset -1, "limiter_ceiling"
    chnset 2, "limiter_attack"
    chnset 140, "limiter_release"
endin


; OSC Listener
; Receives parameters from OnLive 音 (127.0.0.1:7777)
instr OSCListen
    ihOSC OSCinit 7777
    
    kVal init 0
    kSlot init 0
    kEffect init 0
    kGain init 1
    kRate init 1
    kDur init 1
    kBars init 1
    kToken init 0

		 ;_______________________
    ;Sample Mode
    kGot OSClisten ihOSC, "/ol/mode/sample", "f", kVal
    if (kGot == 1) then
        chnset kVal, "sample_mode"
    endif

    ; Global BPM is owned by Csound so loop launch and playback rate share one clock.
    kGot OSClisten ihOSC, "/ol/transport/bpm", "f", kVal
    if (kGot == 1) then
        chnset limit(kVal, 40, 240), "transport_bpm"
    endif

    ; Tempo sync is optional. Off means sample loops play at their original audio speed.
    kGot OSClisten ihOSC, "/ol/transport/sync", "f", kVal
    if (kGot == 1) then
        chnset limit(kVal, 0, 1), "transport_sync"
    endif

    ; Warp keeps loop tempo changes from changing pitch, like Ableton's warped clips.
    kGot OSClisten ihOSC, "/ol/transport/warp", "f", kVal
    if (kGot == 1) then
        chnset limit(kVal, 0, 1), "transport_warp"
    endif

    ; Pad gain channels allow the web sliders to reshape active sample voices in real time.
    kGot OSClisten ihOSC, "/ol/sample/gain", "ff", kSlot, kGain
    if (kGot == 1) then
        kGain = limit(kGain, 0, 16)
        if (kSlot == 0) then
            chnset kGain, "sample_gain_0"
        elseif (kSlot == 1) then
            chnset kGain, "sample_gain_1"
        elseif (kSlot == 2) then
            chnset kGain, "sample_gain_2"
        elseif (kSlot == 3) then
            chnset kGain, "sample_gain_3"
        elseif (kSlot == 4) then
            chnset kGain, "sample_gain_4"
        elseif (kSlot == 5) then
            chnset kGain, "sample_gain_5"
        elseif (kSlot == 6) then
            chnset kGain, "sample_gain_6"
        else
            chnset kGain, "sample_gain_7"
        endif
    endif

    ; The web matrix sends slot/effect/value triples: 0 pitch, 1 ring, 2 blur, 3 flanger, 4 ATS.
    kGot OSClisten ihOSC, "/ol/sample/send", "fff", kSlot, kEffect, kVal
    if (kGot == 1) then
        kVal = limit(kVal, 0, 1)
        if (kEffect == 0) then
            if (kSlot == 0) then
                chnset kVal, "sample_send_pitch_0"
            elseif (kSlot == 1) then
                chnset kVal, "sample_send_pitch_1"
            elseif (kSlot == 2) then
                chnset kVal, "sample_send_pitch_2"
            elseif (kSlot == 3) then
                chnset kVal, "sample_send_pitch_3"
            elseif (kSlot == 4) then
                chnset kVal, "sample_send_pitch_4"
            elseif (kSlot == 5) then
                chnset kVal, "sample_send_pitch_5"
            elseif (kSlot == 6) then
                chnset kVal, "sample_send_pitch_6"
            else
                chnset kVal, "sample_send_pitch_7"
            endif
        elseif (kEffect == 1) then
            if (kSlot == 0) then
                chnset kVal, "sample_send_ring_0"
            elseif (kSlot == 1) then
                chnset kVal, "sample_send_ring_1"
            elseif (kSlot == 2) then
                chnset kVal, "sample_send_ring_2"
            elseif (kSlot == 3) then
                chnset kVal, "sample_send_ring_3"
            elseif (kSlot == 4) then
                chnset kVal, "sample_send_ring_4"
            elseif (kSlot == 5) then
                chnset kVal, "sample_send_ring_5"
            elseif (kSlot == 6) then
                chnset kVal, "sample_send_ring_6"
            else
                chnset kVal, "sample_send_ring_7"
            endif
        elseif (kEffect == 2) then
            if (kSlot == 0) then
                chnset kVal, "sample_send_blur_0"
            elseif (kSlot == 1) then
                chnset kVal, "sample_send_blur_1"
            elseif (kSlot == 2) then
                chnset kVal, "sample_send_blur_2"
            elseif (kSlot == 3) then
                chnset kVal, "sample_send_blur_3"
            elseif (kSlot == 4) then
                chnset kVal, "sample_send_blur_4"
            elseif (kSlot == 5) then
                chnset kVal, "sample_send_blur_5"
            elseif (kSlot == 6) then
                chnset kVal, "sample_send_blur_6"
            else
                chnset kVal, "sample_send_blur_7"
            endif
        elseif (kEffect == 3) then
            if (kSlot == 0) then
                chnset kVal, "sample_send_flanger_0"
            elseif (kSlot == 1) then
                chnset kVal, "sample_send_flanger_1"
            elseif (kSlot == 2) then
                chnset kVal, "sample_send_flanger_2"
            elseif (kSlot == 3) then
                chnset kVal, "sample_send_flanger_3"
            elseif (kSlot == 4) then
                chnset kVal, "sample_send_flanger_4"
            elseif (kSlot == 5) then
                chnset kVal, "sample_send_flanger_5"
            elseif (kSlot == 6) then
                chnset kVal, "sample_send_flanger_6"
            else
                chnset kVal, "sample_send_flanger_7"
            endif
        else
            if (kSlot == 0) then
                chnset kVal, "sample_send_ats_0"
            elseif (kSlot == 1) then
                chnset kVal, "sample_send_ats_1"
            elseif (kSlot == 2) then
                chnset kVal, "sample_send_ats_2"
            elseif (kSlot == 3) then
                chnset kVal, "sample_send_ats_3"
            elseif (kSlot == 4) then
                chnset kVal, "sample_send_ats_4"
            elseif (kSlot == 5) then
                chnset kVal, "sample_send_ats_5"
            elseif (kSlot == 6) then
                chnset kVal, "sample_send_ats_6"
            else
                chnset kVal, "sample_send_ats_7"
            endif
        endif
    endif

    ; Sample triggers schedule short-lived voices that write into the shared sample bus.
    kGot OSClisten ihOSC, "/ol/sample/trigger", "ffff", kSlot, kGain, kRate, kDur
    if (kGot == 1) then
        kGain = limit(kGain, 0, 16)
        if (kSlot == 0) then
            gkSampleLoop0 = 0
            gkSampleToken0 = gkSampleToken0 + 1
            kToken = gkSampleToken0
            chnset kGain, "sample_gain_0"
        elseif (kSlot == 1) then
            gkSampleLoop1 = 0
            gkSampleToken1 = gkSampleToken1 + 1
            kToken = gkSampleToken1
            chnset kGain, "sample_gain_1"
        elseif (kSlot == 2) then
            gkSampleLoop2 = 0
            gkSampleToken2 = gkSampleToken2 + 1
            kToken = gkSampleToken2
            chnset kGain, "sample_gain_2"
        elseif (kSlot == 3) then
            gkSampleLoop3 = 0
            gkSampleToken3 = gkSampleToken3 + 1
            kToken = gkSampleToken3
            chnset kGain, "sample_gain_3"
        elseif (kSlot == 4) then
            gkSampleLoop4 = 0
            gkSampleToken4 = gkSampleToken4 + 1
            kToken = gkSampleToken4
            chnset kGain, "sample_gain_4"
        elseif (kSlot == 5) then
            gkSampleLoop5 = 0
            gkSampleToken5 = gkSampleToken5 + 1
            kToken = gkSampleToken5
            chnset kGain, "sample_gain_5"
        elseif (kSlot == 6) then
            gkSampleLoop6 = 0
            gkSampleToken6 = gkSampleToken6 + 1
            kToken = gkSampleToken6
            chnset kGain, "sample_gain_6"
        else
            gkSampleLoop7 = 0
            gkSampleToken7 = gkSampleToken7 + 1
            kToken = gkSampleToken7
            chnset kGain, "sample_gain_7"
        endif
        event "i", "SampleVoice", 0, kDur, kSlot, kGain, kRate, kToken
    endif

    ; Each launch increments a per-pad token so any previous voice on that pad stops immediately.
    kGot OSClisten ihOSC, "/ol/sample/loop/start", "ffff", kSlot, kGain, kDur, kBars
    if (kGot == 1) then
        kGain = limit(kGain, 0, 16)
        if (kSlot == 0) then
            gkSampleToken0 = gkSampleToken0 + 1
            gkSampleLoop0 = 1
            kToken = gkSampleToken0
            chnset kGain, "sample_gain_0"
        elseif (kSlot == 1) then
            gkSampleToken1 = gkSampleToken1 + 1
            gkSampleLoop1 = 1
            kToken = gkSampleToken1
            chnset kGain, "sample_gain_1"
        elseif (kSlot == 2) then
            gkSampleToken2 = gkSampleToken2 + 1
            gkSampleLoop2 = 1
            kToken = gkSampleToken2
            chnset kGain, "sample_gain_2"
        elseif (kSlot == 3) then
            gkSampleToken3 = gkSampleToken3 + 1
            gkSampleLoop3 = 1
            kToken = gkSampleToken3
            chnset kGain, "sample_gain_3"
        elseif (kSlot == 4) then
            gkSampleToken4 = gkSampleToken4 + 1
            gkSampleLoop4 = 1
            kToken = gkSampleToken4
            chnset kGain, "sample_gain_4"
        elseif (kSlot == 5) then
            gkSampleToken5 = gkSampleToken5 + 1
            gkSampleLoop5 = 1
            kToken = gkSampleToken5
            chnset kGain, "sample_gain_5"
        elseif (kSlot == 6) then
            gkSampleToken6 = gkSampleToken6 + 1
            gkSampleLoop6 = 1
            kToken = gkSampleToken6
            chnset kGain, "sample_gain_6"
        elseif (kSlot == 7) then
            gkSampleToken7 = gkSampleToken7 + 1
            gkSampleLoop7 = 1
            kToken = gkSampleToken7
            chnset kGain, "sample_gain_7"
        endif
        event "i", "SampleLoopVoice", 0, 3600, kSlot, kGain, kDur, kBars, kToken
    endif

    kGot OSClisten ihOSC, "/ol/sample/loop/stop", "f", kSlot
    if (kGot == 1) then
        event "i", "StopSampleLoop", 0, 0.01, kSlot
    endif

    kGot OSClisten ihOSC, "/ol/sample/stop_all", "f", kVal
    if (kGot == 1) then
        gkSampleLoop0 = 0
        gkSampleLoop1 = 0
        gkSampleLoop2 = 0
        gkSampleLoop3 = 0
        gkSampleLoop4 = 0
        gkSampleLoop5 = 0
        gkSampleLoop6 = 0
        gkSampleLoop7 = 0
        gkSampleToken0 = gkSampleToken0 + 1
        gkSampleToken1 = gkSampleToken1 + 1
        gkSampleToken2 = gkSampleToken2 + 1
        gkSampleToken3 = gkSampleToken3 + 1
        gkSampleToken4 = gkSampleToken4 + 1
        gkSampleToken5 = gkSampleToken5 + 1
        gkSampleToken6 = gkSampleToken6 + 1
        gkSampleToken7 = gkSampleToken7 + 1
        turnoff2 "SampleVoice", 0, 0
        turnoff2 "SampleLoopVoice", 0, 0
    endif

		 ;_______________________
    ;Pitch
    		;variant selector for future pitch branches
    kGot OSClisten ihOSC, "/ol/pitch/variant", "f", kVal
    if (kGot == 1) then
        chnset kVal, "pitch_variant"
    endif

    		;on
    kGot OSClisten ihOSC, "/ol/pitch/on", "f", kVal
    if (kGot == 1) then
        chnset kVal, "pitch_on"
    endif

    		;wet
    kGot OSClisten ihOSC, "/ol/pitch/wet", "f", kVal
    if (kGot == 1) then
        chnset kVal, "pitch_wet"
    endif

    		;semi (-12~12)
    kGot OSClisten ihOSC, "/ol/pitch/semi", "f", kVal
    if (kGot == 1) then
        chnset kVal, "pitch_semitone"
    endif
		 
		 ;_______________________
    ; Ring
    		;variant selector for future ring branches
    kGot OSClisten ihOSC, "/ol/ring/variant", "f", kVal
    if (kGot == 1) then
        chnset kVal, "ring_variant"
    endif

    		;on
    kGot OSClisten ihOSC, "/ol/ring/on", "f", kVal
    if (kGot == 1) then
        chnset kVal, "ring_on"
    endif

    		;wet
    kGot OSClisten ihOSC, "/ol/ring/wet", "f", kVal
    if (kGot == 1) then
        chnset kVal, "ring_wet"
    endif
    
		 ;_______________________
    ;Blur on/off & wet
    		;variant selector for future blur branches
    kGot OSClisten ihOSC, "/ol/blur/variant", "f", kVal
    if (kGot == 1) then
        chnset kVal, "blur_variant"
    endif

    		;on
    kGot OSClisten ihOSC, "/ol/blur/on", "f", kVal
    if (kGot == 1) then
        chnset kVal, "blur_on"
    endif

    		;wet
    kGot OSClisten ihOSC, "/ol/blur/wet", "f", kVal
    if (kGot == 1) then
        chnset kVal, "blur_wet"
    endif
    
    kBlurKnob init 100
		; /ol/blur/knob  0~100
		 kGot OSClisten ihOSC, "/ol/blur/len", "f", kVal
		 if (kGot == 1) then
    			chnset kVal, "blur_len" 
		 endif

		 ;_______________________
    ;Flanger
    		;variant selector for future flanger branches
    kGot OSClisten ihOSC, "/ol/flanger/variant", "f", kVal
    if (kGot == 1) then
        chnset kVal, "flanger_variant"
    endif

    		;on
    kGot OSClisten ihOSC, "/ol/flanger/on", "f", kVal
    if (kGot == 1) then
        chnset kVal, "flanger_on"
    endif

    		;wet
    kGot OSClisten ihOSC, "/ol/flanger/wet", "f", kVal
    if (kGot == 1) then
        chnset kVal, "flanger_wet"
    endif

    ; lfo rate
    kGot OSClisten ihOSC, "/ol/flanger/lfo", "f", kVal
    if (kGot == 1) then
        chnset kVal, "lfo_rate"
    endif

		 ;_______________________
    ; ATS Cross spectral layer
    kGot OSClisten ihOSC, "/ol/ats/variant", "f", kVal
    if (kGot == 1) then
        chnset kVal, "ats_variant"
    endif

    kGot OSClisten ihOSC, "/ol/ats/on", "f", kVal
    if (kGot == 1) then
        chnset kVal, "ats_on"
    endif

    kGot OSClisten ihOSC, "/ol/ats/wet", "f", kVal
    if (kGot == 1) then
        chnset kVal, "ats_wet"
    endif

    kGot OSClisten ihOSC, "/ol/ats/morph", "f", kVal
    if (kGot == 1) then
        chnset kVal, "ats_morph"
    endif

    kGot OSClisten ihOSC, "/ol/ats/speed", "f", kVal
    if (kGot == 1) then
        chnset kVal, "ats_speed"
    endif

		 ;_______________________
    ;EQ
    		;lowEQ
    kGot OSClisten ihOSC, "/ol/eq/low", "f", kVal
    if (kGot == 1) then
        chnset kVal, "lowEQ"
    endif

    		;mid
    kGot OSClisten ihOSC, "/ol/eq/mid", "f", kVal
    if (kGot == 1) then
        chnset kVal, "midEQ"
    endif

    		;high
    kGot OSClisten ihOSC, "/ol/eq/high", "f", kVal
    if (kGot == 1) then
        chnset kVal, "highEQ"
    endif

    ; Final master gain sits after all tone and effect processing.
    kGot OSClisten ihOSC, "/ol/master/volume", "f", kVal
    if (kGot == 1) then
        chnset kVal, "master_volume"
    endif

    ; Limiter controls are final-stage protection, after master gain and before outs.
    kGot OSClisten ihOSC, "/ol/limiter/threshold", "f", kVal
    if (kGot == 1) then
        chnset kVal, "limiter_threshold"
    endif

    kGot OSClisten ihOSC, "/ol/limiter/ceiling", "f", kVal
    if (kGot == 1) then
        chnset kVal, "limiter_ceiling"
    endif

    kGot OSClisten ihOSC, "/ol/limiter/attack", "f", kVal
    if (kGot == 1) then
        chnset kVal, "limiter_attack"
    endif

    kGot OSClisten ihOSC, "/ol/limiter/release", "f", kVal
    if (kGot == 1) then
        chnset kVal, "limiter_release"
    endif
    

endin

; ___________________________________________________________
; 											8-Pad Sample Player Voice
; ___________________________________________________________
instr StopSampleLoop
    iSlot = int(p4)

    ; Stopping a pad invalidates its token so loop and one-shot voices release immediately.
    if (iSlot == 0) then
        gkSampleLoop0 = 0
        gkSampleToken0 = gkSampleToken0 + 1
    elseif (iSlot == 1) then
        gkSampleLoop1 = 0
        gkSampleToken1 = gkSampleToken1 + 1
    elseif (iSlot == 2) then
        gkSampleLoop2 = 0
        gkSampleToken2 = gkSampleToken2 + 1
    elseif (iSlot == 3) then
        gkSampleLoop3 = 0
        gkSampleToken3 = gkSampleToken3 + 1
    elseif (iSlot == 4) then
        gkSampleLoop4 = 0
        gkSampleToken4 = gkSampleToken4 + 1
    elseif (iSlot == 5) then
        gkSampleLoop5 = 0
        gkSampleToken5 = gkSampleToken5 + 1
    elseif (iSlot == 6) then
        gkSampleLoop6 = 0
        gkSampleToken6 = gkSampleToken6 + 1
    else
        gkSampleLoop7 = 0
        gkSampleToken7 = gkSampleToken7 + 1
    endif
endin

instr SampleVoice
    iSlot = int(p4)
    iGain = p5
    iRate = p6
    iToken = p7
    SRoot strget 1
    SFile sprintf "%s/pad_%02d.wav", SRoot, iSlot

    kCurrentToken init 0
    kPadGain init iGain
    kPitchSend init 1
    kRingSend init 1
    kBlurSend init 1
    kFlangerSend init 1
    kAtsSend init 1
    if (iSlot == 0) then
        kCurrentToken = gkSampleToken0
        kPadGain chnget "sample_gain_0"
        kPitchSend chnget "sample_send_pitch_0"
        kRingSend chnget "sample_send_ring_0"
        kBlurSend chnget "sample_send_blur_0"
        kFlangerSend chnget "sample_send_flanger_0"
        kAtsSend chnget "sample_send_ats_0"
    elseif (iSlot == 1) then
        kCurrentToken = gkSampleToken1
        kPadGain chnget "sample_gain_1"
        kPitchSend chnget "sample_send_pitch_1"
        kRingSend chnget "sample_send_ring_1"
        kBlurSend chnget "sample_send_blur_1"
        kFlangerSend chnget "sample_send_flanger_1"
        kAtsSend chnget "sample_send_ats_1"
    elseif (iSlot == 2) then
        kCurrentToken = gkSampleToken2
        kPadGain chnget "sample_gain_2"
        kPitchSend chnget "sample_send_pitch_2"
        kRingSend chnget "sample_send_ring_2"
        kBlurSend chnget "sample_send_blur_2"
        kFlangerSend chnget "sample_send_flanger_2"
        kAtsSend chnget "sample_send_ats_2"
    elseif (iSlot == 3) then
        kCurrentToken = gkSampleToken3
        kPadGain chnget "sample_gain_3"
        kPitchSend chnget "sample_send_pitch_3"
        kRingSend chnget "sample_send_ring_3"
        kBlurSend chnget "sample_send_blur_3"
        kFlangerSend chnget "sample_send_flanger_3"
        kAtsSend chnget "sample_send_ats_3"
    elseif (iSlot == 4) then
        kCurrentToken = gkSampleToken4
        kPadGain chnget "sample_gain_4"
        kPitchSend chnget "sample_send_pitch_4"
        kRingSend chnget "sample_send_ring_4"
        kBlurSend chnget "sample_send_blur_4"
        kFlangerSend chnget "sample_send_flanger_4"
        kAtsSend chnget "sample_send_ats_4"
    elseif (iSlot == 5) then
        kCurrentToken = gkSampleToken5
        kPadGain chnget "sample_gain_5"
        kPitchSend chnget "sample_send_pitch_5"
        kRingSend chnget "sample_send_ring_5"
        kBlurSend chnget "sample_send_blur_5"
        kFlangerSend chnget "sample_send_flanger_5"
        kAtsSend chnget "sample_send_ats_5"
    elseif (iSlot == 6) then
        kCurrentToken = gkSampleToken6
        kPadGain chnget "sample_gain_6"
        kPitchSend chnget "sample_send_pitch_6"
        kRingSend chnget "sample_send_ring_6"
        kBlurSend chnget "sample_send_blur_6"
        kFlangerSend chnget "sample_send_flanger_6"
        kAtsSend chnget "sample_send_ats_6"
    else
        kCurrentToken = gkSampleToken7
        kPadGain chnget "sample_gain_7"
        kPitchSend chnget "sample_send_pitch_7"
        kRingSend chnget "sample_send_ring_7"
        kBlurSend chnget "sample_send_blur_7"
        kFlangerSend chnget "sample_send_flanger_7"
        kAtsSend chnget "sample_send_ats_7"
    endif

    if (kCurrentToken != iToken) then
        turnoff
    endif

    ; Each trigger reads one converted stereo WAV and feeds the same effects bus as the microphone.
    aFileL, aFileR diskin2 SFile, iRate, 0, 0
    aEnv linenr 1, 0.003, 0.025, 0.01
    kPadGain = limit(kPadGain, 0, 16)
    aPadL = aFileL * kPadGain * aEnv
    aPadR = aFileR * kPadGain * aEnv
    gaSampleDryL = gaSampleDryL + aPadL
    gaSampleDryR = gaSampleDryR + aPadR
    gaSamplePitchL = gaSamplePitchL + (aPadL * limit(kPitchSend, 0, 1))
    gaSamplePitchR = gaSamplePitchR + (aPadR * limit(kPitchSend, 0, 1))
    gaSampleRingL = gaSampleRingL + (aPadL * limit(kRingSend, 0, 1))
    gaSampleRingR = gaSampleRingR + (aPadR * limit(kRingSend, 0, 1))
    gaSampleBlurL = gaSampleBlurL + (aPadL * limit(kBlurSend, 0, 1))
    gaSampleBlurR = gaSampleBlurR + (aPadR * limit(kBlurSend, 0, 1))
    gaSampleFlangerL = gaSampleFlangerL + (aPadL * limit(kFlangerSend, 0, 1))
    gaSampleFlangerR = gaSampleFlangerR + (aPadR * limit(kFlangerSend, 0, 1))
    gaSampleAtsL = gaSampleAtsL + (aPadL * limit(kAtsSend, 0, 1))
    gaSampleAtsR = gaSampleAtsR + (aPadR * limit(kAtsSend, 0, 1))
endin

instr SampleLoopVoice
    iSlot = int(p4)
    iGain = p5
    iSampleDur = max(0.02, p6)
    iBars = limit(int(p7), 1, 8)
    iToken = p8
    SRoot strget 1
    SFile sprintf "%s/pad_%02d.wav", SRoot, iSlot
    iWarpTableL ftgenonce 0, 0, 0, -1, SFile, 0, 0, 1
    iWarpTableR ftgenonce 0, 0, 0, -1, SFile, 0, 0, 2

    ; Global gates let each pad loop stop independently without channel update races.
    kGate init 1
    kCurrentToken init 0
    kPadGain init iGain
    kPitchSend init 1
    kRingSend init 1
    kBlurSend init 1
    kFlangerSend init 1
    kAtsSend init 1
    kAge timeinsts
    if (iSlot == 0) then
        kGate = gkSampleLoop0
        kCurrentToken = gkSampleToken0
        kPadGain chnget "sample_gain_0"
        kPitchSend chnget "sample_send_pitch_0"
        kRingSend chnget "sample_send_ring_0"
        kBlurSend chnget "sample_send_blur_0"
        kFlangerSend chnget "sample_send_flanger_0"
        kAtsSend chnget "sample_send_ats_0"
    elseif (iSlot == 1) then
        kGate = gkSampleLoop1
        kCurrentToken = gkSampleToken1
        kPadGain chnget "sample_gain_1"
        kPitchSend chnget "sample_send_pitch_1"
        kRingSend chnget "sample_send_ring_1"
        kBlurSend chnget "sample_send_blur_1"
        kFlangerSend chnget "sample_send_flanger_1"
        kAtsSend chnget "sample_send_ats_1"
    elseif (iSlot == 2) then
        kGate = gkSampleLoop2
        kCurrentToken = gkSampleToken2
        kPadGain chnget "sample_gain_2"
        kPitchSend chnget "sample_send_pitch_2"
        kRingSend chnget "sample_send_ring_2"
        kBlurSend chnget "sample_send_blur_2"
        kFlangerSend chnget "sample_send_flanger_2"
        kAtsSend chnget "sample_send_ats_2"
    elseif (iSlot == 3) then
        kGate = gkSampleLoop3
        kCurrentToken = gkSampleToken3
        kPadGain chnget "sample_gain_3"
        kPitchSend chnget "sample_send_pitch_3"
        kRingSend chnget "sample_send_ring_3"
        kBlurSend chnget "sample_send_blur_3"
        kFlangerSend chnget "sample_send_flanger_3"
        kAtsSend chnget "sample_send_ats_3"
    elseif (iSlot == 4) then
        kGate = gkSampleLoop4
        kCurrentToken = gkSampleToken4
        kPadGain chnget "sample_gain_4"
        kPitchSend chnget "sample_send_pitch_4"
        kRingSend chnget "sample_send_ring_4"
        kBlurSend chnget "sample_send_blur_4"
        kFlangerSend chnget "sample_send_flanger_4"
        kAtsSend chnget "sample_send_ats_4"
    elseif (iSlot == 5) then
        kGate = gkSampleLoop5
        kCurrentToken = gkSampleToken5
        kPadGain chnget "sample_gain_5"
        kPitchSend chnget "sample_send_pitch_5"
        kRingSend chnget "sample_send_ring_5"
        kBlurSend chnget "sample_send_blur_5"
        kFlangerSend chnget "sample_send_flanger_5"
        kAtsSend chnget "sample_send_ats_5"
    elseif (iSlot == 6) then
        kGate = gkSampleLoop6
        kCurrentToken = gkSampleToken6
        kPadGain chnget "sample_gain_6"
        kPitchSend chnget "sample_send_pitch_6"
        kRingSend chnget "sample_send_ring_6"
        kBlurSend chnget "sample_send_blur_6"
        kFlangerSend chnget "sample_send_flanger_6"
        kAtsSend chnget "sample_send_ats_6"
    else
        kGate = gkSampleLoop7
        kCurrentToken = gkSampleToken7
        kPadGain chnget "sample_gain_7"
        kPitchSend chnget "sample_send_pitch_7"
        kRingSend chnget "sample_send_ring_7"
        kBlurSend chnget "sample_send_blur_7"
        kFlangerSend chnget "sample_send_flanger_7"
        kAtsSend chnget "sample_send_ats_7"
    endif

    if (kAge > 0.05 && (kGate < 0.5 || kCurrentToken != iToken)) then
        turnoff
    endif

    kBpm chnget "transport_bpm"
    kBpm = limit(kBpm, 40, 240)
    kTempoSync chnget "transport_sync"
    kTempoSync = limit(kTempoSync, 0, 1)
    kWarp chnget "transport_warp"
    kWarp = limit(kWarp, 0, 1)
    kLoopDur = (60 / kBpm) * 4 * iBars
    kSyncedRate = iSampleDur / max(0.02, kLoopDur)
    kRate = (kSyncedRate * kTempoSync) + (1 * (1 - kTempoSync))

    ; Resample mode changes speed and pitch; Warp mode changes loop length while keeping pitch at 1x.
    aDiskL, aDiskR diskin2 SFile, kRate, 0, 1
    aWarpL temposcal kSyncedRate, 1, 1, iWarpTableL, 1
    aWarpR temposcal kSyncedRate, 1, 1, iWarpTableR, 1
    kWarpMode = kTempoSync * kWarp
    aFileL = (aDiskL * (1 - kWarpMode)) + (aWarpL * kWarpMode)
    aFileR = (aDiskR * (1 - kWarpMode)) + (aWarpR * kWarpMode)
    aEnv linenr 1, 0.003, 0.025, 0.01
    kPadGain = limit(kPadGain, 0, 16)
    aPadL = aFileL * kPadGain * aEnv
    aPadR = aFileR * kPadGain * aEnv
    gaSampleDryL = gaSampleDryL + aPadL
    gaSampleDryR = gaSampleDryR + aPadR
    gaSamplePitchL = gaSamplePitchL + (aPadL * limit(kPitchSend, 0, 1))
    gaSamplePitchR = gaSamplePitchR + (aPadR * limit(kPitchSend, 0, 1))
    gaSampleRingL = gaSampleRingL + (aPadL * limit(kRingSend, 0, 1))
    gaSampleRingR = gaSampleRingR + (aPadR * limit(kRingSend, 0, 1))
    gaSampleBlurL = gaSampleBlurL + (aPadL * limit(kBlurSend, 0, 1))
    gaSampleBlurR = gaSampleBlurR + (aPadR * limit(kBlurSend, 0, 1))
    gaSampleFlangerL = gaSampleFlangerL + (aPadL * limit(kFlangerSend, 0, 1))
    gaSampleFlangerR = gaSampleFlangerR + (aPadR * limit(kFlangerSend, 0, 1))
    gaSampleAtsL = gaSampleAtsL + (aPadL * limit(kAtsSend, 0, 1))
    gaSampleAtsR = gaSampleAtsR + (aPadR * limit(kAtsSend, 0, 1))
endin

; ___________________________________________________________
; 											Main Live Instrument 
; ___________________________________________________________
instr Live
		 
    ; Sample Mode can run with nchnls_i=0, so the microphone path must become silence.
    if (nchnls_i < 1) then
        ainL = 0
        ainR = 0
    else
        ainL inch 1
        if (nchnls_i < 2) then
        ainR = ainL
;        print nchnls_i
;        prints "_____________________________________"
        else
            ainR inch 2
        endif
    endif
    
    ; Clean laptop mic rumble/DC before it reaches live monitoring or feedback-based effects.
    aL dcblock2 ainL
    aR dcblock2 ainR
    aL butterhp aL, 70
    aR butterhp aR, 70
    aL butterhp aL, 70
    aR butterhp aR, 70

    ; Keep computer mic-to-speaker monitoring conservative to reduce acoustic feedback risk.
    kSampleMode chnget "sample_mode"
    kSampleMode = limit(kSampleMode, 0, 1)
    aMicL = aL * 0.32 * (1 - kSampleMode)
    aMicR = aR * 0.32 * (1 - kSampleMode)

    ; Sample Mode keeps dry pads and per-effect send buses separate for the web routing matrix.
    aSampleDryL = gaSampleDryL * kSampleMode
    aSampleDryR = gaSampleDryR * kSampleMode
    aSamplePitchL = gaSamplePitchL * kSampleMode
    aSamplePitchR = gaSamplePitchR * kSampleMode
    aSampleRingL = gaSampleRingL * kSampleMode
    aSampleRingR = gaSampleRingR * kSampleMode
    aSampleBlurL = gaSampleBlurL * kSampleMode
    aSampleBlurR = gaSampleBlurR * kSampleMode
    aSampleFlangerL = gaSampleFlangerL * kSampleMode
    aSampleFlangerR = gaSampleFlangerR * kSampleMode
    aSampleAtsL = gaSampleAtsL * kSampleMode
    aSampleAtsR = gaSampleAtsR * kSampleMode
    gaSampleDryL = 0
    gaSampleDryR = 0
    gaSamplePitchL = 0
    gaSamplePitchR = 0
    gaSampleRingL = 0
    gaSampleRingR = 0
    gaSampleBlurL = 0
    gaSampleBlurR = 0
    gaSampleFlangerL = 0
    gaSampleFlangerR = 0
    gaSampleAtsL = 0
    gaSampleAtsR = 0

		; Basic Dry Sound
		 aSigL = aMicL + aSampleDryL
		 aSigR = aMicR + aSampleDryR
    aMatrixL = aMicL + aSampleDryL
    aMatrixR = aMicR + aSampleDryR

    ;PVS
		 ifs    = 2048
		 ihop   = 256
		 iwin   = 2048      
		 iwtype = 1 

; 										 					EFFECTS 
; ___________________________________________________________

; _________________
;Pitch Shift Effect 

		 kPitchVariant chnget "pitch_variant"
		 kPitchOn  chnget "pitch_on"
    kPitchWet chnget "pitch_wet"    
    kPitchAmt = kPitchOn * kPitchWet
    
    ; Variant 0 is the current PVS pitch shifter. Add future pitch branches here.
    ; semitone slider (-12~12)
		 kSemi chnget "pitch_semitone"
		 
		 ; ratio = 2^(semitone/12)
		 kRatio = pow(2, kSemi/12)
		 
    ; Live mic uses the serial chain; Sample Mode uses the per-pad pitch send bus.
    aPitchSrcL = (aSigL * (1 - kSampleMode)) + aSamplePitchL
    aPitchSrcR = (aSigR * (1 - kSampleMode)) + aSamplePitchR
		 fPitchL pvsanal aPitchSrcL, ifs, ihop, ifs, iwtype
		 fPitchR pvsanal aPitchSrcR, ifs, ihop, ifs, iwtype
		 
		 ; pitch shift
		 fPitchL2 pvscale fPitchL, kRatio
		 fPitchR2 pvscale fPitchR, kRatio
		 
		 ;Mix
		 aPitchL pvsynth fPitchL2
		 aPitchR pvsynth fPitchR2
		 
		 ;Dry/Wet
		 aPitchMixL = (1 - kPitchAmt)*aPitchSrcL + kPitchAmt*aPitchL
		 aPitchMixR = (1 - kPitchAmt)*aPitchSrcR + kPitchAmt*aPitchR
    aMatrixL = aMatrixL + ((aPitchMixL - aPitchSrcL) * kSampleMode)
    aMatrixR = aMatrixR + ((aPitchMixR - aPitchSrcR) * kSampleMode)
		 aSigL = (aPitchMixL * (1 - kSampleMode)) + (aSigL * kSampleMode)
		 aSigR = (aPitchMixR * (1 - kSampleMode)) + (aSigR * kSampleMode)

; _________________
;Ringmod 
    kRingVariant chnget "ring_variant"
    kRingOn  chnget "ring_on"
    kRingWet chnget "ring_wet"
    kRingAmt = kRingOn * kRingWet

    ; Variant 0 is the current sine ring mod. Add future ring branches here.
    ; ring freq 50~1500Hz
    kRMfreq = 50 + 1450*kRingWet

    aRingSrcL = (aSigL * (1 - kSampleMode)) + aSampleRingL
    aRingSrcR = (aSigR * (1 - kSampleMode)) + aSampleRingR
    aModL oscili 1, kRMfreq
    aModR oscili 1, kRMfreq*1.01

    aRingL = aRingSrcL * aModL
    aRingR = aRingSrcR * aModR

    aRingMixL = (1 - kRingAmt)*aRingSrcL + kRingAmt*aRingL
    aRingMixR = (1 - kRingAmt)*aRingSrcR + kRingAmt*aRingR
    aMatrixL = aMatrixL + ((aRingMixL - aRingSrcL) * kSampleMode)
    aMatrixR = aMatrixR + ((aRingMixR - aRingSrcR) * kSampleMode)
    aSigL = (aRingMixL * (1 - kSampleMode)) + (aSigL * kSampleMode)
    aSigR = (aRingMixR * (1 - kSampleMode)) + (aSigR * kSampleMode)


; _________________
; 3) Blur
    kBlurVariant chnget "blur_variant"
    kBlurOn  chnget "blur_on"
    kBlurWet chnget "blur_wet"
    kBlurKnob chnget "blur_len"
    kBlurAmt = kBlurOn * kBlurWet
		
    ; Variant 0 is the current memory blur. Add future blur branches here.
		 ; Map knob (0–100) to multiple parameters
    kNorm  = kBlurKnob/100
		 kKn    = pow(max(kNorm, 1e-6), 3)
    kMemLen  = 0.02 + 0.99*kKn     ; memory window
    kFb      = 0.05 + 0.7*kKn     ; feedback amount
    kBlurCtl = 0.99*kKn           ; blur 0~1
    
    ; Memory delay
    aBlurSrcL = (aSigL * (1 - kSampleMode)) + aSampleBlurL
    aBlurSrcR = (aSigR * (1 - kSampleMode)) + aSampleBlurR
    aDL_L delayr 1.5
    aTap_L deltap3 kMemLen
           delayw aBlurSrcL + aTap_L*kFb

    aDL_R delayr 1.5
    aTap_R deltap3 kMemLen*1.02
           delayw aBlurSrcR + aTap_R*kFb

    ; Blur layer
    fL   pvsanal aTap_L, ifs, ihop, ifs, iwtype
    fR   pvsanal aTap_R, ifs, ihop, ifs, iwtype

    kBlurInt = limit(kBlurCtl, 0, 1)
    aBL  pvsynth fL
    aBR  pvsynth fR

    ; balance
    aBL = balance(aBL, aTap_L)
    aBR = balance(aBR, aTap_R)

    ; Blur dry/wet（echo + blur）
    kDryBase = 0.8 - 0.6*kBlurInt
    kWetBase = 0.2 + 0.6*kBlurInt

    aBlurL = aTap_L*kDryBase + aBL*kWetBase
    aBlurR = aTap_R*kDryBase + aBR*kWetBase

    ; blur Dry/Wet
    aBlurMixL = (1 - kBlurAmt)*aBlurSrcL + kBlurAmt*aBlurL
    aBlurMixR = (1 - kBlurAmt)*aBlurSrcR + kBlurAmt*aBlurR
    aMatrixL = aMatrixL + ((aBlurMixL - aBlurSrcL) * kSampleMode)
    aMatrixR = aMatrixR + ((aBlurMixR - aBlurSrcR) * kSampleMode)
    aSigL = (aBlurMixL * (1 - kSampleMode)) + (aSigL * kSampleMode)
    aSigR = (aBlurMixR * (1 - kSampleMode)) + (aSigR * kSampleMode)
 
; _________________
;Flanger
		 kFlVariant chnget "flanger_variant"
		 kFlOn  chnget "flanger_on"
		 kFlWet chnget "flanger_wet"
		 kFlRate chnget "lfo_rate"
		 kFlAmt = kFlOn * kFlWet

		 ; Variant 0 is the current modulated delay flanger. Add future flanger branches here.
		 ; LFO Speed: 0.05~5 Hz
		 kRate = 0.05 + kFlRate * 9.95

		 ; Depth: 1~15 ms
		 kDepth = 0.001 + kFlWet*0.014

		 ; LFO
		 kLFO  oscili kDepth, kRate

		 ; Delay lines
    aFlangerSrcL = (aSigL * (1 - kSampleMode)) + aSampleFlangerL
    aFlangerSrcR = (aSigR * (1 - kSampleMode)) + aSampleFlangerR
		 aDLFL delayr 0.03
		 aTapFL deltap 0.005 + kLFO
        delayw aFlangerSrcL + aTapFL*0.3

		 aDLFR delayr 0.03
		 aTapFR deltap 0.005 + kLFO*1.01
        delayw aFlangerSrcR + aTapFR*0.3

		 aFlL = aTapFL
		 aFlR = aTapFR

		 aFlMixL = (1 - kFlAmt)*aFlangerSrcL + kFlAmt*aFlL
		 aFlMixR = (1 - kFlAmt)*aFlangerSrcR + kFlAmt*aFlR
    aMatrixL = aMatrixL + ((aFlMixL - aFlangerSrcL) * kSampleMode)
    aMatrixR = aMatrixR + ((aFlMixR - aFlangerSrcR) * kSampleMode)
		 aSigL = (aFlMixL * (1 - kSampleMode)) + (aSigL * kSampleMode)
		 aSigR = (aFlMixR * (1 - kSampleMode)) + (aSigR * kSampleMode)

; _________________
;ATS Cross spectral layer
    kAtsOn chnget "ats_on"
    kAtsWet chnget "ats_wet"
    kAtsMorph chnget "ats_morph"
    kAtsSpeed chnget "ats_speed"

    kAtsAmt = limit(kAtsOn, 0, 1) * limit(kAtsWet, 0, 1)

    aAtsLayer init 0
    aAtsSrcL = (aSigL * (1 - kSampleMode)) + aSampleAtsL
    aAtsSrcR = (aSigR * (1 - kSampleMode)) + aSampleAtsR
    if (kAtsAmt > 0.001) then
        SAssets strget 2
        SBeats sprintf "%s/beats.ats", SAssets
        SFox sprintf "%s/fox.ats", SAssets

        ; ATScross is file-analysis based, so live audio gates and blends the generated spectral layer.
        aAtsInput = (aAtsSrcL + aAtsSrcR) * 0.5
        kAtsInputRms rms aAtsInput
        kAtsGate portk limit(kAtsInputRms * 7, 0, 1), 0.05
        kAtsSpeed = limit(kAtsSpeed, 0.1, 2)
        kAtsPhase phasor kAtsSpeed / 4
        kAtsTime = kAtsPhase * 3.85
        kAtsMorph = limit(kAtsMorph, 0, 1)
        kAtsCross = 0.05 + (0.95 * kAtsMorph)
        kAtsThreshold = 0.004 - (0.0035 * kAtsMorph)

        ATSbufread kAtsTime, 1, SFox, 20
        aAtsLayer ATScross kAtsTime, 2, SBeats, 1, kAtsCross, kAtsThreshold, 140
        aAtsLayer = tanh(aAtsLayer * 2.2) * kAtsGate
    endif

    aAtsWetL = (aAtsSrcL * 0.72) + (aAtsLayer * 0.58)
    aAtsWetR = (aAtsSrcR * 0.72) + (aAtsLayer * 0.58)
    aAtsMixL = (1 - kAtsAmt) * aAtsSrcL + kAtsAmt * aAtsWetL
    aAtsMixR = (1 - kAtsAmt) * aAtsSrcR + kAtsAmt * aAtsWetR
    aMatrixL = aMatrixL + ((aAtsMixL - aAtsSrcL) * kSampleMode)
    aMatrixR = aMatrixR + ((aAtsMixR - aAtsSrcR) * kSampleMode)
    aSigL = (aAtsMixL * (1 - kSampleMode)) + (aSigL * kSampleMode)
    aSigR = (aAtsMixR * (1 - kSampleMode)) + (aSigR * kSampleMode)

; _________________
;LOW / MID / HIGH EQ
    aSigL = (aSigL * (1 - kSampleMode)) + (aMatrixL * kSampleMode)
    aSigR = (aSigR * (1 - kSampleMode)) + (aMatrixR * kSampleMode)

		 kLowdB   chnget "lowEQ"
		 kMiddB   chnget "midEQ"
		 kHighdB  chnget "highEQ"

		; 0.5 neutral
;		 kLowGain  = (kLow  * 2)
;		 kMidGain  = (kMid  * 2)
;		 kHighGain = (kHigh * 2)
		 kLowGain  = ampdb(kLowdB)   ; -12~+12 dB 
		 kMidGain  = ampdb(kMiddB)
		 kHighGain = ampdb(kHighdB)

		; LOW 20~200 Hz
		 aLowL  butterlp aSigL, 200					;try vclpf
		 aLowR  butterlp aSigR, 200

		; HIGH 5k~20k Hz
		 aHighL butterhp aSigL, 5000
		 aHighR butterhp aSigR, 5000

		; MID by removing low & high
		 aMidL = aSigL - aLowL - aHighL
		 aMidR = aSigR - aLowR - aHighR

		 aEQ_L = aLowL*kLowGain + aMidL*kMidGain + aHighL*kHighGain
		 aEQ_R = aLowR*kLowGain + aMidR*kMidGain + aHighR*kHighGain

		 aSigL = aEQ_L
		 aSigR = aEQ_R
		 
		 
    ; Remove sub buildup after EQ and effects, then duck if low-end energy starts running away.
    aSigL dcblock2 aSigL
    aSigR dcblock2 aSigR
    aSigL butterhp aSigL, 55
    aSigR butterhp aSigR, 55

    aGuardMono = (aSigL + aSigR) * 0.5
    aGuardLow butterlp aGuardMono, 180
    kLowRms rms aGuardLow
    kLowRisk = limit((kLowRms - 0.05) * 9, 0, 1)
    kFeedbackGainTarget = 1 - (0.65 * kLowRisk)
    kFeedbackGain portk kFeedbackGainTarget, 0.08

; Final Out Put
    ; A short fade-in avoids the instant speaker jump that can seed a feedback loop.
    kStartGain linseg 0, 1.2, 1
    aOutL = aSigL * 0.42 * kFeedbackGain * kStartGain
		 aOutR = aSigR * 0.42 * kFeedbackGain * kStartGain
    
    aOutL = tanh(aOutL)
    aOutR = tanh(aOutR)

    ; Master volume feeds the limiter so users can push or pull the protected output bus.
    kMasterVolume chnget "master_volume"
    kMasterVolume = portk(limit(kMasterVolume, 0, 1), 0.03)
    aOutL = aOutL * kMasterVolume
    aOutR = aOutR * kMasterVolume

    ; The final limiter protects the actual output bus while keeping telemetry honest.
    kLimiterThresholdDb chnget "limiter_threshold"
    kLimiterCeilingDb chnget "limiter_ceiling"
    kLimiterAttackMs chnget "limiter_attack"
    kLimiterReleaseMs chnget "limiter_release"

    kLimiterThresholdDb = limit(kLimiterThresholdDb, -24, 0)
    kLimiterCeilingDb = limit(kLimiterCeilingDb, -12, 0)
    kLimiterAttackSec = max(limit(kLimiterAttackMs, 0.1, 30) / 1000, 0.0001)
    kLimiterReleaseSec = max(limit(kLimiterReleaseMs, 20, 1000) / 1000, 0.001)

    iLimiterLookahead = 0.005
    aLimitLookL delay aOutL, iLimiterLookahead
    aLimitLookR delay aOutR, iLimiterLookahead

    kLimiterPeakL peak aOutL
    kLimiterPeakR peak aOutR
    kLimiterPeak = max(kLimiterPeakL, kLimiterPeakR)
    kLimiterPeakDb = 20 * log10(max(kLimiterPeak, 0.000001))

    kLimiterDesiredDb = kLimiterPeakDb
    if (kLimiterPeakDb > kLimiterThresholdDb) then
        kLimiterOverDb = kLimiterPeakDb - kLimiterThresholdDb
        kLimiterDesiredDb = kLimiterThresholdDb + (kLimiterOverDb / 20)
    endif
    kLimiterDesiredDb = min(kLimiterDesiredDb, kLimiterCeilingDb)
    kLimiterGainTarget = ampdb(kLimiterDesiredDb - kLimiterPeakDb)
    kLimiterGainTarget = limit(kLimiterGainTarget, 0, 1)

    kLimiterGain init 1
    iLimiterControlPeriod = ksmps / sr
    if (kLimiterGainTarget < kLimiterGain) then
        kLimiterCoeff = exp(-iLimiterControlPeriod / kLimiterAttackSec)
    else
        kLimiterCoeff = exp(-iLimiterControlPeriod / kLimiterReleaseSec)
    endif
    kLimiterGain = kLimiterGainTarget + ((kLimiterGain - kLimiterGainTarget) * kLimiterCoeff)

    kLimiterCeilingAmp = ampdb(kLimiterCeilingDb)
    aOutL = limit(aLimitLookL * kLimiterGain, -kLimiterCeilingAmp, kLimiterCeilingAmp)
    aOutR = limit(aLimitLookR * kLimiterGain, -kLimiterCeilingAmp, kLimiterCeilingAmp)

    ; Send lightweight probes from the final output only, so visuals follow the real processed signal.
    aMono = (aOutL + aOutR) * 0.5
    kRmsL rms aOutL
    kRmsR rms aOutR
    kRms = (kRmsL + kRmsR) * 0.5
    kPeakL peak aOutL
    kPeakR peak aOutR
    kPeak = max(kPeakL, kPeakR)
    kClip = 0
    if (kPeak > 0.98) then
        kClip = 1
    endif

    ; A small log-spaced filter bank gives the browser an EQ8-style spectrum without streaming audio.
    aBand00 butterlp aMono, 55
    aBand01 butterbp aMono, 70, 42
    aBand02 butterbp aMono, 110, 66
    aBand03 butterbp aMono, 170, 102
    aBand04 butterbp aMono, 260, 156
    aBand05 butterbp aMono, 400, 240
    aBand06 butterbp aMono, 620, 372
    aBand07 butterbp aMono, 950, 570
    aBand08 butterbp aMono, 1450, 870
    aBand09 butterbp aMono, 2200, 1320
    aBand10 butterbp aMono, 3300, 1980
    aBand11 butterbp aMono, 5000, 3000
    aBand12 butterbp aMono, 7600, 4560
    aBand13 butterbp aMono, 11500, 6900
    aBand14 butterbp aMono, 16000, 7200
    aBand15 butterhp aMono, 16500

    kBand00 rms aBand00
    kBand01 rms aBand01
    kBand02 rms aBand02
    kBand03 rms aBand03
    kBand04 rms aBand04
    kBand05 rms aBand05
    kBand06 rms aBand06
    kBand07 rms aBand07
    kBand08 rms aBand08
    kBand09 rms aBand09
    kBand10 rms aBand10
    kBand11 rms aBand11
    kBand12 rms aBand12
    kBand13 rms aBand13
    kBand14 rms aBand14
    kBand15 rms aBand15

    ; Use min/max windows instead of single-point sampling to avoid aliased, misleading waveforms.
    kWaveTrig metro 60
    kWaveMin max_k aMono, kWaveTrig, 3
    kWaveMax max_k aMono, kWaveTrig, 2
    kMeterTrig metro 30
    OSCsend kWaveTrig, "127.0.0.1", 7778, "/ol/telemetry/wave", "ff", kWaveMin, kWaveMax
    OSCsend kMeterTrig, "127.0.0.1", 7778, "/ol/telemetry/meter", "fff", kRms, kPeak, kClip
    OSCsend kMeterTrig, "127.0.0.1", 7778, "/ol/telemetry/spectrum", "ffffffffffffffff", kBand00,kBand01,kBand02,kBand03,kBand04,kBand05,kBand06,kBand07,kBand08,kBand09,kBand10,kBand11,kBand12,kBand13,kBand14,kBand15

    outs aOutL, aOutR
endin

</CsInstruments>
<CsScore>
; Start both instruments for one hour (3600 seconds)
i "InitDefaults" 0 0.01
i "OSCListen" 0 3600
i "Live"      0 3600
</CsScore>
</CsoundSynthesizer>






































<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>784</width>
 <height>817</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="background">
  <r>253</r>
  <g>244</g>
  <b>253</b>
 </bgcolor>
 <bsbObject type="BSBKnob" version="2">
  <objectName>knob0</objectName>
  <x>333</x>
  <y>331</y>
  <width>80</width>
  <height>80</height>
  <uuid>{3c0dbee7-0d71-44dd-b2b1-7e87f1d98ad0}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>100.00000000</maximum>
  <value>100.00000000</value>
  <mode>lin</mode>
  <mouseControl act="">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
  <color>
   <r>168</r>
   <g>0</g>
   <b>235</b>
  </color>
  <textcolor>#512900</textcolor>
  <border>0</border>
  <borderColor>#512900</borderColor>
  <showvalue>true</showvalue>
  <flatstyle>true</flatstyle>
  <integerMode>false</integerMode>
 </bsbObject>
 <bsbObject type="BSBKnob" version="2">
  <objectName>knob1</objectName>
  <x>461</x>
  <y>402</y>
  <width>80</width>
  <height>80</height>
  <uuid>{2fe046a5-bde1-403e-811e-e4beea7c5bb7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description>iMode</description>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <textcolor>#000000</textcolor>
  <border>0</border>
  <borderColor>#512900</borderColor>
  <showvalue>true</showvalue>
  <flatstyle>true</flatstyle>
  <integerMode>false</integerMode>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>blur_len</objectName>
  <x>293</x>
  <y>512</y>
  <width>20</width>
  <height>100</height>
  <uuid>{0594f5d6-2f38-402f-881a-717738f76b98}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>100.00000000</maximum>
  <value>100.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>309</x>
  <y>705</y>
  <width>80</width>
  <height>25</height>
  <uuid>{c6b9734b-d1aa-49dc-8bf7-5d1e2b105140}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>label3</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>347</x>
  <y>648</y>
  <width>80</width>
  <height>25</height>
  <uuid>{a0a933ea-d05d-4941-8176-dd680f0e9527}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>Knob1</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>302</x>
  <y>620</y>
  <width>80</width>
  <height>25</height>
  <uuid>{4bf3c67a-24a1-4d24-9a9f-790a98a2a7f7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>Knob1</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>pitch_on</objectName>
  <x>66</x>
  <y>40</y>
  <width>20</width>
  <height>100</height>
  <uuid>{7320c9dd-d0d9-438e-8227-e9be28984203}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>76</x>
  <y>152</y>
  <width>80</width>
  <height>25</height>
  <uuid>{94ffe3b8-4515-44ec-97fc-10b3387b901d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>pitch_on</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>pitch_wet</objectName>
  <x>134</x>
  <y>72</y>
  <width>20</width>
  <height>100</height>
  <uuid>{976985ce-87a3-40b1-8f0e-c32e0dfcd772}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>143</x>
  <y>177</y>
  <width>80</width>
  <height>25</height>
  <uuid>{d1080b76-bf81-48b3-b1fb-f68ad1310047}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>pitch_wet</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>pitch_semitone</objectName>
  <x>211</x>
  <y>50</y>
  <width>20</width>
  <height>100</height>
  <uuid>{c03300c3-900d-49c9-b64e-1e9d7b78f862}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>24.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>205</x>
  <y>156</y>
  <width>80</width>
  <height>25</height>
  <uuid>{d640f23f-42bd-45f8-8c27-18b5a28d8ef5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>pitch_semitone</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>ring_on</objectName>
  <x>86</x>
  <y>263</y>
  <width>20</width>
  <height>100</height>
  <uuid>{f34f10e2-67a4-4b5c-9517-fa009f1420f1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>78</x>
  <y>376</y>
  <width>80</width>
  <height>25</height>
  <uuid>{1415765e-5ecb-4eab-a418-cca6b3ab185f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>ring_on</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>ring_wet</objectName>
  <x>152</x>
  <y>268</y>
  <width>20</width>
  <height>100</height>
  <uuid>{ec821332-73a9-4789-b294-6a123ced6a32}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>142</x>
  <y>377</y>
  <width>80</width>
  <height>25</height>
  <uuid>{158130f7-69c6-49e1-be9d-dc8df481d978}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>ring_wet</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>blur_on</objectName>
  <x>85</x>
  <y>438</y>
  <width>20</width>
  <height>100</height>
  <uuid>{5e8710ba-7f48-4eea-96f0-5320000bf546}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>blur_wet</objectName>
  <x>156</x>
  <y>440</y>
  <width>20</width>
  <height>100</height>
  <uuid>{85d87dc9-e8d1-4df6-8d6f-166006a21ba6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>89</x>
  <y>553</y>
  <width>80</width>
  <height>25</height>
  <uuid>{6156080d-ca7e-48dc-8971-549bfd9f763a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>hpf_on</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>164</x>
  <y>552</y>
  <width>80</width>
  <height>25</height>
  <uuid>{f87e3e0e-549d-4ac0-a573-ec4c151c1c90}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>hpf_wet</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBKnob" version="2">
  <objectName>highEQ</objectName>
  <x>448</x>
  <y>110</y>
  <width>80</width>
  <height>80</height>
  <uuid>{ede326a0-e8ff-4b5f-9ee1-242c46b22e89}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>-12.00000000</minimum>
  <maximum>12.00000000</maximum>
  <value>0.20640000</value>
  <mode>lin</mode>
  <mouseControl act="">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
  <color>
   <r>245</r>
   <g>124</g>
   <b>0</b>
  </color>
  <textcolor>#512900</textcolor>
  <border>0</border>
  <borderColor>#512900</borderColor>
  <showvalue>true</showvalue>
  <flatstyle>true</flatstyle>
  <integerMode>false</integerMode>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>459</x>
  <y>196</y>
  <width>80</width>
  <height>25</height>
  <uuid>{a653f301-cdb0-4aff-af89-20694bef28ec}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>highEQ</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBKnob" version="2">
  <objectName>midEQ</objectName>
  <x>564</x>
  <y>141</y>
  <width>80</width>
  <height>80</height>
  <uuid>{b39c5d3a-d7f1-42fd-8d9b-6fa7f17c2221}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>-12.00000000</minimum>
  <maximum>12.00000000</maximum>
  <value>-0.01440000</value>
  <mode>lin</mode>
  <mouseControl act="">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
  <color>
   <r>245</r>
   <g>124</g>
   <b>0</b>
  </color>
  <textcolor>#512900</textcolor>
  <border>0</border>
  <borderColor>#512900</borderColor>
  <showvalue>true</showvalue>
  <flatstyle>true</flatstyle>
  <integerMode>false</integerMode>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>575</x>
  <y>231</y>
  <width>80</width>
  <height>25</height>
  <uuid>{e51df8ee-9ae4-4fce-a169-ddc5acc7a51d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>midEQ</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBKnob" version="2">
  <objectName>lowEQ</objectName>
  <x>684</x>
  <y>141</y>
  <width>80</width>
  <height>80</height>
  <uuid>{c7a820d6-0ab7-42c5-bdb9-8846ffea3a61}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>-12.00000000</minimum>
  <maximum>12.00000000</maximum>
  <value>-0.08880000</value>
  <mode>lin</mode>
  <mouseControl act="">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
  <color>
   <r>245</r>
   <g>124</g>
   <b>0</b>
  </color>
  <textcolor>#512900</textcolor>
  <border>0</border>
  <borderColor>#512900</borderColor>
  <showvalue>true</showvalue>
  <flatstyle>true</flatstyle>
  <integerMode>false</integerMode>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>704</x>
  <y>227</y>
  <width>80</width>
  <height>25</height>
  <uuid>{c1e97049-5654-4c9a-91de-5993f2abdd48}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>lowEQ</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>flanger_on</objectName>
  <x>65</x>
  <y>657</y>
  <width>20</width>
  <height>100</height>
  <uuid>{88de8176-0beb-4be1-a542-84229dca63af}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>59</x>
  <y>792</y>
  <width>80</width>
  <height>25</height>
  <uuid>{c214e13c-c51a-482d-9ccf-947c500adb85}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>flanger_on</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>flanger_wet</objectName>
  <x>139</x>
  <y>657</y>
  <width>20</width>
  <height>100</height>
  <uuid>{0e363ad1-8049-4db9-898f-ea95093ec1c5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>132</x>
  <y>772</y>
  <width>80</width>
  <height>25</height>
  <uuid>{c1a184c5-866e-4889-8165-e92f01334d18}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>flanger_wet</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>lfo_rate</objectName>
  <x>199</x>
  <y>665</y>
  <width>20</width>
  <height>100</height>
  <uuid>{2ed17974-5b4a-4c4d-8c93-3d4dec190ca4}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>196</x>
  <y>778</y>
  <width>80</width>
  <height>25</height>
  <uuid>{0c5a0677-e2aa-4b4d-9dfd-54db46c9c122}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <label>lfo_rate</label>
  <alignment>left</alignment>
  <valignment>top</valignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>false</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>0</borderwidth>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
