<CsoundSynthesizer>
<CsOptions>
; If using BlackHole or Loopback for virtual routing:
; use -iadc -odac directly.
-odac -iadc ;-b128 -B512
</CsOptions>
<CsInstruments>

sr     = 44100
ksmps  = 64
nchnls = 2
nchnls_i = 2
0dbfs  = 1


;;channels

chn_k "pitch_on", 1
chn_k "pitch_wet", 1

chn_k "ring_on", 1
chn_k "ring_wet", 1

chn_k "blur_on", 1 
chn_k "blur_len", 1         
chn_k "blur_wet", 1


chn_k "flanger_on", 1
chn_k "flanger_wet", 1
chn_k "lfo_rate", 1 

;EQ
chn_k "highEQ", 1
chn_k "midEQ", 1
chn_k "lowEQ", 1


; OSC Listener
; Receives parameters from OnLive 音 (127.0.0.1:7777)
instr OSCListen
    ihOSC OSCinit 7777
    
    kVal init 0

		 ;_______________________
    ;Pitch
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
    

endin

; ___________________________________________________________
; 											Main Live Instrument 
; ___________________________________________________________
instr Live
		 
		 ; channel Input Setting
    ainL inch 1
    ainR inch 2
		 if (nchnls_i < 2) then
        ainR = ainL 
;        print nchnls_i
;        prints "_____________________________________"
    endif
    
    ; Normalize input to -6dB headroom
    aL = ainL * 0.5
    aR = ainR * 0.5

		; Basic Dry Sound
		 aSigL = aL
		 aSigR = aR

    ;PVS
		 ifs    = 2048
		 ihop   = 256
		 iwin   = 2048      
		 iwtype = 1 

; 										 					EFFECTS 
; ___________________________________________________________

; _________________
;Pitch Shift Effect 

		 kPitchOn  chnget "pitch_on"
    kPitchWet chnget "pitch_wet"    
    kPitchAmt = kPitchOn * kPitchWet
    
    ; semitone slider (-12~12)
		 kSemi chnget "pitch_semitone"
		 
		 ; ratio = 2^(semitone/12)
		 kRatio = pow(2, kSemi/12)
		 
		 fPitchL pvsanal aSigL, ifs, ihop, ifs, iwtype
		 fPitchR pvsanal aSigR, ifs, ihop, ifs, iwtype
		 
		 ; pitch shift
		 fPitchL2 pvscale fPitchL, kRatio
		 fPitchR2 pvscale fPitchR, kRatio
		 
		 ;Mix
		 aPitchL pvsynth fPitchL2
		 aPitchR pvsynth fPitchR2
		 
		 ;Dry/Wet
		 aSigL = (1 - kPitchAmt)*aSigL + kPitchAmt*aPitchL
		 aSigR = (1 - kPitchAmt)*aSigR + kPitchAmt*aPitchR

; _________________
;Ringmod 
    kRingOn  chnget "ring_on"
    kRingWet chnget "ring_wet"
    kRingAmt = kRingOn * kRingWet

    ; ring freq 50~1500Hz
    kRMfreq = 50 + 1450*kRingWet

    aModL oscili 1, kRMfreq
    aModR oscili 1, kRMfreq*1.01

    aRingL = aSigL * aModL
    aRingR = aSigR * aModR

    aSigL = (1 - kRingAmt)*aSigL + kRingAmt*aRingL
    aSigR = (1 - kRingAmt)*aSigR + kRingAmt*aRingR


; _________________
; 3) Blur
    kBlurOn  chnget "blur_on"
    kBlurWet chnget "blur_wet"
    kBlurKnob chnget "blur_len"
    kBlurAmt = kBlurOn * kBlurWet
		
		 ; Map knob (0–100) to multiple parameters
    kNorm  = kBlurKnob/100
		 kKn    = pow(max(kNorm, 1e-6), 3)
    kMemLen  = 0.02 + 0.99*kKn     ; memory window
    kFb      = 0.05 + 0.7*kKn     ; feedback amount
    kBlurCtl = 0.99*kKn           ; blur 0~1
    
    ; Memory delay
    aDL_L delayr 1.5
    aTap_L deltap3 kMemLen
           delayw aSigL + aTap_L*kFb

    aDL_R delayr 1.5
    aTap_R deltap3 kMemLen*1.02
           delayw aSigR + aTap_R*kFb

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
    aSigL = (1 - kBlurAmt)*aSigL + kBlurAmt*aBlurL
    aSigR = (1 - kBlurAmt)*aSigR + kBlurAmt*aBlurR
 
; _________________
;Flanger
		 kFlOn  chnget "flanger_on"
		 kFlWet chnget "flanger_wet"
		 kFlRate chnget "lfo_rate"
		 kFlAmt = kFlOn * kFlWet

		 ; LFO Speed: 0.05~5 Hz
		 kRate = 0.05 + kFlRate * 9.95

		 ; Depth: 1~15 ms
		 kDepth = 0.001 + kFlWet*0.014

		 ; LFO
		 kLFO  oscili kDepth, kRate

		 ; Delay lines
		 aDLFL delayr 0.03
		 aTapFL deltap 0.005 + kLFO
        delayw aSigL + aTapFL*0.3

		 aDLFR delayr 0.03
		 aTapFR deltap 0.005 + kLFO*1.01
        delayw aSigR + aTapFR*0.3

		 aFlL = aTapFL
		 aFlR = aTapFR

		 aSigL = (1 - kFlAmt)*aSigL + kFlAmt*aFlL
		 aSigR = (1 - kFlAmt)*aSigR + kFlAmt*aFlR

; _________________
;LOW / MID / HIGH EQ
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
		 
		 
; Final Out Put
    aOutL = aSigL * 0.7
		 aOutR = aSigR * 0.7
    
    aOutL = tanh(aOutL)
    aOutR = tanh(aOutR)

    outs aOutL, aOutR
endin

</CsInstruments>
<CsScore>
; Start both instruments for one hour (3600 seconds)
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
