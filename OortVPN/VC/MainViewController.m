//
//  MainViewController.m
//  OortVPN
//
//  Created by bunny on 2018/6/20.
//  Copyright © 2018年 oort_vpn. All rights reserved.
//

#import "MainViewController.h"
@import NetworkExtension;


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
    tunel.providerBundleIdentifier = @"com.yaooort.oortvpn.packettunnel";
    tunel.serverAddress = @"47.88.228.77";
    tunel.username = @"0970136610";
    [self createKeychainValue:@"111111" forIdentifier:@"VPN_PASSWORD"];
    tunel.passwordReference =  [self searchKeychainCopyMatching:@"VPN_PASSWORD"];
    [self.providerManager setEnabled:YES];
    [self.providerManager setProtocolConfiguration:tunel];
    self.providerManager.localizedDescription = @"测试VPN";
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
            [self.providerManager.connection startVPNTunnelAndReturnError:&error];
            if(error) {
                NSLog(@"Start error: %@", error.localizedDescription);
            }else{
                NSLog(@"Connection established!");
            }
        }
    }];
    
}




















#pragma mark--秘钥获取与生成
- (NSData *)searchKeychainCopyMatching:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [searchDictionary setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
    return (__bridge_transfer NSData *)result;
}

- (BOOL)createKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier {
    // creat a new item
    NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
    //OSStatus 就是一个返回状态的code 不同的类返回的结果不同
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    [dictionary setObject:passwordData forKey:(__bridge id)kSecValueData];
    status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    if (status == errSecSuccess) {
        return YES;
    }
    return NO;
}
//服务器地址
static NSString * const serviceName = @"com.yaooort.oortvpn";
- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    //   keychain item creat
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    //   extern CFTypeRef kSecClassGenericPassword  一般密码
    //   extern CFTypeRef kSecClassInternetPassword 网络密码
    //   extern CFTypeRef kSecClassCertificate 证书
    //   extern CFTypeRef kSecClassKey 秘钥
    //   extern CFTypeRef kSecClassIdentity 带秘钥的证书
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    //ksecClass 主键
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:serviceName forKey:(__bridge id)kSecAttrService];
    return searchDictionary;
}
@end
