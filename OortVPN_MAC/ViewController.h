//
//  ViewController.h
//  OortVPN_MAC
//
//  Created by bunny on 2018/6/20.
//  Copyright © 2018年 oort_vpn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import NetworkExtension;
@interface ViewController : NSViewController
@property(strong,nonatomic) NETunnelProviderManager *providerManager;

@end

