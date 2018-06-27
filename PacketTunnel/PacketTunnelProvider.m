//
//  PacketTunnelProvider.m
//  PacketTunnel
//
//  Created by oort on 2018/6/20.
//  Copyright © 2018年 oort_vpn. All rights reserved.
//

#import "PacketTunnelProvider.h"
#import "NEPacketTunnelFlow+NEPacketTunnelFlow_Extension.h"
@implementation PacketTunnelProvider

-(OpenVPNAdapter*)vpnAdapter{
    if(!_vpnAdapter){
        _vpnAdapter = [[OpenVPNAdapter alloc] init];
        _vpnAdapter.delegate = self;
    }
    return _vpnAdapter;
}

-(OpenVPNReachability*)openVpnReach{
    if(!_openVpnReach){
        _openVpnReach = [[OpenVPNReachability alloc] init];
    }
    return _openVpnReach;
}

-(void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData * _Nullable))completionHandler{
    
}

-(void)startTunnelWithOptions:(NSDictionary<NSString *,NSObject *> *)options completionHandler:(void (^)(NSError * _Nullable))completionHandler{

    NETunnelProviderProtocol *proto =  (NETunnelProviderProtocol*)self.protocolConfiguration;
    if(!proto){
        return;
    }
    NSDictionary<NSString *,id> *provider = proto.providerConfiguration;
    NSData * fileContent = provider[@"ovpn"];
    OpenVPNConfiguration *openVpnConfiguration = [[OpenVPNConfiguration alloc] init];
    openVpnConfiguration.fileContent = fileContent;
    NSError *error;
    OpenVPNProperties *properties = [self.vpnAdapter applyConfiguration:openVpnConfiguration error:&error];
    if(error){
        return;
    }
    
    if(!properties.autologin){
        OpenVPNCredentials *credentials = [[OpenVPNCredentials alloc] init];
        credentials.username = [NSString stringWithFormat:@"%@",[options objectForKey:@"username"]];
        credentials.password = [NSString stringWithFormat:@"%@",[options objectForKey:@"password"]];
        [self.vpnAdapter provideCredentials:credentials error:&error];
        if(error){
            return;
        }
    }
    
    [self.openVpnReach startTrackingWithCallback:^(OpenVPNReachabilityStatus status) {
        if(status==OpenVPNReachabilityStatusNotReachable){
            [self.vpnAdapter reconnectAfterTimeInterval:5];
        }
    }];
    
    [self.vpnAdapter connect];
    self.startHandler = completionHandler;
}


-(void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler{
    if ([self.openVpnReach isTracking]) {
        [self.openVpnReach stopTracking];
    }
    
    [self.vpnAdapter disconnect];
    self.stopHandler = completionHandler;
}


-(void)openVPNAdapter:(OpenVPNAdapter *)openVPNAdapter handleError:(NSError *)error{
    BOOL isOpen = (BOOL)[error userInfo][OpenVPNAdapterErrorFatalKey];
    if(isOpen){
        if (self.openVpnReach.isTracking) {
            [self.openVpnReach stopTracking];
        }
        self.startHandler(error);
        self.startHandler = nil;
        
    }
}


-(void)openVPNAdapterDidReceiveClockTick:(OpenVPNAdapter *)openVPNAdapter{
    
}

-(void)openVPNAdapter:(OpenVPNAdapter *)openVPNAdapter handleEvent:(OpenVPNAdapterEvent)event message:(NSString *)message{
    switch (event) {
        case OpenVPNAdapterEventConnected:
            if(self.reasserting){
                self.reasserting = false;
            }
            self.startHandler(nil);
            self.startHandler = nil;
            break;
        case OpenVPNAdapterEventDisconnected:
            if (self.openVpnReach.isTracking) {
                [self.openVpnReach stopTracking];
            }
            self.stopHandler();
            self.stopHandler = nil;
            break;
        case OpenVPNAdapterEventReconnecting:
            self.reasserting = true;
            break;
        default:
            break;
    }
}

-(void)openVPNAdapter:(OpenVPNAdapter *)openVPNAdapter configureTunnelWithNetworkSettings:(NEPacketTunnelNetworkSettings *)networkSettings completionHandler:(void (^)(id<OpenVPNAdapterPacketFlow> _Nullable))completionHandler{
    __weak __typeof(self) weak_self = self;
    [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
        if(!error){
            completionHandler(weak_self.packetFlow);
        }
    }];
    
}


@end


