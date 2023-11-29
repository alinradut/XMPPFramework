//
//  XMPPRoomTests.m
//  XMPPFrameworkTests
//
//  Created by Alin Radut on 11/29/23.
//

#import <XCTest/XCTest.h>
#import "XMPPMockStream.h"
@import KissXML;

////////////////////////////////////////////////////////////////////////


@interface XMPPRoomTests: XCTestCase <XMPPRoomDelegate>

@property (nonatomic, strong) XCTestExpectation *delegateResponseExpectation;
@property (nonatomic, strong) XMPPJID *roomJID;
@property (nonatomic, strong) XMPPJID *userJID;

@end

@implementation XMPPRoomTests

- (void)setUp {
    [super setUp];
    _roomJID = [XMPPJID jidWithString:@"room@conference.domain.com/user"];
    _userJID = [XMPPJID jidWithString:@"user@domain.com/resource"];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRoomDidNotJoin {
    self.delegateResponseExpectation = [self expectationWithDescription:@"DidNotJoin"];

    XMPPMockStream *streamTest = [[XMPPMockStream alloc] init];
    XMPPRoomMemoryStorage *roomStorage = [[XMPPRoomMemoryStorage alloc] init];

    XMPPRoom *room = [[XMPPRoom alloc] initWithRoomStorage:roomStorage jid:_roomJID];

    [room addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [room activate:streamTest];

    __weak typeof(XMPPMockStream) *weakStreamTest = streamTest;
    streamTest.elementReceived = ^void(NSXMLElement *element) {

        XMPPPresence *presence = [self fakeDidNotJoinResponse];
        [weakStreamTest fakeResponse:presence];
    };

    [room joinRoomUsingNickname:@"user" history:nil password:@"invalid"];

    [self waitForExpectationsWithTimeout:6 handler:^(NSError * _Nullable error) {
        if(error){
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (XMPPPresence *)fakeDidNotJoinResponse {
    NSMutableString *s = [NSMutableString string];
    [s appendString: @"<presence from='room@conference.domain.com/user' to='user@domain.com/resource' type='error'>"];
    [s appendString: @"     <x xmlns='http://jabber.org/protocol/muc'><password>invalid</password></x>"];
    [s appendString: @"     <error type='auth'>"];
    [s appendString: @"         <not-authorized xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'></not-authorized>"];
    [s appendString: @"         <text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas' lang='en'>Incorrect password</text>"];
    [s appendString: @"     </error>"];
    [s appendString: @"</presence>"];

    NSError *error;
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:s options:0 error:&error];
    XMPPPresence *presence = [XMPPPresence presenceFromElement:[doc rootElement]];
    return presence;
}

- (void)xmppRoom:(XMPPRoom *)sender didNotJoin:(XMPPIQ *)iqError {
    [_delegateResponseExpectation fulfill];
}

@end
