<chart>
id=132317713614238638
symbol=USDCAD
description=US Dollar vs Canadian Dollar
period_type=0
period_size=15
digits=5
tick_size=0.000000
position_time=1656392400
scale_fix=0
scale_fixed_min=1.272300
scale_fixed_max=1.299000
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=1
mode=1
fore=0
grid=0
volume=2
scroll=0
shift=0
shift_size=19.974392
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
windows_total=5

<window>
height=126.670653
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
path=Indicators\Okmich\SSL Channel.ex5
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
name=SSLUp
draw=1
style=0
width=2
color=11186720
</graph>

<graph>
name=SSLDown
draw=1
style=0
width=2
color=17919
</graph>
<inputs>
InpPeriod=480
InpMethod=5
</inputs>
</indicator>
<object>
type=31
name=autotrade #202956735 buy 0.1 SILVER at 22.832
hidden=1
color=11296515
selectable=0
date1=1601298454
value1=22.832000
</object>

<object>
type=32
name=autotrade #202956833 sell 0.1 SILVER at 22.791
hidden=1
color=1918177
selectable=0
date1=1601298497
value1=22.791000
</object>

<object>
type=2
name=autotrade #202956735 -> #202956833 SILVER
hidden=1
descr=22.832 -> 22.791
color=11296515
style=2
selectable=0
ray1=0
ray2=0
date1=1601298454
date2=1601298497
value1=22.832000
value2=22.791000
</object>

</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Okmich\ADX Oscillator.ex5
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
name=ADX (14)
draw=1
style=0
width=2
color=16443110
</graph>

<graph>
name=Osc
draw=1
style=0
width=2
color=55295
</graph>

<graph>
name=+DI
draw=1
style=2
width=1
color=65280
</graph>

<graph>
name=-DI
draw=1
style=2
width=1
color=17919
</graph>

<level>
level=0.000000
style=2
color=12632256
width=1
descr=
</level>
<inputs>
InpPeriodADX=14
</inputs>
</indicator>
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
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=CHO
draw=1
style=0
width=2
color=4163021
</graph>

<graph>
name=Signal
draw=1
style=2
width=1
color=12632256
</graph>

<level>
level=0.000000
style=2
color=12632256
width=1
descr=
</level>
<inputs>
InpFastMA=23
InpSlowMA=55
InpSignal=9
InpSmoothMethod=1
InpVolumeType=0
</inputs>
</indicator>
</window>
</chart>