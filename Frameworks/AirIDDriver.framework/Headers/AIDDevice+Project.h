//
//  AIDDevice+Project.h
//  AirIDDriver
//
//  Created by Wolfgang Sebastian Blaum on 14.08.14.
//  Updated by several people since then.
//  Copyright (c) 2014 Unicept GmbH. All rights reserved.
//  Copyright (c) 2017, 2018, 2019 certgate GmbH. All rights reserved.
//

#import "AIDDevice.h"
#define CCM_TAG_LEN 4 // xenox was 8 changed on suggestion by AKE as all other drivers use 4

// for full description see  https://confluence.certgate.com/pages/viewpage.action?pageId=73762295#RemoteProcedureCalls(RPC)-DeviceSettings
typedef NS_ENUM(uint8_t, RPCMethod)
{
    RPCMethodDeviceDescriptor     = 0x01,
    
    RPCMethodSCard                = 0x02,
   
    RPCMethodExchangeKey          = 0x03,
    
    RPCMethodSetDeviceFinderName  = 0x04,
   
    RPCMethodBatteryLevel         = 0x05,
   
    RPCMethodCardInformation      = 0x06,
   
    /* RPCMethodSetEncryptionKey  = 0x07, */
    RPCMethodReadSettings         = 0x08,
   
        // marked as reserved at https://confluence.certgate.com/pages/viewpage.action?pageId=73762295#RemoteProcedureCalls(RPC)-DeviceSettings
    RPCMethodReadCertificate      = 0x09,
    
    RPCMethodSetTime              = 0x0A,
    
    RPCMethodGetWorkingTimeRanges = 0x0B,
    
    RPCMethodSetWorkingTimeRanges = 0x0C,
    
    // xenox - FIXME - https://jira.certgate.com/browse/AIMSDK-10
    RPCMethodGetDeviceState       = 0x0D,
    
    RPCMethodGetPairedList        = 0x0E,
    
    RPCMethodRemovePairedDevice   = 0x0F,
    
    // xenox - FIXME - https://jira.certgate.com/browse/AIMSDK-10
    RPCMethodGetDataBufferSize    = 0x10,
    
    RPCMethodGetBatteryState      = 0x11,
    
    /* RPCMethodReserved          = 0x12, */
    
    RPCMethodSetConnIntervalDynamic = 0x40,
    
    RPCMethodSetConnIntervalParams  = 0x41,
    
    RPCMethodSetInitBLESecurity     = 0x42,
    
    RPCMethodSetResponsePacketDataSize = 0x43,
    
    RPCMethodGetGaugeParameters     = 0x44,
    
    RPCMethodSetAdvIntervalParams   = 0x45,
   
    // https://confluence.certgate.com/pages/viewpage.action?pageId=73762295#AirID-RemoteProcedureCalls(RPC)-0x46SetAdvertisingIntervalDynamic
    RPCMethodSetAdvIntervalDynamic = 0x46,
    
    // https://confluence.certgate.com/pages/viewpage.action?pageId=73762295#AirID-RemoteProcedureCalls(RPC)-0x47RSSIstats(COREFW-473)
    RPCMethodGetRSSIStats          = 0x47,
    
    // https://confluence.certgate.com/pages/viewpage.action?pageId=73762295#AirID-RemoteProcedureCalls(RPC)-0x48GetLoggedEventsData
    RPCMethodGetLoggedEventData    = 0x48,
    
    
    RPCMethodRequestEncryption    = 0xA0
};

typedef NS_ENUM(uint8_t, RPCKeyFailure)
{
    RPCKeyFailureInvalidLength      = 0x01,
    RPCKeyFailureEncryptionDisabled = 0x02,
    RPCKeyFailureNoRandom = 0x03,
};

typedef NS_ENUM(uint8_t, AIDDeviceSettingType)
{
    AIDDeviceSettingTypeSignalStrength  = 0x01,
    AIDDeviceSettingTypeAdvertisingMode = 0x02,
    AIDDeviceSettingTypeDisplay         = 0x03,
    AIDDeviceSettingTypeBacklight       = 0x04,
    AIDDeviceSettingTypeContrast        = 0x05,
    AIDDeviceSettingTypeBuzzer          = 0x06,
    AIDDeviceSettingTypeEncryption      = 0x07,
    AIDDeviceSettingTypeCoverage        = 0x08,
};

/**
 * represents a BLE MAC hardware address
 */
typedef struct AIDHardwareAdress
{
    uint8_t byte0;
    uint8_t byte1;
    uint8_t byte2;
    uint8_t byte3;
    uint8_t byte4;
    uint8_t byte5;
} __attribute__((packed)) AIDHardwareAdress;

/** represents the Battery Level on an AirID device
 */
typedef uint8_t AIDBatteryLevel;

typedef struct AIDDeviceSetting
{
    AIDDeviceSettingType type;
    uint8_t value;
} __attribute__((packed)) AIDDeviceSetting;


// https://confluence.certgate.com/pages/viewpage.action?pageId=73762295#AirID-RemoteProcedureCalls(RPC)-0x48GetLoggedEventsData
typedef struct AIDLogEventData
{
  uint32_t ticks; // ticks since system start = 1/1024s
  uint32_t event; // event id
  uint16_t duration; // task duration ticks, max. 64s
  union {
    uint8_t tmr_handle; // soft timer handle
    uint32_t ext_signals; // external signals bitfield
    struct {
      uint8_t connection; // connection id
      union {
        uint16_t mtu; // mtu size
        int8_t rssi; // rssi level
        uint16_t reason; // reason
        uint16_t result; // result
      };
    };
  };
} __attribute__((packed)) AIDLogEventData;



@class AIDDeviceManager;
@protocol AIDDeviceState;

@interface AIDDevice ()

@property(strong, nonatomic) NSNumber *RSSI;
@property(strong, nonatomic, readonly) NSNumber *atrLength;
@property(strong, nonatomic, readonly) NSNumber *atrIndex;
@property(strong, nonatomic) NSDictionary *deviceDescriptor;
@property(strong, nonatomic) CBPeripheral *peripheral;
@property(strong, nonatomic) NSDictionary *advertisementData;
@property(strong, nonatomic) NSOperationQueue *operationQueue;

@property(strong, nonatomic) NSValue *advertisementInfoVersion1;
@property(strong, nonatomic) NSValue *advertisementInfoVersion2;
@property(strong, nonatomic) NSNumber *batteryLevel;
@property(nonatomic) int tmpdataBufferSize;
@property(nonatomic) NSUInteger tmpcommandSize;
@property(nonatomic) NSUInteger tmpresponseSize;

@property(nonatomic) BOOL cablePlugged;
//TODO: remove this if you delete deprecated property cardOS from AIDDevice
@property(strong, nonatomic) NSValue *atrInfo;
@property(strong, nonatomic) NSMutableDictionary *deviceSettings;

@property(strong, nonatomic) id<AIDDeviceState> state;
@property(strong, nonatomic) AIDDeviceData *deviceData;

@property(strong, nonatomic) NSString *accessGroup;


- (void)setInternalCardStatus:(AIDCardStatus)internalCardStatus;
- (void)initSessionKeyWithIV:(uint8_t *)IV key: (uint8_t *)sessionK exchange:(bool) exchangeKey;


- (instancetype)initWithDeviceData:(AIDDeviceData *)deviceData NS_DESIGNATED_INITIALIZER;

- (void)callMethodRaw:(NSData *)data isEncrytionOperation:(bool)isEncrytionOperation keepResult:(bool)keepResult completion:(void (^)(NSData *receivedData, NSError *error))callback;
- (void)callMethod:(RPCMethod)method data:(NSData *)data completion:(void (^)(NSData *receivedData, NSError *error))callback;

- (void)deviceManager:(AIDDeviceManager *)manager didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
- (void)deviceManager:(AIDDeviceManager *)manager didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)deviceManager:(AIDDeviceManager *)manager didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
// check if 256bit LTK is available in keychain
- (bool)checkLTK;
// remove 256Bit LTK from keychain
- (void)cleanupLTK;
- (void)startExchangeKey;
- (void)handleKeyExchangeFailureWithData:(NSData *)data error:(NSError *)error;
- (void)handleKeyExchangeSuccessWithData:(NSData *)data;

- (void) setDataBufferSize:(int)dataBufferSize;
- (void) setCommandSize:(NSUInteger)commandSize;
- (void) setResponseSize:(NSUInteger)responseSize;

- (void)startService;
- (NSData *)createDeviceNameData;

@end
