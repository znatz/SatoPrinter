//
//  ViewController.m
//  SatoPrinter
//
//  Created by 小泉 丈太 on 2015/09/25.
//  Copyright © 2015年 小泉 丈太. All rights reserved.
//

#import "Home.h"
#import <ExternalAccessory/ExternalAccessory.h>

@interface Home ()
@end

EASession * session;
@implementation Home

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)print:(id)sender {
    EAAccessoryManager* accessoryManager = [EAAccessoryManager sharedAccessoryManager];
    if (accessoryManager)
    {
        NSArray* connectedAccessories = [accessoryManager connectedAccessories];
        if ([connectedAccessories count]>=1) {
            NSLog(@"ConnectedAccessories = %@", connectedAccessories);
            EAAccessory *accessory = connectedAccessories[0];
            NSLog(@"%@", [accessory protocolStrings]);
            
            session = [[EASession alloc] initWithAccessory:accessory forProtocol:@"com.sato.protocol"];
            
            [[session inputStream] setDelegate:(id)self];
            [[session inputStream] scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [[session inputStream] open];
            
            [[session outputStream] setDelegate:(id)self];
            [[session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [[session outputStream] open];
            
        }
    }  else {
        NSLog(@"%@",@"\r\nError Turn Bluetooth on first!");
    }
    
    NSLog(@"mainthread %d times called", i);
}

- (Byte *) getBytes : (NSMutableData *) data {
    NSUInteger len = [data length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [data bytes], len);
    return byteData;
}

int i = 0;

- (void)stream:(NSOutputStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    int position = 0;
    uint8_t pStart[47] = {
                0X02,
                0x1B, 0x41, 0x1B, 0x41, 0x31, 0x56, 0x30, 0x30, 0x34, 0x32, 0x34, 0x48, 0x30, 0x34, 0x30, 0x30,
                0x1B, 0x4B, 0x43, 0x31, 0x1B, 0x56, 0x30, 0x30, 0x32, 0x30, 0x1B, 0x48, 0x30, 0x30, 0x34, 0x30,
                0x1B, 0x50, 0x30, 0x30, 0x1B, 0x4C, 0x30, 0x31, 0x30, 0x32, 0x1B, 0x4B, 0x39, 0x42} ;
    position += 47;
    
    uint8_t pEnd[6] = {0x1B, 0x51, 0x31, 0x1B, 0x5A, 0x03};
    position += 6;
    
    
    if (eventCode == 4) {
       if (i<1) {
           NSString *str = [NSString stringWithFormat:@"デバッグテスト：%i.回目の呼び出しだ",i];
           NSLog(@"%@", str);
           position += [str length] * 2;
           NSData *data = [str dataUsingEncoding:NSShiftJISStringEncoding];
           NSMutableData *strData = [[NSMutableData alloc] initWithData:data];
                
           
           NSMutableData *holder = [[NSMutableData alloc] initWithBytes:pStart length:47];
           [holder appendBytes:[self getBytes:strData] length:[str length]*2];
           [holder appendBytes:pEnd length:6];
        
           NSLog(@"%@", holder);
 
           NSInteger written = [[session outputStream] write:(const uint8_t *)[self getBytes:holder] maxLength:position];
           stream =nil;
           i++;
           NSLog(@"%d times called, eventcode %lu, position %d written: %d", i, (unsigned long)eventCode, position, written);
           [[session outputStream] close];
           [[session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        
        NSLog(@"outer %d times called, eventcode %lu", i, (unsigned long)eventCode);
    }

    NSLog(@"outer outer %d times called, eventcode %lu", i, (unsigned long)eventCode);
    
}


@end
