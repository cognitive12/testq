extensions [array]
globals [ sample-car car-timer start-timer stop-all SMT SST SDM SH D SS TTR sp1 sp2 sp3 lats longs distances i j k l
  services no-service-area nsa-size sp1-value sp2-value sp3-value threshold totalDistance thresholddistances calculateSMT]
turtles-own [ speed speed-limit speed-min drive-time current-service current-best-service current-signal-strength future-signal-strength
   fear-potential fear-intensity dist-from-nsa lat long expected-sp likelihood FI time-to-reach]

to setup

  clear-all
   set stop-all 0
   set start-timer 0
   set car-timer 0
   set calculateSMT 1

  ask patches [
     setup-road
     ]
  setup-milestones
  setup-turtles

 ; watch sample-car
  reset-ticks
end
to setup-milestones
  setLatLong
  ask patches [
          if(pycor = 3 and pxcor = 0)[
              set plabel pxcor ;array:item longs (pxcor / 10)
              set pcolor red
            ]
          if(pxcor = 3)[
            if(pycor = 1)[
              set plabel array:item longs i
            ]
            if(pycor = 2)[
              set plabel array:item lats i
            ]
          ]
        ]
  set i 1
  set j 0
  foreach distances
    [
      set j j + ?

        ask patches [

            if(pycor = 3 and pxcor = j)[
              set plabel pxcor ;array:item longs (pxcor / 10)
              set pcolor red
            ]
            if(pxcor = j + 3)[
            if(pycor = 1)[
              set plabel array:item longs i
            ]
            if(pycor = 2)[
              set plabel array:item lats i
            ]
          ]
        ]
      set i i + 1
    ]
; ask patches [
;    if ((pycor = 3) and ((pxcor mod 10) = 0)) [
;       ; set plabel pxcor
;        set pcolor red
;    ]

;    if(((pxcor + 7) mod 10) = 0)[
;      if(pycor = 1)[
;        set plabel array:item longs (pxcor / 10)
;        ]
;      if(pycor = 2)[
;        set plabel array:item lats (pxcor / 10)
;        ]
;      ]
;    if((pycor = 9) and (pxcor = (no-service-area + nsa-size - ceiling (nsa-size / 2) + 5 )))[
;     set plabel (word "No service of " (services) " in this area")
;    ]
;  ]
end
to setup-road  ;; patch procedure
  if (pycor < 7) and (pycor > 3) [ set pcolor white
     ;ask patches[
       ;; set plabel pxcor
     ; ]
;     if(no-service-area < 0)[set no-service-area 0]
;     if (no-service-area > 90)[set no-service-area 90]
;     if(nsa-size + no-service-area > 100)[set nsa-size 100 - no-service-area]
;    if ((pxcor = no-service-area or pxcor > no-service-area) and (pxcor < (no-service-area + nsa-size)) and (pxcor mod 2) = 0) [
;      set pcolor yellow


  ;   ]
   ]

  ;; if ((pycor = 2) and ((pxcor mod 10) = 0)) [ set pcolor yellow

  ; set plabel 'car'
  ;   ]

end
to setLatLong
  ;set lats array:from-list [33.144508 33.145677 33.145288 33.146200 33.146318 33.146896 33.140682 33.138557 33.138852 33.138352 33.133555 33.124631]
  set lats array:from-list [33.144552 33.144449 33.144377 33.144323 33.144235 33.144163 33.144132 33.144076 33.144051 33.144029 33.144043 33.144066]
  set longs array:from-list [73.745719 73.745606 73.745550 73.745475 73.745386 73.745300 73.745203 73.745064 73.744965 73.744850 73.744742 73.744607]
  set sp1 array:from-list [-100 -60 -50 -65 -80 -45 -65 -75 -90 -70 -50]
  set sp2 array:from-list [-90 -70 -60 -50 -30 -50 -95 -75 -50 -70 -60]
  set sp3 array:from-list [-80 -50 -50 -70 -50 -75 -85 -100 -40 -70 -65]
 ;let distances array:from-list [308.4 2507 254 385.2 118.4 805.4 1089 1185 351.7 597.7 109.3]
  set thresholddistances array:from-list [15 10 10 12 11 10 14 10 11 13 12]
  set distances [15 10 10 12 11 10 14 10 11 13 12]
  set services array:from-list["Ufone" "Telenor"  "Zong"]

end
to setup-turtles

  set-default-shape turtles "car"
    create-turtles 1

     ask turtle 0
    [
       if random-start-position[
        set car-start-position  (precision random-xcor 0)
       ]
       set color red
       set xcor car-start-position ;;random-xcor
       set ycor 5
       set heading 90 ; 270 backward
       set car-timer 0
       set drive-time 0
       set fear-potential 0
       set fear-intensity 0
       set dist-from-nsa 0
       set current-service services-label
      ; set current-signal-strength
       set lat array:item lats (car-start-position / 10)
       set long array:item longs (car-start-position / 10)
       ;;; set initial speed to be in range 0.1 to 1.0
       set speed speed-of-car
       set speed-limit  1
       set speed-min  0
    ]

  set sample-car turtle 0 ;;one-of turtles
  ask sample-car [ set color red ]

end

; this procedure is needed so when we click "Setup" we
; don't end up with any two cars on the same patch
to separate-cars  ;; turtle procedure
  if any? other turtles-here
    [ fd 1
      separate-cars]
end

to go
  if(start-timer = 0 )[set start-timer (precision timer 3)]
    if(stop-all = 0)[
      ;findDistanceFromNSA
      ;findMobilityTimeWithMega
      calculateFear
   ;; if there is a car right ahead of you, match its speed then slow down
  ask turtle 0 [
    ;if(xcor < 10)
       set lat array:item lats (xcor / 10)
       set long array:item longs (xcor / 10)
    let car-ahead one-of turtles-on patch-ahead 1
    ifelse (stop-car and (xcor = car-stop-position or (xcor >= car-stop-position + 0.9 ) ) )
      [ set speed 0
        set stop-all 1

         ]
      ; otherwise, speed up
      [
        set car-timer (precision timer 3)
        set drive-time (precision (car-timer - start-timer) 3)
         speed-up-car
          ]
    ;;; don't slow down below speed minimum or speed up beyond speed limit
    if speed < speed-min  [ set speed speed-min ]
    if speed > speed-limit   [ set speed speed-limit ]
    fd speed ]
  ;;;;;;;;;;;;;;;;;;;;;;Report Calling;;;;;;;;;;;;;;;
  let report-fear fearIntensity
  let report-distance distance1
  let report-current-service currentService
  let report-service-strength currentSignalStrength
    tick
    ]
; set timer tick
end

;; turtle (car) procedure
;to slow-down-car  [car-ahead]
  ;; slow down so you are driving more slowly than the car ahead of you
 ; set speed [speed] of car-ahead - deceleration
;end


;; turtle (car) procedure
to speed-up-car
  ifelse increase-speed [
  set speed speed + acceleration][
  set speed speed ;speed-of-car
  ]
end
to findDistanceFromNSA
  ask turtle 0[
;    ifelse(xcor > no-service-area and xcor < no-service-area + nsa-size )[set dist-from-nsa 0
;      set D 0 ]
;    [ifelse(xcor < no-service-area)[ set dist-from-nsa no-service-area - xcor][
;     set dist-from-nsa no-service-area + nsa-size - xcor
;     set D no-service-area + nsa-size - xcor
;     ]
;   ]
    findRemainingDistance

  ]

end
to findRemainingDistance
  set i 0
  set j 0
  set k 0
  set l 0
  foreach distances
    [
      ;;set l

      set j j + ?
      ifelse(xcor <= j and k = 0)[
        set k 1
        set dist-from-nsa j - xcor
        set time-to-reach (dist-from-nsa / speed)
      ][if(xcor > j )[
        set i i + 1
        set totalDistance ?
        ]

      ]
    ]
end
to findAvailableSP
  set sp1-value array:item sp1 (i + 1)
  set sp2-value array:item sp2 (i + 1)
  set sp3-value array:item sp3 (i + 1)
end
to findbestSP
  ;print current-service
  ifelse(current-service = "Ufone")[
    set current-signal-strength array:item sp1 i
    set future-signal-strength array:item sp1 (i + 1)
   if(sp1-value > -50)[set expected-sp "Ufone"]
   if(sp1-value <= -50 and sp2-value > sp3-value and sp2-value > -50)[set expected-sp "Telenor" ]
   if(sp1-value <= -50 and sp3-value > sp2-value and sp3-value > -50)[set expected-sp "Zong" ]
  ][
    ifelse(current-service = "Telenor")[
      set current-signal-strength array:item sp2 i
      set future-signal-strength array:item sp2 (i + 1)
      if(sp2-value > -50)[set expected-sp "Telenor"]
      if(sp2-value <= -50 and sp1-value > sp3-value and sp1-value > -50)[set expected-sp "Ufone" ]
      if(sp2-value <= -50 and sp3-value > sp1-value and sp3-value > -50)[set expected-sp "Zong" ]
    ][
     set current-signal-strength array:item sp3 i
     set future-signal-strength array:item sp3 (i + 1)
      if(sp3-value > -50)[set expected-sp "Zong"]
      if(sp3-value <= -50 and sp1-value > sp2-value and sp1-value > -50)[set expected-sp "Ufone" ]
      if(sp3-value <= -50 and sp2-value > sp1-value and sp2-value > -50)[set expected-sp "Telenor" ]
    ]
  ]
; let x array:item sp1 i
; let y array:item sp2 i
; let z array:item sp3 i
 set ufone-signal-strength array:item sp1 i
 set telenor-signal-strength array:item sp2 i
 set zong-signal-strength array:item sp3 i
 ;let SHs array:from-list [ 'a' 'b' 'c']

; print (word "Ufone" (a) " ")
; print (word "Telenor" (b) " ")
; print (word "Zong" (c) " ")
end
to findcurrentbestSP
  ifelse(ufone-signal-strength > telenor-signal-strength and ufone-signal-strength > zong-signal-strength)[
    set current-best-service "Ufone"
  ][
    ifelse(ufone-signal-strength < telenor-signal-strength and telenor-signal-strength > zong-signal-strength)[
      set current-best-service "Telenor"
    ][
     set current-best-service "Zong"
    ]
  ]
end
to findMobilityTimeWithMega[shift]

  ifelse(shift = [1])[
    calculateSST[1]
    calculateSDM
    calculateSH[1]
    ][
    calculateSST[0]
    calculateSDM
    calculateSH[0]
    ]


  set SMT (precision (SST + SDM + SH) 3)
end
to calculateSST[sense]
  ;let SSTs array:from-list [ 0.40 0.41 0.39 0.42 0.40]
  ifelse(Mode = "GA")[
     set SST GaST
   ; set SSTs array:from-list [ 0.40 0.41 0.43 0.42 0.41]
  ][
     set SST MegaST
  ]

  ;let SSTs [ 0.40 0.41 0.39 0.42 0.40]
 ; let index random 4
  ;let c array:item SSTs index

  if(sense = [1])[findAvailableSP]
end
to calculateSH [shift]

  ;let SHs array:from-list [ 1 1.05 1.06 0.95 1.02]
  ifelse(Mode = "GA")[
    set SH GaHO
   ; set SHs array:from-list [ 1 1.15 1.13 1.2 1.21]
  ][
    set SH MegaHO
  ]
  ;let SHs [1 1.05 1.10 0.55 1.15]
 ; let index random 4
  ;let c array:item SHs index

  ;let SHs [ 1 1.05 1.10 0.55 1.15]
  ;set index random 4
  ;let c item SHs index
  ;set SH c

  if(shift = [1] and expected-sp != 0)[set current-service expected-sp]  ;;and dist-from-nsa <= 1  ; and time-to-reach > SMT
  if(shift = [2] and expected-sp != 0 and time-to-reach > SMT)[
    findcurrentbestSP
    set current-service current-best-service
    ]  ;;in case failure
end

to calculateSDM

  ;let SDMs array:from-list [ 1.25 1.30 1.35 1.20 1.19]
  ifelse(Mode = "GA")[
    set SDM GaOT
   ; set SDMs array:from-list [ 1.65 1.62 1.70 1.71 1.69]
  ][
    set SDM MegaOT
  ]
  ;let index random 4
  ;let c array:item SDMs index

  findbestSP
end
to calculateThreshold
  set totalDistance  array:item thresholddistances i
  if(totalDistance > 0)[
  set threshold ((totalDistance - dist-from-nsa) / totalDistance)
  ]
  if(threshold > 1)[
    set threshold 1
    ]
  if(threshold < 0)[
    set threshold 0
    ]
end
to calculateFear
  ask turtle 0[

    findDistanceFromNSA
    calculateThreshold
   ; findMobilityTimeWithMega[0]
       ;set fear-potential ((UD + LH + IG) / 3)
       calculateLikelihoodAndFI
      ;; if(calculateSMT = 1)[
           findMobilityTimeWithMega[0]
        ;;   set calculateSMT 0
        ;;   ]
       ifelse(FI >= 0.2 and FI < 0.3)[
         ;print "calculateSST"
         calculateSST[1]
         ][
         ifelse(FI >= 0.3 and FI < 0.5)[
           ; print "calculateSDM"
          ; calculateSST
         if(time-to-reach >= SMT)[
             calculateSST[1]
            ]
           calculateSDM
           ][
           if(FI >= 0.5 and dist-from-nsa < 1)[
          ;   print "calculateSH"
             ;findMobilityTimeWithMega[1]
             if(time-to-reach >= SMT)[
               calculateSST[1]
               calculateSDM
             ]
            ; calculateSST
           ;  calculateSDM
             calculateSH[1]

             ;set calculateSMT 1
             ]

           ]
         ]
         if(current-signal-strength <= -50 and time-to-reach >= SMT)[
           print "Failed to shift spectrum on time"
           calculateSST[1]
           calculateSH [2]
          ; set calculateSMT 1
           ]
    ]

 ;if((SS < 25 and SS > 0) and (D < 25 and D > 0))
end

to calculateLikelihoodAndFI

 if ( threshold >= TH5)
 [
   set LH (1)
   set IG (1)
   set UD (1)
   set fear-potential ((UD + LH + IG)/ 3)
   ifelse H-FI-On-NSA [ set FI(1) ][
     set FI( fear-potential - FT)
     ]
 ]
 if ( threshold >= TH4 and threshold < TH5)
 [
   set LH (0.7)
   set IG (0.7)
   set UD (0.7)
   set fear-potential ((UD + LH + IG)/ 3)
   set FI( fear-potential - FT)
   if(FI < 0)[set FI 0 ]

 ]
 if ( threshold >= TH3 and threshold < TH4)
 [
   set LH (0.5)
   set IG (0.5)
   set UD (0.5)
   set fear-potential ((UD + LH + ig)/ 3)
   set FI(  fear-potential - FT)
   if(FI < 0)[set FI 0 ]
 ]
 if ( threshold >= TH2 and threshold < TH3)
 [
   set LH (0.25)
   set IG (0.25)
   set UD (0.25)
   set fear-potential ((UD + LH + ig)/ 3)
   set FI(  fear-potential - FT)
   if(FI < 0)[set FI 0 ]
 ]
 if ( threshold >= TH1 and threshold < TH2)
 [
   set LH (0.1)
   set IG (0.1)
   set UD (0.1)
   set fear-potential ((UD + LH + ig)/ 3)
   set FI(  fear-potential - FT)
   if(FI < 0)[set FI 0 ]
 ]
; if ( threshold < TH1 )
; [
;   set LH (0)
;   set IG (0)
;   set UD (0)
;   set fear-potential ((UD + LH + IG)/ 3)
;   set FI( fear-potential - FT)
;   if(FI < 0)[set FI 0 ]
; ]

end
 to-report currentService

  report [current-service] of turtle 0

end
  to-report currentSignalStrength

  report [current-signal-strength] of turtle 0

end
  to-report fearIntensity
    report [FI] of turtle 0
  end
   to-report distance1
    report [threshold] of turtle 0
  end

; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
16
325
1321
513
-1
-1
12.104
1
10
1
1
1
0
1
0
1
0
106
0
12
1
1
1
ticks
30.0

BUTTON
12
18
84
59
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
98
18
169
58
Start
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
985
50
1118
83
speed-of-car
speed-of-car
0
1
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
985
87
1119
120
acceleration
acceleration
0
1
0.19
.01
1
NIL
HORIZONTAL

PLOT
507
10
948
167
Car speeds
time
speed
0.0
300.0
0.0
1.1
true
true
"" ""
PENS
"red car" 1.0 0 -2674135 true "" "plot [speed] of sample-car"
"Speed" 1.0 0 -10899396 true "" "plot max [speed] of turtles"

MONITOR
13
80
113
125
car speed
ifelse-value any? turtles\n  [  word (precision ([speed] of sample-car * 100000 / 3600) 3) \"m/s\"  ]\n  [  0 ]
3
1
11

SWITCH
984
12
1118
45
increase-speed
increase-speed
0
1
-1000

SLIDER
987
161
1120
194
car-start-position
car-start-position
0
100
4
1
1
NIL
HORIZONTAL

SLIDER
987
235
1121
268
car-stop-position
car-stop-position
0
100
68
1
1
NIL
HORIZONTAL

SWITCH
987
198
1120
231
stop-car
stop-car
0
1
-1000

CHOOSER
1130
10
1316
55
services-label
services-label
"Ufone" "Telenor" "Zong"
1

MONITOR
1232
61
1318
106
Current Service
[current-service] of turtle 0
17
1
11

INPUTBOX
1232
113
1318
173
ufone-signal-strength
-60
1
0
Number

INPUTBOX
1232
175
1318
235
telenor-signal-strength
-70
1
0
Number

INPUTBOX
1232
237
1320
297
zong-signal-strength
-50
1
0
Number

MONITOR
15
227
105
272
Fear Potential
ifelse-value any? turtles\n  [ \n    [fear-potential] of sample-car\n  ]\n  [  0 ]
5
1
11

MONITOR
14
130
112
175
Distance from NSA
ifelse-value any? turtles\n  [ \n    [dist-from-nsa] of sample-car\n  ]\n  [  0 ]
5
1
11

MONITOR
139
80
228
125
SMT
SMT
17
1
11

SLIDER
651
239
823
272
UD
UD
0
1
0.7
.01
1
NIL
HORIZONTAL

SLIDER
652
275
824
308
LH
LH
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
651
203
823
236
IG
IG
0
1
0.7
0.01
1
NIL
HORIZONTAL

INPUTBOX
329
212
390
272
TH1
0.1
1
0
Number

INPUTBOX
393
212
450
272
TH2
0.3
1
0
Number

INPUTBOX
453
213
511
273
TH3
0.5
1
0
Number

MONITOR
1132
62
1223
107
Expected SP
[expected-sp] of turtle 0
17
1
11

BUTTON
185
16
260
49
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1131
123
1225
168
Expected Ufone
sp1-value
17
1
11

MONITOR
1131
187
1226
232
Expected Telenor
sp2-value
17
1
11

MONITOR
1131
249
1226
294
Expected Zong
sp3-value
17
1
11

MONITOR
14
177
81
222
Threshold
threshold
3
1
11

MONITOR
85
178
230
223
Distance b/w current points
totalDistance
17
1
11

MONITOR
138
129
229
174
Time To Reach
[time-to-reach] of turtle 0
3
1
11

MONITOR
138
228
231
273
Fear Intensity
[FI] of turtle 0
3
1
11

INPUTBOX
260
213
320
273
FT
0.3
1
0
Number

CHOOSER
392
10
488
55
Mode
Mode
"MEGA" "GA"
1

SWITCH
275
10
384
43
H-FI-On-NSA
H-FI-On-NSA
1
1
-1000

SLIDER
274
60
381
93
MegaST
MegaST
0.38
0.44
0.41
0.01
1
NIL
HORIZONTAL

SLIDER
274
96
381
129
MegaOT
MegaOT
1.19
1.35
1.35
0.01
1
NIL
HORIZONTAL

SLIDER
273
132
380
165
MegaHO
MegaHO
0.95
1.06
1.06
0.01
1
NIL
HORIZONTAL

SLIDER
393
60
488
93
GaST
GaST
0.40
0.44
0.42
0.01
1
NIL
HORIZONTAL

SLIDER
393
97
488
130
GaOT
GaOT
1.620
1.72
1.69
0.01
1
NIL
HORIZONTAL

SLIDER
393
132
489
165
GaHO
GaHO
1
1.21
1
0.01
1
NIL
HORIZONTAL

INPUTBOX
514
214
574
274
TH4
0.7
1
0
Number

INPUTBOX
580
213
643
273
TH5
0.9
1
0
Number

SWITCH
968
125
1120
158
random-start-position
random-start-position
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model models the movement of cars on a highway. Each car follows a simple set of rules: it slows down (decelerates) if it sees a car close ahead, and speeds up (accelerates) if it doesn't see a car ahead.

The model demonstrates how traffic jams can form even without any accidents, broken bridges, or overturned trucks.  No "centralized cause" is needed for a traffic jam to form.

## HOW TO USE IT

Click on the SETUP button to set up the cars. Set the NUMBER slider to change the number of cars on the road.

Click on DRIVE to start the cars moving.  Note that they wrap around the world as they move, so the road is like a continuous loop.

The ACCELERATION slider controls the rate at which cars accelerate (speed up) when there are no cars ahead.

When a car sees another car right in front, it matches that car's speed and then slows down a bit more.  How much slower it goes than the car in front of it is controlled by the DECELERATION slider.

## THINGS TO NOTICE

Traffic jams can start from small "seeds."  These cars start with random positions and random speeds. If some cars are clustered together, they will move slowly, causing cars behind them to slow down, and a traffic jam forms.

Even though all of the cars are moving forward, the traffic jams tend to move backwards. This behavior is common in wave phenomena: the behavior of the group is often very different from the behavior of the individuals that make up the group.

The plot shows three values as the model runs:

 * the fastest speed of any car (this doesn't exceed the speed limit!)
 * the slowest speed of any car
 * the speed of a single car (turtle 0), painted red so it can be watched.

Notice not only the maximum and minimum, but also the variability -- the "jerkiness" of one vehicle.

Notice that the default settings have cars decelerating much faster than they accelerate. This is typical of traffic flow models.

Even though both ACCELERATION and DECELERATION are very small, the cars can achieve high speeds as these values are added or subtracted at each tick.

## THINGS TO TRY

In this model there are three variables that can affect the tendency to create traffic jams: the initial NUMBER of cars, ACCELERATION, and DECELERATION. Look for patterns in how the three settings affect the traffic flow.  Which variable has the greatest effect?  Do the patterns make sense?  Do they seem to be consistent with your driving experiences?

Set DECELERATION to zero.  What happens to the flow?  Gradually increase DECELERATION while the model runs.  At what point does the flow "break down"?

## EXTENDING THE MODEL

Try other rules for speeding up and slowing down.  Is the rule presented here realistic? Are there other rules that are more accurate or represent better driving strategies?

In reality, different vehicles may follow different rules. Try giving different rules or ACCELERATION/DECELERATION values to some of the cars.  Can one bad driver mess things up?

The asymmetry between acceleration and deceleration is a simplified representation of different driving habits and response times. Can you explicitly encode these into the model?

What could you change to minimize the chances of traffic jams forming?

What could you change to make traffic jams move forward rather than backward?

Make a model of two-lane traffic.

## NETLOGO FEATURES

The plot shows both global values and the value for a single turtle, which helps one watch overall patterns and individual behavior at the same time.

The `watch` command is used to make it easier to focus on the red car.

## RELATED MODELS

"Traffic Grid" adds a street grid with stoplights at the intersections.

"Gridlock" (a HubNet model) is a participatory simulation version of Traffic Grid


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Wilensky, U. (1997).  NetLogo Traffic Basic model.  http://ccl.northwestern.edu/netlogo/models/TrafficBasic.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was developed at the MIT Media Lab using CM StarLogo.  See Resnick, M. (1994) "Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds."  Cambridge, MA: MIT Press.  Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
setup
repeat 180 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="services-label">
      <value value="&quot;Ufone&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zong-signal-strength">
      <value value="-70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;MEGA&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MegaHO">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-car">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IG">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-of-car">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TH3">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ufone-signal-strength">
      <value value="-65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MegaOT">
      <value value="1.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UD">
      <value value="0.54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="telenor-signal-strength">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TH1">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-stop-position">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-start-position">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FT">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GaST">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GaOT">
      <value value="1.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GaHO">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MegaST">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LH">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TH2">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceleration">
      <value value="0.0069"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H-FI-On-NSA">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="increase-speed">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="acceleration">
      <value value="0.19"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TH3">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GaST">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-of-car">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MegaOT">
      <value value="1.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-stop-position">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GaOT">
      <value value="1.69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LH">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TH2">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-start-position">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="increase-speed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ufone-signal-strength">
      <value value="-80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-car">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MegaST">
      <value value="0.41"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="IG">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MegaHO">
      <value value="1.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="services-label">
      <value value="&quot;Ufone&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GaHO">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="UD">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FT">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="telenor-signal-strength">
      <value value="-30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;GA&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H-FI-On-NSA">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TH5">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-start-position">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zong-signal-strength">
      <value value="-50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TH1">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TH4">
      <value value="0.7"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
