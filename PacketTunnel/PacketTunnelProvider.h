//
//  PacketTunnelProvider.h
//  PacketTunnel
//
//  Created by oort on 2018/6/20.
//  Copyright © 2018年 oort_vpn. All rights reserved.
//

@import NetworkExtension;
@import OpenVPNAdapter;

@interface PacketTunnelProvider : NEPacketTunnelProvider<OpenVPNAdapterDelegate>

@property(nonatomic,strong) OpenVPNAdapter *vpnAdapter;

@property(nonatomic,strong) OpenVPNReachability *openVpnReach;

typedef void(^StartHandler)(NSError * _Nullable);
typedef void(^StopHandler)(void);

@property(nonatomic,copy) StartHandler startHandler;

@property(nonatomic,copy) StopHandler stopHandler;

@end
