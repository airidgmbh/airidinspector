//
//  AIDDevice.h
//  AirIDDriver
//
//  Created by Wolfgang Sebastian Blaum on 22.07.14.
//  Updated by several people since then.
//  Copyright (c) 2014 Unicept GmbH. All rights reserved.
//  Copyright (c) 2017, 2018, 2019 certgate GmbH. All rights reserved.
//

#ifndef AID_DEVICE_H
#define AID_DEVICE_H
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "AIDDefines.h"
#import "AIDDevicePairedDevices.h"

/** private
 */
typedef NS_ENUM(uint8_t, RPCReturnCode)
{
    RPCReturnCodeSuccess                     = 0x00,
    RPCReturnCodeMethodNotSpecified          = 0x01,
    RPCReturnCodeUnknownMethod               = 0x02,
    RPCReturnCodeMethodFailure               = 0x03,
    RPCReturnCodeDecryptFailure              = 0x04,
    RPCReturnCodeEncryptFailure              = 0x05,
    RPCReturnCodeKeyNotSet                   = 0x06,
    RPCReturnCodeIncorrectEncryption         = 0x07,
    RPCReturnCodeEncryptedMethodNotSpecified = 0x08,
};

/** @enum provides status about a smartcard in an AirID device */
typedef NS_ENUM(NSUInteger, AIDCardStatus)
{
    /** card status is unkown      */
    AIDCardStatusUnknown    = 0,
    /** card is not available */
    AIDCardStatusAbsent     = 1,
    /** card is present     */
    AIDCardStatusPresent    = 2,
    /** card is in position     */
    AIDCardStatusInPosition = 3,
    /** card is powered (ATR) */
    AIDCardStatusPowered    = 4,
    /** card status is in negotiation */
    AIDCardStatusNegotiable = 5,
    /** The card is ready to use if it reaches this status */
    AIDCardStatusSpecific   = 6,
};

/** @enum provides error status in case of a communication error with an AirID device */
typedef NS_ENUM(NSInteger, AIDDeviceError)
{
    /** Unkown device error */
    AIDDeviceErrorUnknown                   = 0,
    /** The AirID device received an unknown or invalid RPC call */
    AIDDeviceErrorProcedureCall             = 1,
    /** An operation failed because of a missing bluetooth connection */
    AIDDeviceErrorBluetooth                 = 2,
    /** Device and AirID have different keys for encryption */
    AIDDeviceErrorEncryptionKeysMismatch    = 3,
    /** An error was reported by the bluetooth subsystem */
    AIDDeviceErrorBluetoothCommunication    = 4,
    /** The connection to the device was aborted unexpectedly */
    AIDDeviceErrorUnexpectedConnectionAbort = 5,
    /** Initialization of a connected AirID device timed out */
    AIDDeviceErrorInitializationTimeout     = 6,
    /** Bluetooth connection did fail to connect peripheral */
    AIDDeviceErrorDidFailToConnectDevice    = 7,
};

/** @enum provides presence status for an AirID device */
typedef NS_ENUM(NSUInteger, AIDDeviceStatus)
{
    /** The device is known by the system but sends no advertisment packets (or is out of range) */
    AIDDeviceStatusAbsent,
   /** The device is sending advertisment packets */
    AIDDeviceStatusPresent,
    /** The device was connected and is initalized at the moment */
    AIDDeviceStatusConnected,
    /** The device is ready to use */
    AIDDeviceStatusInitialized,
};

/**
 * The first digit of the serial number (AirID1) or the prefix of the serial number (AirID2 and higher) shows which device family is used.
 * Use serialNumberToFamily() to get the modell type for an AirID device..
*/
typedef NS_ENUM(NSUInteger, AIDDeviceFamily)
{
    /** Device family could not be parsed from ill-formed serial number. */
    AIDDeviceFamilyInvalid = 0,

    /** This is am AirID 1 device */
    AIDDeviceFamilyClassic = 5,
   /** This is an OneKey Bridge USB dongle device */
    AIDDeviceFamilyDongle  = 6,
    /** no longer used  */
    AIDDeviceFamilyMini    = 7,
     /** no longer used  */
    AIDDeviceFamilyMicro   = 8,
    /** This is an AirID 2 device   */
    AIDDeviceFamilyTwo     = 9,
    /** This is an AirID 3 device */
    AIDDeviceFamilyThree   = 10,
    /** OneKeyID 1 device */
    AIDDeviceFamilyOKIDOne   = 11,
    /** This is an AirID2 Mini device */
    AIDDeviceFamilyTwoMini   = 12,
    /** reserved - This is an AirID 3 device */
    AIDDeviceFamilyThreeMini = 13  // xenox - A3MX - just preparing
};

@class CBPeripheral, AIDService, AIDDevice, AIDDeviceDescriptor;

@class AIDCard, AIDDeviceData;

NS_ASSUME_NONNULL_BEGIN

@interface NSData(ReturnCode)
- (RPCReturnCode)returnCode;
- (NSData*)firstByte;
@end

/**
 * The AIDDevice interface provides an abstract representation of an AirID device
 *
 */
@interface AIDDevice : NSObject

/**
 * Unique indentifier  48bit UUID of an AirID device
 */
@property(strong, nonatomic, readonly) NSUUID *identifier;

/**
 * Name of the AirID device. Use this only for displaying purposes.
 */
@property(strong, nonatomic, readonly) NSString *name;

/**
 * Averaged signal strength for an AirID device
 */
@property(strong, nonatomic, readonly) NSNumber *signalStrength;

/**
 * LTK and Session keys are automatically exchanged if needed. You can observe this property to show a notice to the user.
 */
@property(nonatomic, getter=isExchangingKeys) BOOL exchangingKeys;

/**
 * True if the USB-Cable is plugged in at the moment.
 */
@property(nonatomic, readonly, getter=isCablePlugged) BOOL cablePlugged;

/**
 True if communication session is secured by a 265-bit AES key.
 */
@property(nonatomic, readonly, getter=isEncryptionEnabled) BOOL encryptionEnabled;

/**
 * The status of the smard card which is inserted into device.
 * If Status changes to AIDCardStatusSpecific the AIDCard-property of the device will be non-nil and can be used to communicate with the smard card.
 * @see AIDCardStatus
 */
@property(atomic, readonly) AIDCardStatus cardStatus;

/**
 * Non-nil if the inserted card is ready to communicate and powered on
 */
@property(strong, nonatomic, nullable) AIDCard *card;

/**
 * Current status of the device.
 */
@property(nonatomic, readonly) AIDDeviceStatus status;

/**
the maximum supported apdu command size (minimum 266 bytes)
*/
@property(nonatomic, readonly) NSUInteger commandSize;

/**
 the maximum supported apdu response size (minimum 258 bytes)
 */
@property(nonatomic, readonly) NSUInteger responseSize;

@end

/**
 *
 * The AIDDevice interface provides an abstract representation of an AirID device
 * Initialization is executed after a device is successfully connected. The properties in this section are only valid if the corresponding InitOperation was executed.
 */
@interface AIDDevice (Initialization)

typedef NS_OPTIONS(uint16_t, AIDInitOperation)
{
    AIDInitOperationNone                    = 0,
    AIDInitOperationReadDeviceDescriptor    = 1 << 0,
    AIDInitOperationReadBatteryLevel        = 1 << 1,
    AIDInitOperationReadCardInfo            = 1 << 2,
    AIDInitOperationReadSettings            = 1 << 3,
    AIDInitOperationSetFinderName           = 1 << 4,
    AIDInitOperationSetTime                 = 1 << 5,
    AIDInitOperationGetWorkingTime          = 1 << 6,
    AIDInitOperation256BitKey               = 1 << 7,
    AIDInitOperationGetDataBufferSize       = 1 << 8,

    AIDInitOperationsAll = (AIDInitOperationReadDeviceDescriptor | AIDInitOperationReadBatteryLevel | AIDInitOperationReadCardInfo | AIDInitOperationReadSettings |
                            AIDInitOperationSetTime | AIDInitOperationSetFinderName | AIDInitOperationGetWorkingTime | AIDInitOperation256BitKey | AIDInitOperationGetDataBufferSize)
};

/**
 * @return the required Initialisation Operations
 */
+ (AIDInitOperation)requiredInitialisationOperations;

/** set the required AIDInitOperations
 * @param operations -  The list of required AIDInitOperations
 */
+ (void)setRequiredInitialisationOperations:(AIDInitOperation)operations;

//AIDInitOperationReadDeviceDescriptor
/**
 * @return the hardware address for the AirID device
 */
@property(strong, nonatomic, readonly, nullable) NSString *hardwareAddress;

//AIDInitOperationReadDeviceDescriptor
/**
 * @return the serial number for the AirID device
 */
@property(strong, nonatomic, readonly, nullable) NSString *serialNumber;

//AIDInitOperationReadDeviceDescriptor
/**
 * @return the firmware version of the AirID device
 */
@property(strong, nonatomic, readonly, nullable) NSString *firmwareVersion;

//AIDInitOperationReadDeviceDescriptor
/**
 * @return the hardware version/revision of the AirID device
 */
@property(strong, nonatomic, readonly, nullable) NSString *hardwareVersion;

//AIDInitOperationReadDeviceDescriptor
/**
 * @return the build date of the firmware for AirID devicel
 */
@property(strong, nonatomic, readonly, nullable) NSString *buildDate;

//AIDInitOperationReadDeviceDescriptor
/**
 * @return the boot loader version of the AirID device
 */
@property(strong, nonatomic, readonly, nullable) NSString *bootloaderVersion;

//AIDInitOperationReadCardInfo
@property(strong, nonatomic, readonly, nullable) NSString *cardOS DEPRECATED_ATTRIBUTE;

//AIDInitOperationReadBatteryLevel
/**
 * @return the acual battery level for an AirID device
 */
@property(strong, nonatomic, readonly, nullable) NSNumber *batteryLevel;

//AIDInitOperationReadSettings
/**
 * @return deviceSettings - NSDictionary of settings for an AirID device
 */
@property(strong, nonatomic, readonly, nullable) NSDictionary *deviceSettings;

- (void)changeDeviceSettingWithKey:(nonnull NSString *)key withValue:(nonnull NSNumber *)value;

/**
 *  getPairedDevices provides a list of paired devices from an AirID device view
 */
- (void)getPairedDevices:(void(^)(AIDDevicePairedDevices *prefDev, NSError *error)) callback;

- (void)removePairedDevice:(u_int8_t) idx callback:(void(^)(AIDDevicePairedDevices *prefDev, NSError *error)) callback;

- (void)sendRaw:(NSData *)data completion:(void (^)(NSData *receivedData, NSError *error))callback;

//AIDInitOperationGetDataBufferSize
/**
 * @return the acual data buffer size for *XPDU usage
 */
@property(nonatomic, readonly) int dataBufferSize;

AID_EXTERN NSString *const kDeviceSettingsTypeSignalStrength;
AID_EXTERN NSString *const kDeviceSettingsTypeAdvertisingMode;
AID_EXTERN NSString *const kDeviceSettingsTypeDisplay;
AID_EXTERN NSString *const kDeviceSettingsTypeBacklight;
AID_EXTERN NSString *const kDeviceSettingsTypeBuzzer;
AID_EXTERN NSString *const kDeviceSettingsTypeContrast;
AID_EXTERN NSString *const kDeviceSettingsTypeEncryption;

// access date like this:
// [array[day]["start"|"end"]["day"|"hour"|"minute"] asInt]
//@property(copy, readwrite) NSMutableArray *workingTimes;

/** getter to retrieve a copy of working times of the device. if not known, nil is returned. */
- (NSMutableArray *)getWorkingTimes;



/** set the working times attribute of this class (should be called when the working times are retrieved)
 * @param newWorkingTimes an NSMutableArray of working times
 */
- (void)gotWorkingTimesFromDevice:(NSMutableArray *)newWorkingTimes;

/** set working times of device and update it.
 * @param workingTimes - an NSMutableArray of working times
 * @return true on success, false otherwise
 */
- (bool)updateWorkingTimesOnDevice:(NSMutableArray *) workingTimes;

/**  maps an AirID serial number to an AIDDeviceFamilys ENUM object
 *  @param serialNumber The AirID serial number as NSString
 *  @return AIDDeviceFamily ENUM object for a given AirID device serial number
 *  @see AIDDeviceFamily
 */
- (AIDDeviceFamily)serialNumberToFamily:(NSString*) serialNumber;

@end

NS_ASSUME_NONNULL_END

#endif
