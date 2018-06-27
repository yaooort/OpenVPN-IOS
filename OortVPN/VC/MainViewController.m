//
//  MainViewController.m
//  OortVPN
//
//  Created by oort on 2018/6/20.
//  Copyright © 2018年 oort_vpn. All rights reserved.
//

#import "MainViewController.h"
@import NetworkExtension;

NSString * const UESRNAME = @"用户名";
NSString * const PASSWORD = @"密码";

@interface MainViewController ()

@property(strong,nonatomic) NETunnelProviderManager *providerManager;

@property(strong,nonatomic) UIButton *connBtn;


@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.connBtn = [[UIButton alloc] init];
    [self.connBtn setFrame:CGRectMake(0, 0, 100, 50)];
    [self.connBtn setCenter:self.view.center];
    [self.connBtn setTitle:@"连接" forState:UIControlStateNormal];
    [self.connBtn setBackgroundColor:[UIColor orangeColor]];
    [self.connBtn addTarget:self action:@selector(connection) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.connBtn];
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if(error){
            return ;
        }
        self.providerManager = managers.firstObject?managers.firstObject:[NETunnelProviderManager new];
        [self initProvider];
        
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVpnStateChange:) name:NEVPNStatusDidChangeNotification object:nil];
}
-(void)onVpnStateChange:(NSNotification *)Notification {
    
    switch (self.providerManager.connection.status) {
        case NEVPNStatusInvalid:
            NSLog(@"链接无效");
            break;
        case NEVPNStatusDisconnected:
            NSLog(@"未连接");
            break;
        case NEVPNStatusConnecting:
            NSLog(@"正在连接");
            break;
        case NEVPNStatusConnected:
            NSLog(@"已连接");
            break;
        case NEVPNStatusDisconnecting:
            NSLog(@"断开连接");
            break;
        case NEVPNStatusReasserting:
            NSLog(@"********************ReConnecting******************");
            break;
        default:
            break;
            
    }
}

-(void)initProvider{
    NETunnelProviderProtocol *tunel = [[NETunnelProviderProtocol alloc] init];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"SG01" withExtension:@"ovpn"];
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    tunel.providerConfiguration = @{@"ovpn": data};
    tunel.providerBundleIdentifier = @"com.yaooort.oortvpn.packettunne";
    tunel.serverAddress = @"oortopenvpn.org";
    tunel.disconnectOnSleep = NO;
    [self.providerManager setEnabled:YES];
    [self.providerManager setProtocolConfiguration:tunel];
    self.providerManager.localizedDescription = @"OortVPN";
    [self.providerManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
        if(error) {
            NSLog(@"Save error: %@", error);
        }else {
            NSLog(@"add success");
            [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                NSLog(@"loadFromPreferences!");
            }];
        }
    }];
    
}


- (void)connection{
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if(!error){
            NSError *error = nil;
            [self.providerManager.connection startVPNTunnelWithOptions:@{@"username":UESRNAME,@"password":PASSWORD} andReturnError:&error];
            if(error) {
                NSLog(@"Start error: %@", error.localizedDescription);
            }else{
                NSLog(@"Connection established!");
            }
        }
    }];
    
}

@end
