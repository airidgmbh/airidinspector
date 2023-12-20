//
//  AIDCard.h
//  Test
//
//  Created by Wolfgang Sebastian Blaum on 16.07.14.
//  Updated by several people since then.
//  Copyright (c) 2014 Unicept GmbH. All rights reserved.
//  Copyright (c) 2017, 2018, 2019 certgate GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pcsclite.h"
#import "AIDDefines.h"

/** @enum AIPCardProtocol is used the distinguish between different ISO 7816 low level TPDU protocol a smartcard uses
 */
typedef NS_OPTIONS(NSUInteger, AIPCardProtocol){
    /** TPDU protocol not supported     */
    AIPCardProtocolUndefined = 0,
    /** card prefers to use T=0 TPDU protocol     */
    AIPCardProtocolT0 = (1 << 0),
      /** card prefers to use T=1 TPDU protocol     */
    AIPCardProtocolT1 = (1 << 1),
      /** card supports T=0 and T=1 TPDU protocol     */
    AIPCardProtocolTx = (AIPCardProtocolT0 | AIPCardProtocolT1),
      /** card prefers to use low level TPDU protocol  ?   */
    AIPCardProtocolRaw = (1 << 4),
};

NS_ASSUME_NONNULL_BEGIN

/** AIDCardAPDUCompletionHandler */
typedef void (^AIDCardAPDUCompletionHandler)(NSData * _Nullable receivedData, SCARD_IO_REQUEST * _Nullable receiveProtocol, NSError * _Nullable error);
/** AIDCardResetCompletionHandler */
typedef void (^AIDCardResetCompletionHandler)(NSData * _Nullable receivedData, NSError * _Nullable error);
/** AIDCardShutdownCompletionHandler  */
typedef void (^AIDCardShutdownCompletionHandler)(NSError * _Nullable error);

typedef void (^AIDCardSetProtocolCompletionHandler)(NSError * _Nullable error);

@class AIDCard;

@class AIDDevice;
/**
 * The AIDCard interface provides an  way to communicate with  a smartcard
 *
 ## Connecting with the SmartCard
 
 When successfully connected and initialized with the AirID reader you can either use the winscard inspired API in AirIdSCard.h or the card-property of AIDDevice to talk to the SmartCard. The latter is recommended and shown here.
 
 First you have to reset the card. This will power on the card if it's not already.
 
 ~~~ objc
 // reset card and get the Answer-to-reset
 // if [AIDDevice card] is not nil a card is present in the reader
 if ([device card] != nil)
 {
 [[device card] resetCardWithCompletion:^(NSData *receivedData, NSError *error)
 {
     if(error == nil)
     {
        //receivedData will contain the Answer-to-reset of the SmartCard
     }
 }];
 }
 ~~~
 
 After that you can send APDUs to the card by calling `[AIDCard sendAPDUWithData:(NSData*)data withIORequest:(const SCARD_IO_REQUEST*)request completion:(void (^)(NSData* receivedData, SCARD_IO_REQUEST* receiveProtocol))callback;]`. Use NULL for the SCARD_IO_REQUEST as protocol-testing is not implemented yet. The AirID assumes usage of the first reported protocol if multiple are supported.
 
 ~~~ objc
 if ([device card] != nil) {
 [[_device card] sendAPDUWithData:data withIORequest:NULL completion:^(NSData *receivedData, SCARD_IO_REQUEST* receiveProtocol) {
 //receivedData will contain the answer to your APDU
 }];
 }
 ~~~
 
 When finished with your task you should call `[AIDCard shutdownCardWithCompletion:(void (^)())callback`. This will power off the card and helps unnecessarily draining power from the AirIDs battery.
 */
@interface AIDCard : NSObject

/** Identifies the active protocol that the card has
 
 Note: The activeProtocol value doesn't reflect on the actual card protocol unless the card is first turned on (with resetCardWithCompletion).
 
 And will be changed upon successful change of the card's protocol with (setProtocol) method.
 */
@property(readonly) AIPCardProtocol activeProtocol;

/** Identifies the supported card protocol, if the card supports both T=0 and T=1, the value of this property should be AIPCardProtocolTx.
 */
@property(readonly) AIPCardProtocol supportedProtocol;

/* AIDDevice also references AIDCard, to avoid circular dependencies,
   use only a weak reference here */
@property(weak, nonatomic) AIDDevice *device;

- (instancetype)init __attribute__((unavailable("This is not the designated initializer for AIDCard")));
/** initializes this AIDCard object for a given AirID device
 * @param device - the  AirID device where the smartcard is asigned to
 */
- (instancetype)initWithDevice:(AIDDevice *)device NS_DESIGNATED_INITIALIZER;

/** sendAPDUwithData allows you to send and retrieve C-APDU and R-APDU data pakets without the need to use the winscard API
 *
 * @param data - the APDU data to submit
 * @param request - the SCARD_iO_REQUEST
 * @param callback - callback completion handler
 *
 */
- (void)sendAPDUWithData:(NSData *)data withIORequest:(nullable const SCARD_IO_REQUEST *)request completion:(AIDCardAPDUCompletionHandler)callback;

/** resetCardWithCompletion allows you to reset (powering on) and smardcard inserted in an AirID device
 *
 * @param callback - callback completion handler
 *
 */
- (void)resetCardWithCompletion:(nullable AIDCardResetCompletionHandler)callback;

/** setprotocol allows you to select the protocol T = 0 or T = 1
 * @param protocol protocol to be specified, either 0 for T = 0 or 1 for T = 1
 * @param callback - callback completion handler
 *
 */
- (void)setProtocol:(AIPCardProtocol)protocol completion:(nonnull AIDCardSetProtocolCompletionHandler)callback;

/** When finished with your task you should call [AIDCard shutdownCardWithCompletion:(void (^)())callback. This will power off the card and helps unnecessarily draining power from the AirIDs battery.
 *
 * @param callback - callback completion handler
 *
 */
- (void)shutdownCardWithCompletion:(nullable AIDCardShutdownCompletionHandler)callback;

/** start smardcard transaction */
- (BOOL)beginTransaction;
/** stop smardcard transaction */
- (void)endTransaction;

AID_EXTERN NSString *const AIDCardErrorDomain;

typedef NS_ENUM(NSUInteger, AIDCardError) {
    AIDCardErrorUnknown = 0,
    AIDCardErrorSharingViolation = 1,
    AIDCardErrorNotSupportedProtocol = 2,
};

NS_ASSUME_NONNULL_END

@end
