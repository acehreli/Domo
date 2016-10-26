/* Speed-test methods for extracting the NBT Session Service length field.
 *
 *  This is a test program.  It implements a small set of different
 *  mechanisms for extacting a 17-bit LENGTH value from a big-endian
 *  byte order 32-bit input.  The operations are repeated multiple
 *  times on order to generate performance comparisons.
 *
 * $Id: BigEndianExtraction.d; 2016-10-25 22:36:41 -0500; Christopher R. Hertel$
 */

version( LittleEndian )
  {
  import core.bitop : bswap;
  }

enum elementCount = 100_000;
enum testCount    =  10_000;

uint extractLength( ubyte[4] a )
  {
  return( ((a[1] & 0x01) << 16) + (a[2] * 0x0100) + a[3] );
  } /* extractLength */

uint extractLength_bigEndianToNative( ubyte[4] a )
  {
  import std.bitmanip : bigEndianToNative;

  return( bigEndianToNative!uint(a) & 0x1ffff );
  } /* extractLength_bigEndianToNative */

uint extractLength_bswap( ubyte[4] a ) // @nogc pure nothrow
  {
  version( LittleEndian )
    {
    return( bswap( *(cast(uint*)(a.ptr)) ) & 0x0001FFFF );
    }
  else
    {
    return( *(cast(uint*)(a.ptr)) & 0x0001FFFF );
    }
  } /* extractLength_bswap */

unittest
  {
  import std.stdio : writeln;

  ubyte[4] a = [ 0, 1, 2, 3 ];
  const expected = 0x00010203;

  writeln( "Unit Tests..." );
  assert( extractLength( a ) == expected );
  assert( extractLength_bigEndianToNative( a ) == expected );
  assert( extractLength_bswap( a ) == expected );
  writeln( "...done." );
  } /* unittest */

void main()
  {
  import std.stdio     : writefln;
  import std.datetime  : benchmark, msecs;

  ubyte[4][] testArrays;
  testArrays.length   = elementCount;
  ulong overallResult = 0;

  auto test( alias func )()
    {
    ulong result = 0; // Ensure that the optimizer doesn't throw the code away.

    foreach( element; testArrays )
      {
      result += func( element );
      }
    return( result );
    } /* test */

  const measurements
    = benchmark!( () => overallResult += test!extractLength,
                  () => overallResult += test!extractLength_bigEndianToNative,
                  () => overallResult += test!extractLength_bswap )(testCount);

  writefln("extractLength()                  : %s msecs",measurements[0].msecs);
  writefln("extractLength_bigEndianToNative(): %s msecs",measurements[1].msecs);
  writefln("extractLength_bswap()            : %s msecs",measurements[2].msecs);
  writefln("overallResult: %s", overallResult);
  } /* main */
