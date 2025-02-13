<chart>
id=132317713614238638
symbol=USDCHF
description=US Dollar vs Swiss Franc
period_type=1
period_size=1
digits=5
tick_size=0.000000
position_time=1651561200
scale_fix=0
scale_fixed_min=0.936700
scale_fixed_max=0.960400
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=8
mode=1
fore=0
grid=0
volume=2
scroll=0
shift=1
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
window_type=3
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
height=126.670653
objects=0

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
path=Indicators\Articles\Super Trend.ex5
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
name=Filling
draw=7
style=0
width=1
color=12903679,10025880
</graph>

<graph>
name=SuperTrend
draw=10
style=0
width=1
color=32768,255
</graph>
<inputs>
InpPeriod=100
Multiplier=3.0
Show_Filling=false
</inputs>
</indicator>
</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Okmich\Directional Trend Index.ex5
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
name=DTI
draw=1
style=0
width=2
arrow=251
color=16436871
</graph>

<graph>
name=Up level
draw=1
style=2
width=1
arrow=251
color=3329330
</graph>

<graph>
name=Down level
draw=1
style=2
width=1
arrow=251
color=42495
</graph>
<inputs>
InpPeriod=40
InpSmoothing=20
InpSignal=9
InpAnchor=true
</inputs>
</indicator>
</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Articles\Connors RSI.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=1
scale_fix_min_val=0.000000
scale_fix_max=1
scale_fix_max_val=100.000000
expertmode=0
fixed_height=-1

<graph>
name=CRSI
draw=1
style=0
width=1
arrow=251
color=11829830
</graph>

<level>
level=80.000000
style=2
color=12632256
width=1
descr=Overbought
</level>

<level>
level=20.000000
style=2
color=12632256
width=1
descr=Oversold
</level>
<inputs>
InpPeriodRSI=3
InpPeriodSM=2
InpPeriodPercRank=100
InpAppliedPrice=1
InpOverbought=80
InpOversold=20
</inputs>
</indicator>
</window>
</chart>