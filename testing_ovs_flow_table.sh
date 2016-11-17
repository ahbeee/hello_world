#!/bin/bash
#
# Pica8 Toolman Project
# Author: Phil Huang <phil_huang@edge-core.com>
#
# Reference:
# 1. http://www.rendoumi.com/open-vswitchzhong-ovs-ofctlde-xiang-xi-yong-fa/
# 2. http://www.pica8.com/document/v2.6/pdf/ovs-commands-reference.pdf
# 3. http://intranet.pica8.com/display/picos27sp/Optimizing+TCAM+Usage
#
# By default, the hardware aside two flows, so the max number of flow is 2046
#

function flush() {

ovs-vsctl del-br ovs-br
[ -f flow_list ] && rm flow_list
ovs-vsctl add-br ovs-br
#Physical port for 1g or 10g
ovs-vsctl add-port ovs-br te-1/1/1 -- set Interface te-1/1/1 type=pica8
#ovs-vsctl add-port ovs-br ge-1/1/1 -- set Interface ge-1/1/1 type=pica8
}

function show_flow_entries() {

SLEEP_TIME=60
echo "Wait for $SLEEP_TIME to add flow entry"
sleep $SLEEP_TIME
echo "Total of Hardware Flow Entry"
ovs-appctl pica/dump-flows | grep "Total"
echo "Total of Software Flow Entry"
ovs-ofctl dump-flows ovs-br | wc -l

}

function add_flows() {

ovs-ofctl add-flows ovs-br flow_list

}

function set_match_mode() {

echo
echo "TCPv4/UDPv4 with enable set-match-mode, it can only match below fields:"
echo "in_port, nw_proto, nw_src, nw_dst, dl_type=0x0800"
echo
#Short Flow TCAM
ovs-vsctl set-match-mode mac=10-1000,ip=2000-20000,arp_tpa=30000-40000,ipv6_full=50000-50001,ipv6_dst=50002-50003,ipv6_src=50004-60000
#Default
#ovs-vsctl set-match-mode default 
}

function generate_flow_list() {

flush

for i in `seq 1 150`; do
  for k in `seq 1 150`; do
    eval "ENTRY=\"$1\""
    echo "$ENTRY" >> flow_list
  done
done

}

function generate_flow_list_1() {

flush

for i in `seq 0 9`; do
  for j in `seq 0 9`; do
    for k in `seq 0 9`; do
      for l in `seq 0 9`; do
        for m in `seq 1 2`; do
          eval "ENTRY=\"$1\""
          echo "$ENTRY" >> flow_list
	    done
      done
    done
  done
done

}

function test_case_1() {

echo
echo "Test Case 1: ARP Matching"
echo "in_port, arp_tpa, dl_type=0x0806"
echo

FLOW_PATTERN="priority=30000,in_port=1,arp_tpa=192.168.\$i.\$k,dl_type=0x0806,actions=output:2"

set_match_mode
generate_flow_list $FLOW_PATTERN
add_flows
show_flow_entries

}

function test_case_2() {

echo
echo "Test Case 2: MAC Matching"
echo "in_port, dl_src, dl_dst, dl_vlan, dl_type"
echo

FLOW_PATTERN="priority=900,in_port=1,dl_src=00:11:22:33:\$i\$j:55,dl_dst=11:22:33:44:55:\$k\$l,dl_vlan=\$m,dl_type=0x0806,actions=output:2"

set_match_mode
generate_flow_list_1 $FLOW_PATTERN
add_flows
show_flow_entries

}

function test_case_3() {

echo
echo "Test Case 3: L3 IPv4 Matching"
echo "in_port, nw_proto, nw_src, nw_dst, dl_type=0x0800"
echo

FLOW_PATTERN="priority=2000,in_port=1,dl_type=0x0800,nw_proto=6,nw_src=10.1.\$k.\$i,nw_dst=10.1.\$i.\$k,actions=output:2"

set_match_mode
generate_flow_list $FLOW_PATTERN
add_flows
show_flow_entries

}

function test_case_4() {

echo
echo "Test Case 4: L3 Ipv6 (Full mode) Matching"
echo "in_port,dl_vlan,ipv6_src,ipv6_dst,nw_proto,dl_type=0x86dd"
echo

FLOW_PATTERN="priority=50000,in_port=1,dl_vlan=\$i,ipv6_src=2001::1:\$i,ipv6_dst=2001::2:\$k,nw_proto=6,dl_type=0x86dd,actions=output:2"

set_match_mode
generate_flow_list $FLOW_PATTERN
add_flows
show_flow_entries

}

function test_case_5() {

echo
echo "Test Case 5: L3 Ipv6 (Dst mode) Matching"
echo "in_port,dl_src,dl_dst,dl_vlan,ipv6_dst,nw_proto,dl_type=0x86dd"
echo

FLOW_PATTERN="priority=50002,in_port=1,dl_src=00:11:22:33:44:55,dl_dst=11:22:33:44:55:66,dl_vlan=1,ipv6_dst=2001::\$i:\$k,nw_proto=6,dl_type=0x86dd,actions=output:2"

set_match_mode
generate_flow_list $FLOW_PATTERN
add_flows
show_flow_entries

}
function test_case_6() {

echo
echo "Test Case 6: L3 Ipv6 (Src mode) Matching"
echo "in_port,dl_src,dl_dst,dl_vlan,ipv6_src,nw_proto,dl_type=0x86dd"

FLOW_PATTERN="priority=50004,in_port=1,dl_src=00:11:22:33:44:55,dl_dst=11:22:33:44:55:66,dl_vlan=1,ipv6_src=2001::\$i:\$k,nw_proto=6,dl_type=0x86dd,actions=output:2"

set_match_mode
generate_flow_list $FLOW_PATTERN
add_flows
show_flow_entries

}

function test_case_7() {

echo
echo "Test Case 7: L4 TCPv4 Matching"
echo

FLOW_PATTERN="dl_src=00:11:22:33:44:55,dl_dst=11:22:33:44:55:66,dl_type=0x0800,dl_vlan=\$k,dl_vlan_pcp=\$i,nw_proto=6,nw_tos=123,tp_src=123,tp_dst=321,nw_src=10.1.\$i.\$k,nw_dst=10.1.\$k.\$i,actions=output:2"

set_match_mode
generate_flow_list $FLOW_PATTERN
add_flows
show_flow_entries

}

function test_case_8() {

echo
echo "Test Case 8: L4 UDPv4 Matching"
echo

FLOW_PATTERN="dl_src=00:11:22:33:44:55,dl_dst=11:22:33:44:55:66,dl_type=0x0800,dl_vlan=1,dl_vlan_pcp=1,nw_proto=17,nw_tos=63,udp_src=4444,udp_dst=44443,nw_src=10.1.\$i.\$k,nw_dst=10.1.\$k.\$i,actions=output:2"

set_match_mode
generate_flow_list $FLOW_PATTERN
add_flows
show_flow_entries

}
# Main Process

#test_case_1 # ARP
#test_case_2 # MAC
#test_case_3 # L3 IPv4
#test_case_4 # L3 IPv6 Full
#test_case_5 # L4 IPv6 Dst
#test_case_6 # L4 IPv6 Src
#test_case_7 # L4 TCPv4
#test_case_8 # L4 UDPv4

