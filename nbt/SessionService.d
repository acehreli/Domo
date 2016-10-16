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
 * Date:      11 October 2016
 * License:   GNU Lesser General Public License version 3
 * Standards: IETF RFC1001 and RFC1002 (STD#19)
 * Brief:     NBT Session Service
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
 *    <li>Type (8 bits)
 *    <li>Flags (7 bits)
 *    <li>Length (17 bits)
 *  </ul>
 *  In RFC1002, the Flags field is listed as being 8 bits wide, but the
 *  lowest order bit is a "length extension" which is used as the high-
 *  order bit of the Length field.  None of the other Flags bits have
 *  ever been defined.  It makes sense, therefore, to view the Length
 *  field as being 17 bytes, and the first 7 bits of the Flags field as
 *  "Reserved, Must Be Zero".
 */
module SessionService;

/* Enumerated Constants ----------------------------------------------------- */

// Protocol Details
enum ushort SS_PORT = 139;  /// Default Session Service TCP listener port.

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

// Negative Respoinse Error Codes
enum:ubyte
  {
  SS_ERR_NOT_LISTENING = 0x80,  /// Not Listening _On Called_ Name
  SS_ERR_NOT_ANSWERING = 0x81,  /// Not Listening _For Calling_ Name
  SS_ERR_NOT_PRESENT   = 0x82,  /// Called Name Not Present
  SS_ERR_INSUFFICIENT  = 0x83,  /// Insufficient Resources
  SS_ERR_UNSPECIFIED   = 0x8F   /// Unspecified Error
  };


/* Functions ---------------------------------------------------------------- */

ulong extractLength( ubyte a[4] )
  {
  return( (ulong)(((a[1] & 0x01) * 0x010000) + (a[2] * 0x0100) + a[3]) );
  } /* extractLength */

/* ================================= la fin ================================= */
