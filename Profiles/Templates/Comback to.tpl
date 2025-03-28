<chart>
id=132317713614238643
symbol=GBPUSD
description=Great British Pound vs US Dollar
period_type=0
period_size=15
digits=5
tick_size=0.000000
position_time=1734932700
scale_fix=0
scale_fixed_min=1.283000
scale_fixed_max=1.305500
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=1
mode=1
fore=0
grid=0
volume=0
scroll=0
shift=1
shift_size=20.652898
fixed_pos=0.000000
ticker=1
ohlc=0
one_click=0
one_click_btn=1
bidline=1
askline=1
lastline=0
days=0
descriptions=0
tradelines=1
tradehistory=1
window_left=52
window_top=52
window_right=1265
window_bottom=750
window_type=1
floating=0
floating_left=0
floating_top=0
floating_right=0
floating_bottom=0
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=0
foreground_color=16777215
barup_color=65280
bardown_color=255
bullcandle_color=65280
bearcandle_color=255
chartline_color=65280
volumes_color=3329330
grid_color=10061943
bidline_color=10061943
askline_color=255
lastline_color=49152
stops_color=255
windows_total=2

<window>
height=126.670653
objects=6

<indicator>
name=Main
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\Okmich\Moving Averages.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=
draw=1
style=0
width=2
arrow=251
color=2139610
</graph>
<inputs>
MA_Length=233
MA_Type=0
MA_Price=1
Shift=0
</inputs>
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\Okmich\Moving Averages.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=
draw=1
style=0
width=2
arrow=251
color=255
</graph>
<inputs>
MA_Length=477
MA_Type=0
MA_Price=1
Shift=0
</inputs>
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\Practise\Nema.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=nema
draw=10
style=0
width=2
arrow=251
color=8421504,16748574,6333684
</graph>
<inputs>
NemaPeriod=233.0
NemaDepth=0
NemaPrice=0
</inputs>
</indicator>
<object>
type=31
name=autotrade #8148692224 buy 0.01 GBPUSD at 1.24463, GBPUSD
hidden=1
color=11296515
selectable=0
date1=1739356069
value1=1.244630
</object>

<object>
type=32
name=autotrade #8148694475 sell 0.01 GBPUSD at 1.24470, profit 0.07,
hidden=1
color=1918177
selectable=0
date1=1739356264
value1=1.244700
</object>

<object>
type=31
name=autotrade #8148698163 buy 0.01 GBPUSD at 1.24413, GBPUSD
hidden=1
color=11296515
selectable=0
date1=1739356530
value1=1.244130
</object>

<object>
type=32
name=autotrade #8148700450 sell 0.01 GBPUSD at 1.24395, profit -0.18
hidden=1
color=1918177
selectable=0
date1=1739356749
value1=1.243950
</object>

<object>
type=2
name=autotrade #8148692224 -> #8148694475, profit 0.07, GBPUSD
hidden=1
descr=1.24463 -> 1.24470
color=11296515
style=2
selectable=0
ray1=0
ray2=0
date1=1739356069
date2=1739356264
value1=1.244630
value2=1.244700
</object>

<object>
type=2
name=autotrade #8148698163 -> #8148700450, profit -0.18, GBPUSD
hidden=1
descr=1.24413 -> 1.24395
color=11296515
style=2
selectable=0
ray1=0
ray2=0
date1=1739356530
date2=1739356749
value1=1.244130
value2=1.243950
</object>

</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Practise\Nema_MACD.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=OSMA filling
draw=7
style=0
width=1
arrow=251
color=15128749,12180223
</graph>

<graph>
name=MACD
draw=10
style=0
width=3
arrow=251
color=12632256,16748574,6333684
</graph>

<graph>
name=MACD signal
draw=1
style=2
width=1
arrow=251
color=7504122
</graph>
<inputs>
MacdFast=233
MacdSlow=477
MacdSignal=15
NemaDepth=1
TimeFrame=0
Interpolate=true
</inputs>
</indicator>
</window>
</chart>