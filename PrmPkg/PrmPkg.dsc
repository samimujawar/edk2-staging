## @file
# Build description file for PrmPkg
#
# Copyright (C) Microsoft Corporation
# SPDX-License-Identifier: BSD-2-Clause-Patent
##

[Defines]
  PLATFORM_NAME                  = Prm
  PLATFORM_GUID                  = C29BB610-84F9-448D-A7DD-5A04C5A54F52
  PLATFORM_VERSION               = 0.1
  DSC_SPECIFICATION              = 0x00010005
  OUTPUT_DIRECTORY               = Build/$(PLATFORM_NAME)
  SUPPORTED_ARCHITECTURES        = IA32|X64
  BUILD_TARGETS                  = DEBUG|RELEASE|NOOPT
  SKUID_IDENTIFIER               = DEFAULT

  DEFINE  PLATFORM_PACKAGE       = $(PLATFORM_NAME)Pkg

[LibraryClasses.common]
  #
  # EDK II Packages
  #
  BaseLib|MdePkg/Library/BaseLib/BaseLib.inf
  BaseMemoryLib|MdePkg/Library/BaseMemoryLib/BaseMemoryLib.inf
  CpuLib|MdePkg/Library/BaseCpuLib/BaseCpuLib.inf
  DebugLib|MdePkg/Library/BaseDebugLibNull/BaseDebugLibNull.inf
  DebugPrintErrorLevelLib|MdePkg/Library/BaseDebugPrintErrorLevelLib/BaseDebugPrintErrorLevelLib.inf
  DxeServicesLib|MdePkg/Library/DxeServicesLib/DxeServicesLib.inf
  MemoryAllocationLib|MdeModulePkg/Library/BaseMemoryAllocationLibNull/BaseMemoryAllocationLibNull.inf
  MtrrLib|UefiCpuPkg/Library/MtrrLib/MtrrLib.inf
  PcdLib|MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
  PeCoffExtraActionLib|MdePkg/Library/BasePeCoffExtraActionLibNull/BasePeCoffExtraActionLibNull.inf
  PeCoffLib|MdePkg/Library/BasePeCoffLib/BasePeCoffLib.inf
  PrintLib|MdePkg/Library/BasePrintLib/BasePrintLib.inf
  RngLib|MdePkg/Library/BaseRngLib/BaseRngLib.inf
  UefiBootServicesTableLib|MdePkg/Library/UefiBootServicesTableLib/UefiBootServicesTableLib.inf

[LibraryClasses.common.DXE_DRIVER, LibraryClasses.common.DXE_RUNTIME_DRIVER]
  #
  # EDK II Packages
  #
  BaseMemoryLib|MdePkg/Library/BaseMemoryLibOptDxe/BaseMemoryLibOptDxe.inf
  DevicePathLib|MdePkg/Library/UefiDevicePathLib/UefiDevicePathLib.inf
  DxeServicesTableLib|MdePkg/Library/DxeServicesTableLib/DxeServicesTableLib.inf
  HobLib|MdePkg/Library/DxeHobLib/DxeHobLib.inf
  MemoryAllocationLib|MdePkg/Library/UefiMemoryAllocationLib/UefiMemoryAllocationLib.inf
  PcdLib|MdePkg/Library/DxePcdLib/DxePcdLib.inf
  UefiDriverEntryPoint|MdePkg/Library/UefiDriverEntryPoint/UefiDriverEntryPoint.inf
  UefiLib|MdePkg/Library/UefiLib/UefiLib.inf
  UefiRuntimeServicesTableLib|MdePkg/Library/UefiRuntimeServicesTableLib/UefiRuntimeServicesTableLib.inf

  #
  # PRM Package
  #
  PrmContextBufferLib|$(PLATFORM_PACKAGE)/Library/DxePrmContextBufferLib/DxePrmContextBufferLib.inf

###################################################################################################
#
# Components Section - List of the modules and components that will be processed by compilation
#                      tools and the EDK II tools to generate PE32/PE32+/Coff image file.
#
###################################################################################################

[Components]
  #
  # PRM Context Buffer Library
  #
  $(PLATFORM_PACKAGE)/Library/DxePrmContextBufferLib/DxePrmContextBufferLib.inf

  #
  # PRM Configuration Driver
  #
  $(PLATFORM_PACKAGE)/PrmConfigDxe/PrmConfigDxe.inf {
    <LibraryClasses>
      NULL|$(PLATFORM_PACKAGE)/Samples/PrmSampleAcpiParameterBufferModule/Library/DxeAcpiParameterBufferModuleConfigLib/DxeAcpiParameterBufferModuleConfigLib.inf
      NULL|$(PLATFORM_PACKAGE)/Samples/PrmSampleContextBufferModule/Library/DxeContextBufferModuleConfigLib/DxeContextBufferModuleConfigLib.inf
      NULL|$(PLATFORM_PACKAGE)/Samples/PrmSampleHardwareAccessModule/Library/DxeHardwareAccessModuleConfigLib/DxeHardwareAccessModuleConfigLib.inf
  }

  #
  # PRM Module Loader Driver
  #
  $(PLATFORM_PACKAGE)/PrmLoaderDxe/PrmLoaderDxe.inf

  #
  # PRM SSDT Installation Driver
  #
  $(PLATFORM_PACKAGE)/PrmSsdtInstallDxe/PrmSsdtInstallDxe.inf

  #
  # PRM Sample Modules
  #
  $(PLATFORM_PACKAGE)/Samples/PrmSamplePrintModule/PrmSamplePrintModule.inf
  $(PLATFORM_PACKAGE)/Samples/PrmSampleAcpiParameterBufferModule/PrmSampleAcpiParameterBufferModule.inf
  $(PLATFORM_PACKAGE)/Samples/PrmSampleHardwareAccessModule/PrmSampleHardwareAccessModule.inf {
    <LibraryClasses>
      DebugLib|MdePkg/Library/BaseDebugLibNull/BaseDebugLibNull.inf
  }
  $(PLATFORM_PACKAGE)/Samples/PrmSampleContextBufferModule/PrmSampleContextBufferModule.inf

  #
  # The SampleMemoryAllocationModule was used during a time in the POC when the OS
  # provided memory allocation services. This module was successful in using those services.
  # Since OS services have been removed (aside from debug prints), this module is no longer
  # relevant but kept around for archival purposes.
  #
  #$(PLATFORM_PACKAGE)/Samples/PrmSampleMemoryAllocationModule/PrmSampleMemoryAllocationModule.inf

[BuildOptions]
# Force deprecated interfaces off
  *_*_*_CC_FLAGS = -D DISABLE_NEW_DEPRECATED_INTERFACES
