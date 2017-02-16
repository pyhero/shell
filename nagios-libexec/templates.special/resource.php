<?php
#
# (c)2016 Aiuv Co., Ltd.
# (c)2016 Panda <panda@aiuv.cc>
#
$this->MACRO['TITLE']   = "Disk";
$this->MACRO['COMMENT'] = "Total";
#
# Interfaces Connections
$services = $this->tplGetServices("(172.16)","(Disk-)");

#throw new Kohana_exception(print_r($services,TRUE));
#
# The Datasource Name for Graph 1 ( index 0 )
$ds_name[0] = "Total Disk"; 
$opt[0]	    = " --vertical-label \"Bytes\" -b 1024 --title \"Total Disk\" --slope-mode --lower-limit 0.0";
$def[0]     = "";
#
# Iterate through the list of hosts
$Total = array();
$Used = array();
$operator = array();
foreach($services as $key=>$val){
    $data    = $this->tplGetData($val['host'], $val['service']);
    $def[0] .= rrd::def("v0$key", $data['DS'][0]['RRDFILE'], $data['DS'][0]['DS'], "AVERAGE");
    $def[0] .= rrd::def("v1$key", $data['DS'][1]['RRDFILE'], $data['DS'][1]['DS'], "AVERAGE");
    array_push($Total, "v0$key");
    array_push($Used, "v1$key");
    array_push($operator, "ADDNAN");
}
//error_log("Total:".$Total."\n"."Used:".$Used."\n",3,"/tmp/xx.log");
//error_log("Total:".var_export($Total,true)."\n"."Used:".var_export($Used,true)."\n",3,"/tmp/xx.log");
array_shift($operator);
$def[0] .= rrd::cdef('Total', join($Total, ',') . "," . join($operator, ','));
$def[0] .= rrd::cdef('Used', join($Used, ',') . "," . join($operator, ','));
$def[0] .= rrd::cdef('t', 'Total,1024,*');
$def[0] .= rrd::cdef('u', 'Used,1024,*');

$def[0] .= rrd::line1('t', '#0000CC', 'Total');
$def[0] .= rrd::gprint('t', 'LAST', " Current\: %7.2lf %sB");
$def[0] .= rrd::gprint('t', 'AVERAGE', " Average\: %7.2lf %sB");
$def[0] .= rrd::gprint('t', 'MAX', " Maximum\: %7.2lf %sB\j");
$def[0] .= rrd::area('u', '#00CC00', 'Used');
$def[0] .= rrd::gprint('u', 'LAST', "Current\: %7.2lf %sB");
$def[0] .= rrd::gprint('u', 'AVERAGE', " Average\: %7.2lf %sB");
$def[0] .= rrd::gprint('u', 'MAX', " Maximum\: %7.2lf %sB");

$this->MACRO['TITLE']   = "Memory";
$this->MACRO['COMMENT'] = "Total";
#
# Interfaces Connections
$services = $this->tplGetServices("(172.16)","(HOSTSTATIC)");

#throw new Kohana_exception(print_r($services,TRUE));
#
# The Datasource Name for Graph 1 ( index 0 )
$ds_name[1] = "Total Memory"; 
$opt[1]	    = " --vertical-label \"Bytes\" -b 1024 --title \"Total Memory\" --slope-mode --lower-limit 0.0 ";
$def[1]     = "";
#
# Iterate through the list of hosts
$Total = array();
$Avail = array();
$Buffer = array();
$Cached = array();
$operator = array();
foreach($services as $key=>$val){
    $data    = $this->tplGetData($val['host'], $val['service']);
    $def[1] .= rrd::def("v0$key", $data['DS'][12]['RRDFILE'], $data['DS'][12]['DS'], "AVERAGE");
    $def[1] .= rrd::def("v1$key", $data['DS'][13]['RRDFILE'], $data['DS'][13]['DS'], "AVERAGE");
    $def[1] .= rrd::def("v2$key", $data['DS'][14]['RRDFILE'], $data['DS'][14]['DS'], "AVERAGE");
    $def[1] .= rrd::def("v3$key", $data['DS'][15]['RRDFILE'], $data['DS'][15]['DS'], "AVERAGE");
    array_push($Total, "v0$key");
    array_push($Avail, "v1$key");
    array_push($Buffer, "v2$key");
    array_push($Cached, "v3$key");
    array_push($operator, "ADDNAN");
}
//error_log(var_export($data,true)."\n",3,"/tmp/xx.log");
array_shift($operator);
$def[1] .= rrd::cdef('Total', join($Total, ',') . "," . join($operator, ','));
$def[1] .= rrd::cdef('Avail', join($Avail, ',') . "," . join($operator, ','));
$def[1] .= rrd::cdef('Buffer', join($Buffer, ',') . "," . join($operator, ','));
$def[1] .= rrd::cdef('Cached', join($Cached, ',') . "," . join($operator, ','));
$def[1] .= rrd::cdef('t', 'Total,1024,*');
$def[1] .= rrd::cdef('a', 'Avail,1024,*');
$def[1] .= rrd::cdef('u', 'Total,Avail,-,1024,*');
$def[1] .= rrd::cdef('au', 'Total,Avail,-,Buffer,-,Cached,-,1025,*');
$def[1] .= rrd::cdef('b', 'Buffer,1024,*');
$def[1] .= rrd::cdef('c', 'Cached,1024,*');

$def[1] .= rrd::line2('t', '#FF0000', 'Total');
$def[1] .= rrd::gprint('t', 'LAST', " Current\: %7.2lf %sB\j");
/*
$def[1] .= rrd::area('a', '#FF8800', 'Avail');
$def[1] .= rrd::gprint('a', 'LAST', "Current\: %7.2lf %sB");
$def[1] .= rrd::gprint('a', 'AVERAGE', " Average\: %7.2lf %sB");
$def[1] .= rrd::gprint('a', 'MAX', " Maximum\: %7.2lf %sB");
*/
$def[1] .= rrd::area('au', '#FF8800', 'Adjed Used');
$def[1] .= rrd::gprint('au', 'LAST', "Current\: %7.2lf %sB");
$def[1] .= rrd::gprint('au', 'AVERAGE', " Average\: %7.2lf %sB");
$def[1] .= rrd::gprint('au', 'MAX', " Maximum\: %7.2lf %sB");
$def[1] .= rrd::area('b', '#777777', 'Buffers', 'au');
$def[1] .= rrd::gprint('b', 'LAST', "Current\: %7.2lf %sB");
$def[1] .= rrd::gprint('b', 'AVERAGE', " Average\: %7.2lf %sB");
$def[1] .= rrd::gprint('b', 'MAX', " Maximum\: %7.2lf %sB");
$def[1] .= rrd::area('c', '#00CC00', 'Cached', 'b');
$def[1] .= rrd::gprint('c', 'LAST', "Current\: %7.2lf %sB");
$def[1] .= rrd::gprint('c', 'AVERAGE', " Average\: %7.2lf %sB");
$def[1] .= rrd::gprint('c', 'MAX', " Maximum\: %7.2lf %sB");
$def[1] .= rrd::line1('u', '#0000FF', 'Total Used');
$def[1] .= rrd::gprint('u', 'LAST', "Current\: %7.2lf %sB");
$def[1] .= rrd::gprint('u', 'AVERAGE', " Average\: %7.2lf %sB");
$def[1] .= rrd::gprint('u', 'MAX', " Maximum\: %7.2lf %sB");

$this->MACRO['TITLE']   = "Traffic";
$this->MACRO['COMMENT'] = "Private";
#
# Interfaces Connections
$services = $this->tplGetServices("(172.16)","Iface-eth0");

#throw new Kohana_exception(print_r($services,TRUE));
#
# The Datasource Name for Graph 1 ( index 0 )
$ds_name[2] = "Private Traffic"; 
$opt[2]	    = " --vertical-label \"Bytes/Second\" -b 1000 --title \"Private Traffic\" --slope-mode ";
$def[2]     = "";
#
# Iterate through the list of hosts
$InOctets = array();
$OutOctets = array();
$operator = array();
foreach($services as $key=>$val){
    $data    = $this->tplGetData($val['host'], $val['service']);
    $def[2] .= rrd::def("v0$key", $data['DS'][0]['RRDFILE'], $data['DS'][0]['DS'], "AVERAGE");
    $def[2] .= rrd::def("v1$key", $data['DS'][1]['RRDFILE'], $data['DS'][1]['DS'], "AVERAGE");
    array_push($InOctets, "v0$key");
    array_push($OutOctets, "v1$key");
    array_push($operator, "ADDNAN");
}
array_shift($operator);
$def[2] .= rrd::cdef('InOctets', join($InOctets, ',') . "," . join($operator, ','));
$def[2] .= rrd::cdef('OutOctets', join($OutOctets, ',') . "," . join($operator, ','));

$def[2] .= rrd::area('InOctets', '#00CC00', 'Input');
$def[2] .= rrd::gprint('InOctets', 'LAST', " Current\: %7.2lf %sB/s");
$def[2] .= rrd::gprint('InOctets', 'AVERAGE', " Average\: %7.2lf %sB/s");
$def[2] .= rrd::gprint('InOctets', 'MAX', " Maximum\: %7.2lf %sB/s\j");
$def[2] .= rrd::line1('OutOctets', '#0000CC', 'Output');
$def[2] .= rrd::gprint('OutOctets', 'LAST', "Current\: %7.2lf %sB/s");
$def[2] .= rrd::gprint('OutOctets', 'AVERAGE', " Average\: %7.2lf %sB/s");
$def[2] .= rrd::gprint('OutOctets', 'MAX', " Maximum\: %7.2lf %sB/s");

$this->MACRO['TITLE']   = "Traffic";
$this->MACRO['COMMENT'] = "Pubilc";
#
# Interfaces Connections
$services = $this->tplGetServices("(172.16)","Iface-eth1");

#throw new Kohana_exception(print_r($services,TRUE));
#
# The Datasource Name for Graph 1 ( index 0 )
$ds_name[3] = "Public Traffic"; 
$opt[3]	    = " --vertical-label \"Bytes/Second\" -b 1000 --title \"Public Traffic\" --slope-mode ";
$def[3]     = "";
#
# Iterate through the list of hosts
$InOctets = array();
$OutOctets = array();
$operator = array();
foreach($services as $key=>$val){
    $data    = $this->tplGetData($val['host'], $val['service']);
    $def[3] .= rrd::def("v0$key", $data['DS'][0]['RRDFILE'], $data['DS'][0]['DS'], "AVERAGE");
    $def[3] .= rrd::def("v1$key", $data['DS'][1]['RRDFILE'], $data['DS'][1]['DS'], "AVERAGE");
    array_push($InOctets, "v0$key");
    array_push($OutOctets, "v1$key");
    array_push($operator, "ADDNAN");
}
array_shift($operator);
$def[3] .= rrd::cdef('InOctets', join($InOctets, ',') . "," . join($operator, ','));
$def[3] .= rrd::cdef('OutOctets', join($OutOctets, ',') . "," . join($operator, ','));

$def[3] .= rrd::area('InOctets', '#00CC00', 'Input');
$def[3] .= rrd::gprint('InOctets', 'LAST', " Current\: %7.2lf %sB/s");
$def[3] .= rrd::gprint('InOctets', 'AVERAGE', " Average\: %7.2lf %sB/s");
$def[3] .= rrd::gprint('InOctets', 'MAX', " Maximum\: %7.2lf %sB/s\j");
$def[3] .= rrd::line1('OutOctets', '#0000CC', 'Output');
$def[3] .= rrd::gprint('OutOctets', 'LAST', "Current\: %7.2lf %sB/s");
$def[3] .= rrd::gprint('OutOctets', 'AVERAGE', " Average\: %7.2lf %sB/s");
$def[3] .= rrd::gprint('OutOctets', 'MAX', " Maximum\: %7.2lf %sB/s");
?>
