/*
 * This file is part of the Skycoin project, https://skycoin.net
 *
 * Copyright (C) 2014 Pavol Rusnak <stick@satoshilabs.com>
 * Copyright (C) 2019 Skycoin Project
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __PROTECT_H__
#define __PROTECT_H__

#include "types.pb.h"
#include <stdbool.h>

bool protectButton(ButtonRequestType type, bool confirm_only);
bool protectPin(bool use_cached);
bool protectChangePin(void);
bool protectPassphrase(void);

extern bool protectAbortedByInitialize;

// Symbols exported for testing
bool protectChangePinEx(const char* (*)(PinMatrixRequestType, const char*));
const char* requestPin(PinMatrixRequestType type, const char* text);

#endif
