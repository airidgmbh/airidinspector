//
//  AIDDeviceManager.h
//  AirIDDriver
//
//  Created by Wolfgang Sebastian Blaum on 17.07.14.
//  Updated by several people since then.
//  Copyright (c) 2014 Unicept GmbH. All rights reserved.
//  Copyright (c) 2017, 2018, 2019 certgate GmbH. All rights reserved.

#ifndef AIRID_DRIVER_H
#define AIRID_DRIVER_H

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "AIDDefines.h"

NS_ASSUME_NONNULL_BEGIN

AID_EXTERN NSString *const AIDDriverVersion;

@class AIDDeviceManager, AIDService, AIDDevice, UICKeyChainStore;
/**
 *
 *
 */
@protocol AIDDeviceManagerDelegate<NSObject>
    
@optional

- (void)deviceManagerStatePowerOn:(AIDDeviceManager *)manager;
- (void)deviceManagerStatePowerOff:(AIDDeviceManager *)manager;

/**
 * This is called before the user selected device is changed.
 * It will be not called after disconnecting the user selected device and subsequently connecting it as the user
 * selected device has not changed (just the state changed).
 * @param manager - an shared instance of the AirIDDeviceManager
 * @param device - The selected AirID device
 */
- (void)deviceManager:(AIDDeviceManager *)manager willChangeUserSelectedDevice:(AIDDevice *)device;

/**
 * This is called after the user selected device is changed.
 * @param manager - an shared instance of the AirIDDeviceManager
 * @param device - The selected AirID device
 */
- (void)deviceManager:(AIDDeviceManager *)manager didChangeUserSelectedDevice:(AIDDevice *)device;

/**
 * This will be called each time the device list changes.
 * @param manager - an shared instance of the AirIDDeviceManager
 * see The devices object documentation for details when the list changes.
 */
- (void)deviceManagerDidChangeDeviceList:(AIDDeviceManager *)manager;

/**
 * If the delegate implements this callback it will be called when forgetUserSelectedDevice was called.
 * @param manager - an shared instance of the AirIDDeviceManager
 */
- (void)deviceManagerDidForgetUserSelectedDevice:(AIDDeviceManager *)manager;

/**
* If the delegate implements this method the framework will not show any disconnection error message by itself.
* @param manager - an shared instance of the AirIDDeviceManager
* @param device - The selected AirID device
*/
- (void)deviceManager:(AIDDeviceManager *)manager didConnectDevice:(AIDDevice *)device;

/**
 * If the delegate implements this method the framework will not show any disconnection error message by itself.
 * @param manager - an shared instance of the AirIDDeviceManager
 * @param device - The selected AirID device
 * @param error - the error in case disconnect failed
 */
- (void)deviceManager:(AIDDeviceManager *)manager didDisconnectDevice:(AIDDevice *)device error:(nullable NSError *)error;

/**
 * Called if the device failed to connect in which case the error will be set.
 * @param manager - an shared instance of the AirIDDeviceManager
 * @param device - The selected AirID device
 * @param error - the error in case disconnect failed
 */
- (void)deviceManager:(AIDDeviceManager *)manager didFailToConnectDevice:(AIDDevice *)device error:(nullable NSError *)error;

@end

/**
 The AIDDeviceManager is the main entrance to the AirIDDriver SDK
 The device manager gives you the opportunity to search for AirIDs and connect to a device. Call `[[AIDDeviceManager sharedManager] setScanForPeripherals:YES]` before calling `[[AIDDeviceManager sharedManager] start]` to tell the device manager to scan for AirIDs.
 To be notified when devices appear or disappear either set the delegate property of the device manager or register the `AIDDeviceManagerDidChangeDeviceList`
 notification in `NSNotificationCenter`.
 
 Here is an example:
 
 ~~~ objc
 - (void)startDeviceManagerScanningForDevices  {
 // set yourself as delegate
 AIDDeviceManager.sharedManager.delegate = self;
 
 // (or)register for notification
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(deviceListChanged:)
 name:AIDDeviceManagerDidChangeDeviceList
 object:nil];
 
 AIDDeviceManager.sharedManager.autoConnectSavedDevice = NO;
 AIDDeviceManager.sharedManager.scanForPeripherals = YES;
 [AIDDeviceManager.sharedManager start];
 }
 ~~~
 
 Depending of which alternative you choose, implement one of the following:
 
 1.)
 
 ~~~objc
 - (void)deviceListChanged:(NSNotification*)notification {
 NSArray* devices = [[AIDDeviceManager sharedManager] devices];
 //Do something with devices. Use [AIDDevice name] for displaying purposes.
 //Use main queue if you change any UI
 dispatch_async(dispatch_get_main_queue(), ^{
 });
 }
 ~~~
 
 2.)
 
 ~~~objc
 - (void)deviceManagerDidChangeDeviceList:(AIDDeviceManager *)manager {
 NSArray* devices = manager.devices;
 //Do something with devices. Use [AIDDevice name] for displaying purposes.
 //Use main queue if you change any UI
 dispatch_async(dispatch_get_main_queue(), ^{
 });
 }
 ~~~
 
 To connect to the desired device and get notified when the device ist ready to use, add an observer to the device status property and call '[AIDDeviceManager connect:(AIDDevice*)]`
 
 ~~~objc
 [device addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:nil];
 [[AIDDeviceManager sharedManager] connectDevice:device];
 ~~~
 
 You can use the device when its status changed to 'AIDDeviceStatusInitialized'(see "Using Central App").
 
 If you want to save and remember the AirID your user has chosen, use `[AIDDevice identifer]`. This will uniquely identify the AirID device. You can then check if the device you want to reconnect is in the list of found devices:
 
 ~~~objc
 if ([[device identifier] isEqual:myDeviceIdentifier] && [device status] == AIDDeviceStatusPresent) {
 }
 ~~~
 
 ## Reconnecting the device
 
 If you set `[[AIDDeviceManager sharedManager] setAutoConnectSavedDevice:YES]` the device which was connected last will be automatically disconnected and reconnected when the app changes state. However if you want more control you can deny autoconnection and handle dis-/reconnection by yourself. Please notice that an instance of AIDDevice is not deallocated until the app is killed. Use this code for example:
 
 ~~~objc
 //"myDevice"" was set when we told DeviceManger to connect it.
 - (void)applicationDidEnterBackground:(UIApplication *)application {
 [[AIDDeviceManager sharedManager] disconnectDevice:self.myDevice];
 }
 
 - (void)applicationWillEnterForeground:(UIApplication *)application {
 [[AIDDeviceManager sharedManager] connectDevice:self.myDevice];
 }
 ~~~
 
 If the device failed to connect you will get a callback to the managers delegate.
 
 ~~~objc
 - (void)deviceManager:(AIDDeviceManager *)manager didFailToConnectDevice:(AIDDevice *)device error:(nullable NSError *)error;
 {
 NSLog(@"failed to connect, error: %@", error);
 }
 ~~~
 
 If the device is disconnected you will get a callback to the managers delegate. Restart scanning if you disabled it before and want to rediscover your device.
 
 ~~~objc
 - (void)deviceManager:(AIDDeviceManager *)manager didDisconnectDevice:(AIDDevice *)device error:(NSError *)error
 {
 [manager setScanForPeripherals:YES];
 }
 ~~~
 
 If the disconnection was initiated manually by the Driver the error will be set to nil.  If the device disconnected unexpectedly, the error will be set and the underlying error will contain the reason:
 * If the peripheral started the disconnection, look for: domain=CBErrorDomain code=CBErrorPeripheralDisconnected
 * If the the connection timed out, look for: domain=CBErrorDomain code=CBErrorConnectionTimeout
 
 
 To forget the data for the saved device (which is stored in the keychain) call forgetSavedDevice.
 
 ~~~objc
 [[AIDDeviceManager sharedManager] forgetSavedDevice];
 ~~~

 
 */
@interface AIDDeviceManager : NSObject
/**
 * reference to the singleton AIDDeviceManager
 */
+ (instancetype)sharedManager;

/**
 Returns the current version of the app as found in the `CFBundleShortVersionString` key of the main bundle's `infoDictionary`.
 
 Placed here for convenience's sake.
 */
+ (NSString *)getDriverShortVersionString;

/**
 Returns the current version of the app as found in the `kCFBundleVersionKey` key of the main bundle's `infoDictionary`.
 
 Placed here for convenience's sake.
 */
+ (NSString *)getDriverLongVersionString;

/**
 *
 */
@property(nullable, weak, nonatomic) id<AIDDeviceManagerDelegate> delegate;

/**
 * Scan for devices which are in advertising mode.
 */
@property(nonatomic) BOOL scanForPeripherals;

/**
 * Found devices. This will include all devices except for the currently connected device.
*  Even those which are not sending advertisment packets any more (state is Absent).
 
 * The device list can be observed with the deviceManagerDidChangeDeviceList: delegate and changes when
*  - a new connection has been made to a device (it is not available for connections anymore)
*  - the connection to a device has been closed (it is now available for new connections)
*  - a device other than the user selected device changes it's state from/to Absent 
 */
@property(strong, atomic, readonly) NSArray *devices;
 
/**FIXME - TBD*/
@property(strong, atomic, readonly) NSArray *connectedDevices;

/**
 * The device which is connected or was lastly connected. It will be automatically dis-/re-connected when the app changes to back-/fore-ground.
 * If autoConnectSavedDevice is set to YES, the framework tries to save/read the savedDevice to the Keychain and connects it on startup.
 * but also when a device becomes available. In fact it means connect and disconnect management is completely done inside the AirIDDriver
 */
@property(nullable, strong, nonatomic, readonly) AIDDevice *savedDevice;

/*
 * If autoConnectSavedDevice is set to YES, the framework tries to save/read the savedDevice to the Keychain and connects it on startup.
 * but also when a device becomes available. In fact it means connect and disconnect management is completely done inside the AirIDDriver
 *
 */
@property(nonatomic) BOOL autoConnectSavedDevice;


@property(nonatomic) BOOL useDriverDeviceManagement;

// xenox - FIXME - we should remove that
// provides access to the underkeying UICKeyChainStore API
@property(nullable, strong, nonatomic, readonly) UICKeyChainStore *keyChainStore;


/**
* The default timer interval for the connection watchdog (by reading the RSSI from a connected device)
 */
@property(nonatomic) NSTimeInterval connTimerInterval;


/**
 * @return True if the bluetooth subsystem is powered on. May change if the user turns off bluetooth (e.g. by using the the command center).
 */
@property(getter=isBluetoothPoweredOn) BOOL bluetoothPoweredOn;

/**
 * Start up the bluetooth subsystem and try to connect to saved device from KeyChain. You can specify the Keychain Group.
 * @param accessGroup - The KeyChain accessgroup you like to use
 */
- (void)startWithAccessGroup:(nullable NSString *)accessGroup;
- (void)start;

/**
 * Connect a device.
 * When the connection attempt and the subsequent initialization of the device fails, the callback didFailToConnectDevice:device:error will be
 * called with the error set.
 * @param device - The AIDDevice object for an AirID device
 */
- (void)connectDevice:(AIDDevice *)device;

/**
 * Disconnect a device.
 *  @param device - The AIDDevice object for an AirID device
 */
- (void)disconnectDevice:(AIDDevice *)device;

/**
 * Forget the saved device by setting it to nil and removing it from the keychain.
 * @warning This also diconnects an AirID device if still is connected
*/
- (void)forgetSavedDevice;

/**
 * @warning Private: do not use.
 *  @param device - The AIDDevice object for an AirID device
 */
- (void)deviceChangedFromPresentIntoAbsent:(AIDDevice*) device;

@end

AID_EXTERN NSString *const AIDDeviceManagerStatePowerOn;
AID_EXTERN NSString *const AIDDeviceManagerStatePowerOff;
/** userInfo contains the old AirID device  */
AID_EXTERN NSString *const AIDDeviceManagerWillChangeUserSelectedDevice; //userInfo contains old device
/* userInfo contains the new selected AirID device */
AID_EXTERN NSString *const AIDDeviceManagerDidChangeUserSelectedDevice;  //userInfo contains new device
/** userInfo is nil. Use [AIDDeviceManager devices] to get the list of devices. */
AID_EXTERN NSString *const AIDDeviceManagerDidChangeDeviceList;
AID_EXTERN NSString *const AIDDeviceManagerUserSelectedDeviceUserInfoKey;

AID_EXTERN NSString *const AIDDeviceErrorDomain;

NS_ASSUME_NONNULL_END

#endif
