#include <err.h>
#include <string.h>

#import "Testing.h"
#import "../WSFrame.h"

int
main()
{
        char frameData[] = {0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f,
                            0x4d, 0x51, 0x58};

        START_SET("Masking set");

        /* Create frame and add frameData */
        WSFrame *frame = [[WSFrame alloc] init];
        NSData *data = [NSData dataWithBytes:frameData
                                      length:sizeof(frameData)];
        [frame appendData:data];

        /* Check if message is masked */
        pass(YES == [frame isMasked], "Frame is masked");

        /* Check length of message */
        pass(5 == [frame messageLength], "Message length");

        /* Unmask message */
        pass([[frame message] isEqualToString:@"Hello"] == YES,
                        "Unmask message");

        [frame release];

        END_SET("Masking set");
        
        return 0;
}
