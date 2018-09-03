globals
[
  selected-car   ;; the currently selected car
  number-of-trucks
  number-of-cars
  collisions
]
patches-own [ clear-in ]
turtles-own
[
  speed         ;; the current speed of the car
  speed-limit   ;; the maximum speed of the car (different for all cars)
  lane          ;; the current lane of the car
  target-lane   ;; the desired lane of the car
  patience      ;; the driver's current patience
  max-patience  ;; the driver's maximum patience
  change?       ;; true if the car wants to change lanes
  in-range      ;; vehicles in sonar range
  nearest       ;; vehicle that is very close
  howclose      ;; if any vehicle is close, what is its distance
  alert         ;; generate alert if howclose is less than safety distance
  adj_up
  adj_down
  no-of-collisions
  displacement
  Width
  Safety_lateral_distance
  Ld
  Fear
  Norm
  threshold

  ;; OCC Model based emotions coputation
  FP           ;; Fear Potential
  FT           ;; Fear Threshold
  FI           ;; Fear Intensity
]

to setup
  clear-all
  draw-road ;; draw roads
  setVehicleCount  ;; calculate the number of cars and trucks on the basis of selected ratio
  set-default-shape turtles "car"
  crt number-of-cars [ setup-cars ]
  crt number-of-trucks [ setup-trucks ]
  set selected-car one-of turtles
  ;; color the selected car red so that it is easy to watch
 ;; ask selected-car [ set color red ]
  reset-ticks
end
;; following functino will calculate the vehicles count based on ratio
to setVehicleCount
  let sep position ":" vehicles-ratio
  let trucks  substring vehicles-ratio 0 sep
  let cars substring vehicles-ratio (sep + 1) (length vehicles-ratio)
  let percent (number-of-vehicles / (read-from-string trucks + read-from-string cars))
  set number-of-trucks ceiling (percent * (read-from-string trucks))
  set number-of-cars floor (percent * (read-from-string cars))
end
;; following functino will draw the road
to draw-road
  ask patches [
    set pcolor green
    if ((pycor > -4) and (pycor < 4)) [ set pcolor gray ]
    if ((pycor = 0) and ((pxcor mod 3) = 0)) [ set pcolor yellow ]
    if ((pycor = 4) or (pycor = -4)) [ set pcolor black ]
  ]
end
; this function will setup the simulation
to setup-cars
  set size 1  ; where 1 is equal to 4.43 meters
  set color red
  set lane (random 2)
  set target-lane lane
  ifelse (lane = 0) [
    setxy random-xcor -2
  ]
  [
    setxy random-xcor  2
  ]
  set heading 90
   set speed min-velocity-range + random-float ( max-velocity-range - min-velocity-range)
  set speed-limit max-velocity-range ;(((random 11) / 10) + 1)
  set change? false
  set max-patience 1 ;((random 0.9) + 0.1)
  set patience (max-patience - (random 0.9))
  set Width 1
  set Ld 0.5

  ;; make sure no two cars are on the same patch
  loop [
   ifelse any? other turtles-here [ fd 1 ] [ stop ]
  ]
end
; this function will create the number of trucks calculated by vehicle count function
to setup-trucks
  set shape "truck"
  set size 2.4 ; 10.xx / 4.43 = 2.4 meters
  set color one-of [ red green blue brown ];;green
  set lane (random 2)
  set target-lane lane
  ifelse (lane = 0) [
    setxy random-xcor -2
  ]
  [
    setxy random-xcor  2
  ]
  set heading 90
  set speed min-velocity-range + random-float ( max-velocity-range - min-velocity-range)
  set speed-limit max-velocity-range ;(((random 11) / 10) + 1)
  set change? false
  set max-patience 1;((random 0.9) + 0.1)
  set patience (max-patience - (random 0.1))
  set Width 1.5
  set Ld 0.75

  ;; make sure no two cars are on the same patch
  loop [
    ifelse any? other turtles-here [ fd 2.4 ] [ stop ]
  ]
end
;; All turtles look first to see if there is a turtle directly in front of it,
;; if so, set own speed to front turtle's speed and decelerate.  Otherwise,  If no front   ,,,,,,,,,,,,,,,,,,,,,,,///////// if any? (turtles-on patch-ahead 1) with [shape = "truck"] and (howclose < safety_distance)
;; turtles are found, accelerate towards speed-limit
to adjustspeed
  let cpos xcor
  let speedup false
  let speeddown false
   if(howclose > 0 and howclose < safety_distance)[
    ask nearest [
      ifelse(xcor > cpos)[
        set speeddown true
        ][
        set speedup true
        ]
      ]]
     if (speeddown = true)[
    set Norm "Keep the distance from stronger"
    decelerate1
    ]
  if speedup = true [
    set Norm "Increase your speed to keep safe distance from other vehicles "
    accelerate1
    ]
    set adj_up speedup
    set adj_down speeddown

end
to adjustspeedbasedonFear
  let cpos xcor
  let speedup false
  let speeddown false
  if(howclose > 0 and FI > ego)[  ;;0.2
    ask nearest [
      ifelse(xcor > cpos)[
        set speeddown true
        ][
        set speedup true
        ]
      ]
    ]
  if (speeddown = true)[
    set Norm "Follow the Social Norm: Keep the distance from stronger"
    decelerate2
    ]
  if speedup = true [
    set Norm "Follow the Social Norm: Increase your speed to keep safe distance from other vehicles "
    accelerate2
    ]
    set adj_up speedup
    set adj_down speeddown

end
;; this function will find and maintain safety distance from other vehicles
to findsafetydistance
  let wl Width
  let wt 0
  let cLd Ld
  let iscar false
  if(howclose > 0 and howclose < safety_distance)[
    ask nearest [
      set wt Width
      if ( Ld > cLd )[ set cLd Ld ]
    ]
  ]

end
;; GO button will trigger this function.
to drive
  ask turtles [


    if (speed < min-velocity-range) [ set speed min-velocity-range ]
    if (speed > max-velocity-range ) [ set speed max-velocity-range ]


    find-in-range-vehicles ;; find vehicles within the sonar range
    find-closest-vehicle ;; find the nearest vehicle within sonar range

;    if(meta-cognition)[
;      fd speed
;      ]
    ifelse(meta-cognition)[
       calculateFearIntensity
    ;; adjustspeed ;; apply norms
    adjustspeedbasedonFear
      fd speed
      ][
       adjustspeed
         fd speed
      ]
    ifelse howclose = 0 Or howclose > safety_distance
    [
     set alert "normal" ;orange

     ][
     ifelse howclose = safety_distance[
       set alert "careful" ;red

       ][
       set alert "danger" ;green

       ]
     ]

;    ifelse (change? = false) [ signal ] [ if(meta-cognition)[change-lanes ]]

;    check-for-collisions
  ]


  tick
end
to calculateEgo
 let egoThreshHold 0.5
 ifelse (howclose > safety_distance)[
   set ego 0
   ][
   let diff (howclose / safety_distance)
  ifelse(diff < 0.15)[
    set ego 0
    ][
    ifelse(diff > 0.15 and diff < 0.375)[
      set ego 0.25
      ]
    [
      ifelse(diff < 0.625 and diff > 0.375)[
        set ego 0.5
      ]
      [
        ifelse(diff > 0.625 and diff < 0.875)[
        set ego 0.75
        ][
      set ego 1
        ]
      ]
      ]
    ]
    set ego (ego - egoThreshHold)
    set ego precision ego 2
    if(ego < 0)[ set ego 0]

   ]

end
to calculateFearIntensity
  calculateEgo
  set  threshold howclose
  let threshold_ratio (threshold / safety_distance)
  if ( threshold >= safety_distance)
  [
    set LE (0.1)
    set ig (0.1)
    set UE (0.1)

    set fp ((ue + le + ig)/ 3)
    set ft (0.24)
    ifelse((fp - ft) < 0)[
      set fI 0
    ][
      set fI( fp - ft)
    ]
    set Fear "V. Low"
 ]

  if (threshold <= safety_distance and threshold_ratio < 0.25)

 [ set LE (0.3)
   set ig (0.3)
   set UE (0.3)

   set fp ((ue + le + ig)/ 3)
   set ft (0.24)
  ifelse((fp - ft) < 0)[
      set fI 0
   ][
      set fI( fp - ft)
   ]

   set Fear "Low"
 ]

  if (threshold <= safety_distance and threshold_ratio >= 0.25 and threshold_ratio < 0.5)


 [ set LE (0.4)
   set ig (0.4)
   set UE (0.4)

   set fp ((ue + le + ig)/ 3)
   set ft (0.24)
   set fI( fp - ft)
   set Fear "Medium"
 ]
 if (threshold <= safety_distance and threshold_ratio >= 0.5 and threshold_ratio < 0.75)

 [ set LE (0.5)
   set ig (0.5)
   set UE (0.5)

   set fp ((ue + le + ig)/ 3)
   set ft (0.24)
   set fI( fp - ft)
   set Fear "High"
 ]


 if (threshold <= safety_distance and threshold_ratio >= 0.75 and threshold_ratio < 0.85)

 [ set LE (0.7)
   set ig (0.7)
   set UE (0.7)
   set fp ((ue + le + ig)/ 3)
   set ft (0.24)
   set fI( fp - ft)
set Fear "V. High"
  ]


 if (threshold <= safety_distance and threshold_ratio >= 0.85 and threshold_ratio < 1)

 [ set LE (0.9)
   set ig (0.9)
   set UE (0.9)
   set fp ((ue + le + ig)/ 3)
   set ft (0.24)
   set fI( fp - ft)
set Fear "V. High"
  ]

end
;; check if its about to collide with other vehicles add one in count and orange the patch for a while
to check-for-collisions
   if any? other turtles-here [ set no-of-collisions (no-of-collisions + 1) ]
  ask patches with [ pcolor = orange ]
  [ set clear-in clear-in - 1
    if clear-in = 0
    [ set pcolor gray ]
  ]
  ask patches with [ count turtles-here > 1 ]
  [
    set pcolor orange
    set clear-in 5
    set collisions (collisions + 1)
   ; ask turtles-here [ die ]
  ]
end
;; increase speed of cars
to accelerate1  ;; turtle procedure
  set speed (speed + accleration-rate)
end

;; reduce speed of cars
to decelerate1  ;; turtle procedure
  set speed (speed - decleration-rate)
end


;;;;;;;;;;;///////////////// Fear based acceleration/ Decleration strategy






to accelerate2  ;; turtle procedure
  set speed (speed + accleration-rate)
end

;; reduce speed of cars
to decelerate2  ;; turtle procedure
  set speed (speed - decleration-rate)
end
















;;;;;;;;/////////////////





;; if patience is very high then this function will allow to change the lane
;to change-lanes  ;; turtle procedure
;  ifelse (patience <= 0) [
;    ifelse (max-patience <= 0.1) [
;      set max-patience 1;(random 0.9) + 0.01
;    ]
;    [
;      set max-patience 1;(max-patience - (random 0.05))
;    ]
;    set patience max-patience
;    ifelse (target-lane = 0) [
;      set target-lane 1
;      set lane 0
;    ]
;    [
;      set target-lane 0
;      set lane 1
;    ]
;  ]
;  [
;    set patience (patience - 0.01)
;  ]
;  ifelse (target-lane = lane) [
;    ifelse (target-lane = 0) [
;      set target-lane 1
;      set change? false
;    ]
;    [
;      set target-lane 0
;      set change? false
;    ]
;  ]
;  [
;    ifelse (target-lane = 1) [
;      ifelse (pycor = 2) [
;        set lane 1
;        set change? false
;      ]
;      [
;        ifelse (not any? turtles-at 0 1) [
;          set ycor (ycor + 1)
;        ]
;        [
;          ifelse (not any? turtles-at 1 0) [
;            set xcor (xcor + 1)
;          ]
;          [
;            decelerate
;            if (speed <= 0) [ set speed 0.1 ]
;          ]
;        ]
;      ]
;    ]
;    [
;      ifelse (pycor = -2) [
;        set lane 0
;        set change? false
;      ]
;      [
;        ifelse (not any? turtles-at 0 -1) [
;          set ycor (ycor - 1)
;        ]
;        [
;          ifelse (not any? turtles-at 1 0) [
;            set xcor (xcor + 1)
;          ]
;          [
;            decelerate
;            if (speed <= 0) [ set speed 0.1 ]
;          ]
;        ]
;      ]
;    ]
;  ]
;end

;; this function is to find the vehicles that lie within the radar range.
to find-in-range-vehicles
  set in-range other turtles in-radius sonar_range
 ; show in-range
end
;; find the closest vehicle from the in range vehicles.
to find-closest-vehicle
  set nearest min-one-of in-range [distance myself]
  ifelse(nearest != nobody)[
    set howclose distance nearest
  ]
  [
    set howclose 0
  ]
end
;; this function will help vehicles to change the lane
to signal
  ifelse (any? turtles-at 1 0) [
    if ([speed] of (one-of (turtles-at 1 0))) < (speed) [
      set change? true
    ]
  ]
  [
    set change? false
  ]
end
;; reporter function for test environment
 to-report Total_no_of_collision

  report sum [no-of-collisions] of turtles

end
;; this function will allow to select the car
to select-car
  if mouse-down? [
    let mx mouse-xcor
    let my mouse-ycor
    if any? turtles-on patch mx my [

      ;ask selected-car [ set color black ]
      set selected-car one-of turtles-on patch mx my
     ;; ask selected-car [ set color red ]
      watch selected-car
      display
    ]
  ]
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
325
11
828
245
25
10
9.6832
1
10
1
1
1
0
1
0
1
-25
25
-10
10
1
1
1
ticks
30.0

BUTTON
32
10
107
43
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
33
88
108
121
go
drive
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
49
107
82
go once
drive
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
12
128
109
161
select car
select-car
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
390
380
485
425
average speed
mean [speed] of turtles
2
1
11

SLIDER
122
10
282
43
number-of-vehicles
number-of-vehicles
0
30
5
1
1
NIL
HORIZONTAL

SLIDER
120
130
280
163
min-velocity-range
min-velocity-range
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
120
92
280
125
max-velocity-range
max-velocity-range
0
1
1
0.01
1
NIL
HORIZONTAL

PLOT
950
265
1317
435
Car Speeds
Time
Speed
0.0
300.0
0.0
1.0
true
true
"set-plot-y-range 0 ((max [speed-limit] of turtles) + .5)" ""
PENS
"average" 1.0 0 -10899396 true "" "plot mean [speed] of turtles"
"max" 1.0 0 -11221820 true "" "plot max [speed] of turtles"
"min" 1.0 0 -13345367 true "" "plot min [speed] of turtles"
"selected-car" 1.0 0 -2674135 true "" "plot [speed] of selected-car"

SWITCH
120
250
281
283
meta-cognition
meta-cognition
0
1
-1000

CHOOSER
120
45
280
90
vehicles-ratio
vehicles-ratio
"2:1" "3:1" "4:1"
1

SLIDER
120
288
282
321
safety_distance
safety_distance
2
10
4
1
1
NIL
HORIZONTAL

SLIDER
120
325
282
358
sonar_range
sonar_range
1
10
4
1
1
NIL
HORIZONTAL

MONITOR
390
325
482
370
Alert Message
[alert] of selected-car
17
1
11

MONITOR
310
325
375
370
Distance
[howclose] of selected-car
4
1
11

TEXTBOX
315
265
555
325
Select any vehicle to see below values by clicking \"Select Car\" button and then click on any vehicle.\n
14
105.0
1

PLOT
560
265
945
435
Number of Collisions
time
collisions
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Collisions" 1.0 0 -5298144 true "" "plot sum [no-of-collisions] of turtles"
"Selected Car" 1.0 0 -13791810 true "" "plot [no-of-collisions] of selected-car"

SLIDER
120
170
292
203
accleration-rate
accleration-rate
0
1
0.3
0.05
1
NIL
HORIZONTAL

SLIDER
120
210
292
243
decleration-rate
decleration-rate
0
1
0.2
0.05
1
NIL
HORIZONTAL

MONITOR
310
380
375
425
Fear Level
[Fear] of selected-car
17
1
11

MONITOR
160
435
485
480
Road Norm
[Norm] of selected-car
17
1
11

SLIDER
860
15
1032
48
LE
LE
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
860
55
1032
88
IG
IG
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
860
95
1032
128
UE
UE
0
1
0.3
0.1
1
NIL
HORIZONTAL

PLOT
1045
80
1315
260
Fear
Time
Fear Intensity
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [fi] of selected-car"

MONITOR
215
385
272
430
FI
[FI] of selected-car
17
1
11

SLIDER
45
205
78
351
ego
ego
0
1
0
0.25
1
NIL
VERTICAL

MONITOR
65
405
122
450
ego
[ego] of selected-car
17
1
11

@#$#@#$#@
## WHAT IS IT?

This project is a more sophisticated two-lane version of the "Traffic Basic" model.  Much like the simpler model, this model demonstrates how traffic jams can form. In the two-lane version, drivers have a new option; they can react by changing lanes, although this often does little to solve their problem.

As in the traffic model, traffic may slow down and jam without any centralized cause.

## HOW TO USE IT

Click on the SETUP button to set up the cars. Click on DRIVE to start the cars moving. The STEP button drives the car for just one tick of the clock.

The NUMBER slider controls the number of cars on the road. The LOOK-AHEAD slider controls the distance that drivers look ahead (in deciding whether to slow down or change lanes). The SPEED-UP slider controls the rate at which cars accelerate when there are no cars ahead. The SLOW-DOWN slider controls the rate at which cars decelerate when there is a car close ahead.

You may wish to slow down the model with the speed slider to watch the behavior of certain cars more closely.

The SELECT-CAR button allows you to pick a car to watch. It turns the car red, so that it is easier to keep track of it. SELECT-CAR is best used while DRIVE is turned off. If the user does not select a car manually, a car is chosen at random to be the "selected car".

The AVERAGE-SPEED monitor displays the average speed of all the cars.

The CAR SPEEDS plot displays four quantities over time:
- the maximum speed of any car - CYAN
- the minimum speed of any car - BLUE
- the average speed of all cars - GREEN
- the speed of the selected car - RED

## THINGS TO NOTICE

Traffic jams can start from small "seeds." Cars start with random positions and random speeds. If some cars are clustered together, they will move slowly, causing cars behind them to slow down, and a traffic jam forms.

Even though all of the cars are moving forward, the traffic jams tend to move backwards. This behavior is common in wave phenomena: the behavior of the group is often very different from the behavior of the individuals that make up the group.

Just as each car has a current speed and a maximum speed, each driver has a current patience and a maximum patience. When a driver decides to change lanes, he may not always find an opening in the lane. When his patience expires, he tries to get back in the lane he was first in. If this fails, back he goes... As he gets more 'frustrated', his patience gradually decreases over time. When the number of cars in the model is high, watch to find cars that weave in and out of lanes in this manner. This phenomenon is called "snaking" and is common in congested highways.

Watch the AVERAGE-SPEED monitor, which computes the average speed of the cars. What happens to the speed over time? What is the relation between the speed of the cars and the presence (or absence) of traffic jams?

Look at the two plots. Can you detect discernible patterns in the plots?

## THINGS TO TRY

What could you change to minimize the chances of traffic jams forming, besides just the number of cars? What is the relationship between number of cars, number of lanes, and (in this case) the length of each lane?

Explore changes to the sliders SLOW-DOWN, SPEED-UP, and LOOK-AHEAD. How do these affect the flow of traffic? Can you set them so as to create maximal snaking?

## EXTENDING THE MODEL

Try to create a 'traffic-3 lanes', 'traffic-4 lanes', 'traffic-crossroads' (where two sets of cars might meet at a traffic light), or 'traffic-bottleneck' model (where two lanes might merge to form one lane).

Note that the cars never crash into each other- a car will never enter a patch or pass through a patch containing another car. Remove this feature, and have the turtles that collide die upon collision. What will happen to such a model over time?

## NETLOGO FEATURES

Note the use of `mouse-down?` and `mouse-xcor`/`mouse-ycor` to enable selecting a car for special attention.

Each turtle has a shape, unlike in some other models. NetLogo uses `set shape` to alter the shapes of turtles. You can, using the shapes editor in the Tools menu, create your own turtle shapes or modify existing ones. Then you can modify the code to use your own shapes.

## RELATED MODELS

Traffic Basic


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Wilensky, U. (1998).  NetLogo Traffic 2 Lanes model.  http://ccl.northwestern.edu/netlogo/models/Traffic2Lanes.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

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
NetLogo 5.1.0
@#$#@#$#@
setup
repeat 50 [ drive ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Experiment1_SocialNorms_8AVs_Varying FearIntensities" repetitions="7" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>drive</go>
    <timeLimit steps="150"/>
    <metric>sum [no-of-collisions] of turtles</metric>
    <enumeratedValueSet variable="max-velocity-range">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decleration-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicles-ratio">
      <value value="&quot;3:1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sonar_range">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-velocity-range">
      <value value="0.21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meta-cognition">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="safety_distance">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="UE" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="number-of-vehicles">
      <value value="8"/>
    </enumeratedValueSet>
    <steppedValueSet variable="LE" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="IG" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="accleration-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ego">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment1_SocialNorms_15AVs_Varying FearIntensities" repetitions="7" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>drive</go>
    <timeLimit steps="150"/>
    <metric>sum [no-of-collisions] of turtles</metric>
    <enumeratedValueSet variable="max-velocity-range">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decleration-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicles-ratio">
      <value value="&quot;3:1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sonar_range">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-velocity-range">
      <value value="0.21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meta-cognition">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="safety_distance">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="UE" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="number-of-vehicles">
      <value value="15"/>
    </enumeratedValueSet>
    <steppedValueSet variable="LE" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="IG" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="accleration-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ego">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment1_SocialNorms_15AVs_Varying FearIntensities_with safety distance 2" repetitions="7" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>drive</go>
    <timeLimit steps="150"/>
    <metric>sum [no-of-collisions] of turtles</metric>
    <enumeratedValueSet variable="max-velocity-range">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decleration-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicles-ratio">
      <value value="&quot;3:1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sonar_range">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-velocity-range">
      <value value="0.21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meta-cognition">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="safety_distance">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="UE" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="number-of-vehicles">
      <value value="15"/>
    </enumeratedValueSet>
    <steppedValueSet variable="LE" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="IG" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="accleration-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ego">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment1_SocialNorms_22AVs_Varying FearIntensities_with safety distance 2" repetitions="7" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>drive</go>
    <timeLimit steps="150"/>
    <metric>sum [no-of-collisions] of turtles</metric>
    <enumeratedValueSet variable="max-velocity-range">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decleration-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicles-ratio">
      <value value="&quot;3:1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sonar_range">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-velocity-range">
      <value value="0.21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meta-cognition">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="safety_distance">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="UE" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="number-of-vehicles">
      <value value="22"/>
    </enumeratedValueSet>
    <steppedValueSet variable="LE" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="IG" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="accleration-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ego">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment1_SocialNorms_30AVs_Varying FearIntensities_with safety distance 2" repetitions="7" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>drive</go>
    <timeLimit steps="150"/>
    <metric>sum [no-of-collisions] of turtles</metric>
    <enumeratedValueSet variable="max-velocity-range">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decleration-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicles-ratio">
      <value value="&quot;3:1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sonar_range">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-velocity-range">
      <value value="0.21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meta-cognition">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="safety_distance">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="UE" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="number-of-vehicles">
      <value value="30"/>
    </enumeratedValueSet>
    <steppedValueSet variable="LE" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="IG" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="accleration-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ego">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment1_SocialNorms_8AVs_Varying FearIntensities_with medium speed (0.5) and low accleration (0.2)" repetitions="7" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>drive</go>
    <timeLimit steps="150"/>
    <metric>sum [no-of-collisions] of turtles</metric>
    <enumeratedValueSet variable="max-velocity-range">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decleration-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicles-ratio">
      <value value="&quot;3:1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sonar_range">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-velocity-range">
      <value value="0.21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meta-cognition">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="safety_distance">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="UE" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="number-of-vehicles">
      <value value="8"/>
    </enumeratedValueSet>
    <steppedValueSet variable="LE" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="IG" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="accleration-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ego">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment1_SocialNorms_15AVs_Varying FearIntensities_low speeds (0.3) and low decleration rate (0.2)" repetitions="7" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>drive</go>
    <timeLimit steps="150"/>
    <metric>sum [no-of-collisions] of turtles</metric>
    <enumeratedValueSet variable="max-velocity-range">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decleration-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vehicles-ratio">
      <value value="&quot;3:1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sonar_range">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-velocity-range">
      <value value="0.21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meta-cognition">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="safety_distance">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="UE" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="number-of-vehicles">
      <value value="15"/>
    </enumeratedValueSet>
    <steppedValueSet variable="LE" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="IG" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="accleration-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ego">
      <value value="0.5"/>
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
1
@#$#@#$#@
