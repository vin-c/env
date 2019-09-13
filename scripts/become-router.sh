#!/bin/bash

IF_NET=wlp2s0
IF_SHARED=eno0

iptables -A FORWARD -o $IF_NET -i $IF_SHARED -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $IF_NET -o $IF_SHARED -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -o $IF_NET -i $IF_SHARED -j ACCEPT
iptables -A FORWARD -i $IF_NET -o $IF_SHARED -j ACCEPT
iptables -t nat -A POSTROUTING -o $IF_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -o $IF_SHARED -j MASQUERADE
