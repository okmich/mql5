<chart>
id=132317713614238640
symbol=EURCAD
description=Euro vs Canadian Dollar
period_type=1
period_size=1
digits=5
tick_size=0.000000
position_time=0
scale_fix=0
scale_fixed_min=1.296000
scale_fixed_max=1.330100
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=2
mode=1
fore=0
grid=0
volume=2
scroll=0
shift=1
shift_size=20.614597
fixed_pos=0.000000
ticker=1
ohlc=1
one_click=0
one_click_btn=1
bidline=1
askline=1
lastline=0
days=0
descriptions=0
tradelines=0
tradehistory=0
window_left=0
window_top=0
window_right=0
window_bottom=0
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
windows_total=4

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
arrow=251
color=11186720
</graph>

<graph>
name=SSLDown
draw=1
style=0
width=2
arrow=251
color=17919
</graph>
<inputs>
InpPeriod=600
InpMethod=5
</inputs>
</indicator>
</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Okmich\Slope Divergence of TSI.ex5
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

<graph>
name=SD_TSI
draw=1
style=0
width=1
arrow=251
color=16118015
</graph>

<level>
level=0.000000
style=2
color=12632256
width=1
descr=
</level>
<inputs>
TSIPeriod=38
firstSmoothingPeriod=38
secondSmoothingPeriod=5
priceFirstSmoothingPeriod=23
priceSecondSmoothingPeriod=2
</inputs>
</indicator>
</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Articles\NEMA MACD.ex5
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
name=MACD
draw=2
style=0
width=1
arrow=251
color=12632256
</graph>

<graph>
name=signal
draw=1
style=2
width=1
arrow=251
color=255
</graph>

<level>
level=0.000000
style=2
color=12632256
width=1
descr=
</level>
<inputs>
inpNemaType=1
inpFastPeriod=40
inpSlowPeriod=100
inpSignalPeriod=9
inpPrice=1
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
scale_line_value=54.038623
scale_fix_min=0
scale_fix_min_val=16.083522
scale_fix_max=0
scale_fix_max_val=91.993725
expertmode=0
fixed_height=-1

<graph>
name=
draw=1
style=0
width=1
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
color=16443110
</graph>
period=5
method=1
</indicator>
</window>
</chart>