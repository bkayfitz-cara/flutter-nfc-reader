#import "FlutterNfcReaderPlugin.h"
@import CoreNFC;

#define kId @"nfcId"
#define kContent @"nfcContent"
#define kStatus @"nfcStatus"
#define kError @"nfcError"


@interface FlutterNfcReaderPlugin()<NFCNDEFReaderSessionDelegate>
@property (nonatomic, strong) NSString *instruction;
@property (nonatomic, copy) FlutterResult resulter;
@property (nonatomic, strong) NFCNDEFReaderSession *nfcSession;
@end

@implementation FlutterNfcReaderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"flutter_nfc_reader" binaryMessenger:registrar.messenger];
    FlutterNfcReaderPlugin *instance = [[FlutterNfcReaderPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void) handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"NfcRead"]) {
        NSDictionary *arguments = call.arguments;
        _instruction = arguments[@"instruction"];
        if (!_instruction) {
            _instruction = @"";
        }
        
        _resulter = result;
        [self activateNFC:_instruction];
        
        
    } else if ([call.method isEqualToString:@"NfcStop"]) {
        [self disableNFC];
        
        
    } else {
        result([NSString stringWithFormat:@"iOS %@", UIDevice.currentDevice.systemVersion]);
    }
}

- (void) activateNFC:(NSString *)instruction {
    _nfcSession = [[NFCNDEFReaderSession alloc] initWithDelegate:self
                                                           queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                        invalidateAfterFirstRead:YES];
    
    [_nfcSession setAlertMessage:instruction];
    [_nfcSession beginSession];
}

- (void) disableNFC {
    [_nfcSession invalidateSession];
    NSDictionary *data = @{kId: @"", kContent: @"", kError: @"", kStatus: @"stopped"};
    if (_resulter) {
        _resulter(data);
    }
    _resulter = nil;
}

- (void)readerSession:(NFCNDEFReaderSession *)session didDetectNDEFs:(NSArray<NFCNDEFMessage *> *)messages {
    NFCNDEFMessage *message = messages.firstObject;
    NFCNDEFPayload *payload = message.records.firstObject;
    NSString *payloadContent = [[NSString alloc] initWithData:payload.payload encoding:NSUTF8StringEncoding];
    NSDictionary *data = @{kId: @"", kContent: payloadContent, kError: @"", kStatus: @"read"};
    if (_resulter) {
        _resulter(data);
    }
    [self disableNFC];
}

- (void)readerSession:(NFCNDEFReaderSession *)session didInvalidateWithError:(NSError *)error {
    // Ignore 'Single Tap Read' errors.  its not actually an error.
    if (error.code == 204) {
        return;
    }
    
    NSLog(@"%@", error.localizedDescription);
    NSDictionary *data = @{kId: @"", kContent: @"", kError: error.localizedDescription, kStatus: @"error"};
    if (_resulter) {
        _resulter(data);
    }
    [self disableNFC];
}


@end
