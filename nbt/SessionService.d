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
 * Brief:     Support for the NBT Session Service
 * Details:
 *  The NBT Session Service provides for the establishment and maintenance
 *  of NetBIOS sessions over TCP, including the framing of NetBIOS session
 *  messages.
 *
 *  NBT Session Service messages all have the same general format.  They
 *  all start with a 4-octet header followed by 0 or more octets of
 *  additional data.  The number of octets of additional data is given in
 *  the length field.
 *
 *  The header is given in Network Byte Order, and is split into
 *  three subfields:
 *    - Type (8 bits)
 *    - Flags (7 bits)
 *    - Length (17 bits)
 *
 *  In RFC1002, the Flags field is listed as being 8 bits wide, but the
 *  lowest order bit is a "length extension" which is used as the high-
 *  order bit of the Length field.  None of the other Flags bits have
 *  ever been defined.  It makes sense, therefore, to view the Length
 *  field as being 17 bytes, and the Flags field as "Reserved, Must Be
 *  Zero".
 */
module SessionService;

// Protocol Details
const SS_PORT = 139;  /// The default NBT Session Service TCP listener port.

// Message Types
const SS_SESSION_MESSAGE    = 0x00; /// Payload follows.
const SS_SESSION_REQUEST    = 0x81; /// Request creation of a NetBIOS session.
const SS_POSITIVE_RESPONSE  = 0x82; /// NetBIOS session accepted.
const SS_NEGATIVE_RESPONSE  = 0x83; /// NetBIOS session denied.
const SS_RETARGET_RESPONSE  = 0x84; /// NetBIOS session redirected.
const SS_SESSION_KEEPALIVE  = 0x85; /// NBT session keep-alive.

// Error Codes
const SS_ERR_NOT_LISTENING  = 0x80; /// Not Listening _On Called_ Name
const SS_ERR_NOT_ANSWERING  = 0x81; /// Not Listening _For Calling_ Name
const SS_ERR_NOT_PRESENT    = 0x82; /// Called Name Not Present
const SS_ERR_INSUFFICIENT   = 0x83; /// Insufficient Resources
const SS_ERR_UNSPECIFIED    = 0x8F; /// Unspecified Error

/* ================================= la fin ================================= */
