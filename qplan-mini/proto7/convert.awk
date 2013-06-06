BEGIN 	{id = 9; FS = "\t"}
$2 == 1 {printf("%d\t%s\tNative:1\n", id++, $1)}
$3 == 1 {printf("%d\t%s\tWeb:1\n", id++, $1)}
$4 == 1 {printf("%d\t%s\tApps:1\n", id++, $1)}
$5 == 1 {printf("%d\t%s\tSET:1\n", id++, $1)}
$6 == 1 {printf("%d\t%s\tOverhead:1\n", id++, $1)}
$7 == 1 {printf("%d\t%s\tUX:1\n", id++, $1)}
$8 == 1 {printf("%d\t%s\tBB:1\n", id++, $1)}
