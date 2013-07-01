#include <err.h>

#import "Testing.h"

/*
 * This checks the following at a method level:
 *
 *  - <some test>
 */
int
main()
{
        START_SET("Test set");

        /* Check mask bit */
        pass(YES == YES, "<description>");
        END_SET("Masking set");
        
        return 0;
}
