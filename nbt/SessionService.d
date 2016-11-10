/* ========================================================================== **
 *                              SessionService.d
 * ========================================================================== **
 *
 * Copyright © 2016 Christopher R. Hertel
 *
 *  This file is part of the Domo project.
 *
 *  Domo is free software: you can redistribute it and/or modify it under the
 *  terms of the GNU Lesser General Public License as published by the Free
 *  Software Foundation, either version 3 of the License, or (at your option)
 *  any later version.
 *
 *  Domo is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 *  FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with Domo.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ========================================================================== **
 * Notes:
 *
 * ========================================================================== **
 *//**
 * File:      SessionService.d
 * Authors:   Christopher R. Hertel
 * Created:   11 October 2016
 * License:   GNU Lesser General Public License version 3
 * Standards: IETF RFC1001 and RFC1002 (STD#19)
 * Brief:     NBT Session Service tools
 * Version:
 *    $Id: SessionService.d; 2016-11-10 09:09:12 -0600; Christopher R. Hertel$
 *
 * Details:
 *  The NBT Session Service provides for the establishment and maintenance
 *  of NetBIOS sessions over TCP, including the framing of NetBIOS session
 *  messages.
 *
 *  The Session Service is probably the simplest aspect of the NBT
 *  transport suite.  There are only six possible messages, most of which
 *  have a fixed length:
 *  <ul>
 *    <li>Session Message (4 octet header + variable length user data)
 *    <li>Session Request (72 octets)
 *    <li>Positive Session Response (4 octets)
 *    <li>Negative Session Response (5 octets)
 *    <li>Retarget Session Response (10 octets)
 *    <li>Session Keepalive (4 octets)
 *  </ul>
 *  NBT Session Service messages all have the same general format.  They
 *  all start with a 4-octet header followed by 0 or more octets of
 *  additional data.  The number of octets of additional data is given in
 *  the length field.
 *
 *  The header is in Network Byte Order, and is split into three subfields:
 *  <ul>
 *    <li>TYPE (8 bits)
 *    <li>FLAGS (7 bits)
 *    <li>LENGTH (17 bits)
 *  </ul>
 *  In RFC1002, the FLAGS field is listed as being 8 bits wide, but the
 *  lowest order bit is a "length extension", which is used as the high-
 *  order bit of the LENGTH field.  None of the other FLAGS bits have
 *  ever been defined, so it makes sense to view the LENGTH field as
 *  being 17 bits wide.  The FLAGS field is then only 7 bits wide, and
 *  all of the bits are "Reserved, Must Be Zero".
 *  <pre>
 *                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
 *     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |      TYPE     |    FLAGS    |             LENGTH              |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |                                                               |
 *    /               TRAILER (Packet Type Dependent)                 /
 *    |                                                               |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+</pre>
 *  <hr>
 */
module SessionService;


/* Imports ------------------------------------------------------------------ */

import std.array : join;

version( LittleEndian )
  {
  import core.bitop : bswap;
  }


/* Enumerated Constants ----------------------------------------------------- */

// Protocol Details
enum ushort SS_PORT = 139;  /// Session Service TCP listener port (139).

// Message Types
enum:ubyte
  {
  SS_SESSION_MESSAGE   = 0x00,  /// Payload follows.
  SS_SESSION_REQUEST   = 0x81,  /// Request creation of a NetBIOS session.
  SS_POSITIVE_RESPONSE = 0x82,  /// NetBIOS session accepted.
  SS_NEGATIVE_RESPONSE = 0x83,  /// NetBIOS session denied.
  SS_RETARGET_RESPONSE = 0x84,  /// NetBIOS session redirected.
  SS_SESSION_KEEPALIVE = 0x85   /// NBT session keep-alive.
  };

// Negative Response Error Codes
enum:ubyte
  {
  SS_ERR_NOT_LISTENING = 0x80,  /// Not Listening On Called Name
  SS_ERR_NOT_ANSWERING = 0x81,  /// Not Listening For Calling Name
  SS_ERR_NOT_PRESENT   = 0x82,  /// Called Name Not Present
  SS_ERR_INSUFFICIENT  = 0x83,  /// Insufficient Resources
  SS_ERR_UNSPECIFIED   = 0x8F   /// Unspecified Error
  };

// Fixed Session Messages
/// The Positive Session Response message.
enum ubyte[] SS_POSITIVE_RESPONSE_MSG = cast(ubyte[])"\x82\0\0\0";

/// The Session Keep Alive message.
enum ubyte[] SS_SESSION_KEEPALIVE_MSG = cast(ubyte[])"\x85\0\0\0";

// Subfield Masks
private enum ubyte flgMask = 0xFE;        // FLAGS subfield mask (octet).
private enum uint  lenMask = 0x0001FFFF;  // LENGTH subfield mask (32-bit).


/* Functions ---------------------------------------------------------------- */

/** Extract the FLAGS bits from the NBT Session Service header.
 *
 *  Input:  hdr - An array of four octets, representing an NBT Session
 *                Service header as it was received from the wire.
 *
 *  Output: A single ubyte value with just the FLAGS bits expressed.
 *          A non-zero return value should be considered an error, since
 *          none of the FLAGS bits are actually defined in RFC1002 (but
 *          see the Notes, below).
 *
 *  Notes:  Despite the definition given in RFC1002, this code views the
 *          FLAGS field as being only 7 bits wide, while the LENGTH field
 *          is viewed as being 17 bits.  This is logically consistent with
 *          the original definition given in the RFC, but it works better.
 */
ubyte getHdrFlags( ubyte[4] hdr )
  {
  return( hdr[1] & flgMask );
  } /* getHdrFlags */

/** Extract the LENGTH from the NBT Session Service Header.
 *
 *  Input:  hdr - An array of four octets, representing the NBT Session
 *                Service header as it was received from the wire.
 *
 *  Output: The value of the 17-bit header LENGTH field, as an unsigned
 *          32-bit integer.
 */
ulong getHdrLen( ubyte[4] hdr )
  {
  version( LittleEndian )
    return( bswap( *(cast(uint*)(hdr.ptr)) ) & lenMask );
  else
    return( *(cast(uint*)(hdr.ptr)) & lenMask );
  } /* getHdrLen */

/** Compose a correctly formatted Session Message header.
 *
 * Input:   bufrPtr - A pointer to a buffer (at least 4 octets in length)
 *                    into which the NBT Session Message header will be
 *                    written.<br>
 *          msgLen  - The length value to be encoded.  This value must be
 *                    in the range 0..131071 (2^17 - 1).
 *
 * Errors:  AssertionError  - Thrown if <msgLen> is greater than 0x0001FFFF.
 */
void msgHdr( ubyte *bufrPtr, uint msgLen )
  {
  // Messages must not exceed the NBT message size limit.
  assert( msgLen == (msgLen & lenMask), "Maximum NBT message size exceeded." );
  // Ensure Network Byte Order.
  version( LittleEndian )
    {
    msgLen = bswap( msgLen );
    }
  // Copy the length bytes into <bufr>.
  *cast(uint *)(bufrPtr) = msgLen;
  } /* msgHdr */

/* Test a string of octets (ubytes) to see if they match the pattern
 * of an L1 encoded NBT name.
 */
private bool L1okay( ubyte[] name )
  {
  import std.algorithm : canFind;

  // Ensure that we have a correctly encoded NBT name.
  if( (name.length != 34) || ('\x20' != name[0]) || ('\0' != name[33]) )
    return( false );
  // Each character of <name>, except the first and last,
  // must be in the range 'A'..'P'.
  foreach( c; name[1..33] )
    if( !( "ABCDEFGHIJKLMNOP".canFind( c ) ) )
      return( false );
  return( true );
  } /* L1okay */

/** Create an NBT Session Service Session Request message.
 *  Input:  CalledName  - The name of the NBT service to which the message
 *                        is addressed.<br>
 *          CallingName - The name of the NBT service or application that
 *                        is sending the session request.
 *
 *  Errors: AssertError - Thrown if either of the input paramaters does
 *                        not match the required format.
 *
 *  Output: An array of ubytes.
 *          The first four bytes are always [0x81, 0, 0, 0x44].  The
 *          remaining bytes are the given Called and Calling names.
 *          The total length of the output should always be 72 bytes.
 */
ubyte[] SessionRequest( ubyte[] CalledName, ubyte[] CallingName )
  {
  static enum ubyte[] prefix = cast(ubyte[])"\x81\0\0\x44";

  assert( L1okay( CalledName ), "Malformed 'Called' Name" );
  assert( L1okay( CallingName ), "Malformed 'Calling' Name" );
  return( join( [ prefix, CalledName, CallingName ] ) );
  } /* SessionRequest */

/** Create an NBT Session Service Negative Session Response message.
 *  Input:  ErrCode - One of the five defined NBT Session Service error
 *                    codes.  Any other value is silently replaced with
 *                    SS_ERR_UNSPECIFIED.
 *
 *  Output: An array of five ubytes.  The first four bytes will always
 *          be [ 0x83, 0, 0, 1 ].  The final byte will be the error code.
 */
ubyte[] NegativeResponse( ubyte errCode )
  {
  static enum ubyte[] prefix = cast(ubyte[])"\x83\0\0\x01";

  if( errCode < 0x80 || errCode > 0x83 )
    errCode = SS_ERR_UNSPECIFIED;
  return( join( [ prefix, [errCode] ] ) );
  } /* NegativeResponse */

/* ================================= la fin ================================= */
