/** @file
  PRM Module Static Data

  Defines the structure of the static data buffer for the PRM Sample Context Buffer module.

  Copyright (c) Microsoft Corporation
  SPDX-License-Identifier: BSD-2-Clause-Patent

**/

#ifndef __PRM_STATIC_DATA_SAMPLE_CONTEXT_BUFFER_MODULE_H__
#define __PRM_STATIC_DATA_SAMPLE_CONTEXT_BUFFER_MODULE_H__

#include <Base.h>

#define   SOME_VALUE_ARRAY_MAX_VALUES   16

typedef struct {
  BOOLEAN       Policy1Enabled;
  BOOLEAN       Policy2Enabled;
  UINT8         SomeValueArray[SOME_VALUE_ARRAY_MAX_VALUES];
} STATIC_DATA_SAMPLE_CONTEXT_BUFFER_MODULE;

#endif
