<?php
#
# (c)2016 Aiuv Co., Ltd.
# (c)2016 Panda <panda@aiuv.cc>
#
$this->MACRO['TITLE']   = "5xx";
$this->MACRO['COMMENT'] = "Total";
#
# Interfaces Connections
$services = $this->tplGetServices("(PHP-172.16)","(modian.com)");

#throw new Kohana_exception(print_r($services,TRUE));
#
# The Datasource Name for Graph 1 ( index 0 )
$ds_name[0] = "Total 5xx"; 
$opt[0]	    = " --title \"Total 4 5 xx\"";
$def[0]     = "";
#
# Iterate through the list of hosts
$fourxx = array();
$fivexx = array();
$operator = array();
foreach($services as $key=>$val){
    $data    = $this->tplGetData($val['host'], $val['service']);
    $def[0] .= rrd::def("v0$key", $data['DS'][0]['RRDFILE'], $data['DS'][0]['DS'], "AVERAGE");
    $def[0] .= rrd::def("v1$key", $data['DS'][1]['RRDFILE'], $data['DS'][1]['DS'], "AVERAGE");
    array_push($fourxx, "v0$key");
    array_push($fivexx, "v1$key");
    array_push($operator, "ADDNAN");
}
//error_log("Total:".$Total."\n"."Used:".$Used."\n",3,"/tmp/xx.log");
//error_log("Total:".var_export($Total,true)."\n"."Used:".var_export($Used,true)."\n",3,"/tmp/xx.log");
array_shift($operator);
$def[0] .= rrd::cdef('fourxx', join($fourxx, ',') . "," . join($operator, ','));
$def[0] .= rrd::cdef('fivexx', join($fivexx, ',') . "," . join($operator, ','));

$def[0] .= rrd::line1('fourxx', '#FF8C00', '4xx');
$def[0] .= rrd::gprint('fourxx', 'LAST', " Current\: %2.0lf %s");
$def[0] .= rrd::gprint('fourxx', 'AVERAGE', " Average\: %2.0lf %s");
$def[0] .= rrd::gprint('fourxx', 'MAX', " Maximum\: %2.0lf %s\j");
$def[0] .= rrd::line1('fivexx', '#FF0000', '5xx');
$def[0] .= rrd::gprint('fivexx', 'LAST', "Current\: %2.0lf %s");
$def[0] .= rrd::gprint('fivexx', 'AVERAGE', " Average\: %2.0lf %s");
$def[0] .= rrd::gprint('fivexx', 'MAX', " Maximum\: %2.0lf %s");
?>
