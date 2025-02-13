<chart>
id=132317713614238638
symbol=USDCAD
description=US Dollar vs Canadian Dollar
period_type=1
period_size=1
digits=5
tick_size=0.000000
position_time=1656392400
scale_fix=0
scale_fixed_min=1.281300
scale_fixed_max=1.323200
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=4
mode=1
fore=0
grid=0
volume=0
scroll=0
shift=0
shift_size=20.102433
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
window_right=1361
window_bottom=684
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
windows_total=3

<window>
height=151.964145
objects=3

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
path=Indicators\Okmich\Donchian Channel.ex5
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
name=Highest high
draw=1
style=0
width=1
arrow=251
color=7451452
</graph>

<graph>
name=Lowest low
draw=1
style=0
width=1
arrow=251
color=17919
</graph>

<graph>
name=Middle Line
draw=1
style=2
width=1
arrow=251
color=12632256
</graph>
<inputs>
inpChannelPeriod=55
inpMode=1
</inputs>
</indicator>
<object>
type=32
name=autotrade #544914 sell 0.03 USDCAD at 1.26177, USDCAD
hidden=1
color=1918177
selectable=0
date1=1638971767
value1=1.261770
</object>

<object>
type=31
name=autotrade #545037 buy 0.03 USDCAD at 1.26291, profit -2.71, USD
hidden=1
color=11296515
selectable=0
date1=1638979483
value1=1.262910
</object>

<object>
type=2
name=autotrade #544914 -> #545037, profit -2.71, USDCAD
hidden=1
descr=1.26177 -> 1.26291
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1638971767
date2=1638979483
value1=1.261770
value2=1.262910
</object>

</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Okmich\Chaikin Oscillator.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=-7622.565000
scale_fix_max=0
scale_fix_max_val=7081.465000
expertmode=0
fixed_height=-1

<graph>
name=CHO
draw=1
style=0
width=1
arrow=251
color=11186720
</graph>

<graph>
name=Signal
draw=1
style=2
width=1
arrow=251
color=4163021
</graph>

<level>
level=0.000000
style=2
color=12632256
width=1
descr=
</level>
<inputs>
InpFastMA=12
InpSlowMA=26
InpSignal=5
InpSmoothMethod=1
InpVolumeType=0
</inputs>
</indicator>
</window>

<window>
height=50.000000
objects=0

<indicator>
name=Money Flow Index
path=
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=51.220882
scale_fix_min=0
scale_fix_min_val=8.431496
scale_fix_max=0
scale_fix_max_val=94.010268
expertmode=0
fixed_height=-1

<graph>
name=
draw=1
style=0
width=1
arrow=251
color=16748574
</graph>

<level>
level=20.000000
style=2
color=12632256
width=1
descr=
</level>

<level>
level=80.000000
style=2
color=12632256
width=1
descr=
</level>

<level>
level=50.000000
style=2
color=12632256
width=1
descr=
</level>
real_volumes=0
period=20
</indicator>

<indicator>
name=Moving Average
path=
apply=9
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
draw=129
style=2
width=1
arrow=251
color=16443110
</graph>
period=5
method=1
</indicator>
</window>
</chart>