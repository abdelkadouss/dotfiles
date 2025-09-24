use ../../.shared/version/trim.nu 'version trim';
use std/assert *;

let version = "v1.2.3"
let expected = "1.2.3"
let res = ( version trim $version )
print $"OUTPUT: ( $res )"
assert ( $res == $expected ) "remove the first v"

let version = "1.2.3.jl.34.6.d" 
let expected = "1.2.3"
let res = ( version trim $version )
print $"OUTPUT: ( $res )"
assert ( $res == $expected ) "take only the first three cells"

let version = "1.2.3.jl.34.6.d" 
let expected = "1.2.3-jl-34-6-d"
let res = ( version trim --other-dots-to-dashes $version )
print $"OUTPUT: ( $res )"
assert ( $res == $expected ) "make the other dots to dashes"
