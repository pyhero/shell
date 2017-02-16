<?php
$s = '';
if ($MAX[1]) {
    $s = $MAX[1] / 1000000;
    $s = ' (' . $s . 'Mbps)';
}
$s = preg_replace("/^Iface-/", "", $servicedesc) . $s;
$ds_name[1] = "Traffic";
$opt[1] = " --vertical-label \"Bytes/Second\" -b 1000 --title \"$s of $hostname\" --slope-mode ";

$def[1]  = "DEF:a=$rrdfile:$DS[1]:AVERAGE ";
$def[1] .= "DEF:b=$rrdfile:$DS[2]:AVERAGE ";
if ($MAX[1]) {
    $def[1] .= "CDEF:c=a,$MAX[1],800,/,/ ";
    $def[1] .= "CDEF:d=b,$MAX[1],800,/,/ ";
}
$def[1] .= 'LINE1:a#0000CC:Input ';
$def[1] .= 'GPRINT:a:LAST:" Current\: %7.2lf %sB/s" ';
$def[1] .= 'GPRINT:a:AVERAGE:"Average\: %7.2lf %sB/s" ';
$def[1] .= 'GPRINT:a:MAX:"Maximum\: %7.2lf %sB/s" ';
if ($MAX[1]) {
    $def[1] .= 'GPRINT:c:LAST:"  Percent  Current\: %11.2lf%%" ';
    $def[1] .= 'GPRINT:c:AVERAGE:"Average\: %11.2lf%%" ';
    $def[1] .= 'GPRINT:c:MAX:"Maximum\: %11.2lf%%"\j ';
} else {
//    $def[1] .= '\j ';
}
$def[1] .= 'AREA:b#00CC00:Output ';
$def[1] .= 'GPRINT:b:LAST:"Current\: %7.2lf %sB/s" ';
$def[1] .= 'GPRINT:b:AVERAGE:"Average\: %7.2lf %sB/s" ';
$def[1] .= 'GPRINT:b:MAX:"Maximum\: %7.2lf %sB/s" ';
if ($MAX[1]) {
    $def[1] .= 'GPRINT:d:LAST:"  Percent  Current\: %11.2lf%%" ';
    $def[1] .= 'GPRINT:d:AVERAGE:" Average\: %11.2lf%%" ';
    $def[1] .= 'GPRINT:d:MAX:" Maximum\: %11.2lf%%"\j ';
} else {
//    $def[1] .= '\j ';
}
?>
