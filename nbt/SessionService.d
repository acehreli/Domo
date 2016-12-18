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
 *    $Id: SessionService.d; 2016-12-18 14:00:49 -0600; Christopher R. Hertel$
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
 *  The Session Message is a length followed by a payload.  This is the
 *  message type used to transport higher-level protocols, particularly
 *  SMB.  All of the other message types (all fixed-length) are used for
 *  NBT Session Service housekeeping.
 *
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
 *
 * Usage:
 *  <b>Sending Outgoing Messages</b>
 *
 *  Two messages, the Positive Session Response and the Session Keepalive,
 *  are invariant.  These two messages are defined as immutable constants,
 *  each 4 bytes in length.
 *  <ul>
 *    <li><tt>SS_POSITIVE_RESPONSE_MSG</tt> - Positive Session Response
 *    <li><tt>SS_SESSION_KEEPALIVE_MSG</tt> - Session Keepalive
 *  </ul>
 *  The Session Request, Negative Session Response, and Retarget Response
 *  messages all need to be created using message-specific data.  See:
 *  <ul>
 *    <li><tt>CreateSessReq()</tt> - Create a Session Request message
 *    <li><tt>CreateNegResp()</tt> - Session Request denied with errorcode
 *    <li><tt>CreateRetResp()</tt> - Retarget to new IP and/or Port
 *  </ul>
 *  Finally, the <tt>msgHdr()</tt> function is called to write a Session
 *  Message header into a given 4-byte buffer.  The assumption is that a
 *  buffer will be pre-allocated and re-used because doing so is more
 *  efficient than allocating a new buffer each time a message is composed.
 *
 *  <b>Receiving Incoming Messages</b>
 *
 *  The first byte of each (framed) message will tell you which kind of
 *  message you've received.
 *  <dl><dt>
 *    SS_SESSION_MESSAGE (0x00)</dt><dd>
 *      Session message headers are 4-bytes long and represent a message
 *      length with a maximum value of 0x0001FFFF.  The <tt>GetHdrLen()</tt>
 *      function can be used to extract the message length.
 *      </dd><dt>
 *    SS_SESSION_REQUEST (0x81)</dt><dd>
 *      A Session Request is sent by a client when it wishes to initiate an
 *      NBT session with a server.  In modern implementations, this message
 *      <i>should</i> be sent by the client and <i>should</i> be considered
 *      optional by the server.  This message includes two NetBIOS names:
 *      <ul><li>The client's Calling Name</li>
 *          <li>The Called Name, which is the name of the service to which
 *              the client wishes to connect.
 *      </li></ul>
 *      Use the <tt>ParseSessReq()</tt> function to extract these names from
 *      the message.
 *      </dd><dt>
 *    SS_POSITIVE_RESPONSE (0x82)</dt><dd>
 *      This is a fixed message that indicates that a Session Request has been
 *      accepted.  The three bytes following the message code must all be NULs
 *      (0x00).  You can validate this message by comparing it against
 *      <tt>SS_POSITIVE_RESPONSE_MSG</tt>.
 *      </dd><dt>
 *    SS_NEGATIVE_RESPONSE (0x83)</dt><dd>
 *      The Negative Session Response message is returned by the server when
 *      it cannot accept a Session Request.  Use <tt>ParseNegResp()</tt> to
 *      extract the error code.
 *      </dd><dt>
 *    SS_RETARGET_RESPONSE (0x84)</dt><dd>
 *      A server may send this message to a client to indicate a forwarding
 *      address for a particular service.  The <tt>ParseRetResp()</tt> can
 *      be used to extract the IP address and port number from the message.
 *      In theory, the client will retry the connection using the new values.
 *      In practice, this message is rarely sent, and even more rarely
 *      respected upon receipt.
 *      </dd><dt>
 *    SS_SESSION_KEEPALIVE (0x85)</dt><dd>
 *      This is a fixed message used to verify that an existing, but quiet,
 *      session is still active.  The three bytes following the message code
 *      must all be NULs (0x00).  You can validate this message by comparing
 *      it against <tt>SS_SESSION_KEEPALIVE_MSG</tt>.
 *  </dd></dl>
 *
 * References:
 *  <dl><dt>
 *    [IMPCIFS]</dt><dd>
 *      "Implementing CIFS - The Common Internet File System", Prentice Hall,
 *      August 2003, ISBN:013047116X,<br>
 *      <a href="http://www.ubiqx.org/cifs/">http://www.ubiqx.org/cifs/</a>
 *  </dd></dl>
 * <hr>
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
  }

// Negative Response Error Codes
enum:ubyte
  {
  SS_ERR_NOT_LISTENING = 0x80,  /// Not Listening On Called Name
  SS_ERR_NOT_ANSWERING = 0x81,  /// Not Listening For Calling Name
  SS_ERR_NOT_PRESENT   = 0x82,  /// Called Name Not Present
  SS_ERR_INSUFFICIENT  = 0x83,  /// Insufficient Resources
  SS_ERR_UNSPECIFIED   = 0x8F   /// Unspecified Error
  }

// Fixed Session Service messages
/// The Positive Session Response message.
immutable ubyte[4] SS_POSITIVE_RESPONSE_MSG = cast(ubyte[4])"\x82\0\0\0";

/// The Session Keep Alive message.
immutable ubyte[4] SS_SESSION_KEEPALIVE_MSG = cast(ubyte[4])"\x85\0\0\0";

// Subfield Masks
private enum ubyte flgMask = 0xFE;        // FLAGS subfield mask (octet).
private enum uint  lenMask = 0x0001FFFF;  // LENGTH subfield mask (32-bit).

// Internal Session Service message prefixes
private enum ubyte[] sessReqPrefix  = cast(ubyte[])"\x81\0\0\x44";
private enum ubyte[] negRespPrefix  = cast(ubyte[])"\x83\0\0\x01";
private enum ubyte[] retargetPrefix = cast(ubyte[])"\x84\0\0\x06";


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
ubyte GetHdrFlags( ubyte[4] hdr )
  {
  return( hdr[1] & flgMask );
  } /* GetHdrFlags */

/** Extract the LENGTH from the NBT Session Service Header.
 *
 *  Input:  hdr - An array of four octets, representing the NBT Session
 *                Service header as it was received from the wire.
 *
 *  Output: The value of the 17-bit header LENGTH field, as an unsigned
 *          32-bit integer.
 */
ulong GetHdrLen( ubyte[4] hdr )
  {
  version( LittleEndian )
    return( bswap( *(cast(uint*)(hdr.ptr)) ) & lenMask );
  else
    return( *(cast(uint*)(hdr.ptr)) & lenMask );
  } /* GetHdrLen */

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
    msgLen = bswap( msgLen );

  // Copy the length bytes into the buffer.
  *cast(uint *)(bufrPtr) = msgLen;
  } /* msgHdr */

/* Test a string of octets (ubytes) to see if they match the pattern
 * of an L1 encoded NBT name.
 */
private bool L1okay( in ubyte[34] name )
  {
  // Ensure that we have a correctly encoded NBT name.
  if( ('\x20' != name[0]) || ('\0' != name[33]) )
    return( false );
  // Each character of <name>, except the first and last,
  //  must be in the range 'A'..'P'.
  foreach( c; name[1..33] )
    if( ('A' > c) || (c > 'P') )
      return( false );
  return( true );
  } /* L1okay */

/** Create an NBT Session Service Session Request message.
 *
 *  Input:  Called  - The name of the NBT service to which the message is
 *                    addressed.<br>
 *          Calling - The name of the NBT service or application that is
 *                    sending the session request.
 *
 *  Errors: AssertError - Thrown if either of the input paramaters does
 *                        not match the required format.
 *
 *  Output: An array of ubytes.
 *          The first four bytes are always [0x81, 0, 0, 0x44].  The
 *          remaining bytes are the given Called and Calling names.
 *          The total length of the output should always be 72 bytes.
 */
ubyte[] CreateSessReq( ubyte[34] Called, ubyte[34] Calling )
  {
  assert( L1okay( Called  ), "Malformed 'Called' Name" );
  assert( L1okay( Calling ), "Malformed 'Calling' Name" );
  return( join( [ sessReqPrefix, Called, Calling ] ) );
  } /* CreateSessReq */

/** Parse an NBT Session Request message.
 *
 *  Input:  msg     - The 72-byte NBT Session Request message to be parsed.<br>
 *          Called  - [out] The level one encoded NetBIOS name of the
 *                    service that the client is trying to access.<br>
 *          Calling - [out] The level one encoded NetBIOS name by which the
 *                    client process wishes to be known.
 *
 *  Notes:  The Called and Calling names are level one encoded unqualified
 *          NetBIOS names.  You'll want to read the NBT section of [IMPCIFS]
 *          to get a clearer idea of what this means.
 */
void ParseSessReq( ubyte[72] msg, out ubyte[34] Called, out ubyte[34] Calling )
  {
  assert( (sessReqPrefix == msg[0..4]), "Malformed Session Request message" );

  Called  = msg[ 4..38];
  Calling = msg[38..72];
  assert( L1okay( Called  ), "Malformed 'Called' Name" );
  assert( L1okay( Calling ), "Malformed 'Calling' Name" );
  } /* ParseSessReq */

/** Create an NBT Session Service Negative Session Response message.
 *
 *  Input:  ErrCode - One of the five defined NBT Session Service error
 *                    codes.  Any other value is silently replaced with
 *                    SS_ERR_UNSPECIFIED.
 *
 *  Output: An array of five ubytes.  The first four bytes will always
 *          be [ 0x83, 0, 0, 1 ].  The final byte will be the error code.
 */
ubyte[] CreateNegResp( ubyte errCode )
  {
  if( errCode < 0x80 || errCode > 0x83 )
    errCode = SS_ERR_UNSPECIFIED;
  return( join( [ negRespPrefix, [errCode] ] ) );
  } /* CreateNegResp */

/** Parse an NBT Negative Session Response message.
 *
 *  Input:  msg - The five byte NBT Negative Session Response message to be
 *                parsed.<br>
 *
 *  Output: The one-byte error code included in the message.
 *
 *  Errors: AssertionError  - Thrown if the message header is not an NBT
 *                            Negative Response message header.
 */
ubyte ParseNegResp( ubyte[5] msg )
  {
  assert( (negRespPrefix == msg[0..4]),
          "Malformed Negative Response message" );
  return( msg[4] );
  } /* ParseNegResp */

/** Create an NBT Session Service Retarget Response message.
 *
 *  Input:  IPv4addr  - A four byte array; an IP address.
 *                      This is the IP address to which the calling node
 *                      will be redirected.  Note that NBT is does not
 *                      provide support for IPv6.<br>
 *          PortNum   - The TCP port to which the calling node will be
 *                      redirected.
 *
 *  Output: An array of ten ubytes.  The first four bytes will always be
 *          [ 0x84, 0, 0, 6 ].  The remainder will be the given IP
 *          IPv4 address and port number.
 *
 *  Notes:  This function is included for completeness.  Most NBT
 *          implementations ignore the Retarget message.
 */
ubyte[] CreateRetResp( ubyte[4] IPv4addr, ushort PortNum )
  {
  ubyte[2] port;

  port[0] = ((PortNum >> 8) & 0xff);
  port[1] = (PortNum & 0xff);
  return( join( [ retargetPrefix, IPv4addr, port ] ) );
  } /* CreateRetResp */

/** Parse an NBT Retarget Response message.
 *
 *  Input:  msg       - The message, which must be 10 bytes in length.<br>
 *          IPv4addr  - [out] An IPv4 address, extracted from the message.<br>
 *          PortNum   - [out] A port number, also extracted from the message.
 *
 *  Notes:  The Retarget Response was intended to allow the server to tell a
 *          client where to go.  That is, the client is supposed to retry the
 *          connection by contacting the returned IPv4 address at the returned
 *          port number.  Most modern implementations, however, do not respect
 *          the Retarget Response.
 *
 *  Errors: AssertionError  - Thrown if the message header is not an NBT
 *                            Retarget Response message header.
 */
void ParseRetResp( ubyte[10] msg, out ubyte[4] IPv4addr, out ushort PortNum )
  {
  assert( (retargetPrefix == msg[0..4]),
          "Malformed Retarget Response message" );

  IPv4addr = msg[4..8];
  PortNum  = (msg[8] << 8) + msg[9];
  } /* ParseRetResp */

/* ============================ SessionService.d ============================ */
