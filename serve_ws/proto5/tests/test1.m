#include <err.h>
#include <string.h>

#import "Testing.h"

/*
 * Defines
 */

/* Byte 0 of websocket frame */
#define WS_FRAME_FIN 0x80
#define WS_FRAME_OP_TEXT 0x01

/* Byte 1 of websocket frame */
#define WS_FRAME_MASK 0x80


/*
 * Static methods
 */

static BOOL
is_masked(const char *frame)
{
        /* The mask bit is in the second byte of the frame */
        if (frame[1] & WS_FRAME_MASK)
                return YES;
        else
                return NO;
}


/*
 * NOTE: Only handling message lengths < 125. We'll need to test frames that are
 * greater than this (there are two more cases).
 */
static long
message_length(const char *frame)
{
        /* The length is in the second byte (if the length < 125) */
        char result = frame[1] & ~WS_FRAME_MASK;

        if (result > 125)
                errx(1, "Can't handle messages > 125");

        return result;
}

static char
toggle_byte_mask(const char *message, int byteIndex, const char *mask)
{
        char mask_byte = mask[byteIndex % 4];
        char result = message[byteIndex] ^ mask_byte;

        return result;
}


/*
 * We'll only handle short messages (<= 125 bytes).
 */
static char
unmask_message_byte(const char *frame, long message_length, int message_byte_index)
{
        const char *mask_start;
        const char *message_start;

        if (message_length > 125)
                errx(1, "Not handling messages longer than 125 bytes");

        /* For a message of length < 125, the mask starts at Byte 2 and the
         * message starts at Byte 6 */
        mask_start = frame + 2;
        message_start = frame + 6;

        return toggle_byte_mask(message_start, message_byte_index, mask_start);
}


/*
 * This checks the following at a method level:
 *
 *  - identify a masked frame
 *  - parse message length
 *  - unmask a message
 *  - mask a message
 */
int
main()
{
        char frame[] = {0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f,
                        0x4d, 0x51, 0x58};
        int i;

        START_SET("Masking set");

        /* Check mask bit */
        pass(YES == is_masked(frame), "Frame is masked");

        /* Get length of body text */
        int expected_length = 5;
        pass(expected_length == message_length(frame), "Check message length");

        /* Unmask message */
        char expected_message[] = "Hello";
        for (i=0; i < strlen(expected_message); i++)
                pass(expected_message[i] == unmask_message_byte(frame, 5, i),
                                "Can unmask message");

        /* Mask message */
        char message[] = "Hello";
        char mask[] = {0x37, 0xfa, 0x21, 0x3d}; 
        char expected_masked_message[] = {0x7f, 0x9f, 0x4d, 0x51, 0x58};
        for (i=0; i < 5; i++)
                pass(expected_masked_message[i] ==
                                toggle_byte_mask(message, i, mask),
                                "Can mask byte from message");

        END_SET("Masking set");
        
        return 0;
}
